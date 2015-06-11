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

  try
    req =
      method: 'POST'
      url: "#{baseUrl}#{vars.deliveryId}#{'/receive'}"
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
      body: body

request.variables = ->
  [
    { name: 'lead.postal_code', type: 'string', required: true, description: 'Zip code' }
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

  event.billable = 0

  batchrobot: event

response.variables = ->
  [
    { name: 'batchrobot.outcome', type: 'string', description: 'Was the post successful? Success or failure.'},
    { name: 'batchrobot.reason', type: 'string', description: 'If the post failed this is the error reason.'},
    { name: 'batchrobot.billable', type: 'number', description: 'If the event is billable, else 0.' }
  ]

#
# Exports ----------------------------------------------------------------
#
#
module.exports =
  name: 'BatchRobot Append'
  request: request
  response: response

