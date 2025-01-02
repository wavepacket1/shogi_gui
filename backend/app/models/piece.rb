class Piece < ApplicationRecord
    class << self
        def promote_piece(piece)
            "+#{piece}"
        end
        
        def get_piece_class(piece_type)
            normalized_type = piece_type.gsub('+', '')

            "Pieces::#{normalized_type}".constantize
        end

        def fetch_piece(board_array, row, col)
            board_array[row][col]
        end

        def place_piece!(board_array, from_piece, move_info)
            piece = move_info[:promoted] ? Piece.promote_piece(from_piece) : from_piece
            board_array[move_info[:to_row]][move_info[:to_col]] = piece
        end

        def determine_piece_key(piece, side)
            side == 'b' ? piece.upcase : piece.downcase
        end

        def decrease_hand_piece!(hand, piece_key)
            hand[piece_key] -= 1
            hand.delete(piece_key) if hand[piece_key].zero?
        end

        def place_piece_on_board!(board_array, row, col, piece_key)
            board_array[row][col] = piece_key
        end

        def capture_piece!(to_piece, hand, side)
            captured_piece = to_piece.gsub(/^\+/, '') # 成り駒を基本形に戻す
            captured_piece = side == 'b' ? captured_piece.upcase : captured_piece.downcase # 駒を手駒として変換
            hand[captured_piece] ||= 0
            hand[captured_piece] += 1
        end

        def clear_source_square!(board_array, move_info)
            board_array[move_info[:from_row]][move_info[:from_col]] = nil
        end

        # 移動先に駒がないことを確認
        def drop_target_empty?(board_array, row, col)
            board_array[row][col].nil?
        end

        def valid_from_piece?(from_piece, side)
            return false if from_piece.nil?

            is_black_piece = from_piece.upcase == from_piece
            side == 'b' ? is_black_piece : !is_black_piece
        end

        def valid_to_piece?(to_piece, side)
            return true if to_piece.nil?

            is_to_black_piece = to_piece.upcase == to_piece
            side == 'b' ? !is_to_black_piece : is_to_black_piece
        end

        def validate_hand!(hand, piece_key)
            unless hand[piece_key]&.positive?
                raise StandardError, "持ち駒（#{piece_key}）がありません"
            end
        end
    end
end