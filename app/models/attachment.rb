class Attachment < ApplicationRecord
  has_attached_file :essay
  validates_attachment_content_type :essay, content_type: ["application/zip", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword", "application/octet-stream"]
  belongs_to :user
  belongs_to :assignment_schedule
  has_one :correction
  has_one :assignment, through: :assignment_schedule

  accepts_nested_attributes_for :correction

  def assignment_number
    return assignment.number
  end
end
