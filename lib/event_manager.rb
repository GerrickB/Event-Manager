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
    #legislators = legislators.officials

    legislator_names = legislators.map do |legislator|
      legislator.name
    end

    legislators_string = legislator_names.join(",")

  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
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

  legislators = legislators_by_zipcode(zipcode)

  #personal_letter = template_letter.gsub('FIRST_NAME', name)
  #personal_letter.gsub!('LEGISLATORS', legislators)
  #alternate way
  #personal_letter = template_letter.gsub('FIRST_NAME', name)
  #personal_letter = personal_letter.gsub('LEGISLATORS', legislators)
  form_letter = erb_template.result(binding)

  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
  
  #old one
  #puts "#{name} #{zipcode} #{legislators}"
  #new one
  #puts personal_letter
  #puts form_letter
end