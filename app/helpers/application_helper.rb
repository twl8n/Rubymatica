# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # nov 23 2010 When the menu was removed from offer_upload.html.erb,
  # it was no longer necessary to generate options for the select.

  # def ah_options

  #   # At least @ vars from hello_world_controller.rb are visible
  #   # here. For now it is find just being hard coded, but as soon as
  #   # this needs more flexibility, or needs to be generalized, it will
  #   # have to change.
    
  #   # puts @menu_items
    
  #   # The values are hard coded in save_file() in
  #   # hello_world_controller.rb. Don't change the values without
  #   # fixing the other code.

  #   options_for_select([["Ingest", "1"],[ "Metadata", "2"]], ["1"])
  # end

end
