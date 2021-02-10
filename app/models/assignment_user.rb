class AssignmentUser < ApplicationRecord
  belongs_to :user
  belongs_to :assignment

  enum status: %i[
    No_entrega
    Primera
    Segunda
    Tercera
    Banned
  ]

  def status_report
    if AssignmentUser.statuses[self.status] == AssignmentUser.statuses[:No_entrega]
      return "No entregado"
    elsif AssignmentUser.statuses[self.status] == AssignmentUser.statuses[:Primera]
      return "No entrega segunda etapa"
    elsif AssignmentUser.statuses[self.status] == AssignmentUser.statuses[:Segunda]
      return "No entrega tercera etapa"
    elsif AssignmentUser.statuses[self.status] == AssignmentUser.statuses[:Tercera]
      return "Completado"
    end
  end

  def status_color
    if self.status_report == "Completado"
      return "green"
    else
      return "red"
    end
  end

  def self.update_users_status assignment_number
    users = User.with_role(:student)
    assignment = Assignment.find_by number: assignment_number
    if assignment.nil?
      return "No se encontro el assignment número #{assignment_number}"
    end
    users.each do |u|
      assignment_user = AssignmentUser.find_or_create_by(user_id: u.id, assignment_id: assignment.id)
      if u.completed_first_stage? assignment_number
        assignment_user.status = AssignmentUser.statuses[:Primera]
        if u.completed_second_stage? assignment_number
          assignment_user.status = AssignmentUser.statuses[:Segunda]
          if u.completed_third_stage? assignment_number
            assignment_user.status = AssignmentUser.statuses[:Tercera]
          end
        end
      end
      assignment_user.save
    end
  end

end
