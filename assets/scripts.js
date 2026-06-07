$(function () {
  $('[data-toggle="tooltip"]').tooltip()

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
      if (action.indexOf('list-manage.com') !== -1) {
        var jsonpUrl = action.replace('/post?', '/post-json?');
        // Append form data and JSONP callback
        if (jsonpUrl.indexOf('?') === -1) jsonpUrl += '?';
        jsonpUrl = jsonpUrl + '&' + data + '&c=?';
        $.ajax({
          url: jsonpUrl,
          dataType: 'jsonp',
          success: function (resp) {
            if (resp.result === 'success') {
              var msg = resp.msg ? resp.msg.replace(/"/g, '') : '';
              var text = 'Thanks — please check your email to confirm subscription.';
              if (msg) {
                text += ' Mailchimp response: ' + msg;
              }
              text += ' If you do not receive a confirmation email, check your spam folder and verify your Mailchimp list settings (double opt-in and sender email).';
              $('#newsletterMessage').addClass('alert alert-success').text(text);
            } else {
              var msg = resp.msg || 'Subscription failed. Please try again.';
              msg = msg.replace(/"/g, '');
              if (/already subscribed/i.test(msg)) {
                msg = 'You are already subscribed. Please check your inbox or spam folder for the confirmation email.';
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
            $('#newsletterMessage').addClass('alert alert-danger').text('Subscription failed due to a network error. Please try again.');
            $button.prop('disabled', false).text('Subscribe');
          }
        });
      } else {
        // Non-Mailchimp providers: fall back to normal submit to allow provider handling
        // Remove our handler and submit the form normally
        $form.off('submit');
        $form.submit();
      }
    });
  }
})
