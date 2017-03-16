# Description:
#   Simulate a user of the GeoHealth/HAppi_backend API
#
# Dependencies:
#   none
#
# Configuration:
#   SIMULATION_API_BASE_URL must point to the base URL API of the simulation environment, not ending with a '/'
#
# Commands:
#   hubot simulate users=X symptoms=SYMPTOMS_NAME; [latitude=LATITUDE longitude=LONGITUDE radius=RADIUS] - Simulate X users having the symptoms specified in the array SYMPTOMS_NAME (an array containing the names and the number of occurrences of the symptom to create := [name;nb_of_occurrence;]+) happening at the current time of the bot and some random gps location in the RADIUS (in meters) of LATITUDE, LONGITUDE.
#   hubot users - list the users that hubot has already created with their emails and passwords
#
# Notes:
#   This script was designed to work with the API described in https://github.com/GeoHealth/HAppi_backend/blob/master/swagger.yaml
#   It is important that the list of symptoms ends with a semicolon.
#
#   Example: hubot simulate users=10 symptoms=Abdominal Pain;10;Divergent strabismus;2; latitude=50.673856699999995 longitude=4.23655 radius=1000
#
# Authors:
#   seza443, kagelmacher

module.exports = (robot) ->
  api_path = process.env.SIMULATION_API_BASE_URL
  create_user_path = 'auth'
  get_symptoms_path = 'symptoms'

  robot.create_user = (email) ->
    data = JSON.stringify({email: email, password: '11112222', password_confirmation: '11112222'})
    return new Promise (resolve, reject) ->
      robot.http(api_path + '/' + create_user_path)
        .header('Content-Type', 'application/json')
        .post(data) (err, res, body) ->
          if err
            reject err
          else
            response = JSON.parse(body)
            if response.status == 'success'
              resolve {user: response.data, headers: res.headers}
            else reject response

  robot.get_symptom_by_name = (name, headers) ->
    return new Promise (resolve, reject) ->
      robot.http(api_path + '/' + get_symptoms_path + "?name=#{name}")
        .header('access-token', headers['access-token'])
        .header('client', headers['client'])
        .header('uid', headers['uid'])
        .post() (err, res, body) ->
          if err
            reject err
          else
            response = JSON.parse(body)
            if response.symptoms.length > 0
              resolve response.symptoms[0]
            else
              resolve null

  robot.respond /simulate users=(\d+) symptoms=(.*);(?: latitude=((?:\d*\.)?\d+) longitude=((?:\d*\.)?\d+) radius=(\d+))?/i, (res) ->
    nb_of_users = res.match[1]
    symptoms_names = res.match[2]
    latitude = res.match[3]
    longitude = res.match[4]
    radius = res.match[5]

    console.log(nb_of_users, symptoms_names, latitude, longitude, radius)
    for i in [1..nb_of_users]
      user = create_user(room.robot)

    res.send 'ok'

