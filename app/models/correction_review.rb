class CorrectionReview < ApplicationRecord
  belongs_to :reviewer, :class_name => :User
  belongs_to :correction
  belongs_to :assignment_schedule
  has_one :assignment, through: :assignment_schedule
  validates :student_comment, presence: true, allow_blank: false

  def corrected
    correction.corrected
  end

  def assignment_number
    assignment.number
  end
end
