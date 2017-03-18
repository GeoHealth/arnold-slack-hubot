# Description:
#   Simulate a user of the GeoHealth/HAppi_backend API
#
# Dependencies:
#   random-email
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

randomEmail = require('random-email'); # random_email = randomEmail();

# Create random lat/long coordinates in a specified radius around a center point
# source: http://stackoverflow.com/a/31280435/2179668
generate_random_coordinate = (center, radius) ->
  y0 = parseFloat(center.latitude)
  x0 = parseFloat(center.longitude)
  rd = parseInt(radius, 10) / 111300 #about 111300 meters in one degree

  u = Math.random()
  v = Math.random()
  w = rd * Math.sqrt(u)
  t = 2 * Math.PI * v
  x = w * Math.cos(t)
  y1 = w * Math.sin(t)
  x1 = x / Math.cos(y0)

  newlat = y0 + y1
  newlon = x0 + x1

  {
    'latitude': newlat
    'longitude': newlon
    'accuracy': center.accuracy
  }

module.exports = (robot) ->
  api_path = process.env.SIMULATION_API_BASE_URL
  create_user_path = 'auth'
  get_symptoms_path = 'symptoms'
  post_occurrence_path = 'occurrences'
  https_options = {rejectUnauthorized: false}

  robot.create_user = (email) ->
    data = JSON.stringify({email: email, password: '11112222', password_confirmation: '11112222'})
    return new Promise (resolve, reject) ->
      robot.http(api_path + '/' + create_user_path, https_options)
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
      robot.http(api_path + '/' + get_symptoms_path + "?name=#{name}", https_options)
        .header('access-token', headers['access-token'])
        .header('client', headers['client'])
        .header('uid', headers['uid'])
        .get() (err, res, body) ->
          if err
            reject err
          else
            response = JSON.parse(body)
            if response.symptoms.length > 0
              resolve response.symptoms[0]
            else
              resolve null

  robot.generate_occurrence = (symptom_id, gps_position = null, radius = 0) ->
    if gps_position && gps_position.latitude && gps_position.longitude
      if radius != undefined && radius != 0
        gps_position = generate_random_coordinate(gps_position, radius)
      return {occurrence: {symptom_id: symptom_id, date: new Date, gps_coordinate: gps_position}}
    else
      return {occurrence: {symptom_id: symptom_id, date: new Date}}

  robot.simulate_occurrences = (symptom_id, headers, nb_of_occurrences, gps_position, radius, channel_res) ->
    for i in [1..nb_of_occurrences]
      new_occurrence = robot.generate_occurrence(symptom_id, gps_position, radius)
      data = JSON.stringify(new_occurrence)
      robot.http(api_path + '/' + post_occurrence_path, https_options)
        .header('Content-Type', 'application/json')
        .header('access-token', headers['access-token'])
        .header('client', headers['client'])
        .header('uid', headers['uid'])
        .post(data) (err, res, body) ->
          if err
            channel_res.send "Error while doing a POST on #{post_occurrence_path} for occurrence #{new_occurrence}"
          else
            channel_res.send "Occurrence created #{body}"

  robot.start_simulation = (nb_of_users, symptoms_names, nb_of_occurrences, gps_position, radius, msg) ->
    for i in [1..nb_of_users]
      do (user_no = i) ->
        robot.create_user(randomEmail()).then (res) ->
          headers = res.headers
          for j in [0..symptoms_names.length-1]
            do (index = j) ->
              robot.get_symptom_by_name(symptoms_names[index], headers).then (symptom) ->
                robot.simulate_occurrences(symptom.id, headers, nb_of_occurrences[index], gps_position, radius, msg)
              .catch (err) ->
                msg.send "Error while searching for the ID of the symptom #{symptoms_names[j]}. No occurrence will be created for this symptom :-1:. Error: #{err}"
        .catch (err) ->
          msg.send "Error creating user #{user_no}. Nothing was simulated for him :crying_cat_face:. Error: #{err}"

  robot.respond /simulate users=(\d+) symptoms=(.*);(?: latitude=((?:\d*\.)?\d+) longitude=((?:\d*\.)?\d+) radius=(\d+))?/i, (msg) ->
    if !process.env.SIMULATION_API_BASE_URL
      msg.send 'Please set the environment variable SIMULATION_API_BASE_URL'
    else
      nb_of_users = msg.match[1]
      symptoms_names_and_nb_of_occurrences = msg.match[2]
      gps_position = {latitude: parseFloat(msg.match[3]), longitude: parseFloat(msg.match[4])}
      radius = parseInt(msg.match[5], 10)
      symptoms_names = symptoms_names_and_nb_of_occurrences.split(';').filter((elm, index, arr) -> return index % 2 == 0) #take all even elements
      nb_of_occurrences = symptoms_names_and_nb_of_occurrences.split(';').filter((elm, index, arr) -> return index % 2 == 1) #take all odd elements

      if symptoms_names.length != nb_of_occurrences.length
        msg.send "Error: #{symptoms_names_and_nb_of_occurrences} is not valid. Please ensure it respect the format : (symptom_name;nb_of_occurrences;)+"
        return

      robot.start_simulation(nb_of_users, symptoms_names, nb_of_occurrences, gps_position, radius, msg)

      msg.send "Ok, I will simulate #{nb_of_users} users, each having those symptoms #{symptoms_names} respectively #{nb_of_occurrences} times and the users will be located in random location near #{gps_position} with a radius of #{radius}"

