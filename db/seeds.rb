# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting to seed the database..."

# Clear existing data (optional - remove if you want to keep existing data)
puts "Clearing existing data..."
SubletListing.destroy_all
User.destroy_all

# Create 10 Users
puts "Creating 10 users..."

users_data = [
  { name: "Emma Johnson", email: "emma.johnson@u.northwestern.edu", first_name: "Emma", last_name: "Johnson" },
  { name: "Michael Chen", email: "michael.chen@u.northwestern.edu", first_name: "Michael", last_name: "Chen" },
  { name: "Sarah Williams", email: "sarah.williams@u.northwestern.edu", first_name: "Sarah", last_name: "Williams" },
  { name: "David Martinez", email: "david.martinez@u.northwestern.edu", first_name: "David", last_name: "Martinez" },
  { name: "Jessica Taylor", email: "jessica.taylor@u.northwestern.edu", first_name: "Jessica", last_name: "Taylor" },
  { name: "Ryan Anderson", email: "ryan.anderson@u.northwestern.edu", first_name: "Ryan", last_name: "Anderson" },
  { name: "Amanda Brown", email: "amanda.brown@u.northwestern.edu", first_name: "Amanda", last_name: "Brown" },
  { name: "Kevin Liu", email: "kevin.liu@u.northwestern.edu", first_name: "Kevin", last_name: "Liu" },
  { name: "Olivia Davis", email: "olivia.davis@u.northwestern.edu", first_name: "Olivia", last_name: "Davis" },
  { name: "James Wilson", email: "james.wilson@u.northwestern.edu", first_name: "James", last_name: "Wilson" }
]

created_users = users_data.map do |user_attrs|
  user = User.find_or_create_by(email: user_attrs[:email]) do |u|
    u.name = user_attrs[:name]
    u.first_name = user_attrs[:first_name]
    u.last_name = user_attrs[:last_name]
    u.active = true
  end
  puts "  ✅ Created user: #{user.name}"
  user
end

# Create 10 Sublet Listings
puts "Creating 10 sublet listings..."

