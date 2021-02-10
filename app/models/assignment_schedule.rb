class AssignmentSchedule < ApplicationRecord
  belongs_to :assignment
  has_many :attachments
  has_many :corrections
  has_many :correction_reviews
  # after_create :send_schedule_notification if Rails.env.production?

  accepts_nested_attributes_for :assignment

  enum stage: %i[
    Primera
    Segunda
    Tercera
    Cuarta
  ]

  def assignment_number
    return assignment.number
  end

  def finished?
    Time.now > self.end_date
  end

  def self.create_reverse_corrections assignment_schedule
    if assignment_schedule.stage != "Tercera"
      puts "Asignación no se puede realizar para la #{assignment_schedule.stage} etapa"
      return false
    end
    @assignment = assignment_schedule.assignment
    unless @assignment.nil?
      second_schedule = @assignment.assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Segunda])
      second_schedule.corrections.each do |c|
        correction = Correction.new(
          corrector_id: c.corrected_id,
          corrected_id: c.corrector_id,
          assignment_schedule_id: assignment_schedule.id
        )
        if c.attachment_id.nil?
          correction.score = 0
        end
        correction.save
      end
    else
      return false
    end
    return true
  end

  def self.random_attachment_assignment assignment_schedule
    #Ensayos que pertenecen a esta etapa
    if assignment_schedule.stage != "Segunda"
      puts "Asignación no se puede realizar para la #{assignment_schedule.stage} etapa"
      return false
    end
    assignations = self.attachment_assignment_helper(assignment_schedule)
    if assignations.empty?
      p "No se asignaron las correcciones correctamente, inténtelo nuevamente"
      return false
    end
    ActiveRecord::Base.transaction do
      assignations.keys.each do |user_assigned|
        assignations[user_assigned].each do |attachment_assigned|
          correction = Correction.new(
            corrector_id: user_assigned,
            corrected_id: attachment_assigned.user.id,
            assignment_schedule_id: assignment_schedule.id
          )
          correction.save
        end
      end
    end
    puts 'Asignación realizada correctamente'
    return true
  end

  def self.attachment_assignment_helper assignment_schedule
    p "Started helper work..."
    attachments = Attachment
      .joins(:user, assignment_schedule: :assignment)
      .where(
        "correction = ? AND
        assignment_schedules.stage = ? AND
        assignments.id = ?",
        false,
        AssignmentSchedule.stages[:Primera],
        assignment_schedule.assignment.id).to_a
    if attachments.empty? || attachments.count < 3
      p "No se encontraron ensayos para esta etapa"
      return {}
    else
      p "Found #{attachments.count} attachments"
    end
    users = User
      .with_role(:student)
      .joins(attachments: [assignment_schedule: :assignment])
      .where('
        attachments.correction = ? AND
        assignment_schedules.stage = ? AND
        assignments.id = ?',
        false,
        AssignmentSchedule.stages[:Primera],
        assignment_schedule.assignment.id).to_a
    if users.empty? || users.count < 3
      p "No se encontraron autores para esta etapa"
      return {}
    else
      p "Found #{users.count} users"
    end
    assignations = {}
    while !attachments.empty?
      to_assign_attachment = attachments.sample
      user1 = users.sample
      user2 = users.sample
      while user1 == to_assign_attachment.user
        user1 = users.sample
      end
      while user2 == to_assign_attachment.user || user1 == user2
        user2 = users.sample
        if users.length == 1
          p "No hay suficientes usuarios"
          return {}
        end
      end
      [user1, user2].each do |user|
        if assignations.key?(user.id)
          assignations[user.id] << to_assign_attachment
          users.delete(user)
        else
          assignations[user.id] = [to_assign_attachment]
        end
      end
      attachments.delete(to_assign_attachment)
    end
    return assignations
  end

  def send_schedule_notification
    assignment_number = self.assignment_number
    ### TODO: Crear las migraciones para definir la hora en que se envió la notificacion de apertura, setearla cuando se abre el form y despues guardar el valor.
    # self.opening_notification_sent_at = DateTime.now
    if self.stage == "Primera"
      User.with_role(:student).where(is_active: true).each do |u|
        u.get_first_stage_schedule_notification
      end
    elsif self.stage == "Segunda"
      @users = User.eager_load(attachments: [assignment_schedule: :assignment])
        .where("number = ? AND assignment_schedules.stage = ? and is_active = true",
          assignment_number,
          AssignmentSchedule.stages["Primera"])
        .with_role(:student)
      @users.each do |u|
        u.get_second_stage_schedule_notification
      end
    elsif self.stage == "Tercera"
      @users = User.eager_load(reverse_corrections: [assignment_schedule: :assignment])
        .where("number = ? AND assignment_schedules.stage = ? AND attachment_id IS NOT NULL AND is_active = true",
          assignment_number,
          AssignmentSchedule.stages["Segunda"])
        .with_role(:student)
      @users.each do |u|
        u.get_third_stage_schedule_notification
      end
    end
    # save
  end

  def sibling_schedules
    assignment.assignment_schedules
  end

  def sibling_first_stage_schedule
    sibling_schedules.where(stage: AssignmentSchedule.stages["Primera"])
  end

  def sibling_second_stage_schedule
    sibling_schedules.where(stage: AssignmentSchedule.stages["Segunda"])
  end

  def sibling_third_stage_schedule
    sibling_schedules.where(stage: AssignmentSchedule.stages["Tercera"])
  end

  def sibling_fourth_stage_schedule
    sibling_schedules.where(stage: AssignmentSchedule.stages["Cuarta"])
  end

end
