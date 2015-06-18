assert = require('chai').assert
fields = require('leadconduit-fields')
querystring = require('querystring')
integration = require('../src/batchrobot')

describe 'BatchRobot Request', ->

  beforeEach ->
    @vars =
      lead:
        fields.buildLeadVars({
          email: 'foo@bar.com'
          first_name: 'Joe'
          })
      chair: 'Steelcase Leap'
      email: 'bar@foo.com'
      delivery_id: '12345'

    #  chair: 'Steelcase Leap'
    #  email: 'bar@foo.com'
    @request = integration.request(@vars)

  it 'should have url', ->
    assert.equal @request.url, 'https://app.batchrobot.com/hub/12345/receive'

  it 'should be POST', ->
    assert.equal @request.method, 'POST'

  it 'should send the correct value of fields in lead', ->
    assert.equal querystring.parse(@request.body).first_name, 'Joe'

  it 'should send the correct value of custom fields', ->
    assert.equal querystring.parse(@request.body).chair, 'Steelcase Leap'

  it 'should not override lead values with custom values of the same name', ->
    assert.equal querystring.parse(@request.body).email, 'foo@bar.com'

describe 'Validate Function', ->
  it 'should not return valid when delivery_id is missing', ->
    vars =
      lead: {email: 'foo@bar.com'}
      chair: 'Steelcase Leap'
    assert.equal integration.validate(vars), 'must have a delivery id'

describe 'Success Response', ->

  it 'should set a success outcome for a 200 status code', ->
    res =
      status: 200
    expected =
      batchrobot:
        outcome: 'success'
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

describe 'Error Response', ->

  it 'should return invalid delivery id error on 400 status code', ->
    res =
      status: 400
    expected =
      batchrobot:
        outcome: 'error'
        reason: 'invalid delivery id'
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response

  it 'should return unknown error on any status code other than 200 or 400', ->
    res =
      status: 500
    expected =
      batchrobot:
        outcome: 'error'
        reason: 'unknown error undefined'
    response = integration.response({}, {}, res)
    assert.deepEqual expected, response