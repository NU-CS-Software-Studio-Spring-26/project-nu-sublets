class PagesController < ApplicationController
  RECENTLY_VIEWED_LISTINGS_LIMIT = 6
  RECOMMENDED_LISTINGS_LIMIT = 6

  layout false
  before_action :authenticate_user!, only: %i[profile update_profile user_profile another_user_account submit_sublet]

  def home
    prepare_recommendation_filters
    @recommended_listings = recommended_listings
    @newest_listings = SubletListing.includes(:user).find_available_listings.order(created_at: :desc).limit(6)
    @budget_friendly_listings = SubletListing.includes(:user).find_available_listings.maximum_price(1000).limit(6)
    @furnished_listings = SubletListing.includes(:user).find_available_listings.furnished_only.limit(6)
    @pet_friendly_listings = SubletListing.includes(:user).find_available_listings.pets_allowed_only.limit(6)
    @recently_viewed_listings = recently_viewed_listings
  end

  def listing
    @listing = if params[:id].present?
                 SubletListing.find(params[:id])
    else
                 SubletListing.find_available_listings.first
    end

    @listing ||= fallback_listing
    @listing_host = @listing.user || fallback_host
    remember_recently_viewed_listing(@listing) if @listing.persisted?
    @listing_questions = if @listing.persisted?
                           @listing.listing_questions.includes(:user).order(created_at: :desc)
    else
                           ListingQuestion.none
    end
    @listing_question = ListingQuestion.new
    @listing_report = ListingReport.new
  end

  def search_results
    listings = search_results_scope
    @total_listings_count = listings.count

    respond_to do |format|
      format.html do
        @pagy, @listings = pagy(:offset, listings, limit: 12)
        @map_listings = listings.limit(150)
      end

      format.pdf do
        pdf = SearchResultsPdf.new(
          listings: listings.includes(:user).to_a,
          applied_filters: applied_search_filters,
          generated_at: Time.zone.now,
          base_url: request.base_url
        ).render

        send_data pdf,
                  filename: "nu-sublets-search-results-#{Time.zone.today.iso8601}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
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
      @profile_errors = [ "Use your Northwestern email." ]
      render :profile, status: :unprocessable_entity
      return
    end

    if current_user.email_changed?
      @profile_errors = [ "Email changes require signing in with your Northwestern Google account." ]
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

  def user_profile
    @profile_user = User.find(params[:id])
    render :anotheruseraccount
  end

  def another_user_account
    @profile_user = User.where.not(id: current_user&.id).first || current_user || fallback_host
    render :anotheruseraccount
  end

  def about
    @footer_about_path = about_path
  end

  def about_us; end

  def disclaimer; end

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
    search_date_value(key, params[key])
  end

  def search_results_scope
    prepare_search_filters

    if @move_in && @move_out && @move_out <= @move_in
      @filter_error = "Move-out date must be after move-in date."
      SubletListing.none
    else
      sort_search_results(SubletListing.search_listings(search_listing_filters))
    end
  end

  def prepare_search_filters
    @natural_query = params[:natural_query].to_s.squish.first(NaturalSearchParser::MAX_QUERY_LENGTH)
    parsed_search_filters = NaturalSearchParser.new(@natural_query).parse
    @search_params = merged_search_params(parsed_search_filters)

    @move_in = search_date_value("move-in", @search_params["move-in"])
    @move_out = search_date_value("move-out", @search_params["move-out"])
    @min_price = @search_params["min_price"].to_s
    @max_price = @search_params["max_price"].to_s
    @bedrooms = @search_params["bedrooms"].to_s
    @bathrooms = @search_params["bathrooms"].to_s
    @selected_amenities = Array(@search_params["amenities"]).reject(&:blank?)
    @selected_preferences = Array(@search_params["preferences"]).reject(&:blank?)
    @sort = params[:sort].presence || "price_asc"
  end

  def search_listing_filters
    {
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
      query: @search_params["query"],
      available_only: true
    }
  end

  def sort_search_results(listings)
    case @sort
    when "price_desc"
      listings.order(price: :desc)
    when "newest"
      listings.order(created_at: :desc)
    when "available_from"
      listings.order(:available_from, :price)
    else
      listings.order(:price)
    end
  end

  def applied_search_filters
    filters = []
    filters << [ "Natural search", @natural_query ] if @natural_query.present?
    filters << [ "Search", @search_params["query"] ] if @search_params["query"].present?
    filters << [ "Move in", @move_in.strftime("%m/%d/%Y") ] if @move_in
    filters << [ "Move out", @move_out.strftime("%m/%d/%Y") ] if @move_out
    filters << [ "Minimum rent", "$#{@min_price}" ] if @min_price.present?
    filters << [ "Maximum rent", "$#{@max_price}" ] if @max_price.present?
    filters << [ "Bedrooms", @bedrooms == "0" ? "Studio" : @bedrooms ] if @bedrooms.present?
    filters << [ "Bathrooms", @bathrooms ] if @bathrooms.present?
    filters << [ "Amenities", @selected_amenities.join(", ") ] if @selected_amenities.any?
    filters << [ "Preferences", @selected_preferences.join(", ") ] if @selected_preferences.any?
    filters << [ "Sort", sort_label(@sort) ] if @sort.present?
    filters
  end

  def sort_label(sort)
    {
      "price_asc" => "Price: low to high",
      "price_desc" => "Price: high to low",
      "newest" => "Newest first",
      "available_from" => "Soonest available"
    }.fetch(sort, sort.to_s.humanize)
  end

  def search_date_value(key, value)
    return if value.blank?

    Date.strptime(value, "%m/%d/%Y")
  rescue Date::Error
    @filter_error = "Invalid date format for #{key.humanize}. Please use MM/DD/YYYY format."
    nil
  end

  def merged_search_params(parsed_filters)
    explicit_filters = {
      "query" => params[:query],
      "move-in" => params["move-in"],
      "move-out" => params["move-out"],
      "min_price" => params[:min_price],
      "max_price" => params[:max_price],
      "bedrooms" => params[:bedrooms],
      "bathrooms" => params[:bathrooms],
      "amenities" => params[:amenities],
      "preferences" => params[:preferences]
    }.compact_blank

    parsed_filters.merge(explicit_filters)
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
      available_until: search_date_param("end-date"),
      photos: Array(params[:photos]).reject(&:blank?)
    }
  end

  def profile_params
    params.require(:user).permit(
      :name,
      :email,
      :profile_photo_url,
      :profile_photo,
      :bio,
      :phone_number,
      :show_email_to_students,
      :show_phone_to_students,
      :password,
      :password_confirmation
    )
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

  def recently_viewed_listings
    ids = recently_viewed_listing_ids
    listings_by_id = SubletListing.includes(:user).available.where(id: ids).index_by(&:id)

    ids.filter_map { |id| listings_by_id[id] }
  end

  def remember_recently_viewed_listing(listing)
    session[:recently_viewed_listing_ids] = ([ listing.id ] + recently_viewed_listing_ids).uniq.first(RECENTLY_VIEWED_LISTINGS_LIMIT)
  end

  def recently_viewed_listing_ids
    Array(session[:recently_viewed_listing_ids]).filter_map do |id|
      Integer(id, exception: false)
    end.uniq.first(RECENTLY_VIEWED_LISTINGS_LIMIT)
  end

  def prepare_recommendation_filters
    @recommendation_move_in_value = params[:recommendation_move_in].to_s
    @recommendation_move_out_value = params[:recommendation_move_out].to_s
    @recommendation_bedrooms = params[:recommendation_bedrooms].to_s
    @recommendation_bathrooms = params[:recommendation_bathrooms].to_s
    @recommendation_amenities = Array(params[:recommendation_amenities]).select do |amenity|
      SubletListing::AMENITY_OPTIONS.include?(amenity)
    end

    @recommendation_move_in = recommendation_date_value("move-in", @recommendation_move_in_value)
    @recommendation_move_out = recommendation_date_value("move-out", @recommendation_move_out_value)

    if @recommendation_move_in && @recommendation_move_out && @recommendation_move_out < @recommendation_move_in
      @recommendation_filter_error = "Move-out date must be after move-in date."
    end
  end

  def recommendation_filters_active?
    @recommendation_move_in_value.present? ||
      @recommendation_move_out_value.present? ||
      @recommendation_bedrooms.present? ||
      @recommendation_bathrooms.present? ||
      @recommendation_amenities.any?
  end
  helper_method :recommendation_filters_active?

  def recommended_listings
    return SubletListing.none if @recommendation_filter_error.present?

    SubletListing.search_listings(
      move_in: @recommendation_move_in,
      move_out: @recommendation_move_out,
      bedrooms: @recommendation_bedrooms,
      bathrooms: @recommendation_bathrooms,
      furnished: @recommendation_amenities.include?("Furnished"),
      pets_allowed: @recommendation_amenities.include?("Pet-friendly"),
      utilities_included: @recommendation_amenities.include?("Utilities included"),
      amenities: @recommendation_amenities,
      available_only: true
    ).includes(:user).order(:price).limit(RECOMMENDED_LISTINGS_LIMIT)
  end

  def recommendation_date_value(label, value)
    return if value.blank?

    Date.strptime(value, "%m/%d/%Y")
  rescue Date::Error
    @recommendation_filter_error = "Invalid date format for #{label}. Please use MM/DD/YYYY format."
    nil
  end
end
