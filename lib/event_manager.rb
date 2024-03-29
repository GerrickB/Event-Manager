require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zip_code(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_home_phone(phone)
  #format phone number
  phone = phone.delete(' ()-.+')
  # or homephone = row[:homephone].delete(' ()-.+')

  if phone.nil?
    '0000000000'
  elsif phone.length < 10
    puts "#{phone} has less than 10 digits"
    puts "new number:"
    phone.ljust(10, '0') 
  #If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits. (use a string digit when comparing because phone number is in string )
  elsif (phone.length == 11) && (phone[0] == '1')
    puts "#{phone} has 11 digits and first number is 1"
    puts "new number:"
    phone[1..11]

  #If the phone number is 11 digits and the first number is not 1, then it is a bad number
  elsif (phone.length == 11) && (phone[0] != '1')
    puts "#{phone} is a bad number"
  #If the phone number is more than 11 digits, assume that it is a bad number
  elsif phone.length > 11
    puts "#{phone} is a bad number"
  else
    phone
  end
end

def get_avg_peak_hour(hours)
  p avg_peak = hours.reduce { |sum, hour| sum + hour }
  avg_peak / hours.length
end

def get_days(regdate)
  regdate = Time.strptime(regdate, "%m/%d/%Y")
  regdate = regdate.strftime("%-d/%-m/%Y")
  array = regdate.split('/')
  # if year start with 0 replace it with 2
  array.map { |num| num[0] = '2' if num[0] == '0'}
  array = array.join('/')
  regdate = Time.parse(array)
  Date.new(regdate.year,regdate.month, regdate.day).wday
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
peak_hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  regdate = row[:regdate]

  peak_hours.push(Time.strptime(regdate, "%m/%d/%Y %k:%M").hour)

  days.push(get_days(regdate))

  zipcode = clean_zip_code(row[:zipcode])

  #homephone = clean_home_phone(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  #p peak_hours
end

#p get_avg_peak_hour(peak_hours)
p days