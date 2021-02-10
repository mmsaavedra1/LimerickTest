class ChangeCorrectionReviewScoreToFloat < ActiveRecord::Migration[5.1]
  def change
    change_column :correction_reviews, :score_delta, :float
  end
end
