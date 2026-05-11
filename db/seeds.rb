# This file should ensure the existence of records required to run the application in every environment.
# The data can be loaded with bin/rails db:seed or created alongside the database with db:setup.

puts "Starting NU Sublets seed data..."

SubletListing.destroy_all
User.destroy_all

USER_COUNT = ENV.fetch("NU_SUBLETS_SEED_USERS", 1000).to_i
LISTING_COUNT = ENV.fetch("NU_SUBLETS_SEED_LISTINGS", 1200).to_i

FIRST_NAMES = %w[
  Alex Avery Blake Cameron Casey Charlie Dakota Drew Emerson Finley Harper
  Jamie Jordan Kai Kendall Logan Morgan Parker Quinn Reese Riley Rowan Sam
  Skyler Taylor
].freeze

LAST_NAMES = %w[
  Anderson Brown Campbell Chen Davis Evans Garcia Green Harris Johnson Kim Lee
  Martinez Miller Nguyen Patel Robinson Smith Taylor Thompson Walker Williams
  Wilson Young
].freeze

STREETS = [
  "Sherman Ave",
  "Davis St",
  "Orrington Ave",
  "Ridge Ave",
  "Oak Ave",
  "Clark St",
  "Hinman Ave",
  "Judson Ave",
  "Central St",
  "Noyes St",
  "Foster St",
  "Emerson St",
  "Maple Ave",
  "Chicago Ave",
  "Garnett Pl"
].freeze

TITLE_PREFIXES = [
  "Sunny",
  "Furnished",
  "Quiet",
  "Modern",
  "Budget-Friendly",
  "Lakefront",
  "Campus",
  "Spacious",
  "Pet-Friendly",
  "Updated"
].freeze

HOME_TYPES = [
  "Studio",
  "1BR Apartment",
  "2BR Apartment",
  "Room in Shared House",
  "Garden Unit",
  "Graduate Student Sublet"
].freeze

DESCRIPTION_DETAILS = [
  "close to Northwestern classes, groceries, transit, and downtown Evanston",
  "with natural light, hardwood floors, and a practical study setup",
  "near the Purple Line with an easy commute to campus and Chicago",
  "with laundry access, a stocked kitchen, and flexible lease timing",
  "on a quieter street with simple access to restaurants and the lakefront",
  "with responsive roommates and space for focused graduate work"
].freeze

PROFILE_PHOTO_URLS = [
  "https://randomuser.me/api/portraits/women/65.jpg",
  "https://randomuser.me/api/portraits/men/73.jpg",
  "https://randomuser.me/api/portraits/women/27.jpg",
  "https://randomuser.me/api/portraits/men/15.jpg",
  "https://randomuser.me/api/portraits/women/32.jpg",
  "https://randomuser.me/api/portraits/men/12.jpg",
  "https://randomuser.me/api/portraits/women/18.jpg",
  "https://randomuser.me/api/portraits/men/8.jpg",
  "https://randomuser.me/api/portraits/women/12.jpg",
  "https://randomuser.me/api/portraits/women/28.jpg",
  "https://randomuser.me/api/portraits/men/18.jpg",
  "https://randomuser.me/api/portraits/women/24.jpg"
].freeze

def generated_name(index)
  first_name = FIRST_NAMES[index % FIRST_NAMES.length]
  last_name = LAST_NAMES[(index / FIRST_NAMES.length) % LAST_NAMES.length]
  suffix = index + 1

  {
    first_name: first_name,
    last_name: "#{last_name} #{suffix}",
    name: "#{first_name} #{last_name} #{suffix}"
  }
end

def generated_address(index)
  street_number = 600 + ((index * 37) % 1700)
  street = STREETS[index % STREETS.length]
  zip = index.even? ? "60201" : "60202"
  "#{street_number} #{street}, Evanston, IL #{zip}"
end

def generated_amenities(index, furnished:, utilities_included:, pets_allowed:)
  labels = []
  labels << "Furnished" if furnished
  labels << "Utilities included" if utilities_included
  labels << "Pet-friendly" if pets_allowed

  rotating = [
    "Laundry",
    "Parking",
    "Natural light",
    "Hardwood floors",
    "Updated kitchen",
    "Balcony / Patio",
    "Gym",
    "Study rooms",
    "Transit access",
    "Near Northwestern University",
    "Downtown Evanston",
    "Lakefront (Lake Michigan)",
    "Grocery nearby",
    "Restaurants",
    "Safe area",
    "Clean space",
    "Work setup",
    "Quiet / Social"
  ]

  4.times { |offset| labels << rotating[(index + offset * 3) % rotating.length] }
  labels.uniq
end

def generated_preferences(index, pets_allowed:)
  labels = [ "Student preferred", "Clean", "Respectful", "LGBTQ+ friendly" ]
  labels << (index.even? ? "Graduate student" : "Young professional")
  labels << ((index % 3).zero? ? "Quiet" : "Social")
  labels << (pets_allowed ? "Pet-friendly" : "No pets")
  labels.uniq
end

puts "Creating #{USER_COUNT} users..."

users = USER_COUNT.times.map do |index|
  name = generated_name(index)
  User.create!(
    name: name[:name],
    first_name: name[:first_name],
    last_name: name[:last_name],
    email: "student#{index + 1}@u.northwestern.edu",
    profile_photo_url: PROFILE_PHOTO_URLS[index % PROFILE_PHOTO_URLS.length],
    active: true
  )
end

puts "Creating #{LISTING_COUNT} sublet listings..."

LISTING_COUNT.times do |index|
  bedrooms = index % 6
  bathrooms = bedrooms.zero? ? 1 : 1 + (index % 2)
  furnished = index.even?
  pets_allowed = (index % 4).zero?
  utilities_included = (index % 3).zero?
  available_from = Date.current + ((index % 90) + 1).days
  available_until = available_from + (60 + (index % 240)).days
  home_type = HOME_TYPES[index % HOME_TYPES.length]
  title = "#{TITLE_PREFIXES[index % TITLE_PREFIXES.length]} #{home_type} Near Campus ##{index + 1}"

  SubletListing.create!(
    user: users[index % users.length],
    title: title,
    description: "#{title} is #{DESCRIPTION_DETAILS[index % DESCRIPTION_DETAILS.length]}. Monthly rent, dates, amenities, and roommate preferences vary across this generated development dataset so search, filtering, maps, and pagination can be tested realistically.",
    price: 650 + ((index * 37) % 1900),
    address: generated_address(index),
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    furnished: furnished,
    pets_allowed: pets_allowed,
    utilities_included: utilities_included,
    amenities: generated_amenities(index, furnished: furnished, utilities_included: utilities_included, pets_allowed: pets_allowed),
    preferences: generated_preferences(index, pets_allowed: pets_allowed),
    available_from: available_from,
    available_until: available_until
  )
end

puts "Database seeding completed."
puts "Created #{User.count} users and #{SubletListing.count} sublet listings."
