module Pieces
    class R 
        class << self
            def move?(move_info, board_array, _side)
                dx = move_info[:to_col] - move_info[:from_col]
                dy = move_info[:to_row] - move_info[:from_row]
                
                return false unless dx == 0 || dy == 0
                
                if dx == 0
                    range = dy > 0 ? (move_info[:from_row] + 1...move_info[:to_row]) : (move_info[:to_row] + 1...move_info[:from_row])
                    range.none? { |row| board_array[row][move_info[:from_col]] }
                else
                    range = dx > 0 ? (move_info[:from_col] + 1...move_info[:to_col]) : (move_info[:to_col] + 1...move_info[:from_col])
                        range.none? { |col| board_array[move_info[:from_row]][col] }
                    end
            end 

            def promoted_move?(move_info, board_array, _side)
                return true if move?(move_info, board_array, _side)
            
                # 玉の動き（隣接1マス）
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = (move_info[:to_row] - move_info[:from_row]).abs
                dx <= 1 && dy <= 1
            end
        end
    end
end