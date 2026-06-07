require "prawn"

class CompareListingsPdf
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  ROWS = [
    [ "Rent", :rent_label ],
    [ "Address/location", :address_label ],
    [ "Move-in date", :available_from_label ],
    [ "Move-out date", :available_until_label ],
    [ "Bedrooms", :bedrooms_label ],
    [ "Bathrooms", :bathrooms_label ],
    [ "Furnished/unfurnished", :furnished_label ],
    [ "Utilities included", :utilities_label ],
    [ "Amenities", :amenities_label ],
    [ "Pet-friendly", :pets_label ],
    [ "Parking", :parking_label ],
    [ "Laundry", :laundry_label ],
    [ "Listing link", :listing_link ]
  ].freeze

  def initialize(listings:, generated_at:, base_url:)
    @listings = listings
    @generated_at = generated_at
    @base_url = base_url
  end

  def render
    Prawn::Document.new(page_size: "LETTER", layout: :landscape, margin: 36, info: document_info) do |pdf|
      @pdf = pdf
      header
      listing_photo_strip
      comparison_table
    end.render
  end

  private

  attr_reader :listings, :generated_at, :base_url, :pdf

  def document_info
    {
      Title: "NU Sublets Listing Comparison",
      Author: "NU Sublets",
      Subject: "Side-by-side sublet listing comparison",
      Creator: "NU Sublets"
    }
  end

  def header
    pdf.fill_color "4E2A84"
    pdf.text "NU Sublets Listing Comparison", size: 24, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 6
    pdf.text "Generated #{generated_at.strftime("%B %-d, %Y at %-I:%M %p %Z")}", size: 10, color: "555555"
    pdf.text "#{listings.size} #{'listing'.pluralize(listings.size)} selected for comparison.", size: 10, color: "555555"
    pdf.move_down 18
  end

  def listing_photo_strip
    column_gap = 12
    column_width = (pdf.bounds.width - (column_gap * (listings.size - 1))) / listings.size
    strip_top = pdf.cursor
    strip_height = 118

    listings.each_with_index do |listing, index|
      x_position = index * (column_width + column_gap)

      pdf.bounding_box([ x_position, strip_top ], width: column_width, height: strip_height) do
        pdf.stroke_color "DDDDDD"
        pdf.fill_color "FAFAFA"
        pdf.fill_and_stroke_rounded_rectangle [ 0, pdf.cursor ], column_width, strip_height, 5
        pdf.fill_color "000000"
        pdf.stroke_color "000000"
        pdf.move_down 8
        pdf.indent(8, 8) do
          render_primary_photo(listing, column_width - 16, 62)
          pdf.move_down 6
          pdf.text listing.title.presence || "Sublet listing", size: 9, style: :bold, overflow: :shrink_to_fit
          pdf.text rent_label(listing), size: 8, color: "555555"
        end
      end
    end

    pdf.move_cursor_to(strip_top - strip_height - 16)
  end

  def render_primary_photo(listing, width, height)
    photo = listing.photos.first

    if photo&.blob && supported_pdf_image?(photo.blob)
      render_blob_image(photo.blob, width, height)
    else
      render_photo_placeholder(width, height, photo&.blob ? "Photo attached" : "No photo")
    end
  end

  def render_blob_image(blob, width, height)
    blob.open do |file|
      pdf.image file.path, fit: [ width, height ], position: :center
    end
  rescue StandardError
    render_photo_placeholder(width, height, "Photo unavailable")
  end

  def render_photo_placeholder(width, height, label)
    pdf.stroke_color "DDDDDD"
    pdf.fill_color "F2F2F2"
    pdf.fill_and_stroke_rounded_rectangle [ 0, pdf.cursor ], width, height, 4
    pdf.fill_color "777777"
    pdf.text_box label,
                 at: [ 0, pdf.cursor - 22 ],
                 width: width,
                 height: 18,
                 align: :center,
                 size: 8,
                 style: :bold
    pdf.fill_color "000000"
    pdf.stroke_color "000000"
    pdf.move_down height
  end

  def comparison_table
    render_table_header

    ROWS.each do |label, method_name|
      height = row_height(label)
      if pdf.cursor < height + 34
        pdf.start_new_page
        render_table_header
      end

      render_table_row(label, listings.map { |listing| send(method_name, listing) }, height)
    end
  end

  def render_table_header
    render_table_row("Attribute", listings.map { |listing| listing_header(listing) }, 54, header: true)
  end

  def render_table_row(label, values, height, header: false)
    top = pdf.cursor
    widths = table_column_widths
    cells = [ label, *values ]

    cells.each_with_index do |value, index|
      x_position = widths.take(index).sum
      background = header || index.zero? ? "F8F6FA" : "FFFFFF"
      text = index.zero? || header ? "<b>#{escape_pdf_text(value)}</b>" : escape_pdf_text(value)

      render_table_cell(text, x_position, top, widths[index], height, background)
    end

    pdf.move_cursor_to(top - height)
  end

  def render_table_cell(text, x_position, top, width, height, background)
    pdf.bounding_box([ x_position, top ], width: width, height: height) do
      pdf.fill_color background
      pdf.fill_rectangle [ 0, pdf.bounds.top ], width, height
      pdf.stroke_color "DDDDDD"
      pdf.stroke_bounds
      pdf.fill_color "000000"
      pdf.text_box text,
                   at: [ 8, pdf.bounds.top - 8 ],
                   width: width - 16,
                   height: height - 16,
                   size: 9,
                   inline_format: true,
                   overflow: :shrink_to_fit,
                   min_font_size: 7
    end
  end

  def table_column_widths
    attribute_width = 116
    listing_width = (pdf.bounds.width - attribute_width) / listings.size
    [ attribute_width, *Array.new(listings.size, listing_width) ]
  end

  def row_height(label)
    case label
    when "Amenities"
      68
    when "Listing link"
      56
    else
      42
    end
  end

  def listing_header(listing)
    [
      listing.title.presence || listing.address.presence || "Sublet listing",
      rent_label(listing)
    ].join("\n")
  end

  def supported_pdf_image?(blob)
    %w[image/png image/jpeg].include?(blob.content_type)
  end

  def rent_label(listing)
    "#{number_to_currency(listing.price, precision: 0)}/month"
  end

  def address_label(listing)
    listing.address.presence || "Not listed"
  end

  def available_from_label(listing)
    listing.available_from&.strftime("%b %-d, %Y") || "N/A"
  end

  def available_until_label(listing)
    listing.available_until&.strftime("%b %-d, %Y") || "N/A"
  end

  def bedrooms_label(listing)
    listing.bedrooms.to_i.zero? ? "Studio" : pluralize(listing.bedrooms, "bedroom")
  end

  def bathrooms_label(listing)
    pluralize(listing.bathrooms, "bathroom")
  end

  def furnished_label(listing)
    listing.furnished? ? "Furnished" : "Unfurnished"
  end

  def utilities_label(listing)
    listing.utilities_included? ? "Included" : "Not included"
  end

  def amenities_label(listing)
    amenities = listing.displayed_amenities
    amenities.present? ? amenities.join(", ") : "Not listed"
  end

  def pets_label(listing)
    listing.pets_allowed? ? "Yes" : "No"
  end

  def parking_label(listing)
    listing.displayed_amenities.include?("Parking") ? "Listed" : "Not listed"
  end

  def laundry_label(listing)
    listing.displayed_amenities.any? { |amenity| amenity.match?(/laundry/i) } ? "Listed" : "Not listed"
  end

  def listing_link(listing)
    "#{base_url}#{Rails.application.routes.url_helpers.sublet_listing_path(listing)}"
  end

  def escape_pdf_text(value)
    ERB::Util.html_escape(value.to_s)
  end
end
