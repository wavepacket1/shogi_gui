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
            id: @comment.id,
            comment_id: @comment.id,
            board_history_id: @comment.board_history_id,
            content: @comment.content,
            created_at: @comment.created_at,
            updated_at: @comment.updated_at
          }, status: :created
        else
          render json: { error: @comment.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "コメント作成エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "コメント作成中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
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
        Rails.logger.info "コメント作成: game_id=#{params[:game_id]}, move_number=#{params[:move_number]}, branch=#{params[:branch] || 'main'}"
        
        @board_history = BoardHistory.find_by(
          game_id: params[:game_id],
          move_number: params[:move_number],
          branch: params[:branch] || 'main'
        )
        
        # board_historyが見つからない場合は作成を試行
        unless @board_history
          Rails.logger.info "board_historyが見つからないため作成を試行"
          game = Game.find_by(id: params[:game_id])
          unless game
            Rails.logger.error "ゲームが見つかりません: game_id=#{params[:game_id]}"
            render json: { error: '指定されたゲームが見つかりません' }, status: :not_found
            return
          end
          
          # 初期局面（move_number: 0）の場合は自動作成
          if params[:move_number].to_i == 0
            Rails.logger.info "初期局面のboard_historyを作成"
            @board_history = BoardHistory.create!(
              game: game,
              move_number: 0,
              branch: params[:branch] || 'main',
              sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1', # 平手初期局面
              notation: '開始局面'
            )
            Rails.logger.info "board_history作成完了: id=#{@board_history.id}"
          else
            Rails.logger.error "初期局面以外のboard_historyは作成できません: move_number=#{params[:move_number]}"
            render json: { error: '指定された局面が見つかりません' }, status: :not_found
            return
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "RecordNotFound: #{e.message}"
        render json: { error: '指定された局面が見つかりません' }, status: :not_found
      rescue StandardError => e
        Rails.logger.error "set_board_historyエラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "局面の取得中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
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