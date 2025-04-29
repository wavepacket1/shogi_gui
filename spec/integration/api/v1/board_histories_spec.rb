require 'swagger_helper'

RSpec.describe 'API::V1::BoardHistories', type: :request do
  path '/api/v1/games/{game_id}/board_histories' do
    get '局面履歴の取得' do
      tags 'BoardHistories'
      produces 'application/json'
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch,  in: :query, type: :string,  description: '分岐名（default: main）', required: false

      response '200', '履歴取得成功' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id:          { type: :integer },
              game_id:     { type: :integer },
              sfen:        { type: :string },
              move_number: { type: :integer },
              branch:      { type: :string },
              created_at:  { type: :string, format: 'date-time' },
              updated_at:  { type: :string, format: 'date-time' },
              notation:    { type: :string, nullable: true }
            },
            required: %w[id game_id sfen move_number branch created_at updated_at]
          }

        let(:game_id) do
          g = Game.create!(status: 'active')
          # 履歴を追加しておく
          g.board_histories.create!(sfen: Board.default_sfen, move_number: 0, branch: 'main')
          g.id
        end
        run_test!
      end

      response '404', 'ゲームが見つからない' do
        let(:game_id) { 0 }
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
          properties: { branches: { type: :array, items: { type: :string } } },
          required: ['branches']

        let(:game_id) do
          g = Game.create!(status: 'active')
          g.board_histories.create!(sfen: Board.default_sfen, move_number: 0, branch: 'main')
          g.board_histories.create!(sfen: Board.default_sfen, move_number: 1, branch: 'main_1')
          g.id
        end
        run_test!
      end

      response '404', 'ゲームが見つからない' do
        let(:game_id) { 0 }
        run_test!
      end
    end
  end

  path '/api/v1/games/{game_id}/navigate_to/{move_number}' do
    post '指定手数への移動' do
      tags 'BoardHistories'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :game_id,     in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '移動先の手数'
      parameter name: :branch,      in: :query, type: :string,  description: '分岐名', required: false

      response '200', '移動成功' do
        schema type: :object,
          properties: {
            game_id:     { type: :integer },
            board_id:    { type: :integer },
            move_number: { type: :integer },
            sfen:        { type: :string }
          },
          required: %w[game_id board_id move_number sfen]

        let(:game) do
          g = Game.create!(status: 'active')
          b = g.create_board!(sfen: Board.default_sfen)
          g.board_histories.create!(sfen: b.sfen, move_number: 0, branch: 'main')
          g
        end
        let(:game_id)     { game.id }
        let(:move_number) { 0 }
        run_test!
      end

      response '404', '手数が見つからない' do
        let(:game_id)     { Game.create!(status: 'active').id }
        let(:move_number) { 999 }
        run_test!
      end
    end
  end

  path '/api/v1/games/{game_id}/switch_branch/{branch_name}' do
    post '分岐切替' do
      tags 'BoardHistories'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :game_id,     in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch_name, in: :path, type: :string,  description: '切替先分岐名'

      response '200', '分岐切替成功' do
        schema type: :object,
          properties: {
            game_id:             { type: :integer },
            branch:              { type: :string },
            current_move_number: { type: :integer }
          },
          required: %w[game_id branch current_move_number]

        let(:game) do
          g = Game.create!(status: 'active')
          g.board_histories.create!(sfen: Board.default_sfen, move_number: 0, branch: 'main')
          g.board_histories.create!(sfen: Board.default_sfen, move_number: 1, branch: 'main_1')
          g
        end
        let(:game_id)     { game.id }
        let(:branch_name) { 'main_1' }
        run_test!
      end

      response '404', '分岐が見つからない' do
        let(:game_id)     { Game.create!(status: 'active').id }
        let(:branch_name) { 'no_branch' }
        run_test!
      end
    end
  end
end 