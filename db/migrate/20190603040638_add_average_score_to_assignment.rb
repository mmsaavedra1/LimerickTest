class AddAverageScoreToAssignment < ActiveRecord::Migration[5.1]
  def change
    add_column :assignments, :average_score, :float, :precision => 8, :scale => 5
  end
end
