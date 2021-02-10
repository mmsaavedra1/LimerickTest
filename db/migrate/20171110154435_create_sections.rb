class CreateSections < ActiveRecord::Migration[5.1]
  def change
    create_table :sections do |t|
      t.references :clase, foreign_key: true
      t.references :term, foreign_key: true
      t.integer :number

      t.timestamps
    end
  end
end
