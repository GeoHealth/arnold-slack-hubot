Helper = require('hubot-test-helper')
chai = require("chai");
expect = chai.expect
nock = require('nock')
tk = require('timekeeper');
sinon = require('sinon')
sinonChai = require("sinon-chai");
chai.use(sinonChai);

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
        .get(symptoms_path)
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
        .get(symptoms_path)
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
        .get(symptoms_path)
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
        .get(symptoms_path)
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

describe 'generate_occurrence', ->
  room = null
  result = null
  fake_symptom_id_1 = 1
  current_date = new Date(1332671929000)    # 25/03/2012
  fake_gps_coordinate = {latitude: 50.2222222222, longitude: 4.2222222222, accuracy: 1}
  fake_range = 100
  fake_start_date = new Date(1331379529000) # 10/03/2012
  fake_end_date = new Date(1332243529000)   # 20/03/2012

  beforeEach ->
    room = helper.createRoom()
    tk.freeze(current_date)

  afterEach ->
    room.destroy()
    tk.reset()

  context 'when no gps location and no dates are given', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1)

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id and a date', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date equals to the current date', ->
      expect(result.occurrence.date).to.eql current_date

  context 'when a gps location is given but no range', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, fake_gps_coordinate)

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')
      expect(result.occurrence).to.have.property('gps_coordinate')

    it 'contains a latitude, longitude and accuracy under gps_coordinate', ->
      expect(result.occurrence.gps_coordinate).to.have.property('latitude')
      expect(result.occurrence.gps_coordinate).to.have.property('longitude')
      expect(result.occurrence.gps_coordinate).to.have.property('accuracy')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date equals to the current date', ->
      expect(result.occurrence.date).to.eql current_date

    it 'has the latitude equals to the given latitude', ->
      expect(result.occurrence.gps_coordinate.latitude).to.eq fake_gps_coordinate.latitude

    it 'has the longitude equals to the given longitude', ->
      expect(result.occurrence.gps_coordinate.longitude).to.eq fake_gps_coordinate.longitude

    it 'has the accuracy equals to the given accuracy', ->
      expect(result.occurrence.gps_coordinate.accuracy).to.eq fake_gps_coordinate.accuracy

  context 'when a gps location and a range are given', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, fake_gps_coordinate, fake_range)

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')
      expect(result.occurrence).to.have.property('gps_coordinate')

    it 'contains a latitude, longitude and accuracy under gps_coordinate', ->
      expect(result.occurrence.gps_coordinate).to.have.property('latitude')
      expect(result.occurrence.gps_coordinate).to.have.property('longitude')
      expect(result.occurrence.gps_coordinate).to.have.property('accuracy')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date equals to the current date', ->
      expect(result.occurrence.date).to.eql current_date

    it 'has the latitude equals to a random latitude close to the original one', ->
      expect(result.occurrence.gps_coordinate.latitude).to.be.closeTo(fake_gps_coordinate.latitude, 0.005)

    it 'has the longitude equals to a random longitude close to the original one', ->
      expect(result.occurrence.gps_coordinate.longitude).to.be.closeTo(fake_gps_coordinate.longitude, 0.005)

    it 'has the accuracy equals to the given accuracy', ->
      expect(result.occurrence.gps_coordinate.accuracy).to.eq fake_gps_coordinate.accuracy


  context 'when a start_date and end_date are given as date', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, null, 0, fake_start_date, fake_end_date)

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date somewhere in the range of start_date and end_date', ->
      expect(result.occurrence.date).to.within(fake_start_date, fake_end_date)

  context 'when a start_date is given as date and end_date is null', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, null, 0, fake_start_date, null)

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date somewhere in the range of start_date and current_date', ->
      expect(result.occurrence.date).to.within(fake_start_date, current_date)

  context 'when a start_date and end_date are given as string (without hours)', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, null, 0, '10-03-2012', '20-03-2012')

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date somewhere in the range of start_date and end_date', ->
      expect(result.occurrence.date).to.within(fake_start_date, fake_end_date)

  context 'when a start_date and end_date are given as string (with hours)', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, null, 0, '10-03-2012 12:30:00', '20-03-2012 10:00:00')

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date somewhere in the range of start_date and end_date', ->
      expect(result.occurrence.date).to.within(fake_start_date, fake_end_date)

  context 'when a start_date and end_date are given as string in an invalid format', ->
    beforeEach ->
      result = room.robot.generate_occurrence(fake_symptom_id_1, null, 0, '10 03/2012', '20 03/2012')

    it 'returns an object with the key "occurrence"', ->
      expect(result).to.have.property('occurrence')

    it 'contains a symptom_id, a date and a gps_coordinate', ->
      expect(result.occurrence).to.have.property('symptom_id')
      expect(result.occurrence).to.have.property('date')

    it 'has the symptom_id equals to the given fake_symptom_id_1', ->
      expect(result.occurrence.symptom_id).to.eq fake_symptom_id_1

    it 'has the date equals null', ->
      expect(result.occurrence.date).to.be.null



