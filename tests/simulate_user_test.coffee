Helper = require('hubot-test-helper')
chai = require("chai");
expect = require('chai').expect
nock = require('nock')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/simulate_user.coffee')
require('../scripts/simulate_user.coffee')

simulation_url = 'http://simulation-url'
process.env.SIMULATION_API_BASE_URL = simulation_url
fake_mail = 'fake@mail.com'
fake_token = 'a_fake_token'
fake_client = 'a_fake_client'

describe 'create_user', ->
  room = null
  result = null
  query = null

  beforeEach ->
    room = helper.createRoom()
    do nock.disableNetConnect

  afterEach ->
    room.destroy()
    nock.cleanAll()

  context 'when the API returns a 200 status code and a correct user', ->
    beforeEach (done) ->
      query = nock(simulation_url)
        .post('/auth')
        .reply (uri, requestBody) ->
          return [
  #           Status
              200,
  #           Response body
              {
                status: "success", data: {id: 0, provider: "email", uid: requestBody.email, name: "Foo", email: requestBody.email}
              },
  #           Response headers
              {
                'access-token': fake_token,
                'client': fake_client,
                'uid': requestBody.email
              }
            ]
      result = room.robot.create_user(fake_mail)
      setTimeout done, 100

    it 'makes an HTTP POST call', ->
      query.done()

    it 'returns a Promise', ->
      expect(result).to.be.a('promise')

    it 'resolves with an object having "user" and "headers" properties', (done) ->
      result.then (res) ->
        expect(res).to.have.property('user')
        expect(res).to.have.property('headers')
        done()
      return

    it 'resolves with a user having an id, uid, email and name; uid and email are equals to fake_mail', (done) ->
      result.then (res) ->
        user = res.user
        expect(user).to.have.property('id')
        expect(user).to.have.property('uid')
        expect(user).to.have.property('email')
        expect(user).to.have.property('name')
        expect(user.uid).to.eq user.email
        expect(user.uid).to.eq fake_mail
        done()
      return

    it 'resolves with headers: access-token, client, uid and they are set to the correct values', (done) ->
      result.then (res) ->
        headers = res.headers
        expect(headers).to.have.property('access-token')
        expect(headers).to.have.property('client')
        expect(headers).to.have.property('uid')
        expect(headers['access-token']).to.eq fake_token
        expect(headers['client']).to.eq fake_client
        expect(headers['uid']).to.eq fake_mail
        done()
      .catch (err) ->
        expect.fail(err, 'no error should be raised')
        done()
      return

  context 'when the API returns a 422 status code and an error because the email was already taken', ->
    beforeEach (done) ->
      query = nock(simulation_url)
        .post('/auth')
        .reply (uri, requestBody) ->
          return [
            422,
            {status:'error',data:{id: null, provider: "email", uid: "", name: null, image: null, email: requestBody.email}, errors:{email: ["has already been taken"], full_messages: ["Email has already been taken"]}},
            { }
          ]
      result = room.robot.create_user(fake_mail)
      setTimeout done, 100

    it 'rejects with the errors', (done) ->
      result.then (res) ->
        expect.fail(res, 'an error should be raised')
        done()
      .catch (err) ->
        expect(err).to.have.property('errors')
        done()
      return

  context 'when the HTTP call returns an error', ->
    expected_error = 'an error occurred'

    beforeEach (done) ->
      query = nock(simulation_url)
        .post('/auth')
        .replyWithError(expected_error)
      result = room.robot.create_user(fake_mail)
      setTimeout done, 100

    it 'rejects with an error', (done) ->
      result.then (res) ->
        expect.fail(res, 'an error should be raised')
        done()
      .catch (err) ->
        expect(err).to.be.an('error')
        done()
      return

