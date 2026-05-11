class PagesController < ApplicationController
  layout false
  before_action :authenticate_user!, only: %i[profile update_profile anotheruseraccount submit_sublet]

  def home
    @recommended_listings = SubletListing.includes(:user).find_available_listings.limit(6)
    @newest_listings = SubletListing.includes(:user).find_available_listings.order(created_at: :desc).limit(6)
  end

  def listing
    @listing = if params[:id].present?
                 SubletListing.find(params[:id])
    else
                 SubletListing.find_available_listings.first
    end

    @listing ||= fallback_listing
    @listing_host = @listing.user || fallback_host
  end

  def search_results
    @move_in = search_date_param("move-in")
    @move_out = search_date_param("move-out")
    @min_price = params[:min_price].to_s
    @max_price = params[:max_price].to_s
    @bedrooms = params[:bedrooms].to_s
    @bathrooms = params[:bathrooms].to_s
    @selected_amenities = Array(params[:amenities]).reject(&:blank?)
    @selected_preferences = Array(params[:preferences]).reject(&:blank?)

    if @move_in && @move_out && @move_out < @move_in
      @filter_error = "Move-out date must be after move-in date."
      listings = SubletListing.none
    else
      listings = SubletListing.search_listings(
        move_in: @move_in,
        move_out: @move_out,
        min_price: @min_price,
        max_price: @max_price,
        bedrooms: @bedrooms,
        bathrooms: @bathrooms,
        furnished: @selected_amenities.include?("Furnished"),
        pets_allowed: @selected_amenities.include?("Pet-friendly"),
        utilities_included: @selected_amenities.include?("Utilities included"),
        amenities: @selected_amenities,
        preferences: @selected_preferences,
        available_only: true
      ).order(:price)
    end

    @total_listings_count = listings.count
    @pagy, @listings = pagy(:offset, listings, limit: 12)
    @map_listings = listings.limit(150)
  end

  def saved; end

  def post_sublet; end

  def profile
    @profile_user = current_user
  end

  def update_profile
    @profile_user = current_user
    current_user.assign_attributes(profile_params)

    if current_user.email.present? && !User.northwestern_email?(current_user.email)
      @profile_errors = ["Use your Northwestern email."]
      render :profile, status: :unprocessable_entity
      return
    end

    if current_user.save
      sync_name_parts
      redirect_to profile_path(tab: "settings", saved: "1")
    else
      @profile_errors = current_user.errors.full_messages
      render :profile, status: :unprocessable_entity
    end
  end

  def public_profile
    @profile_user = User.find(params[:id])

    render :profile
  end

  def anotheruseraccount; end

  def privacy_policy; end

  def login
    redirect_to profile_path if user_signed_in?
  end

  def submit_sublet
    @listing = current_user.sublet_listings.new(sublet_listing_params)

    if @listing.save
      redirect_to search_results_path(
        "move-in": @listing.available_from.strftime("%m/%d/%Y"),
        "move-out": @listing.available_until.strftime("%m/%d/%Y")
      )
    else
      @listing_errors = @listing.errors.full_messages
      render :post_sublet, status: :unprocessable_entity
    end
  end

  private

  def search_date_param(key)
    return if params[key].blank?

    Date.strptime(params[key], "%m/%d/%Y")
  rescue Date::Error
    @filter_error = "Invalid date format for #{key.humanize}. Please use MM/DD/YYYY format."
    nil
  end

  def sublet_listing_params
    {
      title: params[:title].presence || default_listing_title,
      description: params[:description],
      price: params[:price],
      address: formatted_address,
      bedrooms: params[:bedrooms],
      bathrooms: params[:bathrooms],
      furnished: params[:furnished] == "1",
      pets_allowed: params[:pets_allowed] == "1",
      utilities_included: params[:utilities_included] == "1",
      amenities: selected_listing_labels(:amenities, SubletListing::AMENITY_OPTIONS),
      preferences: selected_listing_labels(:preferences, SubletListing::PREFERENCE_OPTIONS),
      available_from: search_date_param("start-date"),
      available_until: search_date_param("end-date")
    }
  end

  def profile_params
    params.require(:user).permit(:name, :email, :profile_photo_url, :profile_photo, :bio)
  end

  def sync_name_parts
    name_parts = current_user.name.to_s.split
    current_user.update_columns(
      first_name: name_parts.first,
      last_name: name_parts.drop(1).join(" ").presence
    )
  end

  def selected_listing_labels(key, allowed_labels)
    Array(params[key]).select { |label| allowed_labels.include?(label) }
  end

  def default_listing_title
    street_address = params["street-address"].presence || "Campus"
    "Sublet at #{street_address}"
  end

  def formatted_address
    [
      params["street-address"],
      params["address-line-2"],
      params[:city],
      params[:state],
      params["zip-code"]
    ].reject(&:blank?).join(", ")
  end

  def fallback_listing
    SubletListing.new(
      title: "Summer Sublet Near Campus",
      description: "Furnished room near Northwestern campus with easy access to transit, groceries, and restaurants.",
      price: 850,
      address: "820 Noyes St, Evanston, IL 60201",
      bedrooms: 1,
      bathrooms: 1,
      furnished: true,
      pets_allowed: false,
      utilities_included: true,
      available_from: Date.new(2026, 6, 16),
      available_until: Date.new(2026, 8, 31)
    )
  end

  def fallback_host
    User.new(
      name: "Jane Doe",
      email: "janedoe@u.northwestern.edu"
    )
  end
end
