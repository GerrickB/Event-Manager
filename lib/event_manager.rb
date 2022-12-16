require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zip_code(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  
    legislator_names = legislators.map do |legislator|
      legislator.name
    end

    legislators_string = legislator_names.join(",")

  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zip_code(row[:zipcode])

  homephone = row[:homephone]

  #format phone number
  homephone = homephone.delete(' ()-.+')
  # or homephone = row[:homephone].delete(' ()-.+')

  #If the phone number is less than 10 digits, assume that it is a bad number
  if homephone.length < 10
    puts "#{homephone} has less than 10 digits"
    homephone = homephone.ljust(10, '0')
    puts "new number:"

  #If the phone number is 10 digits, assume that it is good

  #If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits. (use a string digit when comparing because phone number is in string )
  elsif (homephone.length == 11) && (homephone[0] == '1')
    puts "#{homephone} has 11 digits and first number is 1"
    homephone = homephone[1..11]

  #If the phone number is 11 digits and the first number is not 1, then it is a bad number
  elsif (homephone.length == 11) && (homephone[0] != '1')
    puts "#{homephone} is a bad number"
  #If the phone number is more than 11 digits, assume that it is a bad number
  elsif homephone.length > 11
    puts "#{homephone} is a bad number"
  end
  
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  p homephone
end