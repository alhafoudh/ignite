Rails.application.routes.draw do
  resources :apps do
    member do
      post 'deployments' => 'deployment#create'
    end
  end
end
