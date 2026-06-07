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
        $('#newsletterMessage').addClass('alert-success').text('If the form has not opened in a new tab, please check your browser settings. You should receive a confirmation email shortly.');
      }, 1200);
    });
  }
})
