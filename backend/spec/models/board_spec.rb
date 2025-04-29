require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'アソシエーション' do
    it 'gameに所属すること' do
      expect(Board.reflect_on_association(:game).macro).to eq :belongs_to
    end

    it 'piecesを複数持つこと' do
      expect(Board.reflect_on_association(:pieces).macro).to eq :has_many
    end

    it 'ゲームが削除されたときに関連するpiecesも削除されること' do
      expect(Board.reflect_on_association(:pieces).options[:dependent]).to eq :destroy
    end
  end

  describe 'インスタンスメソッド' do
    describe '#to_sfen' do
      it 'sfenカラムの値を返すこと' do
        sfen = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0'
        board = create(:board, sfen: sfen)
        expect(board.to_sfen).to eq sfen
      end
    end
  end

  describe 'クラスメソッド' do
    describe '.default_sfen' do
      it 'デフォルトのSFEN表記を返すこと' do
        expect(Board.default_sfen).to eq 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0'
      end
    end

    describe '.convert_move_to_indices' do
      it '指し手を配列のインデックスに変換すること' do
        board_array = Array.new(9) { Array.new(9, nil) }
        move = '7g7f'
        expect(Board.convert_move_to_indices(board_array, move)).to eq [2, 6, 2, 5]
      end
    end

    describe '.parse_move' do
      context '駒を動かす場合' do
        it '通常の駒移動を正しく解析すること' do
          move = '7g7f'
          result = Board.parse_move(move)
          expect(result[:type]).to eq :move
          expect(result[:from_row]).to eq 6
          expect(result[:from_col]).to eq 2
          expect(result[:to_row]).to eq 5
          expect(result[:to_col]).to eq 2
          expect(result[:promoted]).to eq false
        end

        it '成り駒の移動を正しく解析すること' do
          move = '7g7f+'
          result = Board.parse_move(move)
          expect(result[:type]).to eq :move
          expect(result[:promoted]).to eq true
        end
      end

      context '駒を打つ場合' do
        it '駒打ちを正しく解析すること' do
          move = 'P*7f'
          result = Board.parse_move(move)
          expect(result[:type]).to eq :drop
          expect(result[:piece]).to eq 'P'
          expect(result[:to_row]).to eq 5
          expect(result[:to_col]).to eq 2
        end
      end
    end
  end
end
