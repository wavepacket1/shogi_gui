module Shogi
    module Pieces
        class BasePiece
            attr_reader :movement,:can_jump

            def initialize(movement,can_jump: false)
                @movement = movement
                @can_jump = can_jump
            end

            def validate_movement(board,present_position,next_position,move_direction)
                @movement.each do |move|
                    return true if knight_move?(move)

                    max_steps = calculate_max_steps(move)
                    next unless next_position?(present_position,next_position,move,max_steps,move_direction)

                    unit_move = calculate_unit_move(move,max_steps)
                    check_for_intermediate_pieces(board, present_position, unit_move, max_steps, move_direction)
                    
                    return true
                end 
                raise "エラー!駒が動ける範囲外です"
            end

            # 駒が動けるかを検証する
            def can_move_validate(board,next_position,move_direction)
                @movement.any? do |move|
                    next_position_board_include?(next_position,move,move_direction)
                end
            end

            private 
            def calculate_unit_move(move,max_steps)
                move.map { |i| i/ max_steps }
            end

            def calculate_max_steps(move)
                [move[0].abs,move[1].abs].max
            end

            def next_position_board_include?(next_position,move,move_direction)
                target_row = next_position[0] + move_direction * move[1]
                target_col = next_position[1] - move_direction * move[0]
                (0..8).include?(target_row) && (0..8).include?(target_col)
            end

            def knight_move?(move)
                move == [1,2] || move == [-1,2]
            end

            def next_position?(present_position,next_position,move,max_steps,move_direction)
                target_row = present_position[0] + move_direction * move[1]
                target_col = present_position[1] - move_direction * move[0]
                target_row == next_position[0] && target_col == next_position[1]
            end

            def intermediate_piece?(board,present_position,unit_move,step,move_direction)
                intermediate_row = present_position[0] + move_direction * (unit_move[1] * step)
                intermediate_col = present_position[1] - move_direction * (unit_move[0] * step)
                board[intermediate_row][intermediate_col]
            end

            def check_for_intermediate_pieces(board, present_position, unit_move, max_steps, move_direction)
                (1...max_steps).each do |step|
                    if intermediate_piece?(board, present_position, unit_move, step, move_direction)
                        raise "エラー！動かそうとしている位置の間に駒があります"
                    end
                end
            end
        end
    end
end