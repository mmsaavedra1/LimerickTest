module Admin
  class CorrectionReviewsController < ApplicationController
    before_action :set_correction_review, only: [:show, :edit, :update, :destroy]
    before_action :set_correction, only: [:new]
    before_action :set_assignment, only: [:index]
    load_and_authorize_resource


    # GET /correction_reviews
    # GET /correction_reviews.json
    def index
      @correction_reviews =
        CorrectionReview
          .joins(assignment_schedule: :assignment)
          .where("assignments.number = ?", params[:assignment_number])
          .order("reviewer_id ASC, stage ASC")
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
        #### TODO cambiar!!!
        if !user.has_role?(:admin) && Time.now < @fourth_stage_schedule.end_date
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
      #TODO validaciones!!!
      @correction_review = CorrectionReview.new(correction_review_params)
      p @correction_review
      @correction_review.reviewer_id = User.first.id
      respond_to do |format|
        if @correction_review.save
          format.html { redirect_to "/etapas/3", notice: 'Tu solicitud fue enviada correctamente.' }
          format.json { render :show, status: :created, location: @correction_review }
        else
          p @correction_review.errors
          format.html { redirect_to "/etapas/3", alert: 'Hubo un error al tratar de enviar tu solicitud.' }
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

      # Use callbacks to share common setup or constraints between actions.
      def set_assignment
        @assignment = Assignment.find_by(number: params[:assignment_number])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def correction_review_params
        params.require(:correction_review).permit(:reviewer_id_id, :correction_id, :assignment_schedule_id, :score_delta, :student_comment, :reviewer_comment)
      end
  end
end
