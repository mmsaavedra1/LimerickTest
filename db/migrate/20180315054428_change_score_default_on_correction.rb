class ChangeScoreDefaultOnCorrection < ActiveRecord::Migration[5.1]
  def change
    change_column_default :corrections, :score, from: 0, to: nil
  end
end
