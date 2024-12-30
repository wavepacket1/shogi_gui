require 'rails_helper'

RSpec.describe 'Api::V1::Games', type: :request do
  describe 'POST /api/v1/games' do
    context '正常なパラメータの場合' do
      let(:valid_params) { { status: 'active' } }

      it 'ゲームを作成し、OpenAPI仕様に準拠したレスポンスを返すこと' do
        post api_v1_games_path, params: valid_params, as: :json
        
        assert_response_schema_confirm    # レスポンスの形式が仕様に準拠しているか確認
        expect(response).to have_http_status(:created)
        
        json = JSON.parse(response.body)
        expect(json).to include(
          'id' => be_kind_of(Integer),
          'status' => 'active'
        )
      end
    end

    context '不正なパラメータの場合' do
      let(:invalid_params) { { status: '' } }

      it 'エラーを返し、OpenAPI仕様に準拠したレスポンスを返すこと' do
        post api_v1_games_path, params: invalid_params, as: :json
        
        assert_response_schema_confirm    # レスポンスの形式が仕様に準拠しているか確認
        expect(response).to have_http_status(:unprocessable_entity)
        
        json = JSON.parse(response.body)
        expect(json).to include('error' => be_kind_of(String))
      end
    end
  end
end 