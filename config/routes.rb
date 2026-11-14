Rails.application.routes.draw do
  # Health check for the ALB target group.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get  "login"  => "sessions#new"
  post "login"  => "sessions#create"
  delete "logout" => "sessions#destroy"

  get  "signup" => "signups#new"
  post "signup" => "signups#create"

  resources :invoices do
    member do
      get :pdf
    end
  end

  get "pdf_render/:id" => "pdf_render#show", as: :pdf_render

  root "invoices#index"
end
