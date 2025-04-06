require 'rails_helper'

RSpec.describe BoardHistory, type: :model do
  let(:game) { Game.create(status: 'active') }
  
  describe 'validations' do
    it 'requires sfen, move_number, and branch' do
      history = BoardHistory.new(game: game)
      expect(history).not_to be_valid
      expect(history.errors[:sfen]).to include("can't be blank")
      expect(history.errors[:move_number]).to include("can't be blank")
    end
    
    it 'enforces uniqueness of move_number within game and branch' do
      BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
        move_number: 1,
        branch: 'main'
      )
      
      duplicate = BoardHistory.new(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1',
        move_number: 1,
        branch: 'main'
      )
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:move_number]).to include("has already been taken")
    end
  end
  
  describe 'navigation methods' do
    before do
      # テストデータをセットアップ
      @history0 = BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
        move_number: 0,
        branch: 'main'
      )
      
      @history1 = BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1',
        move_number: 1,
        branch: 'main'
      )
    end
    
    it 'returns previous board history' do
      expect(@history1.previous_board_history).to eq(@history0)
      expect(@history0.previous_board_history).to be_nil
    end
    
    it 'returns next board history' do
      expect(@history0.next_board_history).to eq(@history1)
      expect(@history1.next_board_history).to be_nil
    end
    
    it 'returns first and last board history' do
      expect(@history0.first_board_history).to eq(@history0)
      expect(@history1.first_board_history).to eq(@history0)
      
      expect(@history0.last_board_history).to eq(@history1)
      expect(@history1.last_board_history).to eq(@history1)
    end
  end
end
