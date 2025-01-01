module Pieces
    class B 
        class << self
            def move?(move_info, board_array, _side)
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = (move_info[:to_row] - move_info[:from_row]).abs
                
                return false unless dx == dy
                
                # 途中に駒がないか確認
                x_direction = move_info[:to_col] > move_info[:from_col] ? 1 : -1
                y_direction = move_info[:to_row] > move_info[:from_row] ? 1 : -1
                
                current_x = move_info[:from_col] + x_direction
                current_y = move_info[:from_row] + y_direction
                
                while current_x != move_info[:to_col]
                    return false if board_array[current_y][current_x]
                    current_x += x_direction
                    current_y += y_direction
                end
                
                true
            end

            def promoted_move?(move_info, board_array, _side)
                # 角の動き
                return true if move?(move_info, board_array, _side)
        
                # 玉の動き（隣接1マス）
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = (move_info[:to_row] - move_info[:from_row]).abs
                dx <= 1 && dy <= 1
            end
        end
    end
end