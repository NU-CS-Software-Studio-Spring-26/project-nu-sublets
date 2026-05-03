if Rails.env.local?
  require "dotenv"

  Dotenv.load(Rails.root.join(".env"))
end
