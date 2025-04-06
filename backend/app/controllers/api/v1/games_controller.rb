# frozen_string_literal: true

module Api
  module V1
    class GamesController < ApplicationController
      def create
        @game = Game.new(game_params)

        @game.errors.add(:status, "can't be blank") if game_params[:status].blank?
        
        if @game.errors.empty? && @game.save
          @board = @game.create_board!(sfen: Board.default_sfen)
          
          # 0手目（開始局面）の履歴を作成
          @game.board_histories.create!(
            sfen: @board.sfen,
            move_number: 0,
            branch: 'main'
          )
          
          render json: {
            game_id: @game.id,
            status: @game.status,
            board_id: @board.id
          }, status: :created
        else
          render json: {
            error: @game.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def show
        @game = Game.find(params[:id])
        render json: @game, include: :board
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'ゲームが見つかりません。' }, status: :not_found
      end

      def nyugyoku_declaration
        @game = Game.find(params[:game_id])
        @board = Board.find(params[:board_id])

        if @game.nyugyoku_declaration(@board)
          render json: {
            status: 'success',
            game_id: @game.id,
            board_id: @board.id
          }, status: :ok
        else
          render json: {
            status: 'failed',
            message: '入玉宣言に失敗しました。'
          }, status: :ok
        end
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: 'ゲームまたは盤面が見つかりません。'
        }, status: :not_found
      end

      private

      def game_params
        params.require(:game).permit(:status)
      end
    end
  end
end
