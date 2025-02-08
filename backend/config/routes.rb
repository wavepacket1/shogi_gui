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
      resources :games, only: [:create, :show] 

      post '/games/:game_id/boards/:board_id/nyugyoku_declaration', to: 'games#nyugyoku_declaration'
      patch '/games/:game_id/boards/:board_id/move', to: 'moves#move'
    end
  end
end