#既存のBoardとPieceを削除
Board.destroy_all
Piece.destroy_all

# シーケンスのリセット
ActiveRecord::Base.connection.reset_pk_sequence!('boards')
ActiveRecord::Base.connection.reset_pk_sequence!('pieces')

# 将棋盤を作成
board = Board.create(name: "初期盤面", active_player: 'b')

# 後手（gote）の駒配置（y=1からy=3）
gote_pieces = [
    # y=0
    { position_x: 0, position_y: 0, piece_type: 'l', promoted: false, owner: 'w' }, 
    { position_x: 1, position_y: 0, piece_type: 'n', promoted: false, owner: 'w' }, 
    { position_x: 2, position_y: 0, piece_type: 's', promoted: false, owner: 'w' }, 
    { position_x: 3, position_y: 0, piece_type: 'g', promoted: false, owner: 'w' }, 
    { position_x: 4, position_y: 0, piece_type: 'k', promoted: false, owner: 'w' }, 
    { position_x: 5, position_y: 0, piece_type: 'g', promoted: false, owner: 'w' }, 
    { position_x: 6, position_y: 0, piece_type: 's', promoted: false, owner: 'w' }, 
    { position_x: 7, position_y: 0, piece_type: 'n', promoted: false, owner: 'w' }, 
    { position_x: 8, position_y: 0, piece_type: 'l', promoted: false, owner: 'w' }, 

    # y=1
    { position_x: 1, position_y: 1, piece_type: 'r', promoted: false, owner: 'w' }, 
    { position_x: 7, position_y: 1,piece_type: 'b', promoted: false, owner: 'w' }, 

    # y=2
    { position_x: 0, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' }, 
    { position_x: 1, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 2, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 3, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 4, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 5, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 6, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 7, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' },
    { position_x: 8, position_y: 2, piece_type: 'P', promoted: false, owner: 'w' }
]

# 先手（sente）の駒配置（y=1からy=3）
sente_pieces = [
    # y=6（先手の最前列）
    { position_x: 0, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' }, 
    { position_x: 1, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 2, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 3, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 4, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 5, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 6, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 7, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },
    { position_x: 8, position_y: 6, piece_type: 'P', promoted: false, owner: 'b' },

    # y=7
    { position_x: 1, position_y: 7, piece_type: 'B', promoted: false, owner: 'b' }, 
    { position_x: 7, position_y: 7, piece_type: 'R', promoted: false, owner: 'b' }, 

    # y=8
    { position_x: 0, position_y: 8, piece_type: 'L', promoted: false, owner: 'b' }, 
    { position_x: 1, position_y: 8, piece_type: 'N', promoted: false, owner: 'b' }, 
    { position_x: 2, position_y: 8, piece_type: 'S', promoted: false, owner: 'b' }, 
    { position_x: 3, position_y: 8, piece_type: 'G', promoted: false, owner: 'b' }, 
    { position_x: 4, position_y: 8, piece_type: 'K', promoted: false, owner: 'b' }, 
    { position_x: 5, position_y: 8, piece_type: 'G', promoted: false, owner: 'b' }, 
    { position_x: 6, position_y: 8, piece_type: 'S', promoted: false, owner: 'b' }, 
    { position_x: 7, position_y: 8, piece_type: 'N', promoted: false, owner: 'b' }, 
    { position_x: 8, position_y: 8, piece_type: 'L', promoted: false, owner: 'b' }
]

# 先手と後手の駒をボードに追加
(sente_pieces + gote_pieces).each do |piece|
  board.pieces.create!(piece)
end

puts "初期盤面（先手と後手の駒）が作成されました。"