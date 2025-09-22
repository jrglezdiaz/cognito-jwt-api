Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      # Authentication routes (no authentication required)
      post "auth/signup", to: "auth#sign_up"
      post "auth/confirm", to: "auth#confirm_sign_up"
      post "auth/signin", to: "auth#sign_in"
      post "auth/signout", to: "auth#sign_out"
      post "auth/refresh", to: "auth#refresh"
      post "auth/forgot-password", to: "auth#forgot_password"
      post "auth/confirm-forgot-password", to: "auth#confirm_forgot_password"
      post "auth/change-password", to: "auth#change_password"

      # User routes (authentication required)
      get "users/profile", to: "users#profile"
      get "users/current", to: "users#current"

      # Posts routes (authentication required)
      resources :posts do
        collection do
          get "my_posts"
        end
      end
    end
  end

  # Defines the root path route ("/")
  root to: proc { [ 200, { "Content-Type" => "application/json" }, [ { message: "Cognito JWT API", version: "1.0.0" }.to_json ] ] }
end
