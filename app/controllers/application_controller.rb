class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => 'No tienes permisos para ver este contenido'
  end
  require 'zip'

  def zip_download attachments, file, correction
    filename = "#{Rails.root}/public/" + file
    begin
      Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
        attachments.each do |f|
          begin
            name, dot, extension = f.essay_file_name.rpartition(".")
            if !correction
              zipfile.add("E#{f.assignment_schedule.assignment_number}_#{f.user.alumni_number}.#{extension}", f.essay.path)
            else
              zipfile.add("A#{f.correction.corrected.alumni_number}_C#{f.user.alumni_number}_#{f.correction.score}.#{extension}" , f.essay.path)
            end
          rescue Zip::EntryExistsError
            name, dot, extension = f.essay_file_name.rpartition(".")
            if !correction
              zipfile.add("E#{f.assignment_schedule.assignment_number}_#{f.user.alumni_number}(1).#{extension}", f.essay.path)
            else
              zipfile.add("A#{f.correction.corrected.alumni_number}_C#{f.user.alumni_number}_#{f.correction.score}(1).#{extension}", f.essay.path)
            end
          end
        end
      end
      zip_data = File.read(filename)
      send_data(zip_data, :type => 'application/zip', :filename => file)
    ensure
      FileUtils.rm_rf(Dir.glob(filename))
    end
  end

  def xlsx_stream(data, sheet_name, io)
    xlsx = Xlsxtream::Workbook.new(io)
    xlsx.write_worksheet sheet_name do |sheet|
      data.each do |row|
        sheet << row
      end
    end
    xlsx.close
    io.close
    xlsx
  end


end
