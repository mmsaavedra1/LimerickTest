class CreateTerms < ActiveRecord::Migration[5.1]
  def change
    create_table :terms do |t|
      t.integer :year
      t.integer :number

      t.timestamps
    end
  end
end
