class Correction < ApplicationRecord
  belongs_to :corrector, :class_name => :User
  belongs_to :corrected, :class_name => :User
  belongs_to :attachment, required: false
  belongs_to :assignment_schedule
  has_one :correction_review

  scope :second_stage, -> { eager_load(assignment_schedule: :assignment)
    .where("stage = ?", AssignmentSchedule.stages[:Segunda])}

  scope :third_stage, -> { eager_load(assignment_schedule: :assignment)
    .where("stage = ?", AssignmentSchedule.stages[:Tercera])}

  scope :from_user, ->(uid) { eager_load(assignment_schedule: :assignment)
    .where("corrector_id = ?", uid) }

  scope :to_user, ->(uid) { eager_load(assignment_schedule: :assignment)
    .where("corrected_id = ?", uid) }

  scope :essay_number, ->(num) { eager_load(assignment_schedule: :assignment)
    .where("number = ?", num) }

  def assignment
    return assignment_schedule.assignment
  end

  def assignment_number
    return assignment_schedule.assignment.number
  end

  def stage
    return assignment_schedule.stage
  end

  def reversed_correction
    Correction
      .eager_load(assignment_schedule: :assignment)
      .find_by("corrector_id = ? AND corrected_id = ? AND number = ?", 
        self.corrected_id,
        self.corrector_id,
        self.assignment_number)
  end
end
