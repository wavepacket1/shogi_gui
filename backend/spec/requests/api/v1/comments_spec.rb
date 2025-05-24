# frozen_string_literal: true

require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Comments API', type: :request do
  let!(:game) { Game.create!(status: 'active', mode: 'study') }
  let!(:board) { Board.create!(game: game, sfen: Board.default_sfen) }
  let!(:board_history) do
    BoardHistory.create!(
      game: game,
      move_number: 0,
      branch: 'main',
      sfen: board.sfen
    )
  end

  path '/api/v1/games/{game_id}/moves/{move_number}/comments' do
    post 'コメントを追加する' do
      tags 'Comments'
      produces 'application/json'
      consumes 'application/json'
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '手数'
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string, description: 'コメント内容', example: 'このあたりの手が難しい' }
        },
        required: ['content']
      }

      response '201', 'コメント作成成功' do
        schema type: :object,
               properties: {
                 id: { type: :integer, example: 42 },
                 content: { type: :string, example: 'テストコメント' },
                 board_history_id: { type: :integer, example: 123 },
                 created_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' },
                 updated_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:comment) { { content: 'テストコメント' } }

        before do
          board_history # レコードを作成
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['content']).to eq('テストコメント')
        end
      end

      response '404', '局面が見つからない' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: '指定された局面が見つかりません' }
               }

        let(:game_id) { 0 }
        let(:move_number) { 0 }
        let(:comment) { { content: 'テストコメント' } }

        run_test!
      end

      response '422', 'バリデーションエラー' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'コメント内容を入力してください' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:comment) { { content: '' } }

        before do
          board_history # レコードを作成
        end

        run_test!
      end
    end

    get 'コメント一覧を取得する' do
      tags 'Comments'
      produces 'application/json'
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '手数'

      response '200', 'コメント一覧取得成功' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, example: 42 },
                   content: { type: :string, example: 'テストコメント' },
                   board_history_id: { type: :integer, example: 123 },
                   created_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' },
                   updated_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' }
                 }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }

        before do
          board_history # レコードを作成
          create(:comment, board_history: board_history, content: 'テストコメント1')
          create(:comment, board_history: board_history, content: 'テストコメント2')
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(2)
          expect(data[0]['content']).to eq('テストコメント2')
          expect(data[1]['content']).to eq('テストコメント1')
        end
      end

      response '404', '局面が見つからない' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: '指定された局面が見つかりません' }
               }

        let(:game_id) { 0 }
        let(:move_number) { 0 }

        run_test!
      end
    end
  end

  path '/api/v1/games/{game_id}/moves/{move_number}/comments/{id}' do
    patch 'コメントを更新する' do
      tags 'Comments'
      produces 'application/json'
      consumes 'application/json'
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '手数'
      parameter name: :id, in: :path, type: :integer, description: 'コメントID'
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string, description: '更新後のコメント内容', example: '修正後のコメント' }
        },
        required: ['content']
      }

      response '200', 'コメント更新成功' do
        schema type: :object,
               properties: {
                 id: { type: :integer, example: 42 },
                 content: { type: :string, example: '更新後のコメント' },
                 board_history_id: { type: :integer, example: 123 },
                 created_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' },
                 updated_at: { type: :string, format: 'date-time', example: '2025-04-29T10:00:00.000Z' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:comment_obj) { create(:comment, board_history: board_history, content: '元のコメント') }
        let(:id) { comment_obj.id }
        let(:comment) { { content: '更新後のコメント' } }

        before do
          board_history # レコードを作成
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['content']).to eq('更新後のコメント')
        end
      end

      response '404', 'コメントが見つからない' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'コメントが見つかりません' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:id) { 0 }
        let(:comment) { { content: '更新後のコメント' } }

        before do
          board_history # レコードを作成
        end

        run_test!
      end
    end

    delete 'コメントを削除する' do
      tags 'Comments'
      produces 'application/json'
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :move_number, in: :path, type: :integer, description: '手数'
      parameter name: :id, in: :path, type: :integer, description: 'コメントID'

      response '200', 'コメント削除成功' do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'コメントを削除しました' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:comment_obj) { create(:comment, board_history: board_history, content: '削除対象のコメント') }
        let(:id) { comment_obj.id }

        before do
          board_history # レコードを作成
          comment_obj   # コメントを作成
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('コメントを削除しました')
          expect(Comment.exists?(id)).to be false
        end
      end

      response '404', 'コメントが見つからない' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'コメントが見つかりません' }
               }

        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:id) { 0 }

        before do
          board_history # レコードを作成
        end

        run_test!
      end
    end
  end

  describe "POST /api/v1/games/:game_id/moves/:move_number/comments" do
    let(:valid_params) do
      {
        comment: {
          content: "テストコメント"
        }
      }
    end

    context "有効なパラメータの場合" do
      it "コメントが作成される" do
        expect {
          post "/api/v1/games/#{game.id}/moves/0/comments", params: valid_params
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq('テストコメント')
        expect(json_response['board_history_id']).to eq(board_history.id)
      end
    end

    context "無効なパラメータの場合" do
      it "エラーが返される" do
        post "/api/v1/games/#{game.id}/moves/0/comments", params: { comment: { content: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include("Content can't be blank")
      end
    end
  end

  describe "GET /api/v1/games/:game_id/moves/:move_number/comments" do
    let!(:comment) { Comment.create!(board_history: board_history, content: "既存のコメント") }

    it "コメント一覧が取得できる" do
      get "/api/v1/games/#{game.id}/moves/0/comments"

      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first['content']).to eq('既存のコメント')
    end
  end
end 