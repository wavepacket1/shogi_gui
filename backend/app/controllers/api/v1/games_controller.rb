# frozen_string_literal: true

module Api
  module V1
    class GamesController < ApplicationController
      before_action :set_game, only: [:resign, :mode]

      def create
        Rails.logger.info "ゲーム作成開始: params=#{params.inspect}"
        Rails.logger.info "game_params: #{game_params.inspect}"
        
        @game = Game.new(game_params)
        Rails.logger.info "ゲームオブジェクト作成: #{@game.inspect}"

        @game.errors.add(:status, "can't be blank") if game_params[:status].blank?
        Rails.logger.info "バリデーション後のエラー: #{@game.errors.full_messages}"
        
        if @game.errors.empty? && @game.save
          Rails.logger.info "ゲーム保存成功: id=#{@game.id}"
          @board = @game.create_board!(sfen: Board.default_sfen)
          Rails.logger.info "ボード作成成功: id=#{@board.id}"
          
          # 0手目（開始局面）の履歴を作成
          @game.board_histories.create!(
            sfen: @board.sfen,
            move_number: 0,
            branch: 'main'
          )
          Rails.logger.info "初期履歴作成成功"
          
          render json: {
            game_id: @game.id,
            status: @game.status,
            board_id: @board.id
          }, status: :created
        else
          Rails.logger.error "ゲーム作成失敗: #{@game.errors.full_messages}"
          render json: {
            error: @game.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "RecordInvalid: #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error "ゲーム作成エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "ゲーム作成中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
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

      def resign
        @game = Game.includes(:board).find(params[:id])
        
        if @game.board.nil?
          render json: { 
            status: 'error', 
            message: 'ゲームの盤面が見つかりません' 
          }, status: :unprocessable_entity
          return
        end
        
        # 現在のアクティブプレイヤーが投了したとして処理
        winning_player = @game.board.sfen.split(' ')[1] == 'b' ? 'white' : 'black'
        
        ActiveRecord::Base.transaction do
          @game.update!(
            status: 'finished',
            winner: winning_player,
            ended_at: Time.current
          )
          
          # 投了の手を履歴に追加
          last_history = @game.board_histories.where(branch: 'main').ordered.last
          next_move_number = last_history ? last_history.move_number + 1 : 1
          
          @game.board_histories.create!(
            sfen: @game.board.sfen,  # 最後の局面のsfenを使用
            move_number: next_move_number,
            branch: 'main'  # 投了は常にメインブランチに記録
          )
        end
        
        render json: {
          status: 'success',
          message: '投了が完了しました',
          game_status: 'finished',
          winner: winning_player,
          ended_at: @game.ended_at.iso8601
        }
      rescue ActiveRecord::RecordNotFound => e
        render json: { 
          status: 'error', 
          message: 'ゲームが見つかりません' 
        }, status: :not_found
      rescue => e
        render json: { 
          status: 'error', 
          message: 'システムエラーが発生しました' 
        }, status: :internal_server_error
      end

      def mode
        if params[:mode].blank?
          render json: { error: 'モードが指定されていません' }, status: :bad_request
          return
        end

        unless ['play', 'edit', 'study'].include?(params[:mode])
          render json: { error: '無効なモードです' }, status: :bad_request
          return
        end

        if @game.update(mode: params[:mode])
          render json: {
            game_id: @game.id,
            mode: @game.mode,
            status: @game.status,
            updated_at: @game.updated_at
          }
        else
          render json: { error: @game.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'ゲームが見つかりません' }, status: :not_found
      end

      private

      def set_game
        @game = Game.find(params[:id])
      end

      def game_params
        params.require(:game).permit(:status, :mode)
      end
    end
  end
end
