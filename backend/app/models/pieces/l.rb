module Pieces
    class L
        class << self
            def move?(move_info, side, board_array)
                dx = move_info[:to_col] - move_info[:from_col]
                dy = move_info[:to_row] - move_info[:from_row]
                
                return false unless dx == 0
                direction = side == 'b' ? -1 : 1
                return false unless dy * direction > 0
                
                # 途中に駒がないか確認
                from_row = move_info[:from_row]
                to_row = move_info[:to_row]
                col = move_info[:from_col]
                
                range = from_row < to_row ? (from_row + 1...to_row) : (to_row + 1...from_row)
                range.none? { |row| board_array[row][col] }
            end
        end
    end
end