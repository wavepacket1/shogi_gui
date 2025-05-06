module Api
  module V1
    class BaseController < ApplicationController
      include DeviseTokenAuth::Concerns::SetUserByToken
    end
  end
end