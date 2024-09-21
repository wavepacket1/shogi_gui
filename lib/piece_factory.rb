class PieceFactory 
    def self.create_piece(type)
        case type.downcase
        #歩
        when 'p'
            Shogi::Pieces::P.new
        #香
        when 'l'
            Shogi::Pieces::L.new
        #桂
        when 'n' 
            Shogi::Pieces::N.new
        #銀
        when 's'
            Shogi::Pieces::S.new
        #金
        when 'g'
            Shogi::Pieces::G.new
        #角
        when 'b'
            Shogi::Pieces::B.new
        #飛
        when 'r'
            Shogi::Pieces::R.new
        #王
        when 'k'
            Shogi::Pieces::K.new
        else 
            raise "不明な駒: #{type}"
        end
    end
end