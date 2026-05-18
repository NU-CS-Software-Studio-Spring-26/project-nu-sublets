class SubletListingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing
  before_action :authorize_listing_owner!

  def update
    if @listing.update(sublet_listing_params)
      redirect_to sublet_listing_path(@listing), notice: "Listing updated."
    else
      redirect_to sublet_listing_path(@listing), alert: @listing.errors.full_messages.to_sentence
    end
  end

  def destroy
    @listing.destroy
    redirect_to profile_path, notice: "Listing deleted."
  end

  private

  def set_listing
    @listing = SubletListing.find(params[:id])
  end

  def authorize_listing_owner!
    return if @listing.user_id == current_user.id

    redirect_to sublet_listing_path(@listing), alert: "You can only manage your own listings."
  end

  def sublet_listing_params
    params.require(:sublet_listing).permit(
      :title,
      :description,
      :price,
      :address,
      :bedrooms,
      :bathrooms,
      :available_from,
      :available_until,
      :furnished,
      :pets_allowed,
      :utilities_included,
      photos: []
    )
  end
end
