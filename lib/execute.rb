require "/Users/kinoko/shogi_app/lib/board.rb"

shogi_board = Shogi::Board.new
# shogi_board.display 
# #駒の移動
# board = shogi_board.initial_board

shogi_board.move("7776P")
shogi_board.board.each do |row|
    puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
end

shogi_board.move("3334p")

shogi_board.board.each do |row|
    puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
end
