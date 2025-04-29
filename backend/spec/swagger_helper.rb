# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s
  config.swagger_docs = {
    'v1/openapi.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Shogi API V1',
        version: 'v1',
        description: '将棋アプリケーションのAPI仕様'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      components: {
        schemas: {
          game: {
            type: :object,
            properties: {
              game_id: { type: :integer },
              status: { type: :string, enum: ['active', 'finished', 'pause'] },
              board_id: { type: :integer }
            },
            required: ['game_id', 'status', 'board_id']
          },
          error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          }
        }
      }
    }
  }
end
