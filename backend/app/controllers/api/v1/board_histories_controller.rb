module Api
  module V1
    class BoardHistoriesController < BaseController
      before_action :set_game

      # GET /api/v1/games/:game_id/board_histories
      def index
        branch = params[:branch] || 'main'
        histories = @game.board_histories
                         .where(branch: branch)
                         .order(:move_number)
        render json: histories.as_json(
          only: %i[id game_id sfen move_number branch created_at updated_at notation]
        )
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found', status: 404 }, status: :not_found
      end

      # GET /api/v1/games/:game_id/board_histories/branches
      def branches
        branch_list = @game.board_histories.distinct.pluck(:branch)
        render json: { branches: branch_list }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found', status: 404 }, status: :not_found
      end

      # POST /api/v1/games/:game_id/navigate_to/:move_number
      def navigate_to
        branch = params[:branch] || 'main'
        history = @game.board_histories.find_by!(
          branch: branch,
          move_number: params[:move_number]
        )
        render json: {
          game_id: @game.id,
          board_id: @game.board.id,
          move_number: history.move_number,
          sfen: history.sfen
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Move not found in branch', status: 404 }, status: :not_found
      end

      # POST /api/v1/games/:game_id/switch_branch/:branch_name
      def switch_branch
        branch = params[:branch_name]
        history = @game.board_histories
                       .where(branch: branch)
                       .order(:move_number)
                       .last!
        render json: {
          game_id: @game.id,
          branch: branch,
          current_move_number: history.move_number
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Branch not found', status: 404 }, status: :not_found
      end

      private

      def set_game
        @game = Game.find(params[:game_id])
      end
    end
  end
end
