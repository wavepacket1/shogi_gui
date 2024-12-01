Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  namespace :api do 
    namespace :v1 do 
      resources :boards, only: [:show, :create] do
        collection do
          get 'default', to: 'boards#default'
        end
      end
      resources :pieces, only: [:update]
      resources :games, only: [:create, :show] 
    end
  end
end