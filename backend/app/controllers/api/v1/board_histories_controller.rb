module Api
  module V1
    class BoardHistoriesController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      
      # 局面履歴の取得
      def index
        @game = Game.find(params[:game_id])
        branch_name = params[:branch] || 'main'
        @board_histories = @game.board_histories.where(branch: branch_name).order(:move_number)
        
        # 履歴に棋譜表記を追加
        histories_with_notation = @board_histories.map do |history|
          history_data = history.as_json
          # 棋譜表記を追加
          history_data['notation'] = history.to_kifu_notation
          history_data
        end
        
        render json: histories_with_notation
      end
      
      # 分岐リストの取得
      def branches
        @game = Game.find(params[:game_id])
        branches = @game.board_histories.pluck(:branch).uniq
        
        render json: { branches: branches }
      end
      
      # 指定した手数の局面に移動
      def navigate_to
        @game = Game.find(params[:game_id])
        branch = params[:branch] || 'main'
        move_number = params[:move_number].to_i
        
        @history = @game.board_histories
                      .where(branch: branch)
                      .find_by(move_number: move_number)
        
        if @history.nil?
          return render json: {
            error: "Move number not found in branch",
            status: 404
          }, status: :not_found
        end
        
        # ボードがない場合は作成
        @board = @game.board || @game.create_board(sfen: @history.sfen)
        
        # 明示的にsfen値を設定して保存
        @board.sfen = @history.sfen
        @board.save!
        
        render json: {
          game_id: @game.id,
          board_id: @board.id,
          move_number: @history.move_number,
          sfen: @history.sfen,
          move_sfen: @history.move_sfen,
          notation: @history.to_kifu_notation
        }
      end
      
      # 分岐切り替え
      def switch_branch
        @game = Game.find(params[:game_id])
        branch_name = params[:branch_name]
        
        # 分岐が存在するか確認
        unless @game.board_histories.where(branch: branch_name).exists?
          return render json: {
            error: "Branch not found",
            status: 404
          }, status: :not_found
        end
        
        # 分岐内の最新局面を取得
        @latest_history = @game.board_histories
                             .where(branch: branch_name)
                             .ordered
                             .last
        
        # ボードがない場合は作成
        @board = @game.board || @game.create_board(sfen: @latest_history.sfen)
        
        # 明示的にsfen値を設定して保存
        @board.sfen = @latest_history.sfen
        @board.save!
        
        render json: {
          game_id: @game.id,
          branch: branch_name,
          current_move_number: @latest_history.move_number,
          move_sfen: @latest_history.move_sfen,
          notation: @latest_history.to_kifu_notation
        }
      end
      
      private
      
      def record_not_found
        render json: {
          error: "Game not found",
          status: 404
        }, status: :not_found
      end
    end
  end
end
