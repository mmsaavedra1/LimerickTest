class AssignmentSchedulesController < ApplicationController
  before_action :set_assignment_schedule, only: [:show, :edit, :update, :destroy, :assign_second_stage_corrections, :assign_third_stage_corrections, :send_notifications]
  load_and_authorize_resource


  # GET /assignment_schedules
  # GET /assignment_schedules.json
  def index
    @assignment_schedules = AssignmentSchedule.all
  end

  # GET /assignment_schedules/1
  # GET /assignment_schedules/1.json
  def show
  end

  # GET /assignment_schedules/new
  def new
    @assignment_schedule = AssignmentSchedule.new
  end

  # GET /assignment_schedules/1/edit
  def edit
  end

  # POST /assignment_schedules
  # POST /assignment_schedules.json
  def create
    @assignment = Assignment.includes(:assignment_schedules).find_or_create_by(number: params[:number])
    @assignment_schedule = AssignmentSchedule.new(assignment_schedule_params)
    @assignment_schedule.start_date = Time.now
    @assignment_schedule.assignment = @assignment
    if @assignment_schedule.save
      #cambiar harcodeo schedule
      if @assignment_schedule.stage == "Segunda"
        AssignmentSchedule.random_attachment_assignment @assignment_schedule
      elsif @assignment_schedule.stage == "Tercera" &&
            !@assignment.assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Segunda]).nil?
        AssignmentSchedule.create_reverse_corrections @assignment_schedule
      end
      redirect_to @assignment_schedule, notice: 'Assignment schedule was successfully created.'
    else
      render :new, alert: 'Hubo un error en crear el formulario.' + @assignment_schedule.errors.full_messages.to_s
    end
  end

  # PATCH/PUT /assignment_schedules/1
  # PATCH/PUT /assignment_schedules/1.json
  def update
    respond_to do |format|
      if @assignment_schedule.update(assignment_schedule_params)
        format.html { redirect_to @assignment_schedule, notice: 'Assignment schedule was successfully updated.' }
        format.json { render :show, status: :ok, location: @assignment_schedule }
      else
        format.html { render :edit }
        format.json { render json: @assignment_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assignment_schedules/1
  # DELETE /assignment_schedules/1.json
  def destroy
    @assignment_schedule.destroy
    respond_to do |format|
      format.html { redirect_to assignment_schedules_url, notice: 'Assignment schedule was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def first_stage
    @assignment_schedules = AssignmentSchedule.includes(attachments: :user)
    @first_stage_schedules = @assignment_schedules
      .where("stage = ?", AssignmentSchedule.stages[:Primera])
      .order(id: :asc)
    @attachments = Attachment.eager_load(:user, :assignment_schedule).where(
      "user_id = ? AND stage = ?",
      current_user.id,
      AssignmentSchedule.stages[:Primera])
  end

  def second_stage
    @second_stage_schedules =
      AssignmentSchedule.where(stage: AssignmentSchedule.stages[:Segunda]).order(id: :asc)
    @to_correct = Attachment.eager_load(assignment_schedule: [assignment: [assignment_schedules: :corrections]])
      .where(
        "assignment_schedules.stage = ? AND
        assignment_schedules_assignments.stage = ? AND
        corrector_id = ? AND
        attachments.user_id != corrector_id AND
        attachments.user_id = corrected_id",
        AssignmentSchedule.stages[:Primera],
        AssignmentSchedule.stages[:Segunda],
        current_user.id
      ).order(aux_name: :asc)
    @corrected_by_me = Attachment.eager_load(assignment_schedule: :corrections)
      .where("assignment_schedules.stage = ? AND corrector_id = ? AND user_id = corrector_id",
      AssignmentSchedule.stages[:Segunda],
      current_user.id)
    @corrections_as_corrector = Correction.eager_load(assignment_schedule: :assignment).where(corrected_id: current_user.id)
    @fourth_stage_schedules = @assignment_schedules
      .where(stage: AssignmentSchedule.stages[:Cuarta])
      .order(id: :asc)
  end

  def third_stage
    @assignment_schedules = AssignmentSchedule.eager_load(attachments: {user: :corrections})
    @third_stage_schedules = @assignment_schedules
      .where(stage: AssignmentSchedule.stages[:Tercera])
      .order(id: :asc)
    @my_essays_corrected = Attachment.eager_load(:assignment_schedule, :correction)
    .where("assignment_schedules.stage = ? AND corrections.corrected_id = ?",
      AssignmentSchedule.stages[:Segunda],
      current_user.id)
    @my_corrections_to_correctors = Correction.eager_load(assignment_schedule: :assignment)
      .where("corrector_id = ? AND stage = ?",
        current_user.id,
        AssignmentSchedule.stages[:Tercera])
    @fourth_stage_schedules = @assignment_schedules
      .where(stage: AssignmentSchedule.stages[:Cuarta])
      .order(id: :asc)
  end

  def fourth_stage
    @assignment_schedules = AssignmentSchedule.eager_load(:assignment, attachments: {user: :corrections})
    @fourth_stage_schedules = @assignment_schedules
      .where(stage: AssignmentSchedule.stages[:Cuarta])
      .order(id: :asc)
  end

  def assign_second_stage_corrections
    @assignment_schedule = AssignmentSchedule.find(params[:id])
    respond_to do |format|
      format.js do
        unless @assignment_schedule.nil? && @assignment_schedule.stage = "Segunda"
          if AssignmentSchedule.random_attachment_assignment @assignment_schedule
            render partial: 'alert', locals: {notice: "Asignación realizada correctamente"}
            return
          end
        end
        render partial: 'alert', locals: {alert: "No se pudo asignar las correcciones"}
      end
    end
  end

  def assign_third_stage_corrections
    @assignment_schedule = AssignmentSchedule.find(params[:id])
    respond_to do |format|
      format.js do
        unless @assignment_schedule.nil? && @assignment_schedule.stage = "Tercera"
          if AssignmentSchedule.create_reverse_corrections @assignment_schedule
            render partial: 'alert', locals: {notice: "Asignación realizada correctamente"}
            return
          end
        end
        render partial: 'notice', locals: {alert: "No se pudo asignar las correcciones"}
      end
    end
  end

  def send_notifications
    begin
      if @assignment_schedule.end_date >= Time.current + 24.hours
        @assignment_schedule.send_schedule_notification
      else
        if @assignment_schedule.stage == "Primera"
          User.send_upload_attachment_reminder_mail @assignment_schedule.assignment_number
        else
          User.send_correction_reminder_mail @assignment_schedule.assignment_number, @assignment_schedule.stage
        end
      end
      msg = "Notificaciones enviadas correctamente para la #{@assignment_schedule.stage} etapa del ensayo #{@assignment_schedule.assignment_number}!"
    rescue Exception => ex
      msg = "An error of type #{ex.class} happened, message is #{ex.message}"
    end
    respond_to do |format|
      format.js do
        render partial: 'alert', locals: {notice: msg}
      end
    end
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
