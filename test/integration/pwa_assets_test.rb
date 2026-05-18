require "test_helper"

class PwaAssetsTest < ActionDispatch::IntegrationTest
  test "manifest loads with installable app fields" do
    get "/manifest.json"

    assert_response :success

    manifest = JSON.parse(response.body)
    assert_equal "NU Sublets", manifest.fetch("name")
    assert_equal "NU Sublets", manifest.fetch("short_name")
    assert_equal "A Northwestern student sublet marketplace.", manifest.fetch("description")
    assert_equal "/", manifest.fetch("start_url")
    assert_equal "/", manifest.fetch("scope")
    assert_equal "standalone", manifest.fetch("display")
    assert_equal "#4E2A84", manifest.fetch("theme_color")
    assert_equal "/icons/icon-192.png", manifest.fetch("icons").first.fetch("src")
    assert_equal "/icons/icon-512.png", manifest.fetch("icons").second.fetch("src")
  end

  test "service worker loads and includes conservative fetch handling" do
    get "/service-worker.js"

    assert_response :success
    assert_includes response.body, "nu-sublets-static-v2"
    assert_includes response.body, "self.addEventListener(\"install\""
    assert_includes response.body, "self.addEventListener(\"activate\""
    assert_includes response.body, "self.addEventListener(\"fetch\""
    assert_includes response.body, "if (request.method !== \"GET\") return;"
    assert_includes response.body, "url.pathname.startsWith(\"/profile\")"
  end

  test "pwa icons load from public icons" do
    {
      "/icons/icon-192.png" => "192x192",
      "/icons/icon-512.png" => "512x512",
      "/icons/apple-touch-icon.png" => "180x180"
    }.each_key do |path|
      get path

      assert_response :success
      assert_equal "image/png", response.media_type
    end
  end

  test "home page links manifest and registers service worker" do
    get root_path

    assert_response :success
    assert_select "link[rel='manifest'][href='/manifest.json']"
    assert_select "meta[name='theme-color'][content='#4E2A84']"
    assert_select "link[rel='apple-touch-icon'][href='/icons/apple-touch-icon.png']"
    assert_includes response.body, "navigator.serviceWorker.register(\"/service-worker.js\", { scope: \"/\" })"
  end
end
