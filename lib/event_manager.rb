require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_date(date)
  date_arr = date.chars
  date_arr.insert(0,date_arr.delete_at(5)).insert(0,date_arr.slice!(6..7)).join
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_numbers(phones)
  phone = phones.to_s.delete("()-").gsub(/[[:space:]]/, '')
  if phone.size > 11 || phone.size < 10 || (phone.size ==11 && phone[0]!="1")
    phone = "Invalid phone number given"
  elsif phone.size == 11 && phone[0] == "1"
    phone.slice!(1..10)
  else 
    phone
  end
end

def save_thank_you_letter(id,form_letter)
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

dates_arr = []
time_arr = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_numbers(row[:homephone])
  date = Date.parse(clean_date(row[:regdate]))
  time = Time.parse(clean_date(row[:regdate]))
  # legislators = legislators_by_zipcode(zipcode)
  dates_arr.push(date)
  time_arr.push(time)
  # form_letter = erb_template.result(binding)
  puts "#{name} #{date}"
  # save_thank_you_letter(id,form_letter)
end

 best_day = dates_arr.map{|date| date.strftime("%A")}.tally.max_by {|key, value| value }
 best_hour = time_arr.map{|time| time.hour}.tally.max_by {|key, value| value }

 puts "The busiest day is #{best_day}"
 puts "The busiest hour is #{best_hour}"