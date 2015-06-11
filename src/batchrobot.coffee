baseUrl = 'https://app.batchrobot.com/hub/'
flatten = require('flat').flatten
querystring = require('querystring')


#
# Request Function -------------------------------------------------------
#

request = (vars) ->

  content = {}
  for key, value of flatten(vars.lead)
    content[key] = value

  for key, value of flatten(vars, {safe:true})
    content[key] = value if !content[key]? and key?.indexOf('.') == -1

  body = querystring.stringify(content)



  method: 'POST'
  url: "#{baseUrl}#{vars.delivery_id}#{'/receive'}"
  headers:
    'Content-Type': 'application/x-www-form-urlencoded'
  body: body

request.variables = ->
  [
    { name: 'delivery_id', type: 'string', required: true, description: 'delivery id' }
  ]

#
# Response Function ------------------------------------------------------
#


response = (vars, req, res) ->
  event = {}
  if res.status == 400
    event.outcome = 'error'
    event.reason = 'invalid delivery id'
  else if res.status != 200
    event.outcome = 'error'
    event.reason = 'unknown error ' + res.body
  else
    event.outcome = 'success'


  batchrobot: event

response.variables = ->
  [
    { name: 'batchrobot.outcome', type: 'string', description: 'Was the post successful? Success or failure.'},
    { name: 'batchrobot.reason', type: 'string', description: 'If the post failed this is the error reason.'},
  ]

#
# Exports ----------------------------------------------------------------
#
#
module.exports =
  name: 'BatchRobot Delivery'
  request: request
  response: response

