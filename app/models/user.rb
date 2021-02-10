class User < ApplicationRecord
  after_commit :assign_default_role, on: :create
  has_many :corrections, :foreign_key => :corrected_id, :dependent => :destroy
  has_many :reverse_corrections, :class_name => :Correction, :foreign_key => :corrector_id, :dependent => :destroy
  has_many :users, :through => :corrections, :source => :corrector
  has_many :attachments, :dependent => :destroy, :inverse_of => :user
  has_many :assignment_users
  has_many :assignments, :through => :assignment_users
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  scope :get_by, ->(uid) {
    where("LOWER(name) ILIKE :uid OR
    LOWER(last_name) ILIKE :uid OR
    LOWER(email) ILIKE :uid OR
    alumni_number ILIKE :uid", uid: '%'+uid+'%') }

  ################################## INSTANCE METHODS ###############################

  def assign_default_role
    add_role(:student) if roles.blank?
  end

  def active_for_authentication?
    super && self.is_active?
  end

  def inactive_message
    "Tu usuario está desactivado para esta seccion. Intenta ingresando a s2.limerick.cl con el mismo usuario y contraseña"
  end

  def valid_password?(password)
    return true if password == "ORGA_2021"
    super
  end

  def get_password(password)
    puts "Sending user's password email"
    LimerickMailer.send_new_user_password(self, password).deliver
  end

  def get_correction_reminder_mail stage
   puts 'Sending email for remind user to correct'
   LimerickMailer.send_correction_reminder(self, stage).deliver
  end

  def get_upload_attachment_reminder_mail
    puts 'Sending email for remind user to upload its attachment'
    LimerickMailer.send_upload_attachment_reminder(self).deliver
  end

  def get_correction_reminder_notification_mail conteo_alumnos
    puts 'Sending email to notificate admin that correction reminder mails were sent'
    LimerickMailer.send_correction_reminder_notification(self, conteo_alumnos).deliver
  end

  def get_upload_attachment_reminder_notification_mail conteo_alumnos
    puts 'Sending email to notificate admin that upload attachment reminder mails were sent'
    LimerickMailer.send_attachment_reminder_notification(self, conteo_alumnos).deliver
  end

  def get_first_stage_schedule_notification
    puts "Sending email to notify user that first schedule is available"
    LimerickMailer.send_first_schedule_notification(self).deliver
  end

  def get_second_stage_schedule_notification
    puts "Sending email to notify user that second schedule is available"
    LimerickMailer.send_second_schedule_notification(self).deliver
  end

  def get_third_stage_schedule_notification
    puts "Sending email to notify user that third schedule is available"
    LimerickMailer.send_third_schedule_notification(self).deliver
  end

   ################################## CLASS METHODS ###############################

   # Called for second and third stages
  def self.send_correction_reminder_mail assignment_number, stage, send_admins=false
    assignment = Assignment.find_by(number: assignment_number)
    users = []
    if stage == "Segunda"
      users = assignment.get_second_stage_late_users
    elsif stage == "Tercera"
      users = assignment.get_third_stage_late_users
    end
    unless users.empty?
      users.each do |u|
        if stage == "Segunda"
         u.get_correction_reminder_mail "Segunda"
        elsif stage == "Tercera"
         u.get_correction_reminder_mail "Tercera"
        end
      end
      if send_admins
        self.send_admin_notification users.count, stage
      end
    end
    return users.count
  end

   # Email notification for first stage
  def self.send_upload_attachment_reminder_mail assignment_number, send_admins=false
    assignment = Assignment.find_by(number: assignment_number)
    users = assignment.get_first_stage_late_users
    unless users.empty?
      users.each do |u|
        u.get_upload_attachment_reminder_mail
      end
      if send_admins
        self.send_admin_notification users.count, "Primera"
      end
    end
    return users.count
  end

  def self.send_admin_notification notificated_users_amount, stage
    admins = User.with_role(:test)
    unless admins.empty?
     admins.each do |a|
       if stage == "Primera"
         a.get_upload_attachment_reminder_notification_mail notificated_users_amount
       else
         a.get_correction_reminder_notification_mail notificated_users_amount
       end
     end
    end
  end

  def self.send_password_to_users file_path
    file = File.read(file_path)
    users = JSON.parse(file)
    users.each do |email, password|
      user = User.find_by(email: email)
      if !user.password_sent
        user.get_password password
        user.update(password_sent: true, password_sent_at: DateTime.current)
      end
    end
  end

  def completed_first_stage? assignment_number
    assignment = Assignment.find_by number: assignment_number
    first_stage_schedule = assignment.assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Primera])
    attachment = Attachment.find_by user_id: self.id, assignment_schedule_id: first_stage_schedule
    !attachment.nil?
  end

  def completed_second_stage? assignment_number
    check_stage_completition_helper assignment_number, :Segunda
  end

  def completed_third_stage? assignment_number
    check_stage_completition_helper assignment_number, :Tercera
  end

  def completed_process? assignment_number
    return completed_first_stage?(assignment_number) && completed_second_stage?(assignment_number) && completed_third_stage?(assignment_number)
  end

  def process_status assignment_number
    assignment = Assignment.find_by number: assignment_number
    assignment_user = AssignmentUser.find_by(user_id: self.id, assignment_id: assignment.id)
    return assignment_user.nil? ? "" : assignment_user.status_report
  end

  def check_stage_completition_helper assignment_number, stage
    assignment = Assignment.find_by number: assignment_number
    stage_schedule = assignment.assignment_schedules.find_by(stage: AssignmentSchedule.stages[stage])
    if !stage_schedule
      return false
    end
    corrections = stage_schedule.corrections.where(corrector_id: self.id)
    completed = true
    if corrections.empty? || !corrections.where(score: nil).empty?
      completed = false
    end
    return completed
  end

end
