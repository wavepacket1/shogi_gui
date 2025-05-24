class AddBranchHierarchyToBoardHistories < ActiveRecord::Migration[7.0]
  def change
    add_column :board_histories, :parent_branch, :string, default: nil
    add_column :board_histories, :branch_point, :integer, default: nil
    add_column :board_histories, :depth, :integer, default: 0
    
    add_index :board_histories, [:game_id, :parent_branch]
    add_index :board_histories, [:parent_branch, :branch_point]
  end
end 