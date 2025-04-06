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

      resources :games, only: [:create, :show] do
        member do
          post :resign
        end

        # 既存のカスタムルート
        post 'boards/:board_id/nyugyoku_declaration', to: 'games#nyugyoku_declaration'
        patch 'boards/:board_id/move', to: 'moves#move'

        # 履歴関連のルート
        resources :board_histories, only: [:index] do
          collection do
            get :branches
            post 'navigate_to/:move_number', to: 'board_histories#navigate_to'
            post 'switch_branch/:branch_name', to: 'board_histories#switch_branch'
          end
        end
      end
    end
  end
end