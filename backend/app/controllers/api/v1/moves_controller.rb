class Api::V1::MovesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def move
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
    
    # 分岐情報の取得
    current_move_number = params[:move_number].to_i
    branch = params[:branch] || 'main'
    
    parsed_data = Parser::SfenParser.parse(@board.sfen)
    move_info = Board.parse_move(params[:move])

    # 合法手でない場合はDBに保存しない
    return unless Validator.legal?(parsed_data, move_info, @game)

    # 既存のコード: 次の局面を作成
    next_board = Move.process_move(@game, @board, parsed_data, move_info)
    
    # 分岐処理: 同じ手数で異なる手を指した場合は新しい分岐を作成
    if current_move_number > 0 && @game.board_histories.exists?(move_number: current_move_number)
      next_move_number = current_move_number + 1
      
      # 既存の分岐と手数が同じ場合、新しい分岐名を生成
      if @game.board_histories.exists?(move_number: next_move_number, branch: branch)
        # 既存の分岐をベースに新しい分岐名を生成
        existing_branches = @game.board_histories.where('branch LIKE ?', "#{branch}_%").pluck(:branch)
        max_branch_number = existing_branches.map { |b| b.split('_').last.to_i }.max || 0
        branch = "#{branch}_#{max_branch_number + 1}"
      end
    else
      # 通常の手順（分岐なし）
      next_move_number = parsed_data[:move_number] + 1
    end
    
    # 局面の履歴を保存（move_sfenを追加）
    @history = @game.board_histories.create!(
      sfen: next_board.sfen,
      move_number: next_move_number,
      branch: branch,
      move_sfen: params[:move]  # 指し手情報をSFEN形式で保存
    )
    
    # レスポンスに履歴情報を追加
    render_success(next_board, @game, @history)
  rescue StandardError => e
    render_error(e)
  end

  private

  def render_success(next_board, game, history)
    next_board_array = Parser::SfenParser.parse(next_board.sfen)[:board_array]
    next_board_hands = Parser::SfenParser.parse(next_board.sfen)[:hand]
    next_side = Parser::SfenParser.parse(next_board.sfen)[:side]

    render json: {
      status: true,
      is_checkmate: Validator.is_checkmate?(next_board_array, next_board_hands, next_side),
      is_repetition: Validator.repetition?(next_board.sfen, game),
      is_repetition_check: Validator.repetition_check?(next_board_array, next_side, game),
      board_id: next_board.id,
      sfen: next_board.sfen,
      move_number: history.move_number,
      branch: history.branch,
      move_sfen: history.move_sfen,  # レスポンスにも指し手情報を含める
      notation: history.to_kifu_notation  # 棋譜表記も含める
    }, status: :ok
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
