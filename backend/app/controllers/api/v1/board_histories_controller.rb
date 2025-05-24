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

      # 全分岐の履歴を取得
      def all_branches
        @game = Game.find(params[:game_id])
        @board_histories = @game.board_histories.order(:move_number, :branch)
        
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

        # 親分岐の深さを計算
        parent_depth = source_history.branch_tree_depth

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
              move_sfen: history.move_sfen,
              parent_branch: source_branch,
              branch_point: move_number,
              depth: parent_depth + 1
            )
          end
        end

        render json: {
          branch_name: branch_name,
          created_at: Time.current.iso8601,
          move_number: move_number,
          source_branch: source_branch,
          parent_branch: source_branch,
          branch_point: move_number,
          depth: parent_depth + 1
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

      # 分岐ツリー構造の取得
      def branch_tree
        @game = Game.find(params[:game_id])
        
        # 全分岐の基本情報を取得
        branches_data = @game.board_histories
                             .select(:branch, :parent_branch, :branch_point, :depth)
                             .distinct
                             .group_by(&:branch)
                             .transform_values(&:first)

        # ツリー構造を構築
        tree = build_branch_tree(branches_data)
        
        render json: {
          tree: tree,
          branches: branches_data.keys,
          total_branches: branches_data.size
        }
      end

      # 指定した手数での分岐情報を取得（+マーク表示用）
      def branches_at_move
        @game = Game.find(params[:game_id])
        move_number = params[:move_number].to_i
        
        # 指定手数に存在する全分岐を取得（全フィールドを取得）
        branches_at_move = @game.board_histories
                               .where(move_number: move_number)
                               .map do |history|
          {
            branch: history.branch,
            parent_branch: history.parent_branch,
            branch_point: history.branch_point,
            depth: history.depth || 0,
            notation: history.to_kifu_notation,
            is_main: history.is_main_branch?
          }
        end
        
        render json: {
          move_number: move_number,
          branches: branches_at_move,
          branch_count: branches_at_move.size,
          has_branches: branches_at_move.size > 1
        }
      end
      
      private
      
      def record_not_found
        render json: {
          error: "Game not found",
          status: 404
        }, status: :not_found
      end

      # 自動分岐名生成（仕様書に合わせてid-1形式に変更）
      def generate_branch_name(game)
        existing_branches = game.board_histories.pluck(:branch).uniq
        counter = 1
        
        loop do
          candidate = "id-#{counter}"
          return candidate unless existing_branches.include?(candidate)
          counter += 1
        end
      end

      # 分岐ツリー構造を構築
      def build_branch_tree(branches_data)
        # ルート分岐（main）から開始
        root = {
          branch: 'main',
          depth: 0,
          children: []
        }
        
        # 深さ順でソートして階層構造を構築
        sorted_branches = branches_data.values.sort_by { |b| b.depth || 0 }
        
        sorted_branches.each do |branch_data|
          next if branch_data.branch == 'main' # mainは既に追加済み
          
          branch_node = {
            branch: branch_data.branch,
            parent_branch: branch_data.parent_branch,
            branch_point: branch_data.branch_point,
            depth: branch_data.depth || 0,
            children: []
          }
          
          # 親分岐を見つけて子として追加
          if parent_node = find_branch_in_tree(root, branch_data.parent_branch)
            parent_node[:children] << branch_node
          else
            # 親が見つからない場合はルートに追加
            root[:children] << branch_node
          end
        end
        
        root
      end

      # ツリー内で指定した分岐を再帰的に検索
      def find_branch_in_tree(node, branch_name)
        return node if node[:branch] == branch_name
        
        node[:children].each do |child|
          if result = find_branch_in_tree(child, branch_name)
            return result
          end
        end
        
        nil
      end
    end
  end
end
