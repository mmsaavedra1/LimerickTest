class ChangeScoreToFloat < ActiveRecord::Migration[5.1]
  def change
    change_column :corrections, :score, :float
  end
end
