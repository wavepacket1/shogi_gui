require_relative 'pieces'
require_relative 'validation'
require 'byebug'
require 'yaml' 

# YAMLファイルの読み込み
CONFIG = YAML.load_file(File.join(__dir__,'config/constants.yml'))

#定数の定義
HAND_INDEX_FIRST = CONFIG['HAND_INDEX_FIRST']
HAND_INDEX_SECOND = CONFIG['HAND_INDEX_SECOND']

# 持ち駒キーと対応する手駒インデックスのマッピング
PLAYER_HAND_INDEX = CONFIG['PLAYER_HAND_INDEX']
RELEASION_PIECE_AND_PROMOTION_PIECE = CONFIG['RELEASION_PIECE_AND_PROMOTION_PIECE'].freeze

module Shogi
    class Board
        attr_reader :board
        def initialize
            @board = initial_board
            @turn = true # 先手番ならtrue, 後手番ならfalse
        end

        # 初期ボードの配置
        def initial_board
            [
                ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                [], # 先手の持ち駒
                []  # 後手の持ち駒
            ]
        end

        # 手を実行するメソッド
        def move(move_protocol)
            Validation::validate_turn(move_protocol,@turn)
            move_direction = turn_value(@turn)

            if move_protocol.start_with?("H")
                strike_piece(move_protocol, move_direction)
            else
                present_position, next_position = parse_positions(move_protocol)
                if promotion_move?(move_protocol)
                    handle_promotion_move(move_protocol, present_position, next_position, move_direction)
                else
                    handle_normal_move(move_protocol, present_position, next_position, move_direction)
                end
            end
            switch_turn
        end

        # ボードを表示するメソッド
        def display
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        # ボードを初期状態にリセットするメソッド
        def reset
            @board = initial_board
        end

        private

        # 通常の移動を処理するメソッド（成り無し）
        def handle_normal_move(move_protocol, present_position, next_position, move_direction)
            piece = extract_piece(move_protocol)

            if Validation::valid_move?(@board,piece, present_position, next_position, move_direction)
                move_piece(present_position, next_position, piece, piece)
            end
        end

        # 成りの移動を処理するメソッド
        def handle_promotion_move(move_protocol, present_position, next_position, move_direction)
            before_piece = move_protocol[-2]
            promote_piece = move_protocol[-1]

            if Validation::promotion_piece?(promote_piece)
                raise "成れません" unless Validation::promotion_validation(next_position,@turn)
            end

            if Validation::valid_move?(@board,before_piece, present_position, next_position, move_direction)
                move_piece(present_position, next_position, before_piece, promote_piece)
            end
        end

        # 駒を移動させるメソッド
        def move_piece(present_position, next_position, before_piece, after_piece)
            take_piece(present_position, next_position, @turn, before_piece)
            @board[present_position[0]][present_position[1]] = nil
            @board[next_position[0]][next_position[1]] = after_piece
        end

        # 駒を取る処理
        def take_piece(present_position, next_position, turn, piece)
            captured_piece = @board[next_position[0]][next_position[1]]
            return unless captured_piece

            if own_piece?(captured_piece, turn)
                raise "移動先に自分の駒があります"
            end

            add_to_hand(captured_piece, turn)
        end

        # 持ち駒から駒を打つ処理
        def strike_piece(move_protocol, move_direction)
            next_position = parse_next_position(move_protocol)
            piece = extract_piece(move_protocol)

            unless Validation::strike_piece_validation(piece, next_position, move_direction,@board,@turn)
                return
            end

            place_piece_on_board(piece, next_position)
            remove_piece_from_hand(move_protocol, piece)
        end

        # 捕獲した駒を持ち駒に追加するメソッド
        def add_to_hand(piece, turn)
            hand_index = turn ? HAND_INDEX_FIRST : HAND_INDEX_SECOND
            transformed_piece = transform_piece(piece, turn)
            @board[hand_index].push(transformed_piece)
        end

        # 駒を成りおよび持ち駒の所有者に応じて変換するメソッド
        def transform_piece(piece, turn)
            base_piece = Validation::promotion_piece?(piece) ? RELEASION_PIECE_AND_PROMOTION_PIECE[piece] : piece
            turn ? base_piece.upcase : base_piece.downcase
        end

        # 指定された駒が自分の駒かどうかを判定するメソッド
        def own_piece?(piece, turn)
            turn ? (piece =~ /[A-Z]/) : (piece =~ /[a-z]/)
        end

        # move_protocolから駒を抽出するメソッド
        def extract_piece(move_protocol)
            move_protocol[-1].to_s
        end

        # 持ち駒から駒を削除するメソッド
        def remove_piece_from_hand(move_protocol, piece)
            hand_key = move_protocol[0..1]
            hand_index = PLAYER_HAND_INDEX[hand_key]

            unless hand_index
                raise "不正な持ち駒キー: #{hand_key}"
            end

            hand = @board[hand_index]
            piece_index = hand.index(piece)
            unless piece_index
                raise "持ち駒に指定された駒が存在しません: #{piece}"
            end

            hand.delete_at(piece_index)
        end

        # move_protocolから次の位置を解析するメソッド
        def parse_next_position(move_protocol)
            row = move_protocol[3].to_i - 1
            col = 9 - move_protocol[2].to_i
            [row, col]
        end

        # move_protocolから現在位置と次位置を解析するメソッド
        def parse_positions(move_protocol)
            present_position = [move_protocol[1].to_i - 1, 9 - move_protocol[0].to_i]
            next_position = parse_next_position(move_protocol)
            [present_position, next_position]
        end

        # ターンに応じた移動方向を決定するメソッド
        def turn_value(turn)
            turn ? -1 : 1
        end

        # move_protocolが成りの動きかどうかを判定するメソッド
        def promotion_move?(move_protocol)
            move_protocol.length == 6
        end

        # ターンを切り替えるメソッド
        def switch_turn
            @turn = !@turn
        end

        # ボード上に駒を配置するメソッド
        def place_piece_on_board(piece, position)
            @board[position[0]][position[1]] = piece
        end
    end
end