describe 'simulate_occurrences', ->
  room = null
  result = null
  query = null
  gps_position = null
  radius = null
  occurrences_path = '/occurrences'
  channel_msg = null
  channel_msg_stub = null
  generate_occurrence_stub = null
  start_date = null
  end_date = null

  beforeEach ->
    room = helper.createRoom()
    do nock.disableNetConnect
    channel_msg = {send: (msg) -> return}
    channel_msg_stub = sinon.spy(channel_msg, 'send')

  afterEach ->
    room.destroy()
    nock.cleanAll()

  context 'when a correct symptom_id is given', ->
    symptom_id = 1

    context 'when headers are valid', ->
      headers = {'access-token': fake_token, 'client': fake_client, 'uid': fake_mail}

      context 'when nb_of_occurrences equals 2', ->
        nb_of_occurrences = 2

        context 'when gps_position, radius, start_date and end_date are null', ->
          fake_occurrence = {occurrence: {symptom_id: symptom_id, date: new Date}}

          beforeEach ->
            generate_occurrence_stub = sinon.stub(room.robot, 'generate_occurrence')
            generate_occurrence_stub.returns(fake_occurrence)
            query = nock(simulation_url)
              .matchHeader('uid', fake_mail)
              .matchHeader('access-token', fake_token)
              .matchHeader('client', fake_client)
              .post(occurrences_path)
              .times(nb_of_occurrences)
              .reply (uri, requestBody) ->
                return [
                  201,
                  {
                    "id": 44,
                    "symptom_id": requestBody.symptom_id,
                    "date": requestBody.date,
                    "gps_coordinate_id": null,
                    "created_at": "2017-03-16T16:16:52.547Z",
                    "updated_at": "2017-03-16T16:16:52.547Z",
                    "user_id": 1
                  },
                  {
                    'access-token': fake_token,
                    'client': fake_client,
                    'uid': fake_mail
                  }
                ]
            result = room.robot.simulate_occurrences(symptom_id, headers, nb_of_occurrences, gps_position, radius, channel_msg, start_date, end_date)

          afterEach ->
            generate_occurrence_stub.reset()

          it 'makes a call to generate_occurrence with the symptom_id, gps_position, radius, start_date and end_date', ->
            expect(generate_occurrence_stub).to.have.been.calledWithExactly(symptom_id, gps_position, radius, start_date, end_date)

          it 'makes 2 call to POST occurrences', ->
            query.done()

          it 'posts 2 messages to the channel with the detail of the created occurrence', (done) ->
            setTimeout () ->
              expect(channel_msg_stub).to.have.been.calledWithMatch(/Occurrence created.*/)
              expect(channel_msg_stub).to.have.been.calledTwice
              done()
            , 100 # wait for the message to be posted

        context 'when gps_position and radius are given', ->
          gps_position = {latitude: "50.2365548", longitude: "4.25636"}
          radius = 0
          fake_occurrence = {occurrence: {symptom_id: symptom_id, date: new Date, gps_coordinate:  {latitude: "50.2365548", longitude: "4.25636"}}}

          beforeEach ->
            generate_occurrence_stub = sinon.stub(room.robot, 'generate_occurrence')
            generate_occurrence_stub.returns(fake_occurrence)
            query = nock(simulation_url)
              .matchHeader('uid', fake_mail)
              .matchHeader('access-token', fake_token)
              .matchHeader('client', fake_client)
              .post(occurrences_path)
              .times(nb_of_occurrences)
              .reply (uri, requestBody) ->
                return [
                  201,
                  {
                    "id": 39,
                    "symptom_id": 200,
                    "date": "2017-02-13T20:31:05.863Z",
                    "gps_coordinate_id": 21,
                    "created_at": "2017-03-16T11:12:41.123Z",
                    "updated_at": "2017-03-16T11:12:41.123Z",
                    "user_id": 1,
                    "gps_coordinate": {
                      "id": 21,
                      "accuracy": null,
                      "altitude": null,
                      "altitude_accuracy": null,
                      "heading": null,
                      "speed": null,
                      "latitude": 50.2365548,
                      "longitude": 4.25636,
                      "created_at": "2017-03-16T11:12:41.119Z",
                      "updated_at": "2017-03-16T11:12:41.119Z"
                    }
                  },
                  {
                    'access-token': fake_token,
                    'client': fake_client,
                    'uid': fake_mail
                  }
                ]
            result = room.robot.simulate_occurrences(symptom_id, headers, nb_of_occurrences, gps_position, radius, channel_msg, start_date, end_date)

          afterEach ->
            generate_occurrence_stub.reset()

          it 'makes a call to generate_occurrence with the symptom_id, gps_position and radius', ->
            expect(generate_occurrence_stub).to.have.been.calledWithExactly(symptom_id, gps_position, radius, start_date, end_date)

          it 'makes 2 call to POST occurrences', ->
            query.done()

          it 'posts 2 messages to the channel with the detail of the created occurrence', (done) ->
            setTimeout () ->
              expect(channel_msg_stub).to.have.been.calledWithMatch(/Occurrence created.*/)
              expect(channel_msg_stub).to.have.been.calledTwice
              done()
            , 100

    context 'when headers are not valid', ->
      headers = {'access-token': 'foo', 'client': 'bar', 'uid': 'wrong'}

      context 'when nb_of_occurrences equals 2', ->
        nb_of_occurrences = 2

        context 'when gps_position and radius are null', ->
          fake_occurrence = {occurrence: {symptom_id: symptom_id, date: new Date}}

          beforeEach ->
            generate_occurrence_stub = sinon.stub(room.robot, 'generate_occurrence')
            generate_occurrence_stub.returns(fake_occurrence)
            query = nock(simulation_url)
              .matchHeader('uid', fake_mail)
              .matchHeader('access-token', fake_token)
              .matchHeader('client', fake_client)
              .post(occurrences_path)
              .times(nb_of_occurrences)
              .replyWithError('an error')
            result = room.robot.simulate_occurrences(symptom_id, headers, nb_of_occurrences, gps_position, radius, channel_msg, start_date, end_date)

          afterEach ->
            generate_occurrence_stub.reset()

          it 'makes a call to generate_occurrence with the symptom_id, gps_position and radius', ->
            expect(generate_occurrence_stub).to.have.been.calledWithExactly(symptom_id, gps_position, radius, start_date, end_date)

          it 'posts 2 messages to the channel with the detail of the error', (done) ->
            setTimeout () ->
              expect(channel_msg_stub).to.have.been.calledWithMatch(/Error while doing a POST on.*/)
              expect(channel_msg_stub).to.have.been.calledTwice
              done()
            , 100 # wait for the message to be posted

