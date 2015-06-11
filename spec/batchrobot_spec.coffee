assert = require('chai').assert
fields = require('leadconduit-fields')
integration = require('../src/batchrobot')

describe 'Zip Code Request', ->

  beforeEach ->
    process.env.ZIPCODES_COM_API_KEY = '1234'
    @vars = lead: { postal_code: '12345'}
    @request = integration.request(@vars)

  it 'should have url', ->
    assert.equal @request.url, 'http://api.zip-codes.com/ZipCodesAPI.svc/1.0/QuickGetZipCodeDetails/12345?key=1234'

  it 'should be GET', ->
    assert.equal @request.method, 'GET'

  it 'should accept JSON', ->
    assert.equal @request.headers.Accept, 'application/json'

  it 'should mask API key', ->
    assert.equal @vars.apiKey, '****'

describe 'Zip Code Validate', ->

  it 'should not allow null zip code', ->
    error = integration.validate(lead: { postal_code: null })
    assert.equal error, 'zip code must not be blank'

  it 'should not allow undefined zip code', ->
    error = integration.validate(lead: {})
    assert.equal error, 'zip code must not be blank'

  it 'should not allow an invalid zip code', ->
    error = integration.validate(lead: fields.buildLeadVars(postal_code: 'donkey'))
    assert.equal error, 'zip code must be valid'

  it 'should not error when zip code is valid', ->
    error = integration.validate(lead: fields.buildLeadVars(postal_code: '12345'))
    assert.isUndefined error

  it 'should not error when zip code is missing the valid key', ->
    error = integration.validate(lead: { postal_code: '12345' })
    assert.isUndefined error

describe 'Success Response', ->

  it 'should set a success outcome for a valid zip code', ->
    res =
      body: """
            {
            "City":"foo",
            "State":"bar",
            "Latitude":"12",
            "Longitude":"34",
            "ZipCode":"12345",
            "County":"foobar"
            }
            """
    expected =
      quickdetails:
        outcome: 'success'
        billable: 1
    response = integration.response({}, {}, res)
    assert.deepEqual expected.quickdetails.outcome, response.quickdetails.outcome

describe 'Failure Response', ->

  it 'outcome should be failure when zip code does not exist', ->
    res =
      body: """
            {}
            """
    expected =
      quickdetails:
        outcome: 'failure'
        reason: 'invalid zip code.'
        billable: 1
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

describe 'Error Response', ->

  it 'should return error outcome on invalid zip code', ->
    res =
      body: """
            {
            "Error":"Invalid user data."
            }
            """
    expected =
      quickdetails:
        error: 'Invalid user data.'
        outcome: 'error'
        reason: 'invalid user data.'
        billable: 1
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response