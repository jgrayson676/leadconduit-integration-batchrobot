assert = require('chai').assert
querystring = require('querystring')
integration = require('../src/batchrobot')
parser = require('leadconduit-integration').test.types.parser(integration.request.variables())

describe 'BatchRobot Request', ->

  beforeEach ->
    @vars = parser
      lead:
        email: 'foo@bar.com'
        first_name: 'Joe'
        state: null
      chair: 'Steelcase Leap'
      email: 'bar@foo.com'
      delivery_id: '12345'
      foo: null
      batchrobot:
        custom:
          favorite_color: 'blue'
          least_favorite_color: null
    @request = integration.request(@vars)

  afterEach ->
    process.env.NODE_ENV = 'test'

  it 'should have url', ->
    assert.equal @request.url, 'https://app.batchrobot.com/hub/12345/receive'

  it 'should be POST', ->
    assert.equal @request.method, 'POST'

  it 'should send the correct value of fields in lead', ->
    assert.equal querystring.parse(@request.body).first_name, 'Joe'

  it 'should send the correct value of old format custom fields', ->
    assert.equal querystring.parse(@request.body).chair, 'Steelcase Leap'

  it 'should send the correct value of new format custom fields', ->
    assert.equal querystring.parse(@request.body).favorite_color, 'blue'

  it 'should not override lead values with custom values of the same name', ->
    assert.equal querystring.parse(@request.body).email, 'foo@bar.com'

  it 'should not send null fields', ->
    assert.isUndefined querystring.parse(@request.body).state
    assert.isUndefined querystring.parse(@request.body).foo
    assert.isUndefined querystring.parse(@request.body).least_favorite_color

  it 'should handle no custom fields', ->
    assert.isUndefined querystring.parse(integration.request(lead: {email: 'foo@bar.com'}, delivery_id: '12345').body).favorite_color

  it 'should delete delivery_id from content', ->
    assert.isUndefined querystring.parse(@request.body).delivery_id, 'delivery_id is in body'

  it 'should set production url correctly', ->
    process.env.NODE_ENV = 'production'
    assert.equal integration.request(@vars).url, 'https://app.batchrobot.com/hub/12345/receive'

  it 'should set staging url correctly', ->
    process.env.NODE_ENV = 'staging'
    assert.equal integration.request(@vars).url, 'http://staging.app.batchrobot.com/hub/12345/receive'

  it 'should set development url correctly', ->
    process.env.NODE_ENV = 'development'
    assert.equal integration.request(@vars).url, 'http://batchrobot.dev/hub/12345/receive'

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

  it 'should return delivery not found on 404 status code', ->
    res =
      status: 404
    expected =
      batchrobot:
        outcome: 'error'
        reason: 'delivery not found'
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