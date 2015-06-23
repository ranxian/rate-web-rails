require 'sidekiq/web'

Rails.application.routes.draw do
  get 'home/index'
  get 'home/show'
  get 'users/show'
  get '/icb2015' => 'icb#show', as: :icb
  get '/worker_heartbeat' => 'admin#worker_heartbeat'

  resources :tasks do
    member do
      get 'rerun'
      get 'continue_task'
      get 'update_from_server'
      get 'stop'
    end
  end

  resources :algorithms do
    member do
      get 'remove_writer'
      get 'remove_reader'
      get 'add_writer'
      get 'add_reader'
      get 'publish'
      get 'unpublish'
      get 'check_result'
    end
  end
  
  resources :benches do
    member do
      get 'progress'
      get 'remove_writer'
      get 'remove_reader'
      get 'add_writer'
      get 'add_reader'
      get 'publish'
      get 'unpublish'
    end
  end
  resources :views do
    member do
      get 'browse'
      get 'progress'
      get 'remove_writer'
      get 'remove_reader'
      get 'add_writer'
      get 'add_reader'
      get 'publish'
      get 'unpublish'
    end
  end
  devise_for :users
  root to: "home#show"

  controller :database do
    get 'database' => 'database#index'
    get 'database/import' => 'import'
    post 'database/browse' => 'browse'
    get 'database/browse_by_query' => 'browse_by_query'
    post 'database/do_import' => 'do_import'
  end

  controller :admin do
    get 'admin' => 'admin#index'
    get 'admin/task_list' => 'task_list'
    get 'admin/add_task' => 'add_task'
    get 'admin/remove_task' => 'remove_task'
    get 'admin/machines' => 'machines'
    get 'admin/shutdown_all_machines' => 'shutdown_all_machines'
    post 'admin/upload_worker' => 'upload_worker'
  end

  mount Sidekiq::Web, at: "/sidekiq"
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
