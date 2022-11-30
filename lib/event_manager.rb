require 'csv'

def clean_zip_code(zip_code)
  zip_code.to_s.rjust(5, '0')[0..4]
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]

  zip_code = clean_zip_code(row[:zip_code])

  puts "#{name} #{zip_code}"
end