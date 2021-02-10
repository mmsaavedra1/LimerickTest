class AssignmentsController < ApplicationController
  before_action :set_assignment, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /assignments
  # GET /assignments.json
  def index
  end

  # GET /assignments/1
  # GET /assignments/1.json
  def show
  end

  # GET /assignments/new
  def new
    @assignment = Assignment.new
  end

  # GET /assignments/1/edit
  def edit
  end

  # POST /assignments
  # POST /assignments.json
  def create
    @assignment = Assignment.new(assignment_params)

    respond_to do |format|
      if @assignment.save
        format.html { redirect_to @assignment, notice: 'Assignment was successfully created.' }
        format.json { render :show, status: :created, location: @assignment }
      else
        format.html { render :new }
        format.json { render json: @assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /assignments/1
  # PATCH/PUT /assignments/1.json
  def update
    respond_to do |format|
      if @assignment.update(assignment_params)
        format.html { redirect_to @assignment, notice: 'Assignment was successfully updated.' }
        format.json { render :show, status: :ok, location: @assignment }
      else
        format.html { render :edit }
        format.json { render json: @assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  def corrections
    @assignments = Assignment.eager_load(:assignment_schedules)
  end

  def essays
    @assignment_schedules = AssignmentSchedule.where(stage: AssignmentSchedule.stages[:Primera])
  end

  def show_essays
    @attachments = Attachment.eager_load(assignment_schedule: :assignment)
    .where(
      "stage = ? AND number = ?", AssignmentSchedule.stages[:Primera], params[:number]
    )
    respond_to do |format|
      format.html
      format.zip do
        file = "essays.zip"
        zip_download @attachments, file, false
      end
    end
  end

  def show_corrections
    @attachments = Attachment.where(assignment_schedule_id: params[:assignment_schedule_id])
    @corrections = Correction.where(assignment_schedule_id: params[:assignment_schedule_id]).order(corrected_id: :asc)
    respond_to do |format|
      format.html
      format.zip do
        file = "corrections.zip"
        @attachments = Attachment.eager_load(assignment_schedule: :assignment)
        .where(
          "stage = ? AND number = ?", AssignmentSchedule.stages[:Segunda], params[:number]
        )
        zip_download @attachments, file, true
      end
      format.xlsx do
        csv = [['Numero alumno', 'Etapa 2 - C1', 'Etapa 2 - C2', 'Etapa 3 - C1',
          'Etapa 3 - C2', 'Reajuste por auditoría', 'Total', 'Razon Descuento/Beneficio']]
        @students = User.eager_load(corrections: [assignment_schedule: :assignment])
          .where("number = ?", params[:number]).order(alumni_number: :asc)
        @not_corrected_students = User.eager_load(corrections: [assignment_schedule: :assignment])
          .where("number = ? AND
            score is NULL
            AND stage = ?",
            params[:number],
            AssignmentSchedule.stages[:Segunda])
        @banned_students = User.eager_load(reverse_corrections: [assignment_schedule: :assignment])
          .where("number = ? AND
            score is NULL AND
            users.id NOT IN (?)",
            params[:number],
            @not_corrected_students.distinct.pluck(:id))
          .order(alumni_number: :asc)

        @students.each do |s|
          row = [s.alumni_number]
          total = 0
          s.corrections.eager_load(assignment_schedule: :assignment)
            .where("number = ?", params[:number]).order(assignment_schedule_id: :asc).each do |c|
            unless c.score.nil?
              row << c.score
              total += c.score
            else
              row << "NC"
              total += 0
            end
          end
          if @banned_students.include?(s)
            row << -total
            total += -total
          else
            row << 0
          end
          row << total
          csv << row
        end
        xlsx_stream(csv, 'Hoja1', ::MyIO.new(response.stream))
      end
    end
  end

  def second_stage_corrections
    @corrections = Correction.where(assignment_schedule_id: params[:assignment_schedule_id]).order(corrected_id: :asc)
  end

  def third_stage_corrections
    @corrections = Correction.where(assignment_schedule_id: params[:assignment_schedule_id]).order(corrected_id: :asc)
  end

  # DELETE /assignments/1
  # DELETE /assignments/1.json
  def destroy
    @assignment.destroy
    respond_to do |format|
      format.html { redirect_to assignments_url, notice: 'Assignment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_assignment
      @assignment = Assignment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def assignment_params
      params.require(:assignment).permit(:number)
    end
end
