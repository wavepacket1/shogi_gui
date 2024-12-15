require 'rails_helper'

RSpec.describe "Api::V1::Moves", type: :request do
  describe "GET /move" do
    it "returns http success" do
      get "/api/v1/move/move"
      expect(response).to have_http_status(:success)
    end
  end

end
