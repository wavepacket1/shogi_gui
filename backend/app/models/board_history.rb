class BoardHistory < ApplicationRecord
    belongs_to :game
  
    validates :sfen, presence: true
    validates :move_number, presence: true, uniqueness: { scope: [:game_id, :branch] }
    validates :branch, presence: true
  
    scope :ordered, -> { order(move_number: :asc) }
    scope :main_branch, -> { where(branch: 'main') }
  
    # 前の局面を取得
    def previous_board_history
      return nil if move_number <= 0
      game.board_histories.where(branch:)
                        .find_by(move_number: move_number - 1)
    end
    
    # 次の局面を取得
    def next_board_history
      game.board_histories.where(branch: branch)
                        .where('move_number > ?', move_number)
                        .order(move_number: :asc).first
    end
  
    # 最初の局面を取得
    def first_board_history
      game.board_histories.where(branch: branch).ordered.first
    end
  
    # 最後の局面を取得
    def last_board_history
      game.board_histories.where(branch: branch).ordered.last
    end
  
    # 棋譜形式で手を表示 (move_sfenを使用)
    def to_kifu_notation
      # 開始局面の場合
      return "開始局面" if move_number == 0

      # 通常の手の場合
      begin
        # この履歴が最後の手で、かつゲームが終了している場合
        game = self.game
        if game.status == 'finished' && game.ended_at && game.winner &&
           self == game.board_histories.where(branch: branch).ordered.last
          return "投了"
        end

        # 前の局面の情報を取得
        prev_history = previous_board_history
        return "#{move_number}手目" unless prev_history
        
        # プレイヤー記号（先手・後手）
        player_position = Parser::SfenParser.parse(prev_history.sfen)
        player_type = player_position[:side]  # 前の局面の手番が現在の指し手の手番
        player_symbol = player_type == 'b' ? '▲' : '△'
        
        # 通常の手の場合の処理
        if move_sfen
          # move_sfenを解析
          to_square, piece_type, is_drop, is_promotion = parse_move_sfen(move_sfen)
          
          # 表示用に変換
          position_str = format_position(to_square)
          piece_name = piece_to_japanese(piece_type)
          
          # 駒打ちと成りの表記
          special_notation = ""
          special_notation += "打" if is_drop
          special_notation += "成" if is_promotion
          
          # 棋譜表記
          "#{player_symbol}#{position_str}#{piece_name}#{special_notation}"
        else
          "#{move_number}手目"
        end
      rescue => e
        Rails.logger.error "棋譜表記の計算でエラー: #{e.message}"
        "#{move_number}手目"
      end
    end
    
    # SFEN/USI形式の指し手を解析 (例: 7g7f, P*3d, 8h2b+)
    def parse_move_sfen(sfen_move)
      if sfen_move.include?('*')
        # 駒打ちの場合
        piece_type, to_square = sfen_move.split('*')
        return [to_square, piece_type, true, false]
      else
        # 通常の移動
        is_promotion = sfen_move.end_with?('+')
        sfen_move = sfen_move.chomp('+') if is_promotion
        
        from_square = sfen_move[0..1]
        to_square = sfen_move[2..3]
        
        # 移動する駒の種類を特定するには元の局面情報が必要
        prev_history = previous_board_history
        return [to_square, nil, false, is_promotion] unless prev_history
        
        prev_position = Parser::SfenParser.parse(prev_history.sfen)
        piece_type = find_piece_at(prev_position, from_square)
        
        return [to_square, piece_type, false, is_promotion]
      end
    end
    
    # 指定した座標にある駒の種類を取得
    def find_piece_at(position, square)
      file = square[0].to_i
      col = 9 - file
      step_map = ('a'..'i').to_a.zip(0..8).to_h
      row = step_map[square[1]]
      
      return nil unless position[:board_array][row] && position[:board_array][row][col]
      
      piece = position[:board_array][row][col]
      piece == ' ' ? nil : piece
    end
  
    private

    # 駒打ちかどうかを判定（シンプルな実装）
    def is_drop_move?(current_position, previous_position, player_side)
      player_key = player_side == 'b' ? :black : :white
      
      return false unless previous_position[:hands] && current_position[:hands] &&
                          previous_position[:hands][player_key] && current_position[:hands][player_key]
      
      # 持ち駒が減っていれば駒打ち
      previous_hand = previous_position[:hands][player_key]
      current_hand = current_position[:hands][player_key]
      
      previous_hand.any? { |piece, count| (current_hand[piece] || 0) < count }
    end
    
    # 座標を漢数字表記に変換
    def format_position(position)
      return "不明" unless position
      file = position[0]
      rank = position[1]
      "#{file}#{japanese_number(rank)}"
    end
    
    # 数字を漢数字に変換
    def japanese_number(num)
      case num.to_s
      when "a" then "一"
      when "b" then "二"
      when "c" then "三"
      when "d" then "四"
      when "e" then "五"
      when "f" then "六"
      when "g" then "七"
      when "h" then "八"
      when "i" then "九"
      else num.to_s
      end
    end
    
    # 駒の英語表記から日本語表記への変換
    def piece_to_japanese(piece_type)
      return "駒" unless piece_type
      
      case piece_type.upcase
      when "P" then "歩"
      when "L" then "香"
      when "N" then "桂"
      when "S" then "銀"
      when "G" then "金"
      when "B" then "角"
      when "R" then "飛"
      when "K" then "玉"
      when "+P" then "と"
      when "+L" then "成香"
      when "+N" then "成桂"
      when "+S" then "成銀"
      when "+B" then "馬"
      when "+R" then "龍"
      else piece_type
      end
    end

    has_many :comments, dependent: :destroy
  end