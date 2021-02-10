class Assignment < ApplicationRecord
  has_many :assignment_schedules
  has_many :attachments, through: :assignment_schedules
  has_many :corrections, through: :assignment_schedules
  has_many :correction_reviews, through: :assignment_schedules
  has_many :assignment_users
  has_many :users, through: :assignment_users

  def get_completed_users
    users = User.eager_load(correction_reviews: :assignment)
                .where("correction_reviews.status = ? and assignment_number = ?",
                        AssignmentUser.statuses[:Tercera],
                        self.number)
  end

  def get_banned_users
    users = User.eager_load(correction_reviews: :assignment)
                .where("correction_reviews.status != ? and assignment_number = ?",
                        AssignmentUser.statuses[:Tercera],
                        self.number)
  end

  def first_stage_schedule
    assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Primera])
  end

  def second_stage_schedule
    assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Segunda])
  end

  def third_stage_schedule
    assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Tercera])
  end

  def fourth_stage_schedule
    assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Cuarta])
  end

  def finished_first_stage?
    finished_stage? :Primera
  end

  def finished_second_stage?
    finished_stage? :Segunda
  end

  def finished_third_stage?
    finished_stage? :Tercera
  end

  def finished_stage? stage
    stage_schedule = assignment_schedules.find_by(stage: AssignmentSchedule.stages[stage])
    if !stage_schedule.nil? && stage_schedule.finished?
      return true
    end
    return false
  end

  def finished_mandatory_stages?
    finished_first_stage? && finished_second_stage? && finished_third_stage?
  end

  # Helper method to get average
  def get_average assignment_num
    assignment = Assignment.find_by(number: assignment_num)
    actual_attachments = assignment.corrections

    if assignment.finished_mandatory_stages?
      average = 0
      size = 0
      actual_attachments.each do |a|
        if (a.score != -1)  
          average += a.score
          size += 1
        end
      end

      average = (average/size).round(2)
      return average
    end
  end

  def get_first_stage_late_users
    in_time_users = User.joins(:attachments)
     .where("attachments.assignment_schedule_id = ? and users.is_active = true", first_stage_schedule.id)
     .distinct.pluck(:id)
    users = User.where("users.id not in (?)", in_time_users).with_role(:student)
    return users
  end

  # Helper method for send_upload_attachment_reminder
  def get_second_stage_late_users
    users = User.joins(:attachments, :reverse_corrections)
     .where("
       attachments.assignment_schedule_id = ?
       AND corrections.assignment_schedule_id = ?
       AND corrections.attachment_id IS NULL
       AND users.is_active = true", first_stage_schedule.id, second_stage_schedule.id)
     .distinct
    return users
  end

  # Helper method for getting third stage late users
  def get_third_stage_late_users
    users = User.joins(:attachments, :reverse_corrections)
     .where("
       attachments.assignment_schedule_id = ?
       AND corrections.assignment_schedule_id = ?
       AND corrections.attachment_id IS NOT NULL
       AND users.is_active = true
       AND users.id IN
       (SELECT corrector_id
        FROM corrections
        WHERE assignment_schedule_id = ?
        AND score IS NULL)", first_stage_schedule.id, second_stage_schedule.id, third_stage_schedule.id)
     .distinct
    return users
  end

  # Metodo que agrega un CorrectionReview a cada corrección no corregida en la tercera etapa.
  # Debe correrse después de que finaliza la cuarta etapa de un ensayo.
  # Debe ser después de la cuarta y no la tercera ya que el alumno está habilitado de poder modificar los CR
  # antes de finalizar la cuarta etapa, además, se cae el script si no hay cuarta etapa.
  def assign_third_stage_not_corrected_scores
    counter = 0
    output = ""
    nc_third_stage_corrections = third_stage_schedule.corrections.where(score: nil)
    nc_third_stage_corrections.each do |nc_correction|
      if nc_correction.correction_review.nil?
        cr = CorrectionReview.new(correction_id: nc_correction.id,
          score_delta: 3,\
          reviewer_comment: "Puntos por no haber sido corregido en la tercera etapa",\
          student_comment: "Reajuste por NC",\
          assignment_schedule_id: fourth_stage_schedule.id,\
          reviewer_id: 1)
        if cr.save
          counter += 1
        else
          output += "ERROR: #{cr.errors.messages}\n"
        end
      else
        output += "ERROR en correccion #{nc_correction.id}\n"
      end
    end
    print output
    p "#{counter} puntajes NC asignados para la tercera etapa del ensayo #{self.number}"
  end

  def get_second_stage_nc_mu
    second_stage_corrections = second_stage_schedule.corrections.eager_load(:corrected)
    ncs = second_stage_corrections.where(score: nil).pluck(:alumni_number)
    mu = second_stage_corrections.where(score: -1).pluck(:alumni_number)
    return {
      'all': ncs + mu,
      'nc': ncs,
      'mu': mu
    }
  end

  def self.get_all_essays_nc_mu(limit: 20)
    out = {}
    Assignment.where("number <= ?", limit).each do |a|
      assignment_nc_mu = a.get_second_stage_nc_mu
      out["e#{a.number}"] = assignment_nc_mu
      out["e#{a.number}"][:nc_count] = assignment_nc_mu[:nc].size
      out["e#{a.number}"][:mu_count] = assignment_nc_mu[:mu].size
    end
    return out
  end

end
