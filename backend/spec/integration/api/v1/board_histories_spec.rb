require 'swagger_helper'

RSpec.describe 'API::V1::BoardHistories', type: :request do
  path '/api/v1/games/{game_id}/board_histories' do
    get '局面履歴の取得' do
      tags 'BoardHistories'
      produces 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch, in: :query, type: :string, required: false, description: '分岐名（デフォルト: main）'
      
      response '200', '履歴取得成功' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              game_id: { type: :integer },
              sfen: { type: :string },
              move_number: { type: :integer },
              branch: { type: :string },
              move_sfen: { 
                type: :string, 
                nullable: true, 
                description: '前局面からの指し手情報（SFEN形式）。例：7g7f, P*3d, 8h2b+'
              },
              notation: { 
                type: :string, 
                nullable: true, 
                description: '棋譜表記（例：「▲7六歩」「△8四銀」）。日本語形式で表示された棋譜。'
              },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          }
        
        let(:game_id) { Game.create(status: 'active').id }
        run_test!
      end
      
      response '404', 'ゲームが見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game_id) { 'invalid' }
        run_test!
      end
    end
  end
  
  path '/api/v1/games/{game_id}/board_histories/branches' do
    get '分岐リストの取得' do
      tags 'BoardHistories'
      produces 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      
      response '200', '分岐リスト取得成功' do
        schema type: :object,
          properties: {
            branches: { 
              type: :array,
              items: { type: :string }
            }
          }
        
        let(:game_id) { Game.create(status: 'active').id }
        run_test!
      end
      
      response '404', 'ゲームが見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game_id) { 'invalid' }
        run_test!
      end
    end
  end
  
  path '/api/v1/games/{game_id}/navigate_to/{move_number}' do
    post '指定した手数の局面に移動' do
      tags 'BoardHistories'
      produces 'application/json'
      consumes 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '移動先の手数'
      parameter name: :branch, in: :query, type: :string, required: false, description: '分岐名（デフォルト: main）'
      
      response '200', '移動成功' do
        schema type: :object,
          properties: {
            game_id: { type: :integer },
            board_id: { type: :integer },
            move_number: { type: :integer },
            sfen: { type: :string },
            move_sfen: { 
              type: :string, 
              nullable: true, 
              description: '前局面からの指し手情報（SFEN形式）' 
            },
            notation: { 
              type: :string, 
              nullable: true, 
              description: '棋譜表記（日本語形式）' 
            }
          }
        
        let(:game) { Game.create(status: 'active') }
        let(:board) { Board.create(game: game, sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0') }
        let(:game_id) { game.id }
        let(:move_number) { 0 }
        
        before do
          BoardHistory.create!(
            game: game,
            sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
            move_number: 0,
            branch: 'main'
          )
        end
        
        run_test!
      end
      
      response '404', '手数が見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game) { Game.create(status: 'active') }
        let(:game_id) { game.id }
        let(:move_number) { 99 }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/games/{game_id}/switch_branch/{branch_name}' do
    post '分岐切り替え' do
      tags 'BoardHistories'
      produces 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch_name, in: :path, type: :string, description: '分岐名'
      
      response '200', '分岐切り替え成功' do
        schema type: :object,
          properties: {
            game_id: { type: :integer },
            branch: { type: :string },
            current_move_number: { type: :integer },
            move_sfen: { 
              type: :string, 
              nullable: true, 
              description: '前局面からの指し手情報（SFEN形式）' 
            },
            notation: { 
              type: :string, 
              nullable: true, 
              description: '棋譜表記（日本語形式）' 
            }
          }
        
        let(:game) { Game.create(status: 'active') }
        let(:board) { Board.create(game: game, sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0') }
        let(:game_id) { game.id }
        let(:branch_name) { 'main' }
        
        before do
          BoardHistory.create!(
            game: game,
            sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
            move_number: 0,
            branch: 'main'
          )
        end
        
        run_test!
      end
      
      response '404', '分岐が見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game) { Game.create(status: 'active') }
        let(:game_id) { game.id }
        let(:branch_name) { 'non_existent_branch' }
        
        run_test!
      end
    end
  end
end
