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
      $('#newsletterMessage').removeClass('alert-success alert-danger').text('');

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
              $('#newsletterMessage').addClass('alert-success').text('Thanks — please check your email to confirm subscription.');
            } else {
              var msg = resp.msg || 'Subscription failed. Please try again.';
              $('#newsletterMessage').addClass('alert-danger').text(msg.replace(/\"/g, ''));
            }
            $button.prop('disabled', false).text('Subscribe');
          },
          error: function () {
            $('#newsletterMessage').addClass('alert-danger').text('Subscription failed due to a network error.');
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
