# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Games API', type: :request do
  path '/api/v1/games/{id}/mode' do
    post 'ゲームモードを変更する' do
      tags 'Games'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer
      parameter name: :mode, in: :body, schema: {
        type: :object,
        properties: {
          mode: { type: :string, enum: ['play', 'edit', 'study'] }
        },
        required: ['mode']
      }

      response '200', 'モード変更成功' do
        let(:id) { game.id }
        let(:game) { create(:game, status: 'active') }
        let(:mode) { { mode: 'edit' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['mode']).to eq('edit')
        end
      end

      response '400', '不正なリクエスト' do
        let(:id) { game.id }
        let(:game) { create(:game, status: 'active') }
        let(:mode) { { mode: 'invalid' } }

        run_test!
      end

      response '404', 'ゲームが見つからない' do
        let(:id) { 0 }
        let(:mode) { { mode: 'edit' } }

        run_test!
      end
    end
  end
end 