json.extract! correction_review, :id, :reviewer_id_id, :correction_id, :assignment_schedule_id, :score_delta, :student_comment, :reviewer_comment, :created_at, :updated_at
json.url correction_review_url(correction_review, format: :json)