describe 'start_simulation', ->
  room = null
  result = null
  channel_msg = null
  channel_msg_stub = null
  create_user_stub = null
  get_symptom_by_name_stub = null
  simulate_occurrences_stub = null
  fake_user_response = {user: {}, headers: {}}
  fake_symptom = {id: 1}

  beforeEach ->
    room = helper.createRoom()
    channel_msg = {send: (msg) -> return}
    channel_msg_stub = sinon.spy(channel_msg, 'send')

  afterEach ->
    room.destroy()
    create_user_stub.restore()
    get_symptom_by_name_stub.restore()
    simulate_occurrences_stub.restore()

  context 'when nb of users = 2, symptoms names = test1 and test2, nb of occurrences are 10 and 20, gps position radius, start_date and end_date are null', ->
    nb_of_users = 2
    symptoms_names = ['test1', 'test2']
    nb_of_occurrences = [10, 20]
    gps_position = null
    radius = null
    start_date = null
    end_date = null

    context 'when the user creation, occurrence simulation and search of symptoms work fine', ->
      beforeEach (done) ->
        create_user_stub = sinon.stub(room.robot, 'create_user')
        create_user_stub.returns(new Promise (resolve, reject) -> resolve(fake_user_response))

        simulate_occurrences_stub = sinon.stub(room.robot, 'simulate_occurrences')
        simulate_occurrences_stub.returns(null)

        get_symptom_by_name_stub = sinon.stub(room.robot, 'get_symptom_by_name')
        get_symptom_by_name_stub.returns(new Promise (resolve, reject) -> resolve(fake_symptom))

        result = room.robot.start_simulation(nb_of_users, symptoms_names, nb_of_occurrences, gps_position, radius, channel_msg, start_date, end_date)
        setTimeout done, 100

      it 'makes 2 calls to create user', ->
        expect(create_user_stub).to.have.been.calledTwice

      it 'makes 4 calls to get the id of a symptom', ->
        expect(get_symptom_by_name_stub).to.have.been.callCount(4)

      it 'makes 4 calls to simulate occurrences', ->
        expect(simulate_occurrences_stub).to.have.been.callCount(4)


    context 'when the user creation works fine but get_symptom_by_name fails', ->
      beforeEach (done) ->
        create_user_stub = sinon.stub(room.robot, 'create_user')
        create_user_stub.returns(new Promise (resolve, reject) -> resolve(fake_user_response))

        simulate_occurrences_stub = sinon.stub(room.robot, 'simulate_occurrences')
        simulate_occurrences_stub.returns(null)

        get_symptom_by_name_stub = sinon.stub(room.robot, 'get_symptom_by_name')
        get_symptom_by_name_stub.returns(new Promise (resolve, reject) -> reject(null))

        result = room.robot.start_simulation(nb_of_users, symptoms_names, nb_of_occurrences, gps_position, radius, channel_msg)
        setTimeout done, 100

      it 'writes and error to the channel 4 times', ->
        expect(channel_msg_stub).to.have.been.callCount(4)
        expect(channel_msg_stub).to.always.have.been.calledWithMatch(/Error while searching for the ID of the symptom.*/)

    context 'when the user creation fails', ->
      beforeEach (done) ->
        create_user_stub = sinon.stub(room.robot, 'create_user')
        create_user_stub.returns(new Promise (resolve, reject) -> resolve(reject(null)))

        simulate_occurrences_stub = sinon.stub(room.robot, 'simulate_occurrences')
        simulate_occurrences_stub.returns(null)

        get_symptom_by_name_stub = sinon.stub(room.robot, 'get_symptom_by_name')
        get_symptom_by_name_stub.returns(new Promise (resolve, reject) -> resolve(fake_symptom))

        result = room.robot.start_simulation(nb_of_users, symptoms_names, nb_of_occurrences, gps_position, radius, channel_msg)
        setTimeout done, 100

      it 'writes and error to the channel 2 times', ->
        expect(channel_msg_stub).to.have.been.callCount(2)
        expect(channel_msg_stub).to.always.have.been.calledWithMatch(/Error creating user.*/)


