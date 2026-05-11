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
  get "search-results" => "pages#search_results", as: :search_results
  get "saved" => "pages#saved", as: :saved
  get "post-sublet" => "pages#post_sublet", as: :post_sublet
  get "profile" => "pages#profile", as: :profile
  get "profiles/:id" => "pages#public_profile", as: :user_profile
  get "privacy-policy" => "pages#privacy_policy", as: :privacy_policy
  get "login" => "pages#login", as: :login
  post "session" => "sessions#create", as: :session
  delete "session" => "sessions#destroy"
  post "post-sublet" => "pages#submit_sublet", as: :submit_sublet
end
