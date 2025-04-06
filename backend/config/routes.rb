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

      # 履歴関連のルート
      get '/games/:game_id/board_histories', to: 'board_histories#index'
      get '/games/:game_id/board_histories/branches', to: 'board_histories#branches'
      post '/games/:game_id/navigate_to/:move_number', to: 'board_histories#navigate_to'
      post '/games/:game_id/switch_branch/:branch_name', to: 'board_histories#switch_branch'
    end
  end
end