describe 'simulate', ->
  room = null
  start_simulation_stub = null

  beforeEach ->
    room = helper.createRoom()
    start_simulation_stub = sinon.stub(room.robot, 'start_simulation')
    start_simulation_stub.returns(null)

  afterEach ->
    room.destroy()
    start_simulation_stub.restore()

  context 'when user says simulate with 2 users and 2 symptoms, one for 1 occurrence and the second for 2 occurrences, without gps localisation parameters to hubot', ->
    beforeEach (done) ->
      room.user.say 'alice', 'hubot simulate users=2 symptoms=test1;1;test2;2;'
      setTimeout done, 100

    it 'calls start_simulation once', ->
      expect(start_simulation_stub).to.have.been.calledOnce

  context 'when the environment variable SIMULATION_API_BASE_URL is not set', ->
    beforeEach (done) ->
      delete process.env.SIMULATION_API_BASE_URL
      room.user.say 'alice', 'hubot simulate users=2 symptoms=test1;1;test2;2;'
      setTimeout done, 100

    afterEach ->
      process.env.SIMULATION_API_BASE_URL = simulation_url

    it 'responds with an error message: Please set the environment variable SIMULATION_API_BASE_URL', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot simulate users=2 symptoms=test1;1;test2;2;']
        ['hubot', 'Please set the environment variable SIMULATION_API_BASE_URL']
      ]

  context 'when not every symptom has a number of occurrences', ->
    beforeEach (done) ->
      room.user.say 'alice', 'hubot simulate users=2 symptoms=test1;test2;2;'
      setTimeout done, 100

    it 'responds with an error message: Error: test1;test2;2 is not valid. Please ensure it respect the format : (symptom_name;nb_of_occurrences;)+', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot simulate users=2 symptoms=test1;test2;2;']
        ['hubot', 'Error: test1;test2;2 is not valid. Please ensure it respect the format : (symptom_name;nb_of_occurrences;)+']
      ]
