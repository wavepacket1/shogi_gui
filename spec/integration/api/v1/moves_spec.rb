require 'swagger_helper'

RSpec.describe 'API::V1::Moves', type: :request do
  path '/api/v1/games/{game_id}/boards/{board_id}/move' do
    post '手の移動' do
      tags 'Moves'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :game_id,  in: :path, type: :integer
      parameter name: :board_id, in: :path, type: :integer
      parameter name: :move,     in: :body,   schema: {
        type: :object,
        properties: {
          move:        { type: :string },
          move_number: { type: :integer },
          branch:      { type: :string }
        },
        required: ['move']
      }

      response '200', '移動成功' do
        schema type: :object,
          properties: {
            status:              { type: :boolean },
            is_checkmate:        { type: :boolean },
            is_repetition:       { type: :boolean },
            is_repetition_check: { type: :boolean },
            board_id:            { type: :integer },
            sfen:                { type: :string },
            move_number:         { type: :integer },
            branch:              { type: :string },
            move_sfen:           { type: :string, nullable: true },
            notation:            { type: :string, nullable: true }
          },
          required: %w[status board_id sfen move_number branch]

        let(:game) do
          g = Game.create!(status: 'active')
          b = g.create_board!(sfen: Board.default_sfen)
          g.board_histories.create!(sfen: b.sfen, move_number: 0, branch: 'main')
          g
        end
        let(:game_id)  { game.id }
        let(:board_id) { game.board.id }
        let(:move)     { { move: '7g7f', move_number: 0, branch: 'main' } }
        run_test!
      end

      response '400', '不正な移動' do
        let(:game_id)  { Game.create!(status: 'active').id }
        let(:board_id) { 0 }
        let(:move)     { { move: '' } }
        run_test!
      end
    end
  end
end 