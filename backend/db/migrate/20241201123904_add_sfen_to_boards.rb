class AddSfenToBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :boards, :sfen, :string, default: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1'
    add_column :boards, :step_number, :integer, null: true
  end
end