listings_data = [
  {
    title: "Cozy 1BR Near Campus",
    description: "Charming one-bedroom apartment just a 5-minute walk from Northwestern campus. Recently renovated with modern appliances and plenty of natural light. Perfect for graduate students or young professionals.",
    price: 1200,
    address: "1845 Sherman Ave, Evanston, IL 60201",
    bedrooms: 1,
    bathrooms: 1,
    furnished: true,
    pets_allowed: false,
    utilities_included: true,
    available_from: Date.current + 1.week,
    available_until: Date.current + 4.months
  },
  {
    title: "Spacious 2BR Apartment with Parking",
    description: "Large two-bedroom apartment with dedicated parking space. Great for roommates! Located in a quiet neighborhood with easy access to public transportation.",
    price: 1800,
    address: "621 Davis St, Evanston, IL 60201",
    bedrooms: 2,
    bathrooms: 1,
    furnished: false,
    pets_allowed: true,
    utilities_included: false,
    available_from: Date.current + 2.weeks,
    available_until: Date.current + 6.months
  },
  {
    title: "Studio in Historic Building",
    description: "Charming studio apartment in a historic Evanston building. High ceilings, hardwood floors, and vintage details. Walking distance to campus and downtown.",
    price: 950,
    address: "1603 Orrington Ave, Evanston, IL 60201",
    bedrooms: 0,
    bathrooms: 1,
    furnished: true,
    pets_allowed: false,
    utilities_included: true,
    available_from: Date.current + 1.month,
    available_until: Date.current + 3.months
  },
  {
    title: "Modern 3BR House Share",
    description: "Beautiful room in a modern 3-bedroom house. Shared kitchen and living areas. Great housemates who are also Northwestern students. Backyard and laundry included.",
    price: 800,
    address: "2157 Ridge Ave, Evanston, IL 60201",
    bedrooms: 1,
    bathrooms: 1,
    furnished: false,
    pets_allowed: true,
    utilities_included: false,
    available_from: Date.current + 3.weeks,
    available_until: Date.current + 5.months
  },
  {
    title: "Luxury 2BR with Lake View",
    description: "Stunning two-bedroom apartment with partial Lake Michigan views. Modern amenities, in-unit washer/dryer, and rooftop terrace access. Perfect for professionals or grad students.",
    price: 2200,
    address: "1570 Oak Ave, Evanston, IL 60201",
    bedrooms: 2,
    bathrooms: 2,
    furnished: true,
    pets_allowed: false,
    utilities_included: true,
    available_from: Date.current + 5.days,
    available_until: Date.current + 8.months
  },
  {
    title: "Budget-Friendly Room Near El",
    description: "Affordable room in shared apartment. Great location near the Purple Line for easy commute to campus or Chicago. Friendly roommates and flexible lease terms.",
    price: 650,
    address: "816 Clark St, Evanston, IL 60201",
    bedrooms: 1,
    bathrooms: 1,
    furnished: true,
    pets_allowed: false,
    utilities_included: true,
    available_from: Date.current + 10.days,
    available_until: Date.current + 4.months
  },
  {
    title: "Pet-Friendly 1BR Garden Apartment",
    description: "Ground-floor apartment with private garden access. Perfect for pet owners! Quiet street but close to campus. Recently updated kitchen and bathroom.",
    price: 1350,
    address: "1401 Hinman Ave, Evanston, IL 60201",
    bedrooms: 1,
    bathrooms: 1,
    furnished: false,
    pets_allowed: true,
    utilities_included: false,
    available_from: Date.current + 2.months,
    available_until: Date.current + 7.months
  },
  {
    title: "Furnished Studio - Summer Sublet",
    description: "Perfect for summer internship! Fully furnished studio with everything you need. Short-term lease available. Walking distance to campus and beach.",
    price: 1100,
    address: "933 Judson Ave, Evanston, IL 60202",
    bedrooms: 0,
    bathrooms: 1,
    furnished: true,
    pets_allowed: false,
    utilities_included: true,
    available_from: Date.current + 6.weeks,
    available_until: Date.current + 3.months
  },
  {
    title: "Large 2BR in Vintage Building",
    description: "Spacious two-bedroom in charming vintage building. Original hardwood floors, high ceilings, and lots of character. Heat included in rent.",
    price: 1650,
    address: "1890 Sherman Ave, Evanston, IL 60201",
    bedrooms: 2,
    bathrooms: 1,
    furnished: false,
    pets_allowed: true,
    utilities_included: true,
    available_from: Date.current + 3.days,
    available_until: Date.current + 6.months
  },
  {
    title: "Modern 1BR with Balcony",
    description: "Brand new one-bedroom apartment with private balcony and modern appliances. Building amenities include fitness center and study lounge. Perfect for serious students.",
    price: 1550,
    address: "1717 Central St, Evanston, IL 60201",
    bedrooms: 1,
    bathrooms: 1,
    furnished: true,
    pets_allowed: false,
    utilities_included: false,
    available_from: Date.current + 1.week,
    available_until: Date.current + 10.months
  }
]

listings_data.each_with_index do |listing_attrs, index|
  # Assign each listing to a different user
  user = created_users[index]
  
  listing = SubletListing.find_or_create_by(
    title: listing_attrs[:title],
    user: user
  ) do |l|
    listing_attrs.each do |key, value|
      l.send("#{key}=", value) unless key == :title
    end
  end
  
  if listing.persisted?
    puts "  ✅ Created listing: #{listing.title} (by #{user.name})"
  else
    puts "  ❌ Failed to create listing: #{listing.title} - #{listing.errors.full_messages.join(', ')}"
  end
end

puts "🎉 Database seeding completed!"
puts "📊 Created #{User.count} users and #{SubletListing.count} sublet listings"
