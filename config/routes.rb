Rails.application.routes.draw do
  devise_for :users
  root 'staff#index', :skip => [:registrations]
  get 'change_password', to: 'auth#new'
  post 'change_password', to: 'auth#update_password'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  resources :staff
  resources :employee
  resources :integration do
    collection do
      get 'google_workspace_callback', to: 'integration#google_workspace_callback'
      get 'authenticate/:integration_id', to: 'integration#authenticate'
      get 'checkin', to: 'integration#checkin'
    end
  end
end
