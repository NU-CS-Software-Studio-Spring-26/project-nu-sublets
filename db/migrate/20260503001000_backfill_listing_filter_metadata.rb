class BackfillListingFilterMetadata < ActiveRecord::Migration[8.1]
  class Listing < ActiveRecord::Base
    self.table_name = "sublet_listings"
  end

  def up
    Listing.find_each do |listing|
      amenities = filter_labels(existing_labels(listing.amenities) + inferred_amenities(listing), amenity_options)
      preferences = filter_labels(existing_labels(listing.preferences) + inferred_preferences(listing), preference_options)

      listing.update_columns(
        amenities: amenities.to_json,
        preferences: preferences.to_json
      )
    end
  end

  def down
    Listing.update_all(amenities: nil, preferences: nil)
  end

  private

  def existing_labels(value)
    return [] if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError, TypeError
    []
  end

  def inferred_amenities(listing)
    text = "#{listing.title} #{listing.description}".downcase
    labels = []
    labels << "Furnished" if listing.furnished
    labels << "Utilities included" if listing.utilities_included || text.include?("heat included")
    labels << "Pet-friendly" if listing.pets_allowed || text.include?("pet")
    labels << "Laundry" if text.include?("laundry") || text.include?("washer")
    labels << "Parking" if text.include?("parking")
    labels << "Natural light" if text.include?("natural light")
    labels << "Hardwood floors" if text.include?("hardwood")
    labels << "Updated kitchen" if text.include?("updated kitchen") || text.include?("modern appliances")
    labels << "Balcony / Patio" if text.include?("balcony") || text.include?("garden") || text.include?("backyard")
    labels << "Rooftop" if text.include?("rooftop")
    labels << "Gym" if text.include?("fitness center") || text.include?("gym")
    labels << "Study rooms" if text.include?("study lounge") || text.include?("study room")
    labels << "Transit access" if text.include?("public transportation") || text.include?("purple line") || text.include?("commute")
    labels << "Near Northwestern University" if text.include?("campus") || text.include?("northwestern")
    labels << "Downtown Evanston" if text.include?("downtown")
    labels << "Lakefront (Lake Michigan)" if text.include?("lake") || text.include?("beach")
    labels << "Flexible lease" if text.include?("flexible lease")
    labels << "Quiet / Social" if text.include?("quiet") || text.include?("social")
    labels << "Clean space" if text.include?("clean") || text.include?("recently renovated")
    labels
  end

  def inferred_preferences(listing)
    text = "#{listing.title} #{listing.description}".downcase
    labels = [ "Female", "Clean", "LGBTQ+ friendly" ]
    labels << "Student preferred" if text.include?("student") || text.include?("campus") || text.include?("northwestern")
    labels << "Graduate student" if text.include?("grad")
    labels << "Young professional" if text.include?("professional")
    labels << "Quiet" if text.include?("quiet")
    labels << "Social" if text.include?("social") || text.include?("friendly roommate")
    labels << "Responsible" if text.include?("serious student")
    labels << "Pet-friendly" if listing.pets_allowed
    labels << "No pets" unless listing.pets_allowed
    labels
  end

  def filter_labels(labels, allowed)
    labels.select { |label| allowed.include?(label) }.uniq
  end

  def amenity_options
    [
      "Furnished",
      "Laundry",
      "AC / Heat",
      "WiFi",
      "TV",
      "Hardwood floors",
      "Natural light",
      "Storage",
      "Private bath / Shared bath",
      "Updated kitchen",
      "Dishwasher",
      "Microwave",
      "Balcony / Patio",
      "Elevator",
      "Secure entry",
      "Doorman",
      "Package room",
      "Bike storage",
      "Gym",
      "Rooftop",
      "Study rooms",
      "Parking",
      "Pet-friendly",
      "Near Northwestern University",
      "Downtown Evanston",
      "Transit access",
      "Lakefront (Lake Michigan)",
      "Grocery nearby",
      "Restaurants",
      "Safe area",
      "Utilities included",
      "Flexible lease",
      "Lease option",
      "Clean space",
      "Stocked kitchen",
      "Work setup",
      "Quiet / Social"
    ]
  end

  def preference_options
    [
      "Student preferred",
      "Graduate student",
      "Young professional",
      "Male",
      "Female",
      "Non-smoker",
      "No pets",
      "Pet-friendly",
      "Clean",
      "Quiet",
      "Respectful",
      "Responsible",
      "Organized",
      "Easygoing",
      "Social",
      "Independent",
      "No overnight guests",
      "No parties",
      "Light cooking",
      "Good hygiene",
      "Communicative",
      "Reliable",
      "LGBTQ+ friendly"
    ]
  end
end
