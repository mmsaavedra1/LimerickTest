class CreateCorrectionReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :correction_reviews do |t|
      t.references :reviewer, foreign_key: {to_table: :users}
      t.references :correction, foreign_key: true
      t.references :assignment_schedule, foreign_key: true
      t.integer :score_delta
      t.text :student_comment
      t.text :reviewer_comment

      t.timestamps
    end
  end
end
