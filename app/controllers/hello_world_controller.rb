
# Copyright 2011 University of Virginia
# Created by Tom Laudeman

require 'sqlite3'

# If you change rubymatica.rb, you must stop and restart the webrick
# server. Nither load nor require work to load the external file
# automatically.

require 'rubymatica'
include Rmatic

class Recs   
  # Used by test/example code below. Not required by Rubymatica.
  def initialize
    @recs = []
  end
  
  def add(rec)
    @recs << rec
  end
  
  def get
    return @recs
  end
  
  def get_binding
    binding
  end
end

# This class has all the methods to service the Rails web pages, as
# well as a plethora of support methods. Some of the support code
# should probably be moved to rubymatica.rb. I've generally tried to
# keep web page specific code here, and general code that doesn't know
# about rendering and display over tin rubymatica.rb.

class HelloWorldController < ApplicationController

  # The request object used by get_remote_addr is not defined until
  # after initialization. doing a "def initialize" didn't work. "def
  # after_initialize" didn't work.  before_filter does work. Given
  # that the "request" object is available in the working code, we
  # conclude that before_filter must have run after whatever object
  # initialization takes place. Finding docs for this behavior is
  # impossible.

  before_filter :my_init
  
  # Some code may chdir, so we need to bake in the path to the msg
  # database. This is a small downside of SQLite and saving a db in
  # each ingest. If there were one, large client-server db, we
  # wouldn't need the path (but we'd have other admin overhead).

  def my_init
    # see rubymatica.rb for class def 
    @mdo = Msg_dohicky.new(get_remote_addr, Script_path)
  end

  # Create a list-of-hash for the Droid PUID categories. Ideally this
  # would be in the puid.db, but this is quick, and when there is a
  # db, the guts of this method can change over to using the db, and
  # the change will be transparent to code that calls this method. We
  # use list here in order to have a fixed order of the labels and
  # cagetories. This order is used in the show_puid_list.html.erb web
  # page, but is not yet used in the file_list.html.erb page.

  def categories_list
    cat_order = []
    cat_order.push({'label'=>'img', 'value'=>'still image'})
    cat_order.push({'label'=>'mov', 'value'=>'moving image'})
    cat_order.push({'label'=>'snd', 'value'=>'sound'})
    cat_order.push({'label'=>'text', 'value'=>'textual'})
    cat_order.push({'label'=>'exe', 'value'=>'executable'})
    cat_order.push({'label'=>'email', 'value'=>'email'})
    cat_order.push({'label'=>'data', 'value'=>'data'})
    cat_order.push({'label'=>'oth', 'value'=>'other'})
    # push(cat_order, {'label'=>'', 'value'=>''})
    return cat_order
  end

  # This is a simple data retrieval method called from
  # show_puid_list() and file_list(). The pfn really could be hard
  # coded. There is only one db, and it is in the same location for a
  # given installation.

  def puid_list(pfn)
    db = SQLite3::Database.new(pfn)
    db.transaction
    stmt = db.prepare("select * from puid_info order by format_id")
    # see rubymatica.rb for class def 
    ps = Proc_sql.new()
    stmt.execute() { |rs|
      ps.chew(rs)
    }
    stmt.close

    # This never had a commit and there have been no errors. We don't
    # need to commit because the query is read-only. The database
    # driver seems forgiving in that we started a transaction and
    # never explicitly did a rollback or commit. We have an implicit
    # rollback.

    db.close()
    return ps;
  end


  # Show the web page for the PUID category editor. Simply read all
  # the PUID data from the db, and send the erb a list of hashes.

  def show_puid_list
    pfn = "#{Script_path}/#{Puid_db}"

    if (! File.exists?(pfn))
      @mdo.set_message("No PUID list database", true)
      redirect_to :action => 'report'
      return
    end

    ps = puid_list(pfn)
    @loh = ps.loh()

    @cat_order = categories_list()
    
  end


  # Save the results of the PUID category editor back to the db. The
  # params keys for our database fields have a number on the end so we
  # can recognize them with a regex.

  def update_puid_list
    pfn = "#{Script_path}/#{Puid_db}"

    if (! File.exists?(pfn))
      @mdo.set_message("No PUID list database", true)
      redirect_to :action => 'report'
      return
    end

    # Could use a transaction block below, and we wouldn't need an
    # explicit db.commit().
    # http://sqlite-ruby.rubyforge.org/sqlite3/classes/SQLite3/Database.html

    db = SQLite3::Database.new(pfn)
    db.transaction()
    stmt = db.prepare("update puid_info set rmatic_category=? where puid=?")
    params.keys.each { |key|
      if (key.match(/.+\/\d+/))
        # print "pp: #{key} set to: " +  params[key] + "\n";
        stmt.execute(params[key], key)
      else
        # print "skipping: #{key} " +  params[key] + "\n";
      end
    }
    stmt.close
    db.commit()
    db.close()
    @mdo.set_message("PUID categories updated.", true)
    redirect_to :action => 'report'
  end


  # Top level method to build the bagit bag. This is just a wrapper to
  # connect Rails and the Ruby method that does the real work.

  def build_bag
    uuid = params[:uuid]
    dir_uuid = "#{Dest}/#{uuid}"
    create_bag(dir_uuid, @mdo)
    redirect_to :action => 'report'
  end

  # Utility methods related to our http session.

  def get_remote_host
    return request.remote_host
  end
  
  def get_remote_addr
    return request.remote_addr
  end
  
  def my_server_port
    return request.server_port
  end


  # Create a web page allowing files to be moved from the origin
  # directory to the meta_data directory of a given ingest. Read the
  # list of files from dir Origin, and offer links to move files to
  # the meta_data dir for the current uuid.

  def offer_import_meta
    @uuid = ""
    if (params.has_key?(:uuid))
      @uuid = params[:uuid]
    else
      @mdo.set_message("No uuid. Can't move files.", true)
      redirect_to :action => 'report'
      return;
    end

    orig_list = `find #{Origin} -maxdepth 1 -mindepth 1  -print`.split("\n")

    bgcolor = '#EEEDFD'
    color_toggle = true
    
    @f_info = [] 
    orig_list.sort.each { |file|
      rh = Hash.new
      rh[:orig] = File.basename(file)
      rh[:name] = "n/a"
      rh[:dirs] = []
      rh[:mets] = ""
      if (color_toggle)
        color_toggle = false
      else
        color_toggle = true
        rh[:bgcolor] = bgcolor
      end
      @f_info.push(rh);
    }
  end


  # Do work, don't generate a web page. This does the actual copy of
  # the meta data from origin to meta_data dir of an ingests. No web
  # page is generated, and we redirect back to report when
  # finished. Since this doesn't generate a web page, it might make
  # sense to move the bulk of the body of this method into a new
  # method in rubymatica.rb.

  def import_meta
    uuid = ""
    name = ""
    if (params.has_key?(:uuid))
      uuid = params[:uuid]
    end
    if (params.has_key?(:name))
      name = params[:name]
    end

    if (name.empty? || uuid.empty?)
      @mdo.set_message("Name or uuid is missing. Can't move files.", true)
      redirect_to :action => 'report'
      return;
    end
    orig = "#{Origin}/#{name}"
    dest = "#{Dest}/#{uuid}/#{Meta}/#{name}"
    dest_dir = "#{Dest}/#{uuid}/#{Meta}"

    if (File.exists?(orig) && File.exists?(dest_dir))
      FileUtils.mv(orig, dest)
      puts "FileUtils.mv(#{orig}, #{dest})\n"
      @mdo.set_message("Imported \"#{name}\" into meta_data.", true)
    else
      @mdo.set_message("#{orig} or #{dest_dir} does not exist.a", true)
    end

    redirect_to :action => 'report'

  end


  # The next 3 methods are all upload related stuff: offer_upload,
  # thank_upload, save_file. Based on this example:

  # http://www.tutorialspoint.com/ruby-on-rails/rails-file-uploading.htm
  
  # Why Ruby/Rails does not rock: http://www.ruby-forum.com/topic/136377
  
  # Rails will default to rendering method.html.erb. (See note 1
  # below.) This code works whcih is interesting. We could put our
  # views (aka templates) anywhere we want, and use any names we
  # want. Who knew? Possible problem with render: changing the erb
  # seems to require a restart of webrick for the changes to happen.
  
  # http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html
  
  # note 1 Nov 11 2010 Rails does simply render the method.html.erb,
  # and while the code below mostly worked (before I commented it
  # out), if some other method did a chdir, the code below
  # broke. Normal rails rendering works even after chdir, so this
  # method which only draws a web page can be empty.

  # http://rails.brentsowers.com/2007/11/using-selecttag-to-make-form-select.html

  def offer_upload
    # An @ var created here is visible insize ah_options() over in
    # application_helper.rb. For now it is hard coded, but could be
    # generalized later without too much trouble.

    # @menu_items = ["xingest", "xmeta"]

    #@upload = {}
    @ig_dir = ""
    @uuid = ""
    if (params.has_key?(:uuid))
      #@upload['uuid'] = params[:uuid]
      @uuid = params[:uuid]
    end
    if (params.has_key?(:dir))
      @ig_dir = params[:dir]
    end

    # See notes above.
    
    # render :file => 'app/views/hello_world/offer_upload.html.erb'
  end

  # We have ActiveRecord::Base which includes the original_filename()
  # method. From this I conclude that ApplicationController inherits
  # ActiveRecord::Base. Since this code works in Rails, we can
  # conclude that it is not necessary to define a new:

  # class DataFile < ActiveRecord::Base

  # We must have a method save_file, however it works fine to have
  # that method in our controller class, therefore we don't need a new
  # class (as several examples on the WWW show).

  # Variables can be nil, "", or undefined. Add code to make sure
  # variables either have a value or "" so that downstream code won't
  # break. Perl doesn't have this problem. Perl rocks.

  # Might be able to use var.to_s.empty? which works with nil and
  # empty, but not with undefined. Or we could call .to_s on
  # everything that should be a string, even nil.to_s forces creation
  # of "". Perl rocks.

  # But wait! params[:upload] is some kind of file upload object, so
  # we don't dare set it to .to_s() so the downstream code is forced
  # to use upload.to_s.empty? to test it.

  def do_upload
    post = save_file(params[:upload], params[:uuid].to_s())

    # Move the upload success message to save_file, and use our
    # set_message() method.

    redirect_to :action => 'report'
  end

  # Fields 'upload' and 'datafile' must match offer_upload.html.erb.
  # Directory seems to be path relative to the base dir containing the
  # rails app, that is: ~/aims_1/am_ruby/. The body of this method
  # could be moved into do_upload since that is (currently) the only
  # place that every calls it.

  # If we have a uuid, then we're uploading to the meta_data area.

  # {"commit"=>"Upload",
  #  "uuid"=>"08fb057e-a522-420f-a2ca-291a564dd82a",
  #  "upload"=>#<File:/tmp/RackMultipart20101123-19603-1nhneoe-0>,
  #  "authenticity_token"=>"Vu42JJ0SOOHoAkiFT+T4vtVw7AYJqLLd3VFs1XJBnHc="}

  # If we only have a file name, then upload to the processing
  # origin directory.

  # {"commit"=>"Upload",
  #  "upload"=>#<File:/tmp/RackMultipart20101123-19603-1d8nnew-0>,
  #  "authenticity_token"=>"Vu42JJ0SOOHoAkiFT+T4vtVw7AYJqLLd3VFs1XJBnHc="}

  # do_upload() above makes sure that args to save_file() are never
  # nil. False or missing values are "".

  def save_file(upload, uuid)

    if (upload.to_s.empty?)
      @mdo.set_message("No file name so nothing was uploaded.", true)
      return 
    end

    name =  upload.original_filename
    base_name = File.basename(name)

    # Cleanse bad chars from file names.
    base_name.gsub!(/[^A-Za-z0-9\-_\.]/, '_')

    if (uuid.empty?)
      save_dir = Origin
      dir_label = "origin directory"
    else
      save_dir = "#{Dest}/#{uuid}/#{Meta}"
      dir_label = "meta_data directory"
    end

    if (! File.exists?(save_dir))
      @mdo.set_message("Directory #{save_dir} does not exist. File not saved.", true)
      return 
    end

    
    # Create the full file path
    # path = File.join(directory, name)
    # write the file
    File.open("#{save_dir}/#{base_name}", "wb") { |myupload|
      myupload.write(upload.read)
    }
    @mdo.set_message("File #{base_name} has been uploaded to #{dir_label}.", true)
  end


  # Draw a simple web page with the dump of the status for this
  # ingest. Status info comes from the info.db database in an given
  # ingest.

  def full_status
    uuid = params[:uuid]
    loh = Rubymatica.get_status(uuid)
    @all_text = "#{uuid}\n"
    loh.each { |hr|
      @all_text.concat("\n#{hr['date']} #{hr['msg']}")
    }
  end

  
  # Disabled. Used only during development. Clear out the SIP system
  # and add fresh ingest dirs to the origin.

  def reset
    redirect_to :action => 'report'

    # rm is too dangerous, but move stuff to the archive dir to clean
    # up. Use mv with -f to force overwrite and -b so that existing
    # dirs or files are renamed as backups.
    `mv --backup=t #{Dest}/* /home/#{ENV['USER']}/archive`;

    # Clean any stuff remaining in the origin folder too. Use mv with
    # -f to force overwrite.
    `mv --backup=t #{Origin}/* /home/#{ENV['USER']}/archive`;

    # Create 5 new test ingest dirs.

    [1,2,3,4,5].each { |xx|
      `cp -a /home/#{ENV['USER']}/ing_2 #{Origin}/ingest_#{xx}`
    }  
    `cp -a /home/#{ENV['USER']}/ing_1 #{Origin}/big_ingest_1`

    @mdo.set_message("Reset complete", false)
    redirect_to :action => 'report'
  end


  # Send a file to the web browser. Get METS.xml or bagit.zip
  # file. Prior to adding bagit.zip , it could have been generalized
  # with get_log_xml() below.
  # http://api.rubyonrails.org/classes/ActionController/Streaming.html

  def get_file
    uuid = params[:uuid]
    file = params[:file]
    
    # Here file only includes the basename, so no need to run basename.

    if ((md = file.match(/(Mets_file)/) ||
         md = file.match(Generic_xml)) &&
        File.exists?("#{Dest}/#{uuid}/#{Meta}/#{md[0]}"))
      @text = IO.read("#{Dest}/#{uuid}/#{Meta}/#{md[0]}")
      send_data(@text,
                :filename => md[1],
                :type => "text/xml",
                :disposition => "inline")
    elsif (file.match(Bagit_file) and File.exists?("#{Dest}/#{uuid}/#{Bagit_file}"))
      @text = IO.read("#{Dest}/#{uuid}/#{Bagit_file}")
      send_data(@text,
                :filename => Bagit_file,
                :type => "application/zip",
                :disposition => "attachment")
    else
      # This really needs a status message, since it will appear to
      # the user that the page just redraws.
      redirect_to :action => 'report'
    end
  end


  # Ugh. Duplication of some of get_file(), this one is specialized to
  # show xml from the ingest_logs dir.

  def get_log_xml
    uuid = params[:uuid]
    file = params[:file]
    full_path = "#{Dest}/#{uuid}/#{Ig_logs}/#{file}"
    if (file.match('xml') and File.exists?(full_path))
      @text = IO.read(full_path)
      send_data(@text,
                :filename => file,
                :type => "text/xml",
                :disposition => "inline")
    else
      # This really needs a status message, since it will appear to
      # the user that the page just redraws.
      redirect_to :action => 'report'
    end
  end


  # Does the real work calling back to process_one() from
  # rubymatica.rb. This does not generate a web page.

  def process_sip
    dir = params[:name]
    dir = File.basename(dir);

    pid = Process.fork;
    if (! pid)
      
      # Forking causes WEBrick to fork, and the child keeps
      # listening. WEBrick is so wrong, but I suspect that forking
      # inside mod_passenger also causes part (or all) of the http
      # server to fork. The exec() below seems to work better, but
      # there could be race conditions.

      # We need to run a script that is two dirs up from where we are
      # when running Rails. Find the absolute path and use it in the
      # exec() below.

      # Because we exec() the code we call won't have anything from
      # our env. So we have to send the port number over on the
      # command line. The port is used for the error log file name.

      # Rails controllers are two dirs down from the app top level
      # directory. Expanding a path that has "/../../" concatenated
      # seems to work, and seems portable in that is also works with
      # bash ls and pwd.

      pfn = File.expand_path(File.dirname(File.expand_path(__FILE__)) + "/../../")
      
      # Process.exec("#{Script_path}/process_sip.rb -i #{dir} -p #{request.server_port}")
      Process.exec("#{pfn}/process_sip.rb -i #{dir} -p #{request.server_port}")
    else
      Process.detach(pid)
    end
    @mdo.set_message("Processing started", true)
    redirect_to :action => 'report'
  end
  

  # Dump log files to a web page. XML files are linked to because they
  # need a different mime time to display as xml.

  def show_logs
    uuid = params[:uuid]
    dir = "#{Dest}/#{uuid}/#{Ig_logs}"
    @logs = ""
    Find.find(dir) { |file|
      if (file == dir)
        next;
      end
      @logs.concat("File: #{File.basename(file)}\n")

      # Easier to show XML in a new window, so create a link. Probably
      # better to move all this html to the erb, but this is quick and
      # easy.

      if (file.match(/\.xml/))
        @logs.concat("<a href=\"get_log_xml?uuid=#{uuid}&file=#{File.basename(file)}\">View XML</a>\n<hr>\n")
      elsif (file.match(/\.db/))
        @logs.concat("(sql database)<hr>\n")
      else
        temp = IO.read(file)
        @logs.concat("#{temp}\n<hr>\n")
      end
    }
  end


  # Build a web page. This creates 3 different reports on one web
  # page. The original was a simple dump of a list of files for a
  # given ingest. If we have a file name match, return the first match
  # which is [0] since matches are in an array (different from other
  # scripting languages where $1 is the first match).

  # Find.find requires a block, so one can't .sort.each. Just create a
  # list and push each item into the list. Then sort, and process as
  # usual.

  def file_list
    uuid = params[:uuid]
    dir = "#{Dest}/#{uuid}"
    @logs = ""
    flist = []
    
    FileUtils.cd(Dest) {
      Find.find(uuid) { |file|
        flist.push(file)
      }
    }
    
    # Only match in the meta_data directory, and then, only certain
    # files. get_file() is hard coded only to serve files from the
    # meta_data dir, so no point in matching anything else.

    # Also match bag.zip in the main directory. It might be smarter to
    # put bag.zip in the meta data directory, but bag.zip isn't meta
    # data so I'm resisiting the notion of moving bag.zip into the
    # meta data dir.

    flist.sort.each { |file|
      bname = File.basename(file)
      if ((file.match(Meta) &&
           (md = bname.match(Mets_file) ||
            md = bname.match(Generic_xml))) ||
          md = file.match("#{uuid}/#{Bagit_file}"))
        fn = md[0]
        # print "Found: #{fn}\n";
        @logs.concat("<a href=\"get_file?uuid=#{uuid}&file=#{fn}\">#{file}</a>\n")
      else
        @logs.concat("#{file}\n")
      end
    }

    # See rubymatica.rb. Returns a list of hash.

    @loh = Rubymatica.get_droid(uuid)

    # Build a new hash where the keys are rmatic_category from the db
    # and the value is the count of files in that category. Read the
    # PUID data from puid.db. Compare it to the list of hash from the
    # file list above. Variable ps is a processed SQL query
    # result. ps.loh() is a list-of-hash where there is one list
    # element per record, and the SQL fields become hash keys from each
    # record.

    # Variable @loh is a list-of-hash for the Droid file
    # identifications. rh is memnonic for "ruby hash" a generic
    # variable name. Look at each file and check it against each of
    # the PUID loh values looking for PUID matches. Increment the
    # counter for the PUID category variable when we get a hit.

    # Variable @cat_hash is an instance variable that is a
    # list-of-hash with one list element per PUID category. The key is
    # the category name and the value is the count of identified files
    # for that category.

    # This simplistic algo won't print categories with zero
    # entries. The web page simply does a .key.sort.each so the porder
    # of the categories will change if the category names are changed.


    @cat_hash = {}
    pfn = "#{Script_path}/#{Puid_db}"
    ps = puid_list(pfn)
    puid_loh = ps.loh()

    @file_total = 0
    @loh.each { |rh|
      puid_loh.each { |ph|
        if (rh['ext_id'].eql?(ph['puid']))
          if (@cat_hash[ph['rmatic_category']].to_s.empty?())
            @cat_hash[ph['rmatic_category']] = 1
          else
            @cat_hash[ph['rmatic_category']] += 1
          end
          @file_total += 1
        end
      }
    }
    
    # print "#{@cat_hash}\n";

  end


  # No web page. Modify the taper XML file for a given ingest. We only
  # modify a few fields, but we could modify more of the TAPER
  # fields. Rather than using Nokogiri, I just opted for the simpler
  # regexps. This method has several internal utility methods.

  def update_taper
    uuid = params[:uuid]
    file = "#{Dest}/#{uuid}/#{Meta}/#{Taper_file}"
    # see rubymatica.rb for class def 
    ingest_name = Ingest.new(uuid).read_meta("ingest_name")

    if (! File.exists?(file))
      @mdo.set_message("Cannot find #{Taper_file} for accession ingest #{ingest_name}.", true)
      redirect_to :action => 'report'
      return
    end

    # If we find <tag></tag> or <tag/> replace. Otherwise insert our
    # tag after </history> (by replacing </history> with itself plus
    # our tag). If there are multiple tags, fix the first and delete
    # the rest.

    # Note: in normal gsub!() you must use '\1' for the first captured
    # expression, but in the looping version you must use $1 or "#{$1}"

    # We use the loop version of gsub!() so that we can have different
    # logic for the first substitution, vs subsequent substitions.

    def mod_tag(txml, tag, new_value)
      if (txml.match(/<#{tag}>.*?<\/#{tag}>/))
        flag = true
        txml.gsub!(/(<#{tag}>).*?(<\/#{tag}>)/) { |ss|
          if flag
            res = $1+new_value+$2
          else
            res = ""
          end
          flag = false
          next res 
        }
      elsif (txml.match(/<#{tag}\/>/))
        flag = true
        txml.gsub!(/<#{tag}\/>/) { |ss|
          if flag
            res = "<#{tag}>#{new_value}</#{tag}>"
          else
            res = ""
          end
          flag = false
          next res
        }
      else
        flag = true
        txml.gsub!(/(<\/history>)/) { |ss|
          if flag
            res = "#{$1}\n  <#{tag}>#{new_value}</#{tag}>"
          else
            res = ""
          end
          flag = false
          next res
        }
      end
      return txml
    end # mod_tag
    

    # Modify dateSpan

    def mod_ds(txml, start_date, end_date)
      if (txml.match(/<dateSpan.*\/>/))
        flag = true;
        txml.gsub!(/<dateSpan.*\/>/) { |ss|
          if (flag)
            res = "<dateSpan start=\"#{start_date}\" end=\"#{end_date}\"\/>"
          else
            res = ""
          end
          flag = false;
          next res
        }
      else
        # Use the loop syntax, but only so we can use $1. We're only
        # expecting one instance of the closing </history> tag.
        txml.gsub!(/(<\/history>)/) { |ss|
          res = "#{$1}\n  <dateSpan start=\"#{start_date}\" end=\"#{end_date}\"\/>"
        }
      end
      return txml
    end # mod_ds 

    # Modify the first extent and remove others. If there are multiple
    # extent tags this leaves a blank line for any extras. Ruby
    # apparently defaults to /m behavior on matches.

    def mod_extent(txml, value, units)
      if (txml.match(/<extent.*\/>/))
        flag = true
        txml.gsub!(/<extent.*\/>/) { |ss|
          if flag
            res =  "<extent value=\"#{value}\" units=\"#{units}\"\/>"
          else
            res = ""
          end
          flag = false
          next res
        }
      else
        # Use the loop syntax, but only so we can use $1. We're only
        # expecting one instance of the closing </history> tag.
        txml.gsub!(/(<\/history>)/) { |ss|
          next "#{$1}\n  <extent value=\"#{value}\" units=\"#{units}\"\/>"
        }
      end
      return txml
    end # mod_extent
    
    # Get the date span of the ingest.

    def date_span(uuid)
      big_list = []
      FileUtils.cd("#{Dest}/#{uuid}/#{Accession_dir}") {
        big_list = `find ./ -mindepth 1 -printf "%T@ %Tc %p\n" | sort`.split("\n")
      }

      # Capture the date and put [1] which is the first capture, into
      # our variable.

      start_date = big_list[0].match(/^\d+.\d+ (.*?) \.\//)[1]
      end_date = big_list.last.match(/^\d+.\d+ (.*?) \.\//)[1]
      return [start_date, end_date]
    end

    # Get the full extent of the ingest.

    def full_extent(uuid)
      # For now just change extent to be the full size of the ingest in bytes
      full_extent = ""
      FileUtils.cd("#{Dest}/#{uuid}/#{Accession_dir}") {
        full_extent = `du -sh ./`.match(/^(.*?)\s+/)[1]
      }
      return full_extent
    end

    # Read the xml, make a few modifications, write the xml back.

    (start_date, end_date) = date_span(uuid)
    txml = IO.read(file);

    txml = mod_tag(txml, "accessionNumber", uuid)
    txml = mod_tag(txml, "respectDeFonds", ingest_name)
    txml = mod_extent(txml, full_extent(uuid), "bytes")
    txml = mod_ds(txml, start_date, end_date )

    new_taper_fd = File.new(file, "w")
    new_taper_fd.write(txml) # write() is a method from IO.
    new_taper_fd.close() # close() is apparently also from IO.

    @mdo.set_message("Submission agreement updated.", true)
    save_status(uuid, "Submission agreement updated.")

    redirect_to :action => 'report'
  end
  

  # Create a web page. The "report" shows a high-level view of all
  # ingests in Rubymatica, as well as serving as a home page and
  # dashboard.

  def report

    # f_info is the list of hashes that we'll send to the erb. It
    # basically holds all the data about ingests and files. It must be
    # @ so it is visible (scope) to the Rails erb.

    @f_info = [] 
    bgcolor = '#EEEDFD'
    color_toggle = true

    # First: process files and dirs in Origin. These are files or
    # directories waiting to be ingested aka processed. This meta data
    # gathering is fairly simple and generates the output in the
    # column "Ingest or import".
    
    @orig_list = `find #{Origin} -maxdepth 1 -mindepth 1  -print`.split("\n")
    @orig_list.sort.each { |file|
      rh = Hash.new
      rh[:orig] = File.basename(file)
      rh[:name] = "n/a"
      rh[:dirs] = []
      rh[:mets] = ""
      if (color_toggle)
        color_toggle = false
      else
        color_toggle = true
        rh[:bgcolor] = bgcolor
      end

      rh[:proc_ok] = false
      re = /(.tar$)|(.zip$)/i
      if re.match(rh[:orig]) || File.directory?(rh[:orig])
        rh[:proc_ok] = true
      end

      @f_info.push(rh);
    }

    # Second: Gather meta data on Dest ingests that have been
    # processed. We really only want a list of directories in the Dest
    # dir. Any files here are errors, so ignore them. Create our old
    # friend, list of hash. rh is memnonic for "Result Hash" or
    # "Record Hash".

    @file_list = `find #{Dest} -maxdepth 1 -mindepth 1 -type d -print`.split("\n")

    file_re = /#{Dest}\/.*\/(.*)/

    # A little func to support sorting. Using the meta data database
    # in the dest path, get the ingest name, and lower case it. We
    # want the ingest name and not Accession_dir.

    def iname(foo)
      bname = File.basename(foo)
      # see rubymatica.rb for class def 
      return Ingest.new(bname).read_meta("ingest_name").to_s.downcase
    end

    # Sort the list of ingests based on ingest name. Notice that the
    # "find" command above is -maxdepth 1 -mindepth 1 so we're only
    # looking at the ingests. We are not looking inside each
    # ingest. It would be cool to do a secondary sort on date.

    @file_list.sort{ |aa,bb| iname(aa) <=> iname(bb) }.each { |file|
      rh = Hash.new
      rh[:mtime] = File.stat(file).mtime
      rh[:orig] = ""
      rh[:name] = File.basename(file)
      rh[:dirs] = ""
      rh[:mets] = "METS.xml"
      rh[:stat] = Rubymatica.get_status(File.basename(file))[-1]['msg']
      rh[:short] = rh[:stat]
      if (rh[:short].length > 20)
        rh[:short] = "#{rh[:short][0..20]}..."
      end
      if (color_toggle)
        color_toggle = false
      else
        color_toggle = true
        rh[:bgcolor] = bgcolor
      end

      # see rubymatica.rb for class def 
      my_ig = Ingest.new(rh[:name])

      # Ugh. Feb 14 2011. I'm guessing this is used for the name of
      # the ingest, not the name of the directory, even though the var
      # is dir_short.
      
      rh[:dir_short] = my_ig.read_meta("ingest_name")
      if (rh[:dir_short].length > 15)
        rh[:dir_short] = "#{rh[:dir_short][0..15]}..."
      end

      @f_info.push(rh);
    }
    @message = @mdo.get_message()
    @mdo.set_message("", false) # clear the message
  end # report
  

  # db test and demo code. 

  def test
    def foo
      @output.concat("this is a test")
    end

    db = SQLite3::Database.new("/home/twl8n/aims_1/am_ruby/test.db");
    # see class def at the top of this file.
    @recs = Recs.new()
    @row_class = ""
    columns = nil
    @output = []
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
  end # test

end # Class HelloWorldController
