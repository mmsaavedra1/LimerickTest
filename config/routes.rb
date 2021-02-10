Rails.application.routes.draw do

  get 'faq', to: 'faq#index'

  devise_for :users, :skip => [:registrations]
  root to: 'passthrough#index'
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end
  resources :assignments, except: [:index, :show]
  resources :assignment_schedules do
    member do
      get :send_notifications
    end
  end
  resources :audit, except: [:show]
  resources :corrections, except: [:show]
  resources :correction_reviews

  get '/etapas', to: 'assignment_schedules#first_stage'
  get '/etapas/1', to: 'assignment_schedules#first_stage'
  get '/etapas/2', to: 'assignment_schedules#second_stage'
  get '/etapas/3', to: 'assignment_schedules#third_stage'
  # get '/etapas/4', to: 'assignment_schedules#fourth_stage', as: 'fourth_stage'

  get '/assignments/', to: 'assignments#essays'
  get '/assignments/essays', to: 'assignments#essays'
  get '/assignments/corrections', to: 'assignments#corrections'
  get '/assignments/:number/essays', to: 'assignments#show_essays'
  get '/assignments/:number/corrections', to: 'assignments#show_corrections'
  get '/assignments/:number/second_stage_corrections/:assignment_schedule_id', to: 'assignments#second_stage_corrections'
  get '/assignments/:number/third_stage_corrections/:assignment_schedule_id', to: 'assignments#third_stage_corrections'

  post '/assignment_schedules/second_corrections/:id', to: 'assignment_schedules#assign_second_stage_corrections', as: :assign_second_corrections
  post '/assignment_schedules/third_corrections/:id', to: 'assignment_schedules#assign_third_stage_corrections', as: :assign_third_corrections

  post '/attachments/uploadFile', to: 'attachments#upload_file'
  post '/attachments/uploadSecondCorrection', to: 'attachments#upload_second_stage_correction'
  post '/attachments/uploadThirdCorrection', to: 'attachments#upload_third_stage_correction'
  get '/attachments/downloadFile', to: 'attachments#download_file'
  get '/attachments/ajax_download', to: 'attachments#ajax_download'

  get '/audit/not_corrected', to: 'audit#not_corrected'
  get '/audit/final_scores', to: 'audit#final_scores'

  namespace :admin do
    resources :assignments, param: :number do
      collection do
        get :correction_reviews, to: "assignment_schedules#fourth_stage"
      end
      resources :correction_reviews
    end
  end
end
