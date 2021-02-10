require "csv"

###### INSTRUCCIONES #######
# rails c
# Crear assignment_users:
# (9..12).each do |number|
#   AssignmentUser.update_users_status(number)
# end
# load 'lib/subir_planillas.rb'
# print_resumen('lib/2020_X/<name>.csv')

def print_resumen(file_name)
  extracted_data = {}
  table = CSV.read(file_name, headers: true)
  errors = ""
  good_shit = ""
  warnings = ""
  errors_counter = 0
  good_shit_counter = 0
  warnings_counter = 0
  current_essay_number = 0
  ncs_counter = 0
  lesswan_counter = 0
  counters_text = ""
  table.each do |student_scores|
    essay_number = student_scores["essay_number"].to_i
    if essay_number != current_essay_number
      if current_essay_number != 0
        counters_text += "Resumen e#{current_essay_number}: ncs => #{ncs_counter}, lesswan => #{lesswan_counter}\n"
      end
      ncs_counter = 0
      lesswan_counter = 0
      current_essay_number = essay_number
    end
    alumni_number = student_scores["alumni_number"]
    e1_s1 = cast_score(student_scores["e2_s1"])
    e1_s2 = cast_score(student_scores["e2_s2"])
    adjustment = cast_score(student_scores["adjustment"])
    teacher_assistant_comments = student_scores["comments"]
		# Mal nombre de variable, se obtienen todas las correcciones asignadas a un usuario especifico
		# en la segunda etapa
		# Se hace match entre corrections.corrected_id = assignment_users.user_id para que aparezcan
    # solo usuarios que participaron en el ensayo
    limerick_students_corrections_in_essay = Correction
                                      .joins(assignment_schedule: [assignment: [assignment_users: :user]])
                                      .eager_load(corrected: :assignment_users)
                                      .where("users.alumni_number = ? and
                                        assignment_schedules.stage = ? and
                                        number = ? and
                                        corrections.corrected_id = assignment_users.user_id",
                                        alumni_number, 1, essay_number)
    if limerick_students_corrections_in_essay.count != 2
      errors += "Bad query for #{alumni_number} on e#{essay_number}, it found #{limerick_students_corrections_in_essay.count} corrections instead of two\n"
    end
    lesswan_count = limerick_students_corrections_in_essay.where(score: -1).count
    nc_count = limerick_students_corrections_in_essay.where(score: nil).count
		##### START mover a helper ####
    # extracted_data retorna la cuenta de cuantos mu y nc se pillaron en cada ensayo para luego comparar.
    if !extracted_data.include?(essay_number)
      extracted_data[essay_number] = {}
    end
    if !extracted_data[essay_number].include?("lesswan")
      extracted_data[essay_number]["lesswan"] = lesswan_count
      extracted_data[essay_number]["nc_count"] = nc_count
    else
      extracted_data[essay_number]["lesswan"] += lesswan_count
      extracted_data[essay_number]["nc_count"] += nc_count
    end
		##### END mover a helper ####
    excluded_ids = []
    [e1_s1, e1_s2].each do |excel_score|
      # Dame todas las correcciones que sean iguales a la nota de la planilla y sobre las que aun no haya iterado (excluded ids)
      matching_corrections = limerick_students_corrections_in_essay.where("score = ?", excel_score).where.not(id: excluded_ids)
			# Si esque tengo un -1 en el excel y fue encontrado en las correcciones del alumno
			# TODO Revisar caso cuando es MU doble, por ende, el score_delta esta x2
      if excel_score == -1 && !matching_corrections.empty?
        matching_corrections.each do |corr|
          #Crear correction_review para una sola de las correcciones si el alumno completo el proceso y si no tiene un ajuste ya hecho
          if corr.corrected.completed_process?(essay_number) && corr.correction_review.nil?
            if adjustment >= 0
							# Si el ajuste de la planilla es mayor a 0 busca la cuarta etapa de ese ensayo para crearle una CR
              assignment_schedule = corr.assignment_schedule.assignment.assignment_schedules.find_by(stage: 3)
              cr = CorrectionReview.new(reviewer_id: 1, correction_id: corr.id, assignment_schedule_id: assignment_schedule.id, score_delta: adjustment, student_comment: "Reajuste por -1", reviewer_comment: teacher_assistant_comments)
              if cr.save
                good_shit += "NOTICE: Se crea CR con puntaje #{adjustment}, ass_sch_id: #{assignment_schedule.id} para lesswan de #{alumni_number} en #{essay_number}\n"
                good_shit_counter += 1
              else
                errors += "ERROR: No se pudo crear CR  con puntaje #{adjustment}, ass_sch_id: #{assignment_schedule.id} para lesswan de #{alumni_number} en #{essay_number} por #{cr.errors.messages}\n"
                errors_counter += 1
              end
            else
              errors += "ERROR: No se pudo crear CR porque hay puntaje negativo en la planilla: #{adjustment} para #{alumni_number} en e#{essay_number} \n"
              errors_counter += 1
            end
          elsif !corr.corrected.completed_process?(essay_number)
            warnings += "WARNING: NO se crea CR para lesswan de #{alumni_number} en #{essay_number} porque no completo las tres etapas o fue baneado\n"
            warnings_counter += 1
          elsif corr.corrected.completed_process?(essay_number) && !corr.correction_review.nil?
            warnings += "WARNING: Alumno #{alumni_number} envio a recorregir su -1 de e#{essay_number} con puntaje #{corr.correction_review.score_delta} por lo que no se deberia hacer nada. Revisar su CR si fue corregido correctamente.\n"
            warnings_counter += 1
          end
          lesswan_counter += 1
          excluded_ids << corr.id
          break
        end
      # Si esque no la encuentra es indicio de error o que hay un NC, si hay una nota igual al reemplazo del NC en la planilla pasa al else
			# Aqui debería entrar si esque hay un NC en la DB porque el NC se reemplazo en el excel y el valor de la planilla no esta en la db
      elsif excel_score != -1 && matching_corrections.empty?
        nc = limerick_students_corrections_in_essay.find_by(score: nil)
				# Revisar si efectivamente hay un NC
        if !nc.nil?
					# Dado que hay un NC revisemos si mando a recorregirlo
          if nc.correction_review.nil?
            #Dado que no lo recorrigio le vamos a crear un correction_review si completo el proceso
            if nc.corrected.completed_process? essay_number
              assignment_schedule = nc.assignment_schedule.assignment.assignment_schedules.find_by(stage: 3)
              cr = CorrectionReview.new(reviewer_id: 1, correction_id: nc.id, assignment_schedule_id: assignment_schedule.id, score_delta: excel_score,  student_comment: "Reajuste por NC", reviewer_comment: teacher_assistant_comments)
              if cr.save
                good_shit += "NOTICE: Se crea CR con puntaje #{excel_score}, ass_sch_id: #{assignment_schedule.id} para NC de #{alumni_number} en #{essay_number}\n"
                good_shit_counter += 1
              else
                errors += "ERROR: No se pudo crear CR con puntaje #{excel_score}, ass_sch_id: #{assignment_schedule.id} para NC de #{alumni_number} en #{essay_number} por #{cr.errors.messages}\n"
                errors_counter += 1
              end
            else
              warnings += "WARNING: NO se crea CR para NC de #{alumni_number} en #{essay_number} por baneado\n"
              warnings_counter += 1
            end
            ncs_counter += 1
            excluded_ids << nc.id
          else
            warnings += "WARNING: Alumno #{alumni_number} envio a recorregir su NC de #{essay_number} por lo que no se deberia hacer nada\n"
            warnings_counter += 1
          end
        # Error
        else
          errors += "ERROR: Deberia haber un NC pero no lo hay: #{alumni_number} on e#{essay_number}, score: #{excel_score.nil? ? 'nil' : excel_score}, e1_s1: #{e1_s1}, e1_s2: #{e1_s2}, excluded_ids: #{excluded_ids}, #{limerick_students_corrections_in_essay.pluck(:score)} \n"
          errors_counter += 1
        end
      elsif excel_score == -1 && matching_corrections.empty?
        errors += "ERROR: Deberia haber un -1 pero no lo hay: #{alumni_number} on e#{essay_number}\n"
        errors_counter += 1
			# Si excel_score != -1 && !matching_corrections.empty? significa que quizas ya fue excluido
      else
        matching_corrections.each do |corr|
          excluded_ids << corr.id
          break
        end
      end
    end
  end
  counters_text += "Resumen e#{current_essay_number}: ncs => #{ncs_counter}, lesswan => #{lesswan_counter}\n"
  print errors
  print warnings
  print good_shit
  print counters_text
  p "Success: #{good_shit_counter}"
  p "Errors: #{errors_counter}"
  p "Warnings: #{warnings_counter}"
end

def cast_score score
  if score == "MU"
    return -1
  end
  return score.gsub(",", ".").to_f
end
