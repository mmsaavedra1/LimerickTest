require 'test_helper'

class AssignmentSchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @assignment_schedule = assignment_schedules(:one)
  end

  test "should get index" do
    get assignment_schedules_url
    assert_response :success
  end

  test "should get new" do
    get new_assignment_schedule_url
    assert_response :success
  end

  test "should create assignment_schedule" do
    assert_difference('AssignmentSchedule.count') do
      post assignment_schedules_url, params: { assignment_schedule: { assignment_number: @assignment_schedule.assignment_number, end_date: @assignment_schedule.end_date, start_date: @assignment_schedule.start_date } }
    end

    assert_redirected_to assignment_schedule_url(AssignmentSchedule.last)
  end

  test "should show assignment_schedule" do
    get assignment_schedule_url(@assignment_schedule)
    assert_response :success
  end

  test "should get edit" do
    get edit_assignment_schedule_url(@assignment_schedule)
    assert_response :success
  end

  test "should update assignment_schedule" do
    patch assignment_schedule_url(@assignment_schedule), params: { assignment_schedule: { assignment_number: @assignment_schedule.assignment_number, end_date: @assignment_schedule.end_date, start_date: @assignment_schedule.start_date } }
    assert_redirected_to assignment_schedule_url(@assignment_schedule)
  end

  test "should destroy assignment_schedule" do
    assert_difference('AssignmentSchedule.count', -1) do
      delete assignment_schedule_url(@assignment_schedule)
    end

    assert_redirected_to assignment_schedules_url
  end
end
