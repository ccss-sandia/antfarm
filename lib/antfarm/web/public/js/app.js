function addUploader() {
  div = $('<div class="upload"></div>');
  $('#uploads').append(div.load('/new'));
}

$(function() {
  addUploader();

  $('#add').click(function() {
    addUploader();
  });

  $('#upload-all').click(function() {
    $.each($('form'), function(n, form) {
      $(this).ajaxSubmit({
        complete: function(xhr, status) {
          console.log(status);
        },
        success: function(response, status, xhr, form) {
          form.parent().remove();
        }
      });
    });
    addUploader();
  });
});
