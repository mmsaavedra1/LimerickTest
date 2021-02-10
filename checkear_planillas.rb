#print JSON.pretty_generate(Assignment.get_all_essays_nc_mu(limit: 4))

limerick = [
      "17642094",
      "17643163",
      "16639855",
      "17626951",
      "17637287",
      "1662503J",
      "18642845",
      "1721064J",
      "17640458",
      "18639372",
      "17638674",
      "16639448",
      "17625084",
      "1663795J",
      "17625211",
      "15624161",
      "12636932",
      "15635341",
      "12637432",
      "16210336",
      "17625912",
      "15639045",
      "15624161",
      "19201478",
      "12637432",
      "17643082",
      "17625084",
      "18637191"
    ]

excel = ["12636932", "12637432", "15624161", "15635341", "15639045", "16210336", "1662503J", "1663795J", "16639448", "16639855", "1721064J", "17625084", "17625211", "17625912", "17626951", "17637287", "17638674", "17640458", "17642094", "17643082", "17643163", "18637191", "18639372", "18642845", "19201478", ]






spreadsheet_db_nc_mu_comparison(limerick, excel)

def spreadsheet_db_nc_mu_comparison(limerick, excel)
  errors = 0
  limerick.each do |ai|
    if !excel.include? ai
      p "El excel no incluye a #{ai}, esto quiere decir que falta buscarlo en la planilla"
      errors += 1
    end
  end
  excel.each do |ai|
    if !limerick.include? ai.to_s
      p "En limerick no aparece #{ai}, revisar el caso en Limerick"
      errors += 1
    end
  end
  if errors == 0
    p "TODO OK"
  end
end











# spreadsheet_db_nc_mu_comparison(limerick, excel)

#no se para que es
def helpers
  Correction.joins(corrected: :assignment_users).where("(score IS NULL or score = -1) AND status = 3").count
  Correction.joins(assignment_schedule: :assignment).where("assignments.number IN (?) and assignment_schedules.stage = ? and (score is NULL or score = -1)", [1,2,3,4,5,6,7], AssignmentSchedule.stages[:Segunda]).count
  Correction.joins(assignment_schedule: :assignment).where("assignments.number IN (?) and assignment_schedules.stage = ? and score is NULL", [1,2,3,4,5,6,7,8], AssignmentSchedule.stages[:Tercera]).count
end

{
  "e9" => {
          :all => [
         [0] "17637732",
         [1] "16638093",
         [2] "16206940"
     ],
           :nc => [],
           :mu => [
         [0] "17637732",
         [1] "16638093",
         [2] "16206940"
     ],
     :nc_count => 0,
     :mu_count => 3
  },
  "e10" => {
          :all => [
         [0] "17641349",
         [1] "12636347",
         [2] "17637546"
     ],
           :nc => [
         [0] "17641349",
         [1] "12636347"
     ],
           :mu => [
         [0] "17637546"
     ],
     :nc_count => 2,
     :mu_count => 1
  },
  "e11" => {
          :all => [
         [0] "16623827",
         [1] "17643104",
         [2] "17638399",
         [3] "17637163",
         [4] "17627885",
         [5] "17643295"
     ],
           :nc => [
         [0] "16623827",
         [1] "17643104",
         [2] "17638399",
         [3] "17637163",
         [4] "17627885",
         [5] "17643295"
     ],
           :mu => [],
     :nc_count => 6,
     :mu_count => 0
  },
  "e12" => {
          :all => [
         [0] "16638093",
         [1] "17642221"
     ],
           :nc => [
         [0] "16638093",
         [1] "17642221"
     ],
           :mu => [],
     :nc_count => 2,
     :mu_count => 0
  }
}
