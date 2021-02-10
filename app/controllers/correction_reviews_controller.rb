class CorrectionReviewsController < ApplicationController
  load_and_authorize_resource
  before_action :set_correction_review, only: [:show, :edit, :update, :destroy]
  before_action :set_correction, only: [:new]


  # GET /correction_reviews
  # GET /correction_reviews.json
  def index
    @correction_reviews = CorrectionReview.all
  end

  # GET /correction_reviews/1
  # GET /correction_reviews/1.json
  def show
  end

  # GET /correction_reviews/new
  def new
    @correction_review = CorrectionReview.new
    @assignment = @correction.assignment
    @fourth_stage_schedule = @assignment.assignment_schedules.find_by(stage: AssignmentSchedule.stages[:Cuarta])
    respond_to do |format|
      if !current_user.has_role?(:admin) && Time.now > @fourth_stage_schedule.end_date
        format.html { redirect_back fallback_location: '/etapas/3', notice: "Hubo un error en procesar tu solicitud, por favor contacta al administrador" }
      else
        format.js
        format.html
        format.json { render json: @resource }
      end
    end
  end

  # GET /correction_reviews/1/edit
  def edit
  end

  # POST /correction_reviews
  # POST /correction_reviews.json
  def create
    assignment_schedule = AssignmentSchedule.find_by(id: params[:correction_review][:assignment_schedule_id])
    correction = Correction.find(params[:correction_review][:correction_id])
    @correction_review = CorrectionReview.new(correction_review_params)
    @correction_review.reviewer_id = User.first.id
    respond_to do |format|
      if (current_user.has_role?(:admin) || Time.now < assignment_schedule.end_date && correction.corrected_id == current_user.id) && @correction_review.save
        format.html { redirect_back fallback_location: root_path, notice: 'Tu solicitud fue enviada correctamente.' }
        format.json { render :show, status: :created, location: @correction_review }
      else
        format.html { redirect_back fallback_location: '/etapas', alert: 'Hubo un error al tratar de enviar tu solicitud.' }
        format.json { render json: @correction_review.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /correction_reviews/1
  # PATCH/PUT /correction_reviews/1.json
  def update
    respond_to do |format|
      if @correction_review.update(correction_review_params)
        format.html { redirect_to @correction_review, notice: 'Correction review was successfully updated.' }
        format.json { render :show, status: :ok, location: @correction_review }
      else
        format.html { render :edit }
        format.json { render json: @correction_review.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /correction_reviews/1
  # DELETE /correction_reviews/1.json
  def destroy
    @correction_review.destroy
    respond_to do |format|
      format.html { redirect_to correction_reviews_url, notice: 'Correction review was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_correction_review
      @correction_review = CorrectionReview.find(params[:id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_correction
      @correction = Correction.find(params[:correction_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def correction_review_params
      params.require(:correction_review).permit(:reviewer_id, :correction_id, :assignment_schedule_id, :score_delta, :student_comment, :reviewer_comment)
    end
end
