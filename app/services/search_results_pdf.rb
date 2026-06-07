require "prawn"

class SearchResultsPdf
  include CentralTimeHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def initialize(listings:, applied_filters:, generated_at:, base_url:)
    @listings = listings
    @applied_filters = applied_filters
    @generated_at = generated_at
    @base_url = base_url
  end

  def render
    Prawn::Document.new(page_size: "LETTER", margin: 42, info: document_info) do |pdf|
      @pdf = pdf
      header
      applied_filters_section
      listings_section
    end.render
  end

  private

  attr_reader :listings, :applied_filters, :generated_at, :base_url, :pdf

  def document_info
    {
      Title: "NU Sublets Search Results",
      Author: "NU Sublets",
      Subject: "Filtered sublet listing search results",
      Creator: "NU Sublets"
    }
  end

  def header
    pdf.fill_color "4E2A84"
    pdf.text "NU Sublets Search Results", size: 24, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 6
    pdf.text "Generated #{central_time_display(generated_at)}", size: 10, color: "555555"
    pdf.text "#{listings.size} #{'listing'.pluralize(listings.size)} matched this search.", size: 10, color: "555555"
    pdf.move_down 18
  end

  def applied_filters_section
    section_title "Applied Filters"

    if applied_filters.any?
      applied_filters.each do |label, value|
        pdf.formatted_text [
          { text: "#{label}: ", styles: [ :bold ] },
          { text: value.to_s }
        ], size: 10
      end
    else
      pdf.text "No filters applied. Showing currently available listings sorted by price.", size: 10
    end

    pdf.move_down 18
  end

  def listings_section
    section_title "Listings"

    if listings.empty?
      pdf.text "No sublets match those filters.", size: 11, color: "555555"
      return
    end

    listings.each_with_index do |listing, index|
      pdf.start_new_page if pdf.cursor < 155
      listing_card(listing, index + 1)
      pdf.move_down 20
    end
  end

  def listing_card(listing, number)
    pdf.bounding_box([ pdf.bounds.left, pdf.cursor ], width: pdf.bounds.width) do
      pdf.stroke_color "DDDDDD"
      pdf.fill_color "FAFAFA"
      pdf.fill_and_stroke_rounded_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 128, 6
      pdf.fill_color "000000"
      pdf.stroke_color "000000"
      pdf.move_down 12
      pdf.indent(12, 12) do
        pdf.text "#{number}. #{listing.title}", size: 13, style: :bold, color: "222222"
        pdf.move_down 4
        pdf.text price_and_space(listing), size: 10, style: :bold
        pdf.text availability(listing), size: 10
        pdf.text listing.address, size: 10 if listing.address.present?
        pdf.text utilities_note(listing), size: 10

        if listing.description.present?
          pdf.move_down 4
          pdf.text truncate(listing.description, length: 150, separator: " "), size: 9, color: "555555"
        end

        pdf.move_down 4
        pdf.text "#{base_url}#{Rails.application.routes.url_helpers.sublet_listing_path(listing)}", size: 9, color: "4E2A84"
      end
    end
  end

  def section_title(text)
    pdf.text text, size: 14, style: :bold, color: "4E2A84"
    pdf.move_down 7
  end

  def price_and_space(listing)
    [
      "#{number_to_currency(listing.price, precision: 0)}/month",
      "#{listing.bedrooms} #{'bedroom'.pluralize(listing.bedrooms)}",
      "#{listing.bathrooms} #{'bathroom'.pluralize(listing.bathrooms)}"
    ].join(" | ")
  end

  def availability(listing)
    "Available #{listing.available_from.strftime("%b %-d, %Y")} to #{listing.available_until.strftime("%b %-d, %Y")}"
  end

  def utilities_note(listing)
    listing.utilities_included? ? "Utilities included" : "Utilities not marked as included"
  end
end
