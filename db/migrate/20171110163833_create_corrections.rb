class CreateCorrections < ActiveRecord::Migration[5.1]
  def change
    create_table :corrections do |t|
      t.references :attachment, foreign_key: true
      t.references :assignment_schedule, foreign_key: true
      t.integer :corrector_id
      t.integer :corrected_id
      t.integer :score, default: 0

      t.timestamps
    end
  end
end
