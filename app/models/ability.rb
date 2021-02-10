class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
      user ||= User.new # guest user (not logged in)
      if user.has_role?(:admin) || user.has_role?(:sub_admin)
        can :manage, :all
      elsif user.id
        can :ajax_download,                  Attachment
        can :create,                         Attachment
        can :show,                           Attachment, user_id: user.id
        can :upload_file,                    Attachment
        can :upload_second_stage_correction, Attachment
        can :upload_third_stage_correction,  Attachment
        can :update,                         Attachment, user_id: user.id
        can :update_correction,              Attachment
        can :download_file,                  Attachment
        can :update,                         Correction, corrector_id: user.id
        can :first_stage,                    AssignmentSchedule
        can :second_stage,                   AssignmentSchedule
        can :third_stage,                    AssignmentSchedule
        can :fourth_stage,                   AssignmentSchedule
        can [:show, :update, :edit],         User, :id => user.id
        can [:index],                        Correction
        can :show,                           CorrectionReview, :correction => {:corrected_id => user.id}
        can :create,                         CorrectionReview
      end
  end
end
