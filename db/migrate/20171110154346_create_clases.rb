class CreateClases < ActiveRecord::Migration[5.1]
  def change
    create_table :clases do |t|
      t.string :professor
      t.references :course, foreign_key: true

      t.timestamps
    end
  end
end
