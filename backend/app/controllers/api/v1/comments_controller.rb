# frozen_string_literal: true

module Api
  module V1
    class CommentsController < BaseController
      before_action :set_board_history
      before_action :set_comment, only: [:update, :destroy]

      def index
        @comments = @board_history.comments.order(created_at: :desc)
        render json: @comments
      end

      def create
        @comment = @board_history.comments.build(comment_params)

        if @comment.save
          render json: {
            comment_id: @comment.id,
            content: @comment.content,
            updated_at: @comment.updated_at
          }, status: :created
        else
          render json: { error: @comment.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      def update
        if @comment.update(comment_params)
          render json: {
            comment_id: @comment.id,
            content: @comment.content,
            updated_at: @comment.updated_at
          }
        else
          render json: { error: @comment.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      def destroy
        @comment.destroy
        render json: { message: 'コメントを削除しました' }, status: :ok
      end

      private

      def set_board_history
        @board_history = BoardHistory.find_by!(
          game_id: params[:game_id],
          move_number: params[:move_number],
          branch: params[:branch] || 'main'
        )
      rescue ActiveRecord::RecordNotFound
        render json: { error: '指定された局面が見つかりません' }, status: :not_found
      end

      def set_comment
        @comment = @board_history.comments.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'コメントが見つかりません' }, status: :not_found
      end

      def comment_params
        params.require(:comment).permit(:content)
      end
    end
  end
end 