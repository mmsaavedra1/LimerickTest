# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_06_021323) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignment_schedules", force: :cascade do |t|
    t.bigint "assignment_id"
    t.integer "stage"
    t.datetime "start_date", default: "2021-01-24 20:32:09"
    t.datetime "end_date", default: "2021-01-26 20:32:09"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "opening_notification_sent_at"
    t.datetime "closing_notification_sent_at"
    t.index ["assignment_id"], name: "index_assignment_schedules_on_assignment_id"
  end

  create_table "assignment_users", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "assignment_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_assignment_users_on_assignment_id"
    t.index ["user_id"], name: "index_assignment_users_on_user_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "average_score"
  end

  create_table "attachments", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "assignment_schedule_id"
    t.string "essay_file_name"
    t.string "essay_content_type"
    t.integer "essay_file_size"
    t.datetime "essay_updated_at"
    t.string "aux_name"
    t.boolean "correction", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_schedule_id"], name: "index_attachments_on_assignment_schedule_id"
    t.index ["user_id"], name: "index_attachments_on_user_id"
  end

  create_table "clases", force: :cascade do |t|
    t.string "professor"
    t.bigint "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_clases_on_course_id"
  end

  create_table "correction_reviews", force: :cascade do |t|
    t.bigint "reviewer_id"
    t.bigint "correction_id"
    t.bigint "assignment_schedule_id"
    t.float "score_delta"
    t.text "student_comment"
    t.text "reviewer_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_schedule_id"], name: "index_correction_reviews_on_assignment_schedule_id"
    t.index ["correction_id"], name: "index_correction_reviews_on_correction_id"
    t.index ["reviewer_id"], name: "index_correction_reviews_on_reviewer_id"
  end

  create_table "corrections", force: :cascade do |t|
    t.bigint "attachment_id"
    t.bigint "assignment_schedule_id"
    t.integer "corrector_id"
    t.integer "corrected_id"
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "contains_author_data", default: false, null: false
    t.index ["assignment_schedule_id"], name: "index_corrections_on_assignment_schedule_id"
    t.index ["attachment_id"], name: "index_corrections_on_attachment_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "course_id"
    t.string "name"
    t.integer "credits"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "sections", force: :cascade do |t|
    t.bigint "clase_id"
    t.bigint "term_id"
    t.integer "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clase_id"], name: "index_sections_on_clase_id"
    t.index ["term_id"], name: "index_sections_on_term_id"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "year"
    t.integer "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "alumni_number", default: "", null: false
    t.string "name", default: ""
    t.string "last_name", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "password_sent", default: false
    t.datetime "password_sent_at"
    t.boolean "is_active", default: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "assignment_schedules", "assignments"
  add_foreign_key "assignment_users", "assignments"
  add_foreign_key "assignment_users", "users"
  add_foreign_key "attachments", "assignment_schedules"
  add_foreign_key "attachments", "users"
  add_foreign_key "clases", "courses"
  add_foreign_key "correction_reviews", "assignment_schedules"
  add_foreign_key "correction_reviews", "corrections"
  add_foreign_key "correction_reviews", "users", column: "reviewer_id"
  add_foreign_key "corrections", "assignment_schedules"
  add_foreign_key "corrections", "attachments"
  add_foreign_key "sections", "clases"
  add_foreign_key "sections", "terms"
end
