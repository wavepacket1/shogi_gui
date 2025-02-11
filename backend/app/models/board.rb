class Board < ApplicationRecord
    has_many :pieces, dependent: :destroy
    belongs_to :game

    class << self 
        def convert_move_to_indices(board_array, move)
            step_map = ('a'..'i').to_a.zip(0..8).to_h
            from_line = 9 - move[0].to_i
            from_step = step_map[move[1]]
            to_line = 9 - move[2].to_i
            to_step = step_map[move[3]]
            [from_line, from_step, to_line, to_step]
        end
    
        def parse_move(move)
            if move.include?('*')
                piece, rest = move.split('*')
                to_row, to_col = convert_square_to_indices(rest)
                { type: :drop, piece: piece, to_row: to_row, to_col: to_col }
            else
                promoted = move.end_with?('+')
                move_str = promoted ? move[0..-2] : move
                from_square = move_str[0..1]
                to_square = move_str[2..3]
    
                from_row, from_col = convert_square_to_indices(from_square)
                to_row, to_col = convert_square_to_indices(to_square)
    
                { type: :move, from_row: from_row, from_col: from_col, to_row: to_row, to_col: to_col, promoted: promoted }
            end
        end
    
        def create_next_board(parsed_data, move_info, board, game)
            board_array, hand, side, move_number = parsed_data.values_at(:board_array, :hand, :side, :move_number)
    
            Move.execute_move_or_drop(board_array, hand, side, move_info)
    
            next_side, next_move_number = update_game_state(side, move_number)
        
            create_board_record(board_array, hand, next_side, next_move_number, game)
        end

        def default_sfen
            "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0"
        end

    
        private
    
        def create_board_record(board_array, hand, side, move_number, game)
            new_sfen = Parser::SfenParser.array_to_sfen(board_array, side, hand, move_number)
            create!(game_id: game.id, sfen: new_sfen)
        end
    
        def update_game_state(side, move_number)
            next_side = (side == 'b' ? 'w' : 'b')
            next_move_number = move_number + 1
            [next_side, next_move_number]
        end
    
        def convert_square_to_indices(sq)
            row_map = ('a'..'i').to_a.zip(0..8).to_h
            row = row_map[sq[1]]
            col = 9 - sq[0].to_i
            [row, col]
        end
    end
end
