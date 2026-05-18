require "test_helper"

class AiListingDraftServiceTest < ActiveSupport::TestCase
  test "builds a demo draft without an api key" do
    draft = AiListingDraftService.call(
      {
        "street-address" => "820 Noyes St",
        "price" => "950",
        "start-date" => "06/12/2026",
        "end-date" => "09/11/2026",
        "bedrooms" => "1",
        "amenities" => [ "Laundry", "Gym" ],
        "utilities_included" => "1"
      },
      api_key: nil
    )

    assert_equal "demo", draft[:source]
    assert_includes draft[:title], "820 Noyes St"
    assert_includes draft[:description], "$950/month"
    assert_includes draft[:description], "utilities included"
    assert_includes draft[:description], "Laundry"
    assert_includes draft[:description], "Gym"
  end

  test "incorporates existing notes into demo copy" do
    draft = AiListingDraftService.call(
      {
        "street-address" => "820 Noyes St",
        "title" => "Quiet Room Near Campus",
        "description" => "Bright furnished room near Northwestern with a short walk to campus."
      },
      api_key: nil
    )

    assert_equal "demo", draft[:source]
    assert_includes draft[:title], "820 Noyes St"
    assert_includes draft[:description], "Additional notes: Bright furnished room near Northwestern with a short walk to campus."
  end

  test "requires some listing context" do
    error = assert_raises(AiListingDraftService::InputError) do
      AiListingDraftService.call({}, api_key: nil)
    end

    assert_equal "Add an address, rent, or notes before generating a draft.", error.message
  end
end
