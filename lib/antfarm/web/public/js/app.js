$(function() {
  $('.upload').load('/new');

  $('#add').click(function() {
    div = $('<div class="upload"></div>');
    div.insertAfter('.upload:last').load('/new');
  });

  $('#upload-all').click(function() {
    $.each($('form'), function(n, form) {
      $(this).ajaxSubmit({
        complete: function(xhr, status) {
          console.log(status);
        }
      });
    });
  });
});
