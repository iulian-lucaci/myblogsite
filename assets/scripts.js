$(function () {
  $('[data-toggle="tooltip"]').tooltip();

  function trackEventIfAllowed(eventName, params) {
    if (typeof window.__sendSiteAnalyticsEvent === 'function') {
      window.__sendSiteAnalyticsEvent(eventName, params || {});
    }
  }

  function isExternalLink(link) {
    if (!link || !link.href) return false;
    if (link.protocol === 'mailto:' || link.protocol === 'tel:') return false;
    var url = new URL(link.href, window.location.href);
    return url.origin !== window.location.origin;
  }

  $(document).on('click', 'a', function (event) {
    var $link = $(this);
    var href = $link.attr('href') || '';
    if (!href || $link.attr('target') === '_blank' || isExternalLink(this)) {
      trackEventIfAllowed('outbound_link_click', {
        link_url: href,
        link_text: ($link.text() || '').trim(),
        link_target: $link.attr('target') || '_self'
      });
    }
  });

  var $newsletterForm = $('#newsletterForm');
  if ($newsletterForm.length) {
    $newsletterForm.on('submit', function (e) {
      e.preventDefault();
      var $form = $(this);
      var action = $form.attr('action') || '';
      var $button = $form.find('button[type=submit]');
      $button.prop('disabled', true).text('Submitting...');
      $('#newsletterMessage').removeClass('alert alert-success alert-danger').text('');

      var data = $form.serialize();

      // Mailchimp requires JSONP for AJAX submissions; detect list-manage.com
      var isMailchimpAction = false;
      try {
        var parsedAction = new URL(action, window.location.href);
        var host = (parsedAction.hostname || '').toLowerCase();
        isMailchimpAction = host === 'list-manage.com' || host.endsWith('.list-manage.com');
      } catch (err) {
        isMailchimpAction = false;
      }
      if (isMailchimpAction) {
        var jsonpUrl = action.replace('/post?', '/post-json?');
        // Append form data and JSONP callback
        if (jsonpUrl.indexOf('?') === -1) jsonpUrl += '?';
        jsonpUrl = jsonpUrl + '&' + data + '&c=?';
        $.ajax({
          url: jsonpUrl,
          dataType: 'jsonp',
          success: function (resp) {
            var wasSuccessful = resp && resp.result === 'success';

            trackEventIfAllowed('newsletter_signup', {
              provider: 'mailchimp',
              status: wasSuccessful ? 'success' : 'error',
              message: resp && resp.msg ? String(resp.msg) : ''
            });

            if (wasSuccessful) {
              var msg = resp.msg ? resp.msg.replace(/"/g, '') : '';
              var text = 'Thanks — your subscription request was received.';
              if (msg) {
                text += ' ' + msg;
              }
              text += ' If you are a new subscriber, please check your inbox and spam folder for the Mailchimp confirmation email.';
              text += ' If you already subscribed previously, no new confirmation email will be sent.';
              $('#newsletterMessage').addClass('alert alert-success').text(text);
            } else {
              var msg = resp.msg || 'Subscription failed. Please try again.';
              msg = msg.replace(/"/g, '');
              if (/already subscribed/i.test(msg)) {
                msg = 'You are already subscribed. No additional confirmation email will be sent. Please check your inbox or spam folder.';
              } else if (/too many recent signup requests/i.test(msg)) {
                msg = 'Too many signup attempts. Please wait a few minutes and try again.';
              } else {
                msg = 'Subscription failed. Please try again or contact support if you do not receive a confirmation email.';
              }
              $('#newsletterMessage').addClass('alert alert-danger').text(msg);
            }
            $button.prop('disabled', false).text('Subscribe');
          },
          error: function () {
            trackEventIfAllowed('newsletter_signup', {
              provider: 'mailchimp',
              status: 'network_error'
            });
            $('#newsletterMessage').addClass('alert alert-danger').text('Subscription failed due to a network error. Please try again.');
            $button.prop('disabled', false).text('Subscribe');
          }
        });
      } else {
        trackEventIfAllowed('newsletter_signup', {
          provider: 'other',
          status: 'redirected'
        });
        // Non-Mailchimp providers: fall back to normal submit to allow provider handling
        // Remove our handler and submit the form normally
        $form.off('submit');
        $form.submit();
      }
    });
  }
});
