module Admin
  class AssignmentSchedulesController < ApplicationController
    load_and_authorize_resource

    def fourth_stage
      @assignment_schedules = AssignmentSchedule.eager_load(:assignment, attachments: {user: :corrections})
      @fourth_stage_schedules = @assignment_schedules
        .where(stage: AssignmentSchedule.stages[:Cuarta])
        .order(id: :asc)
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_assignment_schedule
        @assignment_schedule = AssignmentSchedule.find(params[:id])
      end



      # Never trust parameters from the scary internet, only allow the white list through.
      def assignment_schedule_params
        params.require(:assignment_schedule).permit(:start_date, :end_date, :stage)
      end
  end
end
