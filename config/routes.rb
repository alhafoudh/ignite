Rails.application.routes.draw do
  resources :apps do
    member do
      post 'deployments' => 'deployment#create'
    end
  end

  scope :reverse_proxy do
    post 'reconfigure' => 'reverse_proxy#reconfigure'
  end

  root to: 'apps#index'
end
