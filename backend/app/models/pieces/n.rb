module Pieces
    class N
        class << self
            def move?(move_info, _board_array, side)
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = move_info[:to_row] - move_info[:from_row]
                
                dx == 1 && ((side == 'b' && dy == -2) || (side == 'w' && dy == 2))
            end

            def promoted_move?(move_info, _board_array, side)
                Pieces::G.move?(move_info, _board_array, side)
            end
        end
    end
end