class AddContainsAuthorDataToCorrections < ActiveRecord::Migration[5.1]
  def change
    add_column :corrections, :contains_author_data, :bool, default: false, null: false
  end
end
