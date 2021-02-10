class AttachmentsController < ApplicationController
  before_action :set_attachment, only: [:edit, :update, :destroy]
  load_and_authorize_resource

  # GET /attachments
  # GET /attachments.json
  def index
  end

  # GET /attachments/1
  # GET /attachments/1.json
  def show
  end

  # GET /attachments/new
  def new
    @attachment = Attachment.new
  end

  # GET /attachments/1/edit
  def edit
  end

  # POST /attachments
  # POST /attachments.json
  def create
    @attachment = Attachment.new(attachment_params)

    respond_to do |format|
      if @attachment.save
        format.html { redirect_to @attachment, notice: 'Attachment was successfully created.' }
        format.json { render :show, status: :created, location: @attachment }
      else
        format.html { render :new }
        format.json { render json: @attachment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attachments/1
  # PATCH/PUT /attachments/1.json
  def update
    respond_to do |format|
      if @attachment.update(attachment_params)
        format.html { redirect_to @attachment, notice: 'Attachment was successfully updated.' }
        format.json { render :show, status: :ok, location: @attachment }
      else
        format.html { render :edit }
        format.json { render json: @attaessay_file_namechment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attachments/1
  # DELETE /attachments/1.json
  def destroy
    @attachment.destroy
    respond_to do |format|
      format.html { redirect_to attachments_url, notice: 'Attachment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


#------------------ UPLOAD DOWNLOAD CONTROLLERS ------------------------

  def upload_file
    if params[:attachment][:essay].nil?
      redirect_to '/', alert: 'Debes seleccionar un archivo.'
      return
    end
    @schedule = AssignmentSchedule.find(params[:assignment_schedule_id])
    if Time.now > @schedule.end_date || @schedule.stage != "Primera"
      redirect_back fallback_location: root_path, alert: 'El cuestionario para este archivo está cerrado'
    end
    @attachments = Attachment.eager_load(:user, :assignment_schedule)
    @attachment = @attachments.find_by(
        "users.id = ? AND assignment_schedule_id = ?",
        current_user.id,
        @schedule.id
      )
    if !@attachment.nil?
      @attachment.essay = params[:attachment][:essay]
    else
      @attachment = Attachment.new(attachment_params)
      @attachment.user = current_user
      @attachment.assignment_schedule_id = params[:assignment_schedule_id]
      @attachment.aux_name = SecureRandom.hex(3) + '.' + @attachment.essay_file_name.split('.')[-1]
    end
    if @attachment.save
      redirect_back fallback_location: root_path, notice: 'Archivo subido correctamente.'
    else
      redirect_back fallback_location: root_path, alert: 'Hubo un error en subir tu archivo: ' + @attachment.errors.full_messages.to_s
    end
  end


  def upload_second_stage_correction
    if params[:attachment].nil? || params[:puntaje].nil?
      redirect_back fallback_location: root_path, alert: 'Debes seleccionar un archivo.'
      return
    elsif params[:required_name] != params[:attachment][:essay].original_filename
      redirect_back fallback_location: root_path, alert: 'El nombre del archivo debe ser igual al que descargaste. El archivo no pudo ser subido.'
      return
    end
    @schedule = AssignmentSchedule.includes(:assignment).find_by(id: params[:assignment_schedule_id])
    @my_attachment = Attachment.find_by(
      "user_id = ? AND essay_file_name = ? AND assignment_schedule_id = ?",
      current_user.id, params[:required_name], params[:assignment_schedule_id])
    if !@my_attachment.nil?
      @my_attachment.essay = params[:attachment][:essay]
    else
      @my_attachment = Attachment.new(attachment_params)
      @my_attachment.user = current_user
      @my_attachment.assignment_schedule_id = params[:assignment_schedule_id]
    end
    if @my_attachment.save && update_correction(params, @schedule, @my_attachment)
      redirect_back fallback_location: root_path, notice: 'Archivo subido correctamente.'
    else
      redirect_back fallback_location: root_path, alert: 'Hubo un error en subir tu archivo: ' + @my_attachment.errors.full_messages.to_s
    end
  end


  def upload_third_stage_correction
    @correction = Correction.eager_load(corrected: :attachments)
      .find_by("corrector_id = ? AND corrected_id = ? AND attachments.essay_file_name = ? AND
        corrections.assignment_schedule_id = ?",
        current_user.id,
        params[:corrected],
        params[:filename],
        params[:assignment_schedule_id])
    if !@correction.nil?
      @correction.score = params[:attachment][:score]
      if @correction.save
        redirect_back fallback_location: root_path, notice: 'Corrección subida correctamente.'
      else
        redirect_back fallback_location: root_path, alert: 'Hubo un error en subir tu corrección: ' + @correction.errors.full_messages.to_s + "\n Si sigues con problemas escribe a help@limerick.cl."
      end
    else
      redirect_back fallback_location: root_path, alert: "Hubo un error en subir tu corrección, por favor inténtalo nuevamente. Si sigues con problemas escribe a help@limerick.cl."
    end
  end


  def update_correction params, schedule, attachment
    @correction = Correction.eager_load(:assignment_schedule, corrected: :attachments)
      .find_by("corrector_id = ? AND attachments.aux_name = ? AND corrections.assignment_schedule_id = ?",
        current_user.id,
        params[:attachment][:essay].original_filename,
        schedule.id
      )
    if !@correction.nil?
      @correction.score = params[:puntaje]
      @correction.attachment = attachment
      @correction.contains_author_data = params[:contains_author_data]
      if @correction.save
        return true
      else
        puts @attachment.errors.full_messages.to_s
        return false
      end
    end
  end

  def download_file
    respond_to do |format|
      @download_url = "/attachments/ajax_download?id=#{params[:id]}&assignment_schedule_id=#{params[:assignment_schedule_id]}"
      format.js { render }
    end
  end

  def ajax_download
    @attachment = Attachment.find_by(id: params[:id])
    @schedule = AssignmentSchedule.find_by(id: params[:assignment_schedule_id])
    if !@attachment.nil?
      if @attachment.user_id == current_user.id || current_user.has_role?(:admin) || current_user.has_role?(:sub_admin)
        send_file @attachment.essay.path, filename: @attachment.essay_file_name
      else
        correction = Correction.find_by(
          corrector_id: current_user.id,
          corrected_id: @attachment.user_id,
          assignment_schedule_id: params[:assignment_schedule_id])
        if !correction.nil? && @schedule.stage != "Primera"
          send_file @attachment.essay.path, filename: @attachment.aux_name
        else
          redirect_back fallback_location: root_path, alert: 'Hubo un error al intentar descargar tu archivo, si sigues con problemas envía un mail a help@limerick.cl.'
        end
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attachment
      @attachment = Attachment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attachment_params
      params.require(:attachment).permit(:user_id, :essay, :name, :assignment_schedule, :correction_attributes => [:id, :score, :contains_author_data])
    end
end
