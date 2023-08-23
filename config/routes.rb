Rails.application.routes.draw do
  resources :apps do
    resources :deployments, only: [:create] do
      member do
        post 'start' => 'deployments#start'
      end
    end
  end

  scope :reverse_proxy do
    post 'reconfigure' => 'reverse_proxy#reconfigure'
  end

  root to: 'apps#index'
end
