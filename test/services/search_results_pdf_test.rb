require "test_helper"

class SearchResultsPdfTest < ActiveSupport::TestCase
  class FakePdf
    attr_reader :texts

    def initialize
      @texts = []
    end

    def fill_color(*); end

    def move_down(*); end

    def text(value, **)
      @texts << value
    end
  end

  test "header renders generated timestamp in central time with CT label" do
    service = SearchResultsPdf.new(
      listings: [],
      applied_filters: {},
      generated_at: Time.utc(2026, 5, 1, 1, 30, 0),
      base_url: "https://example.edu"
    )
    fake_pdf = FakePdf.new
    service.instance_variable_set(:@pdf, fake_pdf)

    service.send(:header)

    assert_includes fake_pdf.texts, "Generated April 30, 2026 at 8:30 PM CT"
  end
end
