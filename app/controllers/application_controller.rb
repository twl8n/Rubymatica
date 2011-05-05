# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def test
    
    db = SQLite3::Database.new("/home/twl8n/aims_1/am_ruby/test.db");
    @recs = Recs.new()

    @row_class = ""
    columns = nil
    @output = foo

    db.execute2( "select * from meta" ) do |row|
      if (columns.nil?)
        columns = row
      else
        # process row by creating a hash
        rh = Hash.new
        columns.each_index { |xx|
          # @output = @output + "key #{columns[xx]} value ${row[xx]}<br>\n";
          rh[columns[xx]] = row[xx]
        }
        # @output = @output + "adding #{rh.inspect}<br>\n";
        @recs.add(rh)
      end
    end
  end


end
