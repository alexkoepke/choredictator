#!/usr/bin/env ruby -w

require 'pp'
require 'json'
require 'rest_client'



#define json source file
employeesJson = "employees.json"
choresJson = "chores.json"
assignedChoresJson = "assignedChores.json"
configJson = "config.json"



configFile = File.open(File.expand_path(configJson), 'r')
parsedConfigFile = File.read(configFile)
configHash = JSON.parse(parsedConfigFile)

pp configHash['mailgun']['apiKey']

$apiKey = configHash['mailgun']['apiKey']
$domain = configHash['mailgun']['domain']



# read from json file and save as var.
employeeJson = File.read(employeesJson)
choreJson = File.read(choresJson)
#parse json into has (key, value)
choresHash = JSON.parse(choreJson)
employeeHash = JSON.parse(employeeJson)

#Create an array of employees and emails
employeeArray = employeeHash.keys
employeeEmailArray = employeeHash.values

#Create an array and rotate the chores
rotateChores = choresHash.values.rotate

# merge the employee array and rotated cores and save to file difined in choresJson
newChores = Hash[employeeArray.zip(rotateChores)]
rotatedChoresToJson = JSON.pretty_generate(newChores)
File.open(choresJson, 'w') { |file| file.write(rotatedChoresToJson) }

# Add the employee email to each rotated
count = 0
choresHash.values.each do |i|
  i.merge!(email: employeeEmailArray[count].values[0])
  count += 1
end

assignedChoresToJson = JSON.pretty_generate(choresHash)

File.open(assignedChoresJson, 'w') { |file| file.write(assignedChoresToJson) }

choresHash.values.each do |i|


    textTemplateMonday = 'mondayTemp.txt'
    htmlTemplateMonday ='mondayTemp.html'

    textMonday = 'monday.txt'
    htmlMonday = 'monday.html'

    file_names = [textTemplateMonday, htmlTemplateMonday]

    file_names.each do |file_name|
      text = File.read(file_name)
      textWithChore = text.gsub(/({{chore}})/, i["chore"])
      textWithChoreAndDescription = textWithChore.gsub(/({{Description}})/, i["description"])

      # To write changes to the file, use:
      if file_name == 'mondayTemp.txt'
        File.open(textMonday, "w") {|file| file.puts textWithChoreAndDescription }
        puts "chore txt"
      else
        File.open(htmlMonday, "w") {|file| file.puts textWithChoreAndDescription }
        puts "chore html"
      end
    end

    $text = File.read("./monday.txt")
    $html = File.read("./monday.html")

    RestClient.post "https://api:" + $apiKey + \
    "@api.mailgun.net/v3/" + $domain + "/messages",
    :from => "Chore Dictator poop@mg.choredictator.com",
    :to => i[:email],
    :subject => "Weekly Chore Assigned!: " + i["chore"],
    :text => $text,
    :html => $html


end

