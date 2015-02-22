# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

show = (strategy) ->
  if strategy is 'file'
    $('#bench-by-file').show()
    $('#bench-by-general-allN').hide()
  else if strategy is 'general'
    $('#bench-by-file').hide()
    $('#bench-by-general-allN').show()
  else if strategy is 'allN'
    $('#bench-by-file').hide()
    $('#bench-by-general-allN').show()
  else
    $('#bench-by-file').hide()
    $('#bench-by-general-allN').hide()

ready = ->
  # Hide extra field
  show($('#strategy').val())

  $('#strategy').change ->
    show(this.value)

$(document).ready(ready)
$(document).on('page:load', ready)