describe 'get_symptom_by_name', ->
  room = null
  result = null
  query = null
  headers = {'access-token': fake_token, 'client': fake_client, 'uid': fake_mail}
  symptoms_path = '/symptoms'

  beforeEach ->
    room = helper.createRoom()
    do nock.disableNetConnect

  afterEach ->
    room.destroy()
    nock.cleanAll()

  context 'when the API returns a 200 status code and a single symptom', ->
    unique_symptom_name = 'unique symptom name'

    beforeEach (done) ->
      query = nock(simulation_url)
        .matchHeader('uid', fake_mail)
        .matchHeader('access-token', fake_token)
        .matchHeader('client', fake_client)
        .post(symptoms_path)
        .query({name: unique_symptom_name})
        .reply (uri, requestBody) ->
          return [
            200,
            {
              "symptoms": [
                {
                  "id": 1,
                  "name": unique_symptom_name,
                  "short_description": null,
                  "long_description": null,
                  "gender_filter": "both"
                }
              ]
            },
            {
              'access-token': fake_token,
              'client': fake_client,
              'uid': fake_mail
            }
          ]
      result = room.robot.get_symptom_by_name(unique_symptom_name, headers)
      setTimeout done, 100

    it 'makes an HTTP POST call', ->
      query.done()

    it 'returns a Promise', ->
      expect(result).to.be.a('promise')

    it 'resolves with a symptom having an id, name, short_description, long_description and gender_filter properties', (done) ->
      result.then (res) ->
        expect(res).to.have.property('id')
        expect(res).to.have.property('name')
        expect(res).to.have.property('short_description')
        expect(res).to.have.property('long_description')
        expect(res).to.have.property('gender_filter')
        done()
      return

    it 'resolves with a symptom matching the requested name', (done) ->
      result.then (res) ->
        expect(res.name).to.eq unique_symptom_name
        done()
      return

  context 'when the API returns a 200 status code and 2 symptoms matching the given name', ->
    common_prefix_symptom_name = 'common'
    suffix_symptom_1 = ' symptom_1'
    suffix_symptom_2 = ' symptom_2'

    beforeEach (done) ->
      query = nock(simulation_url)
        .matchHeader('uid', fake_mail)
        .matchHeader('access-token', fake_token)
        .matchHeader('client', fake_client)
        .post(symptoms_path)
        .query({name: common_prefix_symptom_name})
        .reply (uri, requestBody) ->
          return [
            200,
            {
              "symptoms": [
                {
                  "id": 1,
                  "name": common_prefix_symptom_name + suffix_symptom_1,
                  "short_description": null,
                  "long_description": null,
                  "gender_filter": "both"
                },
                {
                  "id": 2,
                  "name": common_prefix_symptom_name + suffix_symptom_2,
                  "short_description": null,
                  "long_description": null,
                  "gender_filter": "both"
                }
              ]
            },
            {
              'access-token': fake_token,
              'client': fake_client,
              'uid': fake_mail
            }
          ]
      result = room.robot.get_symptom_by_name(common_prefix_symptom_name, headers)
      setTimeout done, 100

    it 'resolves with the first symptom matching the requested name', (done) ->
      result.then (res) ->
        expect(res.name).to.eq(common_prefix_symptom_name + suffix_symptom_1)
        done()
      return

  context 'when the API returns a 200 status code and no symptom matching the given name', ->
    unknown_name = 'foobar'

    beforeEach (done) ->
      query = nock(simulation_url)
        .matchHeader('uid', fake_mail)
        .matchHeader('access-token', fake_token)
        .matchHeader('client', fake_client)
        .post(symptoms_path)
        .query({name: unknown_name})
        .reply (uri, requestBody) ->
          return [
            200,
            {
              "symptoms": [ ]
            },
            {
              'access-token': fake_token,
              'client': fake_client,
              'uid': fake_mail
            }
          ]
      result = room.robot.get_symptom_by_name(unknown_name, headers)
      setTimeout done, 100

    it 'resolves with null', (done) ->
      result.then (res) ->
        expect(res).to.be.null
        done()
      return

  context 'when the HTTP call returns an error', ->
    expected_error = 'an error occurred'

    beforeEach (done) ->
      query = nock(simulation_url)
        .post(symptoms_path)
        .replyWithError(expected_error)
      result = room.robot.get_symptom_by_name('do not care about given name', headers)
      setTimeout done, 100

    it 'rejects with an error', (done) ->
      result.then (res) ->
        expect.fail(res, 'an error should be raised')
        done()
      .catch (err) ->
        expect(err).to.be.an('error')
        done()
      return


xdescribe 'simulate', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

  afterEach ->
    room.destroy()

  context 'when user says simulate with 2 users and 2 symptoms, one for 1 occurrence and the second for 2 occurrences, without gps localisation parameters to hubot', ->
    beforeEach ->
      # TODO NOTE Je ne vais pas avoir besoin de simuler l'entiereté des requetes HTTP.
      # TODO NOTE Je vais simplement faire un stub des méthodes create_user, get_symptom_by_name, create_occurrence et vérifier qu'ils ont bien été appelés le bon nombre de fois avec les bons paramètres (en utilisant Sinon.js)
      # TODO NOTE c'est donc uniquement lorsque je teste ces méthodes que je vais mocker les requetes HTTP

      room.user.say 'alice', 'hubot simulate users=2 symptoms=Abdominal Pain;1;Divergent strabismus;2;'

    it 'makes 2 calls to the API to create users and 6 calls to the API to create occurrences', ->
      #todo
#      Stub the HTTP POST call
#      sinon.stub(room.robot.http, 'post');
      expect(requests.length).to.eq 10

    xit 'stores 2 users in the brain of hubot', ->
      #todo

