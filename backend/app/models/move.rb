class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

    class << self
        def process_move(game, board, parsed_data, move_info)
            ActiveRecord::Base.transaction do
                Board.create_next_board(parsed_data, move_info, board, game) 
            end
        rescue StandardError => e
            Rails.logger.error("Move processing failed: #{e.message}")
            raise
        end

        def  execute_move_or_drop(board_array, hand, side, move_info)
            case move_info[:type]
            when :move
                execute_move(board_array, hand, side, move_info)
            when :drop
                execute_drop(board_array, hand, side, move_info)
            else 
                raise ArgumentError, "Invalid move type: #{move_info[:type]}"
            end
        end

        def execute_move(board_array, hand, side, move_info)
            from_piece = board_array[move_info[:from_row]][move_info[:from_col]]
            to_piece = board_array[move_info[:to_row]][move_info[:to_col]]

            # 駒の捕獲
            Piece.capture_piece!(to_piece, hand, side) if to_piece

            # 移動元の駒を消去
            Piece.clear_source_square!(board_array, move_info)
            
            # 移動先に駒を配置
            Piece.place_piece!(board_array, from_piece, move_info)
        end
        
        def execute_drop(board_array, hand, side, move_info)
            piece_key = Piece.determine_piece_key(move_info[:piece], side)

            # 持ち駒を確認
            Piece.validate_hand!(hand, piece_key)

            # 持ち駒を減らす
            Piece.decrease_hand_piece!(hand, piece_key)

            # 盤面に駒を配置
            Piece.place_piece_on_board!(board_array, move_info[:to_row], move_info[:to_col], piece_key)
        end
    end
end