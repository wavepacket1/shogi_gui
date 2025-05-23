module Pieces
    class K 
        class << self
            def move?(move_info, _board_array, _side)
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = (move_info[:to_row] - move_info[:from_row]).abs
                
                dx <= 1 && dy <= 1
            end
        end
    end
end