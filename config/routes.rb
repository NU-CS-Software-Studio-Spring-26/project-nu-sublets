Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"
  get "listing" => "pages#listing", as: :listing
  get "listings/:id" => "pages#listing", as: :sublet_listing
  patch "listings/:id" => "sublet_listings#update"
  delete "listings/:id" => "sublet_listings#destroy"
  post "listings/:sublet_listing_id/questions" => "listing_questions#create", as: :sublet_listing_questions
  post "listings/:sublet_listing_id/reports" => "listing_reports#create", as: :sublet_listing_reports
  patch "listing-questions/:id" => "listing_questions#update", as: :listing_question
  delete "listing-questions/:id" => "listing_questions#destroy"
  get "search-results" => "pages#search_results", as: :search_results
  get "saved" => "pages#saved", as: :saved
  get "post-sublet" => "pages#post_sublet", as: :post_sublet
  get "profile" => "pages#profile", as: :profile
  patch "profile" => "pages#update_profile"
  delete "profile" => "pages#destroy_account"
  get "users/:id" => "pages#user_profile", as: :user_profile
  resources :conversations, only: %i[index show create] do
    resources :messages, only: :create
  end
  mount ActionCable.server => "/cable"
  get "another-user-account" => "pages#another_user_account", as: :another_user_account
  get "about" => "pages#about", as: :about
  get "about-us" => "pages#about_us", as: :about_us
  get "community-guidelines" => "pages#community_guidelines", as: :community_guidelines
  get "disclaimer" => "pages#disclaimer", as: :disclaimer
  get "privacy-policy" => "pages#privacy_policy", as: :privacy_policy
  get "login" => "pages#login", as: :login
  get "signup" => "registrations#new", as: :signup
  post "signup" => "registrations#create"
  get "onboarding/terms" => "onboarding#terms", as: :onboarding_terms
  post "onboarding/terms" => "onboarding#accept_terms", as: :onboarding_accept_terms
  post "google-oauth" => "sessions#google_oauth_unconfigured", as: :google_oauth
  match "auth/:provider/callback" => "sessions#omniauth", via: %i[get post], as: :omniauth_callback
  match "auth/failure" => "sessions#omniauth_failure", via: %i[get post], as: :omniauth_failure
  post "session" => "sessions#create", as: :session
  delete "session" => "sessions#destroy"
  post "post-sublet" => "pages#submit_sublet", as: :submit_sublet
end
