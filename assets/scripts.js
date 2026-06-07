$(function () {
  $('[data-toggle="tooltip"]').tooltip()

  var $newsletterForm = $('#newsletterForm');
  if ($newsletterForm.length) {
    $newsletterForm.on('submit', function () {
      var $button = $(this).find('button[type=submit]');
      $button.prop('disabled', true).text('Submitting...');
      $('#newsletterMessage').removeClass('alert-success alert-danger').text('');
      setTimeout(function () {
        $button.prop('disabled', false).text('Subscribe');
        $('#newsletterMessage').addClass('alert-success').text('Your signup is being submitted. Please complete any confirmation step on the next page and check your email for the double opt-in message.');
      }, 1200);
    });
  }
})
