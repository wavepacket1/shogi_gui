# frozen_string_literal: true

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

      # 分岐作成
      def create_branch
        @game = Game.find(params[:game_id])
        move_number = params[:move_number].to_i
        source_branch = params[:source_branch] || 'main'
        branch_name = params[:branch_name] || generate_branch_name(@game)

        # 分岐名のバリデーション
        if branch_name.blank? || branch_name !~ /\A[a-zA-Z0-9_-]+\z/
          return render json: {
            error: "分岐名は英数字と-_のみ使用できます",
            status: 400
          }, status: :bad_request
        end

        # 同名分岐の存在確認
        if @game.board_histories.where(branch: branch_name).exists?
          return render json: {
            error: "同じ名前の分岐が既に存在します",
            status: 400
          }, status: :bad_request
        end

        # 分岐開始地点の履歴を取得
        source_history = @game.board_histories
                             .where(branch: source_branch, move_number: move_number)
                             .first

        if source_history.nil?
          return render json: {
            error: "指定された局面が見つかりません",
            status: 404
          }, status: :not_found
        end

        ActiveRecord::Base.transaction do
          # 分岐開始地点までの履歴を新しい分岐にコピー
          histories_to_copy = @game.board_histories
                                 .where(branch: source_branch)
                                 .where('move_number <= ?', move_number)
                                 .order(:move_number)

          histories_to_copy.each do |history|
            @game.board_histories.create!(
              sfen: history.sfen,
              move_number: history.move_number,
              branch: branch_name,
              move_sfen: history.move_sfen
            )
          end
        end

        render json: {
          branch_name: branch_name,
          created_at: Time.current.iso8601,
          move_number: move_number,
          source_branch: source_branch
        }, status: :created
      rescue => e
        render json: {
          error: "分岐作成に失敗しました: #{e.message}",
          status: 500
        }, status: :internal_server_error
      end

      # 分岐削除
      def delete_branch
        @game = Game.find(params[:game_id])
        branch_name = params[:branch_name]

        # main分岐は削除不可
        if branch_name == 'main'
          return render json: {
            error: "main分岐は削除できません",
            status: 400
          }, status: :bad_request
        end

        # 分岐の存在確認
        branch_histories = @game.board_histories.where(branch: branch_name)
        if branch_histories.empty?
          return render json: {
            error: "分岐が見つかりません",
            status: 404
          }, status: :not_found
        end

        deleted_histories = 0
        deleted_comments = 0

        ActiveRecord::Base.transaction do
          # 分岐に関連するコメントを削除
          branch_histories.each do |history|
            deleted_comments += history.comments.count
            history.comments.destroy_all
          end

          # 分岐の履歴を削除
          deleted_histories = branch_histories.count
          branch_histories.destroy_all
        end

        render json: {
          message: "分岐「#{branch_name}」を削除しました",
          deleted_histories: deleted_histories,
          deleted_comments: deleted_comments
        }
      rescue => e
        render json: {
          error: "分岐削除に失敗しました: #{e.message}",
          status: 500
        }, status: :internal_server_error
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

      # 自動分岐名生成
      def generate_branch_name(game)
        existing_branches = game.board_histories.pluck(:branch).uniq
        counter = 1
        
        loop do
          candidate = "branch-#{counter}"
          return candidate unless existing_branches.include?(candidate)
          counter += 1
        end
      end
    end
  end
end
