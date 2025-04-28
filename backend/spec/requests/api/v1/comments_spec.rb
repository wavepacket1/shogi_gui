# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Comments API', type: :request do
  path '/api/v1/games/{game_id}/moves/{move_number}/comments' do
    post 'コメントを追加する' do
      tags 'Comments'
      produces 'application/json'
      parameter name: :game_id, in: :path, type: :integer
      parameter name: :move_number, in: :path, type: :integer
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string }
        },
        required: ['content']
      }

      response '201', 'コメント作成成功' do
        let(:game) { create(:game, status: 'active') }
        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
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
        let(:game_id) { 0 }
        let(:move_number) { 0 }
        let(:comment) { { content: 'テストコメント' } }

        run_test!
      end

      response '422', 'バリデーションエラー' do
        let(:game) { create(:game, status: 'active') }
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
      parameter name: :game_id, in: :path, type: :integer
      parameter name: :move_number, in: :path, type: :integer

      response '200', 'コメント一覧取得成功' do
        let(:game) { create(:game, status: 'active') }
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
      parameter name: :game_id, in: :path, type: :integer
      parameter name: :move_number, in: :path, type: :integer
      parameter name: :id, in: :path, type: :integer
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          content: { type: :string }
        },
        required: ['content']
      }

      response '200', 'コメント更新成功' do
        let(:game) { create(:game, status: 'active') }
        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:comment) { create(:comment, board_history: board_history, content: '元のコメント') }
        let(:id) { comment.id }
        let(:comment_params) { { content: '更新後のコメント' } }

        before do
          board_history # レコードを作成
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['content']).to eq('更新後のコメント')
        end
      end

      response '404', 'コメントが見つからない' do
        let(:game) { create(:game, status: 'active') }
        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:id) { 0 }
        let(:comment_params) { { content: '更新後のコメント' } }

        before do
          board_history # レコードを作成
        end

        run_test!
      end
    end

    delete 'コメントを削除する' do
      tags 'Comments'
      produces 'application/json'
      parameter name: :game_id, in: :path, type: :integer
      parameter name: :move_number, in: :path, type: :integer
      parameter name: :id, in: :path, type: :integer

      response '200', 'コメント削除成功' do
        let(:game) { create(:game, status: 'active') }
        let(:game_id) { game.id }
        let(:move_number) { 0 }
        let(:board_history) { create(:board_history, game: game, move_number: move_number) }
        let(:comment) { create(:comment, board_history: board_history, content: '削除するコメント') }
        let(:id) { comment.id }

        before do
          board_history # レコードを作成
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('コメントを削除しました')
          expect(Comment.find_by(id: id)).to be_nil
        end
      end

      response '404', 'コメントが見つからない' do
        let(:game) { create(:game, status: 'active') }
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
end 