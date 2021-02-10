require 'json'

ActiveRecord::Base.transaction do
  user1 = User.new(email: 'admin@limerick.cl', password: 'ORGA_2021')
  user1.add_role(:admin)
  user1.save
  assignment = Assignment.new(number: 1)
  assignment.save
  assignment_schedule =
    AssignmentSchedule.new(
      start_date: Time.now,
      end_date: DateTime.new(2020,3,16,10,0,0, '-03:00'),
      stage: AssignmentSchedule.stages[:Primera],
      assignment: assignment)
  assignment_schedule.save
  file = File.read("#{Rails.root}/lib/output.json")
  users = JSON.parse(file)
  p users.count
  user_password = {}
  users.each do |u|
    generated_password = Devise.friendly_token.first(8)
    user = User.new(
      name: u["name"],
      last_name: u["last_name"],
      email: u["email"],
      alumni_number: u["alumni_number"],
      password: generated_password
    )
    if user.save
      user_password[u["email"]] = generated_password
    else
      p user.email, user.errors.full_messages.to_s
    end
  end
  File.open("#{Rails.root}/lib/passwords.json","w") do |f|
    f.write(JSON.pretty_generate(user_password))
  end
end
