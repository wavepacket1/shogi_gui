require_relative 'pieces/p'
require_relative 'pieces/n'
require_relative 'pieces/k'
require_relative 'pieces/b'
require_relative 'pieces/l'
require_relative 'pieces/s'
require_relative 'pieces/g'
require_relative 'pieces/r'
require_relative 'pieces/t'
require_relative 'pieces/y'
require_relative 'pieces/e'
require_relative 'pieces/i'
require_relative 'pieces/u'
require_relative 'pieces/z'

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
        #と
        when 't'
            Shogi::Pieces::T.new
        #成香
        when 'y'
            Shogi::Pieces::Y.new
        #成桂
        when 'e'
            Shogi::Pieces::E.new
        #成銀
        when 'i'
            Shogi::Pieces::I.new  
        #馬
        when 'u'
            Shogi::Pieces::U.new  
        #龍
        when 'z'
            Shogi::Pieces::Z.new  
        else 
            raise "不明な駒: #{type}"
        end
    end
end