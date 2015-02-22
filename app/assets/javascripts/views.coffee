# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
  # Hide extra field
  $('#view-by-file').hide()
  $('#view-by-import-tag').hide()

  $('#view-strategy').change ->
    strategy = this.value
    if strategy is 'file'
      $('#view-by-file').show()
      $('#view-by-import-tag').hide()
    if strategy is 'import_tag'
      $('#view-by-import-tag').show()
      $('#view-by-file').hide()
    if strategy is 'all'
      $('#view-by-import-tag').hide()
      $('#view-by-file').hide()

$(document).ready(ready)
$(document).on('page:load', ready)
