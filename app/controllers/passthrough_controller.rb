class PassthroughController < ApplicationController
  def index
    if current_user.has_role?(:admin)
      redirect_to '/assignments/essays'
    elsif current_user.has_role?(:sub_admin)
      redirect_to correction_reviews_admin_assignments_path
    elsif current_user.has_role?(:student) || current_user.has_role?(:test)
      redirect_to '/etapas'
    else
      redirect_to '/users/sign_in'
    end
  end
end
