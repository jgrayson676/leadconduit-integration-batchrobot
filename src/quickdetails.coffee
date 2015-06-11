baseUrl = 'http://api.zip-codes.com/ZipCodesAPI.svc/1.0/QuickGetZipCodeDetails/'


#
# Request Function -------------------------------------------------------
#

request = (vars) ->

  vars.apiKey ?= process.env.ZIPCODES_COM_API_KEY

  try
    req =
      method: 'GET'
      url: "#{baseUrl}#{vars.lead.postal_code}?key=#{vars.apiKey}"
      headers:
        'Accept': 'application/json'

  finally
    vars.apiKey = Array(vars.apiKey.length + 1).join('*')

request.variables = ->
  [
    { name: 'lead.postal_code', type: 'string', required: true, description: 'Zip code' }
  ]

#
# Validate Function ------------------------------------------------------
#

validate = (vars) ->
  return 'zip code must not be blank' unless vars.lead.postal_code?
  if !vars.lead.postal_code.valid and vars.lead.postal_code.valid?
    return 'zip code must be valid'

#
# Response Function ------------------------------------------------------
#


response = (vars, req, res) ->
  temp = JSON.parse(res.body)
  event = {}
  for key, value of temp
    event[key.toLowerCase()] = value

  if event.error?
    event.outcome = 'error'
    event.reason = event.error.toLowerCase()
  else if Object.keys(event).length == 0
    event.outcome = 'failure'
    event.reason = 'invalid zip code.'
  else
    event.outcome = 'success'

  event.billable = 1

  quickdetails: event

response.variables = ->
  [
    { name: 'quickdetails.city', type: 'string', description: 'The city in which this zip code is located.'}
    { name: 'quickdetails.state', type: 'string', description: 'The state in which this zip code is located.'}
    { name: 'quickdetails.latitude', type: 'string', description: 'The latitude at which this zip code is located.'}
    { name: 'quickdetails.longitude', type: 'string', description: 'The longitude at which this zip code is located.' }
    { name: 'quickdetails.zipcode', type: 'string', description: 'The original zip code.' }
    { name: 'quickdetails.county', type: 'number', description: 'The county in which this zip code is located' },
    { name: 'quickdetails.outcome', type: 'string', description: 'Was the information about the zip code found successfully? Success or failure.'},
    { name: 'quickdetails.reason', type: 'string', description: 'If the lookup failed this is the error reason.'},
    { name: 'quickdetails.billable', type: 'number', description: 'If the event is billable, else 0.' }
  ]

#
# Exports ----------------------------------------------------------------
#
#
module.exports =
  name: 'Zip Code Data Append'
  validate: validate
  request: request
  response: response

