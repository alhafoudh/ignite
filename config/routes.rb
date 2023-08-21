Rails.application.routes.draw do
  get 'reverse_proxy/reconfigure'
  resources :apps do
    member do
      post 'deployments' => 'deployment#create'
    end
  end

  scope :reverse_proxy do
    post 'reconfigure' => 'reverse_proxy#reconfigure'
  end
end
