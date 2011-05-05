ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  # This works, at lease for http://localhost:3030/
  map.root :controller  => "hello_world",  :action => "report"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.  Note: These
  # default routes make all actions in every controller accessible via
  # GET requests. You should consider removing or commenting them out
  # if you're using named routes and resources.

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  # Works in Rails 2. Will be different in Rails 3.
  map.connect ':action/:id', :controller => 'hello_world'

  # This worked, but was been replaced by the single line above.

  # map.connect '/file_list', :controller => 'hello_world', :action => 'file_list'
  # map.connect '/report', :controller => 'hello_world', :action => 'report'
  # map.connect '/reset', :controller => 'hello_world', :action => 'reset'
  # map.connect '/process_sip', :controller => 'hello_world', :action => 'process_sip'
  # map.connect '/show_logs', :controller => 'hello_world', :action => 'show_logs'
  # map.connect '/get_file', :controller => 'hello_world', :action => 'get_file'
  # map.connect '/get_log_xml', :controller => 'hello_world', :action => 'get_log_xml'
  # map.connect '/full_status', :controller => 'hello_world', :action => 'full_status'
  # map.connect '/offer_upload', :controller => 'hello_world', :action => 'offer_upload'
  # map.connect '/do_upload', :controller => 'hello_world', :action => 'do_upload'
  # map.connect '/build_bag', :controller => 'hello_world', :action => 'build_bag'
  # map.connect '/offer_import_meta', :controller => 'hello_world', :action => 'offer_import_meta'
  # map.connect '/import_meta', :controller => 'hello_world', :action => 'import_meta'
  # map.connect '/update_taper', :controller => 'hello_world', :action => 'update_taper'
  # map.connect '/show_puid_list', :controller => 'hello_world', :action => 'show_puid_list'
  # map.connect '/update_puid_list', :controller => 'hello_world', :action => 'update_puid_list'


end
