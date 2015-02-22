# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

show = (strategy) ->
  if strategy is 'file'
    $('#view-by-file').show()
    $('#view-by-import-tag').hide()
  if strategy is 'import_tag'
    $('#view-by-import-tag').show()
    $('#view-by-file').hide()
  if strategy is 'all'
    $('#view-by-import-tag').hide()
    $('#view-by-file').hide()

ready = ->
  # Hide extra field
  show($('#strategy').val())

  $('#strategy').change ->
    show(this.value)

$(document).ready(ready)
$(document).on('page:load', ready)
