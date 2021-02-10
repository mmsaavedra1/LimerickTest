class CreateAttachments < ActiveRecord::Migration[5.1]
  def change
    create_table :attachments do |t|
      t.references :user, foreign_key: true
      t.references :assignment_schedule, foreign_key: true
      t.attachment :essay
      t.string :aux_name
      t.boolean :correction, default: false

      t.timestamps
    end
  end
end
