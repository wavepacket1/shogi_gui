class ApplicationController < ActionController::API
    include DeviseTokenAuth::Concerns::SetUserByToken

    # エイリアスメソッドを追加
    def authenticate_api_v1_user!
        authenticate_user!
    end
    helper_method :authenticate_api_v1_user! if respond_to?(:helper_method)
end
