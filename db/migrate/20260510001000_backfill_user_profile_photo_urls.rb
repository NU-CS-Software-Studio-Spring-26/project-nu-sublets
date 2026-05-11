class BackfillUserProfilePhotoUrls < ActiveRecord::Migration[8.1]
  PROFILE_PHOTO_URLS = [
    "https://randomuser.me/api/portraits/women/65.jpg",
    "https://randomuser.me/api/portraits/men/73.jpg",
    "https://randomuser.me/api/portraits/women/27.jpg",
    "https://randomuser.me/api/portraits/men/15.jpg",
    "https://randomuser.me/api/portraits/women/32.jpg",
    "https://randomuser.me/api/portraits/men/12.jpg",
    "https://randomuser.me/api/portraits/women/18.jpg",
    "https://randomuser.me/api/portraits/men/8.jpg",
    "https://randomuser.me/api/portraits/women/12.jpg",
    "https://randomuser.me/api/portraits/women/28.jpg",
    "https://randomuser.me/api/portraits/men/18.jpg",
    "https://randomuser.me/api/portraits/women/24.jpg"
  ].freeze

  def up
    say_with_time "Backfilling user profile photo URLs" do
      select_all("SELECT id FROM users WHERE profile_photo_url IS NULL OR profile_photo_url = '' ORDER BY id").each_with_index do |user, index|
        execute <<~SQL.squish
          UPDATE users
          SET profile_photo_url = #{quote(PROFILE_PHOTO_URLS[index % PROFILE_PHOTO_URLS.length])}
          WHERE id = #{user["id"].to_i}
        SQL
      end
    end
  end

  def down
    execute "UPDATE users SET profile_photo_url = NULL WHERE profile_photo_url IN (#{PROFILE_PHOTO_URLS.map { |url| quote(url) }.join(", ")})"
  end
end
