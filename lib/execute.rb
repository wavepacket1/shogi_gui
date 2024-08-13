require "/Users/kinoko/shogi_app/lib/board.rb"

shogi_board = Shogi::Board.new
# shogi_board.display 
#駒の移動
board = shogi_board.initial_board
puts board[6][0]

shogi_board.move(board,[6,0],[5,0],"+FU",-1)