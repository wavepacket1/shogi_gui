require 'swagger_helper'

RSpec.describe 'Api::V1::Moves', type: :request do
  path '/api/v1/games/{game_id}/boards/{board_id}/valid_moves' do
    patch 'Validate moves' do
      tags 'Moves'
      description '指定された指し手が有効かどうかを確認します'
      produces 'application/json'
      consumes 'application/json'
      parameter name: :game_id, in: :path, type: :integer, required: true, description: 'ゲームID'
      parameter name: :board_id, in: :path, type: :integer, required: true, description: 'ボードID'
      parameter name: :move_params, in: :body, schema: {
        type: :object,
        properties: {
          position: { type: :string, example: '7g' }
        },
        required: ['position']
      }

      response '200', '指し手の有効性確認結果' do
        schema type: :object,
          properties: {
            status: { type: :boolean, example: true },
            legal_flag: { type: :boolean, example: true },
            message: { type: :string, example: '有効な手です' },
            possible_moves: { 
              type: :array,
              items: { type: :string },
              example: ['7f', '7e']
            }
          }
        
        let(:game) { create(:game) }
        let(:board) { create(:board, game: game) }
        let(:game_id) { game.id }
        let(:board_id) { board.id }
        let(:move_params) { { position: '7g' } }

        run_test!
      end

      response '422', '不正なパラメータ' do
        schema type: :object,
          properties: {
            status: { type: :boolean, example: false },
            message: { type: :string, example: '不正なパラメータです' }
          }
        
        let(:game) { create(:game) }
        let(:board) { create(:board, game: game) }
        let(:game_id) { game.id }
        let(:board_id) { board.id }
        let(:move_params) { { position: 'invalid' } }

        run_test!
      end

      response '404', 'ゲームまたはボードが見つかりません' do
        schema type: :object,
          properties: {
            status: { type: :string, example: 'error' },
            message: { type: :string, example: 'ゲームが見つかりません。' }
          }
        
        let(:game_id) { 0 }
        let(:board_id) { 0 }
        let(:move_params) { { position: '7g' } }

        run_test!
      end
    end
  end
end 