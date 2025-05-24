class Api::V1::MovesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def move
    Rails.logger.info "🚨 MovesController#move メソッド開始 - パラメータ: #{params.inspect}"
    
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
    
    # 分岐情報の取得
    current_move_number = params[:move_number].to_i || 0
    branch = params[:branch] || 'main'
    
    Rails.logger.info "🎮 指し手受信: #{params[:move]} (ゲームID: #{@game.id}, 手数: #{current_move_number}, 分岐: #{branch})"
    
    parsed_data = Parser::SfenParser.parse(@board.sfen)
    move_info = Board.parse_move(params[:move])

    # 合法手でない場合はDBに保存しない
    return unless Validator.legal?(parsed_data, move_info, @game)

    # 既存のコード: 次の局面を作成
    next_board = Move.process_move(@game, @board, parsed_data, move_info)
    
    # 現在の局面から次の手数を算出
    current_board_history = @game.board_histories.find_by(sfen: @board.sfen, branch: branch)
    if current_board_history
      current_move_number = current_board_history.move_number
      Rails.logger.debug "現在の局面発見: 手数#{current_move_number}"
    else
      # 現在の局面が見つからない場合は、最新の手数から推測
      last_history = @game.board_histories.where(branch: branch).order(move_number: :desc).first
      current_move_number = last_history ? last_history.move_number : 0
      Rails.logger.debug "現在の局面未発見、推測手数: #{current_move_number}"
    end
    
    next_move_number = current_move_number + 1
    Rails.logger.debug "次の手数: #{next_move_number}"
    
    # 同じ手数で既に手が存在するかチェック（分岐が必要かどうか）
    existing_histories = @game.board_histories.where(move_number: next_move_number)
    needs_branch = false
    
    Rails.logger.debug "手数#{next_move_number}の既存履歴数: #{existing_histories.count}"
    
    if existing_histories.exists?
      # 同じ手数で異なる手が存在する場合は分岐作成
      existing_move = existing_histories.where(branch: branch).first
      if existing_move.nil?
        Rails.logger.info "⚡ 分岐必要: 手数#{next_move_number}に分岐#{branch}の履歴がない"
        needs_branch = true
      elsif existing_move.move_sfen != params[:move]
        Rails.logger.info "⚡ 分岐必要: 手数#{next_move_number}に異なる手が存在 (既存: #{existing_move.move_sfen}, 新: #{params[:move]})"
        needs_branch = true
      else
        # 全く同じ手が既に存在する場合は何もしない
        Rails.logger.info "❌ 同じ手が既に存在: #{params[:move]}"
        return render json: {
          status: false,
          message: '同じ手が既に存在します',
          board_id: @board.id,
          sfen: @board.sfen
        }, status: :unprocessable_entity
      end
    end
    
    # 分岐が必要な場合は新しい分岐を作成
    if needs_branch
      branch_counter = 1
      original_branch = branch
      new_branch = "#{original_branch}-#{branch_counter}"
      
      # 既存分岐名との重複を避ける
      while @game.board_histories.where(branch: new_branch).exists?
        branch_counter += 1
        new_branch = "#{original_branch}-#{branch_counter}"
      end
      
      Rails.logger.info "🌟 自動分岐作成開始: #{original_branch} → #{new_branch} (手数 #{next_move_number})"
      
      # 新しい分岐に現在の局面までコピー
      histories_to_copy = @game.board_histories
                             .where(branch: original_branch)
                             .where('move_number <= ?', current_move_number)
                             .order(:move_number)
      
      Rails.logger.info "📋 コピー対象履歴数: #{histories_to_copy.count} (手数 0-#{current_move_number})"
      
      histories_to_copy.each do |history|
        new_history = @game.board_histories.create!(
          sfen: history.sfen,
          move_number: history.move_number,
          branch: new_branch,
          move_sfen: history.move_sfen
        )
        Rails.logger.debug "  ✅ 履歴コピー: 手数#{history.move_number} → 分岐#{new_branch}"
      end
      
      branch = new_branch
      Rails.logger.info "🎯 自動分岐作成完了: #{branch} - 指し手: #{params[:move]}"
    else
      Rails.logger.info "📝 通常手順: 分岐#{branch} 手数#{next_move_number} - 指し手: #{params[:move]}"
    end
    
    # 局面の履歴を保存（move_sfenを追加）
    @history = @game.board_histories.create!(
      sfen: next_board.sfen,
      move_number: next_move_number,
      branch: branch,
      move_sfen: params[:move]  # 指し手情報をSFEN形式で保存
    )
    
    Rails.logger.info "💾 履歴保存完了: 手数#{@history.move_number}, 分岐#{@history.branch}"
    
    # レスポンスに履歴情報を追加
    render_success(next_board, @game, @history)
  rescue StandardError => e
    Rails.logger.error "❌ 指し手処理エラー: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    render_error(e)
  end

  private

  def render_success(next_board, game, history)
    next_board_array = Parser::SfenParser.parse(next_board.sfen)[:board_array]
    next_board_hands = Parser::SfenParser.parse(next_board.sfen)[:hand]
    next_side = Parser::SfenParser.parse(next_board.sfen)[:side]

    # 棋譜表記を安全に取得
    notation = begin
      history.to_kifu_notation
    rescue => e
      Rails.logger.error "棋譜表記取得エラー: #{e.message}"
      "#{history.move_number}手目"
    end

    Rails.logger.info "📤 API応答データ: move_number=#{history.move_number}, branch=#{history.branch}, move_sfen=#{history.move_sfen}, notation=#{notation}"

    response_data = {
      status: true,
      is_checkmate: Validator.is_checkmate?(next_board_array, next_board_hands, next_side),
      is_repetition: Validator.repetition?(next_board.sfen, game),
      is_repetition_check: Validator.repetition_check?(next_board_array, next_side, game),
      board_id: next_board.id,
      sfen: next_board.sfen,
      move_number: history.move_number,
      branch: history.branch,
      move_sfen: history.move_sfen,
      notation: notation
    }

    Rails.logger.info "📤 完全なAPI応答: #{response_data.to_json}"

    render json: response_data, status: :ok
  end

  def render_error(error)
    render json: {
      status: false,
      message: error.message,
      board_id: @board.id,
      sfen: @board.sfen
    }, status: :unprocessable_entity
  end

  def record_not_found
    render json: {
      status: false,
      message: 'ゲームまたは盤面が見つかりません。'
    }, status: :not_found
  end
end
