# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
  # Hide extra field
  $('#bench-by-file').hide()
  $('#bench-by-general').hide()
  $('#bench-by-allN').hide()

  $('#strategy').change ->
    strategy = this.value
    if strategy is 'file'
      $('#bench-by-file').show()
      $('#bench-by-general').hide()
      $('#bench-by-allN').hide()
    else if strategy is 'general'
      $('#bench-by-general').show()
      $('#bench-by-file').hide()
      $('#bench-by-allN').hide()
    else if strategy is 'allN'
      $('#bench-by-allN').show()
      $('#bench-by-file').hide()
      $('#bench-by-general').hide()
    else
      $('#bench-by-file').hide()
      $('#bench-by-general').hide()
      $('#bench-by-allN').hide()

$(document).ready(ready)
$(document).on('page:load', ready)
