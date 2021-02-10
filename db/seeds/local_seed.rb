def create_full_assignment assignment, essays, users
  if assignment.save
    assignment_schedule = AssignmentSchedule.new(
      start_date: (Time.now - 2*(60 * 60 * 24)),
      end_date: (Time.now - (60 * 60 * 24)),
      stage: AssignmentSchedule.stages[:Primera],
      assignment: assignment)
    if assignment_schedule.save
      c = 1
      essays.zip(users).each do |e, u|
        attachment1 = Attachment.new(
          user: u,
          assignment_schedule: assignment_schedule,
          #essay: File.new("#{Rails.root}/public/system/attachments/essays/000/000/00#{c}/original/#{e}"),
          aux_name: SecureRandom.hex(3) + '.docx',
        )
        unless attachment1.save
          puts attachment1.errors.full_messages.to_s
        end
        c += 1
      end
    end
    assignment_schedule2 = AssignmentSchedule.new(
      start_date: (Time.now - 2*(60 * 60 * 24)),
      end_date: (Time.now + (60 * 60 * 24)),
      stage: AssignmentSchedule.stages[:Segunda],
      assignment: assignment)
    if assignment_schedule2.save
      AssignmentSchedule.random_attachment_assignment assignment_schedule2
    end
  end
  return assignment_schedule2
end
user1 = User.new(email: 'admin@limerick.cl', password: 'ORGA_2021')
user1.add_role(:admin)
user1.save
user2 = User.new(email: 'b@b.cl', password: '123456', alumni_number: "14630000")
user3 = User.new(email: 'c@c.cl', password: '123456', alumni_number: "14631111")
user4 = User.new(email: 'd@d.cl', password: '123456', alumni_number: "14632222")
user5 = User.new(email: 'e@e.cl', password: '123456', alumni_number: "14633333")

if user2.save && user3.save && user4.save && user5.save
  puts "Usuarios creados correctamente"
else
  puts user2.errors.full_messages.to_s
end
assignment = Assignment.new(number: 1)
assignment2 = Assignment.new(number: 2)
essays = ["ensayo1.docx", "ensayo2.docx", "ensayo3.docx"]
users = [user2, user3, user4]
assignment_schedule2 = create_full_assignment assignment, essays, users
# create_full_assignment assignment2, essays, users
correction1 = Correction.new(
  corrector_id: user2.id,
  corrected_id: user3.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2
)
correction11 = Correction.new(
  corrector_id: user2.id,
  corrected_id: user4.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2

)
correction2 = Correction.new(
  corrector_id: user3.id,
  corrected_id: user4.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2
)
correction22 = Correction.new(
  corrector_id: user3.id,
  corrected_id: user2.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2

)
correction3 = Correction.new(
  corrector_id: user4.id,
  corrected_id: user2.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2

)
correction33 = Correction.new(
  corrector_id: user4.id,
  corrected_id: user3.id,
  score: rand(1..10),
  assignment_schedule: assignment_schedule2

)
correction1.save
correction2.save
correction3.save
correction11.save
correction22.save
correction33.save
AssignmentSchedule.create_reverse_corrections assignment_schedule2
