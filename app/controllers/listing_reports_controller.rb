class ListingReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing

  def create
    report = @listing.listing_reports.new(report_params)
    report.user = current_user

    if report.save
      redirect_to sublet_listing_path(@listing), notice: "Report sent. Thanks for helping keep NU Sublets safe."
    else
      redirect_to sublet_listing_path(@listing), alert: report.errors.full_messages.to_sentence
    end
  end

  private

  def set_listing
    @listing = SubletListing.find(params[:sublet_listing_id])
  end

  def report_params
    params.require(:listing_report).permit(:description)
  end
end
