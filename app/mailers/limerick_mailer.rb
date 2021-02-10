class LimerickMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views
  default from: 'help@limerick.cl'

  def send_new_user_password(user, pass)
    @user = user
    @pass = pass
    mail(:to => user.email, :subject => "[Limerick] Usuario & Contraseña.")
  end

  def send_correction_reminder(user, stage)
    @user = user
    @stage = stage
    mail(:to => user.email, :subject => "[Limerick] Recordatorio correcciones.")
  end

  def send_upload_attachment_reminder(user)
    @user = user
    mail(:to => user.email, :subject => "[Limerick] Recordatorio para subir tu ensayo.")
  end

  def send_correction_reminder_notification(user, conteo_alumnos)
    @user = user
    @conteo_alumnos = conteo_alumnos
    mail(:to => user.email, :subject => "[Limerick] Recordatorio para subir correcciones.")
  end

  def send_attachment_reminder_notification(user, conteo_alumnos)
    @user = user
    @conteo_alumnos = conteo_alumnos
    mail(:to => user.email, :subject => "[Limerick] Recordatorio para subir ensayos.")
  end

  def send_first_schedule_notification(user)
    @user = user
    mail(:to => user.email, :subject => "[Limerick] Notificación de apertura de la primera etapa.")
  end

  def send_second_schedule_notification(user)
    @user = user
    mail(:to => user.email, :subject => "[Limerick] Notificación de apertura de la segunda etapa.")
  end

  def send_third_schedule_notification(user)
    @user = user
    mail(:to => user.email, :subject => "[Limerick] Notificación de apertura de la tercera etapa.")
  end
end
