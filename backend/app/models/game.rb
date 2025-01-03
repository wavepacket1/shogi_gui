class Game < ApplicationRecord
  has_one :board, dependent: :destroy
  validates :status, presence: true, inclusion: { in: ['active', 'completed'] }

  def make_move(move_info)
    parsed_data = {
      board_array: @current_board,
      side: @current_side,
      hands: @hands,
      move_history: @move_history
    }

    if Validator.legal?(parsed_data, move_info)
      # 手を実行
      execute_move(move_info)
      
      # 局面を記録
      Validator.record_position(@current_board, @hands, @current_side, @move_history)
      
      # 入玉の判定
      if Validator.entering_king_rule?(@current_board, @current_side)
        @game_state = :entering_king_achieved
      end
      
      true
    else
      false
    end
  end
end