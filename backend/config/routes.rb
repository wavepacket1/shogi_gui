Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  namespace :api do 
    namespace :v1 do 
      resources :boards, only: [:show, :create] do
        collection do
          get 'default', to: 'boards#default'
        end
      end

      resources :games, only: [:create, :show] do
        member do
          post :resign
          post :mode
        end
      end

      post '/games/:game_id/boards/:board_id/nyugyoku_declaration', to: 'games#nyugyoku_declaration'
      patch '/games/:game_id/boards/:board_id/move', to: 'moves#move'

      # 履歴関連のルート
      get '/games/:game_id/board_histories', to: 'board_histories#index'
      get '/games/:game_id/board_histories/branches', to: 'board_histories#branches'
      post '/games/:game_id/navigate_to/:move_number', to: 'board_histories#navigate_to'
      post '/games/:game_id/switch_branch/:branch_name', to: 'board_histories#switch_branch'
      
      # 分岐管理のルート
      post '/games/:game_id/board_histories/:move_number/branches', to: 'board_histories#create_branch'
      delete '/games/:game_id/branches/:branch_name', to: 'board_histories#delete_branch'
      
      # コメント関連のルート
      post '/games/:game_id/moves/:move_number/comments', to: 'comments#create'
      get '/games/:game_id/moves/:move_number/comments', to: 'comments#index'
      patch '/games/:game_id/moves/:move_number/comments/:id', to: 'comments#update'
      delete '/games/:game_id/moves/:move_number/comments/:id', to: 'comments#destroy'
    end
  end
end