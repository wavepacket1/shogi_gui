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
  
    # 棋譜形式で手を表示 (新実装 - move_sfenを使用)
    def to_kifu_notation
      # 開始局面の場合
      return "開始局面" if move_number == 0
      
      # move_sfenがない場合は旧メソッドにフォールバック
      return legacy_to_kifu_notation unless move_sfen.present?
      
      begin
        # プレイヤー記号（先手・後手）
        prev_history = previous_board_history
        return "#{move_number}手目" unless prev_history
        
        player_position = Parser::SfenParser.parse(prev_history.sfen)
        player_type = player_position[:side]  # 前の局面の手番が現在の指し手の手番
        player_symbol = player_type == 'b' ? '▲' : '△'
        
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
      rank = square[1].to_i
      
      # SFEN座標をボード配列の座標に変換
      col = 9 - file
      row = rank - 1
      
      return nil unless position[:board][row] && position[:board][row][col]
      
      piece = position[:board][row][col]
      piece == ' ' ? nil : piece
    end
    
    # 旧実装（後方互換性のため残す）
    def legacy_to_kifu_notation
      # 開始局面の場合
      return "開始局面" if move_number == 0
      # 前の局面が見つからない場合
      prev_history = previous_board_history
      return "#{move_number}手目" unless prev_history
      
      begin
        # 現在と前の局面を解析
        current_position = Parser::SfenParser.parse(sfen)        # 現在の局面
        previous_position = Parser::SfenParser.parse(prev_history.sfen)  # 前の局面
        
        # プレイヤー記号（先手・後手）
        player_type = previous_position[:side]  # 前の局面の手番が現在の指し手の手番
        player_symbol = player_type == 'b' ? '▲' : '△'
        
        # 局面の変化を検出して、移動先と駒種を抽出
        # （この部分は必要に応じて最小限の実装に）
        to_square, piece_type, is_drop, is_promoted = extract_move_info(current_position, previous_position)
        
        # 分かりやすく日本語表記に変換
        position_str = format_position(to_square)
        piece_name = piece_to_japanese(piece_type)
        
        # 駒打ちと成りの表記
        special_notation = ""
        special_notation += "打" if is_drop
        special_notation += "成" if is_promoted
        
        # 棋譜表記
        "#{player_symbol}#{position_str}#{piece_name}#{special_notation}"
      rescue => e
        Rails.logger.error "棋譜表記の計算でエラー: #{e.message}"
        "取得エラー"
      end
    end
  
    private
  
    # 指し手情報を簡易的に抽出（最小限の実装）
    def extract_move_info(current_position, previous_position)
      player_side = previous_position[:side]
      
      # 駒打ちの判定（持ち駒が減っていれば駒打ち）
      if is_drop_move?(current_position, previous_position, player_side)
        # 駒打ちの情報抽出
        to_square, piece_type = extract_drop_info(current_position, previous_position, player_side)
        return [to_square, piece_type, true, false]
      else
        # 通常の駒移動
        to_square, from_square, piece_type, is_promoted = extract_normal_move(current_position, previous_position, player_side)
        return [to_square, piece_type, false, is_promoted]
      end
    end
    
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
    
    # 駒打ちの情報を抽出（シンプルな実装）
    def extract_drop_info(current_position, previous_position, player_side)
      player_key = player_side == 'b' ? :black : :white
      previous_hand = previous_position[:hands][player_key]
      current_hand = current_position[:hands][player_key]
      
      # 減った持ち駒を特定
      dropped_piece = nil
      previous_hand.each do |piece, count|
        next unless (current_hand[piece] || 0) < count
        dropped_piece = piece.upcase
        break
      end
      
      # 打った場所を特定（新しく駒が置かれた場所）
      to_square = nil
      9.times do |row|
        9.times do |col|
          next unless current_position[:board][row] && previous_position[:board][row]
          next unless current_position[:board][row][col] && previous_position[:board][row][col]
          
          # 空だったマスに駒が置かれた場所を探す
          if previous_position[:board][row][col] == ' ' && 
             current_position[:board][row][col] != ' ' &&
             belongs_to_side?(current_position[:board][row][col], player_side)
            to_square = convert_to_notation(row, col)
            break
          end
        end
        break if to_square
      end
      
      [to_square, dropped_piece]
    end
    
    # 通常の駒移動情報を抽出（シンプルな実装）
    def extract_normal_move(current_position, previous_position, player_side)
      # 移動先（空白だったところに駒が出現）
      to_square = nil
      to_piece = nil
      from_square = nil
      from_piece = nil
      is_promoted = false
      
      # 盤面の差分を検出
      board_diff = {}
      9.times do |row|
        9.times do |col|
          next unless current_position[:board][row] && previous_position[:board][row]
          next unless current_position[:board][row][col] && previous_position[:board][row][col]
          
          current_square = current_position[:board][row][col]
          previous_square = previous_position[:board][row][col]
          
          if current_square != previous_square
            notation = convert_to_notation(row, col)
            board_diff[notation] = { previous: previous_square, current: current_square }
          end
        end
      end
      
      # 移動先を特定
      board_diff.each do |notation, diff|
        if diff[:previous] == ' ' && belongs_to_side?(diff[:current], player_side)
          to_square = notation
          to_piece = diff[:current]
          break
        end
      end
      
      # 移動元を特定
      board_diff.each do |notation, diff|
        next if notation == to_square
        if diff[:previous] != ' ' && belongs_to_side?(diff[:previous], player_side) && diff[:current] == ' '
          from_square = notation
          from_piece = diff[:previous]
          break
        end
      end
      
      # 成りの判定
      if from_piece && to_piece
        is_promoted = from_piece.upcase == to_piece.upcase.gsub(/\+/, '') && to_piece.start_with?('+')
      end
      
      [to_square, from_square, from_piece, is_promoted]
    end
    
    # 内部座標から棋譜表記に変換
    def convert_to_notation(row, col)
      file = 9 - col
      rank = row + 1
      "#{file}#{rank}"
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
      when "1" then "一"
      when "2" then "二"
      when "3" then "三"
      when "4" then "四"
      when "5" then "五"
      when "6" then "六"
      when "7" then "七"
      when "8" then "八"
      when "9" then "九"
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
    
    # 駒が特定の手番のものかを判定
    def belongs_to_side?(piece, side)
      return false unless piece && piece != ' '
      is_upper = piece.upcase == piece
      (side == 'b' && is_upper) || (side == 'w' && !is_upper)
    end
  end