class AuditController < ApplicationController
  load_and_authorize_resource :class => AuditController

  def index
    @assignments = Assignment.all
    respond_to do |format|
      format.html { render }
      format.zip do
        @first_schedule = AssignmentSchedule
          .eager_load(:assignment, :attachments)
          .find_by("number = ? AND stage = ?",
            params[:essay_number],
            AssignmentSchedule.stages["Primera"])
        @second_schedule = AssignmentSchedule
          .eager_load(:assignment, :attachments)
          .find_by("number = ? AND stage = ?",
            params[:essay_number],
            AssignmentSchedule.stages["Segunda"])
        if @second_schedule.nil?
          redirect_to '/audit', alert: 'No hay ensayos que correspondan a los parámetros.'
          return
        end
        @users = User.joins(:attachments).where("attachments.assignment_schedule_id = ?", @first_schedule.id).to_a
        to_be_audited_number = @users.count * (params[:percentage].to_i / 100.0)
        p "number audited: ", to_be_audited_number, @users.count, params[:percentage].to_i / 100
        @attachments_downloaded = []
        if to_be_audited_number > 0
          (1..to_be_audited_number).each do |i|
            well_corrected = false
            while !well_corrected
              user = @users.sample
              user_corrections = Correction.where("assignment_schedule_id = ? AND
                corrected_id = ? AND attachment_id IS NOT NULL", @second_schedule.id, user.id)
              if user_corrections.count == 2
                well_corrected = true
                user_corrections.each do |c|
                  @attachments_downloaded << c.attachment
                end
              end
              @users.delete(user)
            end
          end
          file = "audited_essays.zip"
          zip_download @attachments_downloaded, file, true
        else
          redirect_to '/audit', alert: 'No hay ensayos que correspondan a los parámetross.'
        end
      end
    end
  end

  def not_corrected

    respond_to do |format|
      format.zip do
        @first_schedule = AssignmentSchedule.eager_load(:assignment)
          .find_by("number = ? AND stage = ?", params[:essay_number], AssignmentSchedule.stages["Primera"])
        @second_schedule = AssignmentSchedule.eager_load(:assignment)
          .find_by("number = ? AND stage = ?", params[:essay_number], AssignmentSchedule.stages["Segunda"])
        @attachments = Attachment.where("attachments.user_id
          IN (select corrected_id FROM corrections WHERE corrections.assignment_schedule_id = ? AND corrections.attachment_id IS NULL)
          AND attachments.assignment_schedule_id = ?", @second_schedule.id, @first_schedule.id)
        file = "not_corrected_essays.zip"
        zip_download @attachments, file, false
      end
    end
  end


  def final_scores
    @assignments = Assignment.eager_load(assignment_schedules: :corrections).order(number: :asc).all
    csv = [['Numero alumno', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E8', 'E9', 'E10', 'E11', 'E12' ]]
    User.with_role(:student).order(alumni_number: :asc).each do |curr_user|
      row = [curr_user.alumni_number]
      @assignments.each do |a|
        corrections = Correction.eager_load(assignment_schedule: :assignment).where("assignment_schedules.assignment_id = ? and corrected_id = ?", a.id, curr_user.id)
        second_stage_corrections = corrections.where("assignment_schedules.stage = ?", AssignmentSchedule.stages[:Segunda])
        third_stage_corrections = corrections.where("assignment_schedules.stage = ?", AssignmentSchedule.stages[:Tercera])
        reviews_score_delta = CorrectionReview.joins(:assignment_schedule, :correction ).where("assignment_schedules.assignment_id = ? and corrections.corrected_id = ? and corrections.score != -1 and corrections.score is not NULL", a.id, curr_user.id).sum(:score_delta)
        puntaje_final = reviews_score_delta
        if curr_user.completed_process?(a.number) && a.finished_mandatory_stages?
          if curr_user.completed_second_stage? a.number
            second_stage_corrections.each do |correction|
              if (correction.score.nil? || correction.score == -1) && !correction.correction_review.nil?
                score = correction.correction_review.score_delta
              else
                score = correction.score.nil? ? "NC" : correction.score
              end
              puntaje_final += score.is_a?(String) ? 0 : score
            end
          end
          if curr_user.completed_third_stage? a.number
            third_stage_corrections.each do |correction|
              score = correction.score.nil? ? 3 : correction.score
              puntaje_final += score
            end
          end
          row << puntaje_final
        else
          row << 0
        end
      end
      csv << row
    end
    respond_to do |format|
      format.xlsx do
        xlsx_stream(csv, 'Hoja1', ::MyIO.new(response.stream))
      end
    end
  end

end
