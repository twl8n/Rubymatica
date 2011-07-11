#!/usr/bin/ruby 

# Copyright 2011 University of Virginia
# Created by Tom Laudeman

# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You
# may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.

module Rmatic

  # Originally based on ~/archivematica-read-only/includes/archivematica/processSIP.sh
  # See readme.txt for background and installation notes.
  
  require 'rubygems'
  require 'find'
  require 'nokogiri'
  require 'fileutils'
  require 'bagit'
  require 'escape'

  require "#{File.dirname(File.expand_path(__FILE__))}/rmatic_constants.rb"

  # unbuffer output.
  STDOUT.sync = true

  class Create_bag
    # Create a bagit bag. This class has only one method initialize(),
    # and returns nothing meaningful. I suppose it could be a class
    # method of Rubymatica as are the other utilities.

    def initialize(dir_uuid, mdo)
      # Given a uuid, create a bagit bag. mdo is a message dohicky object.

      uuid = File.basename(dir_uuid);
      Rubymatica.save_status(uuid, "Starting bag creation");

      # Several of the commands here are backticked Linux commands because
      # pure Ruby is either awkward or outright buggy. 

      # If a bag dir already exists, then exit. File.exist? works for dirs
      # too. There is no Dir.exist?.
      
      msg_str = ""
      bag_dir = File.join(dir_uuid, "bag")
      bag_file = File.join(dir_uuid, Bagit_file)

      if (File.exist?(bag_dir))
        FileUtils.rm_rf(bag_dir)
        msg_str = "Removed existing bag dir.\n"
      end
      
      if (File.exist?(bag_file))
        FileUtils.rm_f(bag_file)
        msg_str.concat("Removed existing bag file.\n")
      end
      
      if (! msg_str.empty?)
        Rubymatica.save_status(uuid, msg_str);
      end

      if (! mdo.to_s.empty?)
        mdo.set_message(msg_str, true)
      else
        print msg_str
      end

      # Save the list of top level files and dirs before the bag dir is
      # created. Use the pure Ruby method of getting the top level list of
      # files and directories.

      top_level_list = Dir[File.join(dir_uuid, '*')]

      # New bagit object also creates ./bag and /bag/data

      bag = BagIt::Bag.new(bag_dir) # "#{dir_uuid}/bag"
      Rubymatica.save_status(uuid, "New bag object created");
      hash = bag.bag_info()
      hash["Internal-Sender-Identifier"] = dir_uuid

      bag.write_bag_info(hash)

      # Copy files from dir_uuid into bag/data by each()ing through the
      # list. Don't forget to chomp the copy_me origins because they came
      # from a backticked command. FileUtils.cp_r has a bug, so we can't
      # use it.

      top_level_list.each { |copy_me|
        copy_me.chomp!
        `#{Cp_exe} -a #{copy_me} #{bag_dir}/data`
      }

      # bag_files are all files in data_dir, recursive
      # tag_files are only files in the top level bag dir.

      bag.manifest!
      bag.tagmanifest!

      # Create the bagit file in the main directory. Need to use -r to
      # recursively add files. chdir to the Dest directory, so that the
      # paths in the zip file will begin with the uuid of the
      # ingest. File.basename() gets the last component of a path, even if
      # that component is a directory and not a file.
      
      Dir.chdir(dir_uuid)

      rel_path = File.basename(dir_uuid)

      `#{Zip_exe} -r #{Bagit_file} bag`
      Rubymatica.save_status(uuid, "Zipping bag directory");

      msg_final = "#{dir_uuid}/#{Bagit_file} created."
      mdo.set_message(msg_final, true)
      Rubymatica.save_status(uuid, msg_final)
      Rubymatica.save_status(uuid, "Bag created")

      # We can't easily use pure Ruby to delete because Dir[] doesn't have a
      # depth-first option. 'find' would work, but since we're deleting
      # everything in the bag directory tree, we might as well use
      # /bin/rm.

      # nov 23 2010 Change to just use .rm_rf

      FileUtils.rm_rf(bag_dir)
      return true
    end 
  end

  class Msg_dohicky
    # Set and get messages to show in web pages. Messages are saved in a
    # database so they'll survive page loads. We don't have logins so the
    # user_id is the remote ip address.
    
    # The messages handled by Msg_dohicky are the Rails web page status
    # messages handled on a per-user / per-session basis. There is only
    # one Rmatic_db per Rubymatica instance. This is used primarily in
    # hello_world_controller.rb.
    
    @fn = ""
    @user_id = ""

    def initialize(generic_id, msg_path)
      @user_id = generic_id
      @fn = "#{msg_path}/#{Rmatic_db}"
      
      # If the db doesn't exist, create it.

      if (! File.size?(@fn))
        db = SQLite3::Database.new(@fn)
        sql_source = "#{msg_path}/#{Msg_schema}"
        db.execute_batch(IO.read(sql_source))
        db.close
      end
    end
    
    # Save a message for a given user. If flag is false, remove all old
    # messages. True to add a new message record.
    
    def set_message(str,flag)
      db = SQLite3::Database.new(@fn)
      if (! flag)
        db.transaction
        stmt = db.prepare("delete from msg where user_id=?")
        stmt.execute(@user_id);
        stmt.close
        db.commit
      end

      db.transaction
      stmt = db.prepare("insert into msg (user_id,msg_text) values (?,?)")
      stmt.execute(@user_id, str);
      stmt.close
      db.commit
      db.close();
    end

    # Get all the messages for a given user. Notice that rather than
    # returning a list of hash, we concat the list elements into a
    # single string.

    def get_message
      db = SQLite3::Database.new(@fn)
      db.transaction
      stmt = db.prepare("select msg_text from msg where user_id = ? order by id")
      ps = Proc_sql.new();
      stmt.execute(@user_id){ |rs|
        ps.chew(rs)
      }
      stmt.close
      db.close()
      results = ""
      ps.loh.each { |hr|
        results.concat("\n#{hr['msg_text']}")
      }
      return results
    end
  end # class Msg_dohicky


  class Proc_sql
    # Process (chew) sql records into a list of hash. Called in an
    # execute2() loop. Ruby doesn't really know how to return SQL results
    # as a list of hash, so we need this helper method to create a
    # list-of-hash. You'll see Proc_sql all over where we pull back some
    # data and send that data off to a Rails erb to be looped through,
    # usually as table tr tags.
    
    def initialize
      @columns = []
      @loh = []
    end

    def loh
      if (@loh.length>0)
        return @loh
      else
        return [{'msg' => "n/a", 'date' => 'now'}];
      end
    end

    # Initially I thought I was sending this an array from db.execute2
    # which sends the row names as the first record. However, using
    # db.prepare we use stmt.execute (there is no execute2 for
    # statements), so we're getting a ResultSet on which we'll use the
    # columns() method to get column names.

    # It makes sense to each through the result set here. The calling
    # code is cleaner.

    def chew(rset)
      if (@columns.length == 0 )
        @columns = rset.columns;
      end
      rset.each { |row|
        rh = Hash.new();
        @columns.each_index { |xx|
          rh[@columns[xx]] = row[xx];
        }
        @loh.push(rh);
      }
    end
  end # class Proc_sql


  class Ingest
    # Create a class for the ingest to store ephemera, and simplify
    # calling of methods to save and retrieve that ephemera.

    def initialize(uuid)
      @uuid = uuid;
    end

    def write_meta(name,value)
      fn = "#{Dest}/#{@uuid}/#{Meta}/#{Db_name}"
      if (! File.exists?("#{fn}"))
        return nil;
      end
      
      db = SQLite3::Database.new("#{fn}")
      db.transaction
      stmt = db.prepare("insert into meta (name,value) values (?,?)")
      stmt.execute(name,value);
      stmt.close
      db.commit
      db.close();
    end

    def read_meta(name)
      fn = "#{Dest}/#{@uuid}/#{Meta}/#{Db_name}"
      if (! File.exists?("#{fn}"))
        print "read_meta can't open db #{fn}\n"

        # Was returning nil, but that's kind of hostile. Lots of things
        # break on nil objects that behave better with an empty string.
        
        return "";
      end

      # Using Proc_sql is kind of overkill, but we don't have an
      # equivalent to fetchrow_hashref(), so this will have to do.
      
      db = SQLite3::Database.new("#{fn}")
      stmt = db.prepare("select value from meta where name=?")
      ps = Proc_sql.new();
      stmt.execute(name){ |rs|
        ps.chew(rs)
      }
      stmt.close()
      db.close()
      # Cast to string so we won't ever have a nil object.
      retval = ps.loh()[0]['value'].to_s
      return retval
    end
  end # class Ingest


  class Detox_dic
    # Build a hash for the detox file name changes. We have a method that
    # inverts the hash.
    
    # Normal variables aren't accessible inside the block for
    # Builder.new. Dunno why. There's some comment in the Nokogiri docs
    # about Builder.new with and without an argument list. Just use a
    # new class.

    @inst_dir_uuid = 0;
    def initialize(uuid_file_name, dir_uuid)
      @inst_dir_uuid = dir_uuid
      @detox_dic = Hash.new
      in_fd = File.new(uuid_file_name, "r")
      in_fd.each {|line|
        key, value = line.split("\t")
        key.chomp!
        value.chomp!
        @detox_dic[key] = {:name => value}
      }
      in_fd.close();

      # I hate to make a second hash, but 1.8.7 doesn't have the
      # hash.key() method so this is at least easy and portable. We
      # need to be able to find a given key if we have the detox'd
      # file name. The file_name_clean_up.log file has original and
      # detox'd file names which we'll match up below.

      @invert_dic = Hash.new;
      @detox_dic.each_key { |key|
        @invert_dic[@detox_dic[key][:name]] = key;
      }

      # Get the original and detox'd names from the log file.
      # /home/twl8n/dest/tmp/c878d18b-d34c-4984-a247-036e4d90ca12/ingest_logs/file_name_clean_up.log

      cleaned_fn = "#{File.dirname(uuid_file_name)}/#{Fclean}"
      in_fd = File.new(cleaned_fn, "r")
      in_fd.each {|line|
        orig, fixed = line.split(" \-> ")
        if (orig and fixed)
          orig.chomp!
          fixed.chomp!
          if (! orig.empty? and ! fixed.empty?)
            @detox_dic[@invert_dic[fixed]][:orig] = orig
          end
        end
      }
      in_fd.close();
    end

    def example
      # Just return the first key.
      return @detox_dic.keys[0];
    end
    
    def name(key)
      if (key)
        return @detox_dic[key][:name]
      else
        Rubymatica.save_status(inst_dir_uuid, "bad key: #{key}")
        return nil
      end
    end

    def orig(key)
      if (@detox_dic.has_key?(key) and @detox_dic[key][:orig])
        return @detox_dic[key][:orig]
      else
        return ""
      end
    end
    
    def key(value)
      return @invert_dic[value];
    end
    
    def has_key?(key)
      return @detox_dic.has_key?(key);
    end
  end # class Detox_dic
    

  class Create_mets
    # Create METS xml via Nokogiri.

    # Just run through the directory tree again. I think this is
    # simpler than trying to add nodes. The downside is that if the
    # directory crawl changed for some reason, we'd have to change the
    # directory crawl in 3 places.
    
    # This code assumes that directories are traversed as they are
    # enountered, so I guess that is depth-first.

    # Separate fileSec from structMap. It is just too confusing to
    # keep track of two node sets while recursing.

    def create_fileSec(path, fs_parent, dd)

      fbuilder = Nokogiri::XML::Builder.new {

        file_base = File.basename(path)

        # A nill variable such as file_base can cause the following
        # line to generate the "...in `add_child': Document already
        # has a root node..." error.

        fileGrp(:ID => file_base, :USE => "directory") {
          
          Rubymatica.traverse(path, true).each { |pfile|
            # Don't do anyting with the current dir, or subdirs.
            if (pfile == path)
              next;
            end

            if (File.directory?(pfile))
              create_fileSec(pfile, parent, dd)
            elsif (File.file?(pfile))
              file_base = File.basename(pfile);
              file_uuid = dd.key(pfile);
              
              file("xmlns:xlink" => "http://www.w3.org/1999/xlink",
                   :ID => "file-#{file_base}-#{file_uuid}",
                   :ADMID => "digiprov-#{file_base}-#{file_uuid}") {
                Flocat("xlink:href" => "#{path}/#{file_base}",
                       :locType => "other",
                       :otherLocType => "system")
              }
            end
          }
        }
      }
      fs_parent.add_child(fbuilder.doc.root)
    end
    
    def create_structMap(path, sm_parent, dd, level)
      
      level+=1;
      file_base = File.basename(path)

      sbuilder = Nokogiri::XML::Builder.new {
        
        div(:LABEL => file_base, :TYPE => "directory") {
          
          Rubymatica.traverse(path, true).each { |file|          
            if (file == path)
              next;
            end

            if (File.directory?(file))
              create_structMap(file,parent, dd, level)
            elsif (File.file?(file))
              file_base = File.basename(file);
              file_uuid = dd.key(file);

              file("xmlns:xlink" => "http://www.w3.org/1999/xlink",
                   :ID => "file-#{file_base}-#{file_uuid}",
                   :ADMID => "digiprov-#{file_base}-#{file_uuid}") {
                Flocat("xlink:href" => "#{file}",
                       :locType => "other",
                       :otherLocType => "system")
              }
            end
          }
        }
      }
      sm_parent.add_child(sbuilder.doc.root)
    end
    
    def to_xml
      @builder.to_xml
    end
    
    def initialize(dir_uuid, sip_name)
      uuid_file_name = "#{Dest}/#{dir_uuid}/#{Ig_logs}/#{Uuid_log}"
      path = "#{Dest}/#{dir_uuid}"
      path_base = dir_uuid;
      dd = Detox_dic.new(uuid_file_name, dir_uuid)

      @builder = Nokogiri::XML::Builder.new {

        mets('xmlns:dcterms' => 'http://purl.org/dc/terms/',
             'xmlns:mets' => "http://www.loc.gov/METS/",
             'xmlns:premis' => "info:lc/xmlns/premis-v2",
             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
             'xsi:schemaLocation' => "http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/version18/mets.xsd info:lc/xmlns/premis-v2 http://www.loc.gov/standards/premis/premis.xsd http://purl.org/dc/terms/ http://dublincore.org/schemas/xmls/qdc/2008/02/11/dcterms.xsd" ) do
          
          dmdsec(:ID => "SIP-description") {
            mdWrap {
              xmlData {
                dc_xml = Nokogiri::XML(IO.read("#{path}/#{Meta}/#{Dcx}"))
                parent.add_child(dc_xml.root)
              }
            }
          }

          amdSec {
            Rubymatica.traverse(path, false).each { |file|
              # If not a file, or if system file, then skip. Ugly
              # code structure, but saves another level of
              # indentation.

              if (! File.file?(file))
                next;
              end
              
              # file_uuid is the uuid of the file. dd keys are the
              # whole file name for the file in the tmp directory of
              # the SIP creation. dd.name() is the full file
              # path. dd.orig is the full file path before detox ran
              # on it. Not ever file with have a dd.orig.
              
              file_uuid = dd.key(file)
              file_base = File.basename(file)
              digiprovMD( :ID => "digiprov-#{file_base}-#{file_uuid}") {
                # premis record for the file
                mdWrap( 'MDTYPE' => "PREMIS") {
                  xmlData {
                    long_str = "info:lc/xmlns/premis-v2 http://www.loc.gov/standards/premis/premis.xsd"
                    premis('xmlns' => "info:lc/xmlns/premis-v2",
                           'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                           'version' =>"2.0",
                           'xsi:schemaLocation' => long_str) { |obj|
                      object( 'type' => "file") {
                        objectIdentifier {
                          objectIdentifierType "UUID"
                          #objectIdentifierValue "17dabc78-3dd5-4915-ade7-bef8abda3d41"
                          objectIdentifierValue file_uuid
                          
                          # Can we always put in this element, and either
                          # leave it blank if no detox name, or put the
                          # original name in if not changed? Or add an element
                          # "detox_changed_name" as a boolean?
                          
                          # I added the .empty? test to make this more
                          # robust and it broke. The simple if test
                          # was simple and effective (but might
                          # break). In the fix .empty? doesn't work
                          # for nil, so the upstream code had to be
                          # more complex. Perl's DWIM doesn't always
                          # work in Ruby, "" is true, but nil is
                          # false, and nil.empty? is an error.

                          if ( ! dd.orig(file_uuid).empty? )
                            originalName File.basename(dd.orig(file_uuid))
                          end

                        }
                      }
                    }
                  }

                  # wrap the FITS data for this file
                  mdWrap( 'MDTYPE' => "FITS") {
                    xmlData {
                      # The IO.read full path to the FITS xml file
                      # got long so I'm breaking it up into a couple of
                      # lines and vars.
                      f_path = "#{path}/#{Ig_logs}"
                      f_fname = "FITS-#{file_uuid}-#{file_base}.xml"
                      fits_xml = Nokogiri::XML(IO.read("#{f_path}/#{f_fname}"))
                      parent.add_child(fits_xml.root)
                    }
                  }
                }
              }
            }
          }

          fileSec {
            # Archivematica has a folder name for each SIP, but we
            # have only the uuid so we can't really
            # "#{path_base}-#{uuid}" because path_base is the uuid.

            fileGrp( :ID => "#{dir_uuid}", :USE => "Objects package") {
              @fs_parent = parent;
            }
          }
          
          structMap {
            div(:DMDID => "SIP-description",  :LABEL => dir_uuid,  :TYPE => "directory") {
              @sm_parent = parent;
            }
          }
          
          def fs_parent
            return @fs_parent
          end

          def sm_parent 
            return @sm_parent
          end

        end
      } # end builder
      create_fileSec(path, @builder.fs_parent, dd)
      create_structMap(path, @builder.sm_parent, dd, 0)

    end # end initialize
  end # class Create_mets

  class Rubymatica
    
    # I have misgivings about the name "Rubymatica" since I like names
    # to be unique across all name spaces.
    
    # This is very old code that processes an entire directory where each
    # top level subdir is a separate ingest. Only called from
    # process_sip.rb.

    def initialize(path, reproc)   # historically self.process(path, reproc)
      
      # We really want a list of dirs at the top level. Code below will
      # generate a warning for any files in the top level. The original
      # code used origin_dir/* and the wildcard caused it to only list
      # files and dirs at the top. However, * can cause problems, and I
      # think my find command is what we really want.

      # If the path is not empty, assume we are reprocessing or we are
      # processing a single dir. In either case we will return after
      # calling process_one().

      if (! path.empty?)
        process_one(path, reproc)
        return 
      end

      # If we got down here, we must simply be processing everything we
      # can find in the orig directory. If there aren't any dirs/files in
      # the ingest, then print and exit.

      # cd to the origin directory and do find there. process_one() wants
      # the path relative to the origin, not a full path. We do this with
      # web content to prevent spoofing.

      # Note1: use type -d?

      file_list = []
      FileUtils.cd(Origin) {
        file_list = `#{Find_exe} ./ -maxdepth 1 -mindepth 1  -print`.split("\n")
      }
      if (file_list.length == 0)
        print "No ingests to process in #{Origin}. Exiting.\n";
        exit();
      end

      file_list.each { |file|
        file.chomp!
        process_one(file, false)
      } # end of processing every dir in the ingest
      
      print "All done\n"
      
    end # end init which historically was self.process()

    def self.get_status(uuid)

      # Make this a class method. Get all the status info for a given
      # uuid (ingest). Return a list of hashes suitable for building a
      # web page.

      # Use prepare() because we're using placeholders.
      # Use execute2() because we want column names to build a hash.
      # See the record row processing class Proc_sql above.

      fn = "#{Dest}/#{uuid}/#{Meta}/#{Db_name}"
      if (! File.exists?(fn))
        # Return a single element anon array.
        return [{'msg' => "n/a"}];
      end
      
      db = SQLite3::Database.new("#{fn}")
      stmt = db.prepare("select msg,date from status order by date")
      ps = Proc_sql.new();
      stmt.execute(){ |rs|
        ps.chew(rs)
      }
      stmt.close
      db.close()
      return ps.loh()
    end

    def self.get_droid(uuid)

      # Make this a class method. Get droid info for file files in a
      # given uuid. Return the info in a list of hashes suitable for
      # building a web page.

      # Use prepare() because we're using placeholders.
      # Use execute2() because we want column names to build a hash.
      # See the record row processing class Proc_sql above.

      fn = "#{Dest}/#{uuid}/#{Ig_logs}/fits.db"
      if (! File.exists?(fn))
        # Return a single element anon array.
        return [{'msg' => "n/a"}];
      end

      # Add a nice little hack to get the file utility mime type and
      # return it as alt_mime. We're doing this because DROID often fails
      # to return a mime type. The file utility seems to be the most
      # reliable at returning mime types. We might even be able to get SQL
      # to return a preferred alternate mime but I don't see a simple
      # query for that.

      # jan 10 2011 change from using where element='identity' to where
      # element='fileUtilityOutput' in order to get output from the file
      # utility which is by far the most reliable. Here we use the file
      # utility output for the mime-type as a backup when Droid doesn't
      # give us a mime-type.

      # The sub-queries are getting complex enough that next time this
      # needs work, it should be turned into two or more queries. It
      # appears that sub-queries b and c have identical record ordering
      # that results from "group by", but that seems like a weak assumption.

      # mar 22 2011 some sqlite versions were fine with "is not ''" but that
      # is not valid syntax. Correct is "not like ''".
      
      db = SQLite3::Database.new("#{fn}")
      stmt = db.prepare(
                        "select
	  b.format as format,
	  a.id as id,
	  name,
	  b.ext_id as ext_id,
	  b.ext_type as ext_type,
	  c.mime_type as alt_mime,
	  r_count
	  from
	  file a,
	  (select *,count(*) as r_count from
	   (select * from identity where element='FileFormatHit' order by ext_id)
	   group by file_id) as b,
	  (select * from identity where
		element='fileUtilityOutput' and mime_type not like '' group by file_id) as c
	  where
	  a.id=b.file_id
	  and a.id=c.file_id
	  order by name")

      ps = Proc_sql.new();
      stmt.execute(){ |rs|
        ps.chew(rs)
      }
      stmt.close
      db.close()

      # Fix the alternate mime type to only be the "what/type" excluding
      # any extraneous attributes such as "charset=binary". The database
      # might not have an alternate type so make sure that we at least
      # have an empty string. Remove the path_prefix to create a short
      # name. rh is memnonic for "ruby hash" loh is memnonic for "list of
      # hash"

      path_prefix = "#{Dest}/#{uuid}/"

      ps.loh.each { |rh|
        if rh.has_key?('name')
          rh['short_name'] = rh['name'].gsub(/#{path_prefix}/,'')
        end

        if rh['alt_mime'].to_s.empty?
          rh['alt_mime'] = ""
        else
          rh["alt_mime"].gsub!(/.*(\b[\w+-.]+\/[\w+-.]+\b).*/,'\1')
        end
      }
      return ps.loh()
    end


    def self.traverse(path, p_flag)
      # Is a class method because it is called as a utility
      # function. Otherwise, could be a new class. Traverse path
      # directory tree and return a list of the files. We end up
      # crawling directory trees, and we have a few specific needs, so
      # we needed a little method.
      all_items = [];
      Find.find(path) { |file|
        if (file.match(Ig_logs) or
            file.match(Meta) or 
            file.match(Pv))
          next;
        end
        all_items.push(file);

        # We have to deal with the apparently strange pruning behavior of
        # Find.find(). If file is not the current path, and we want the
        # bahaviour of -maxdepth 1 then prune.

        if (File.directory?(file) and file != path and p_flag)
          Find.prune();
        end
      }
      return all_items;
    end 

    def self.save_status(uuid, msg)
      # Utility class method. Save some status message into the local
      # ingest database (info.db) for a given uuid (ingest). This is
      # the overview log of what happened, and there is no separate
      # log file for these messaged. These status messages are saved
      # in real time as each step of processing completes. Notice the
      # many save_status() calls littered throughout process_one().

      fn = "#{Dest}/#{uuid}/#{Meta}/#{Db_name}"
      if (! File.exists?("#{fn}"))
        return 0;
      end
      
      db = SQLite3::Database.new("#{fn}")
      db.transaction
      stmt = db.prepare("insert into status (uuid, msg,date) values (?,?,datetime('now'))")
      stmt.execute(uuid,msg);
      stmt.close
      db.commit

      # The docs say this: "Closes this database. No checks are done to
      # ensure that a database is not closed more than once, and closing a
      # database more than once can be catastrophic." Multiple close()
      # calls with SQLite seem fine.
      db.close();
    end


    private

    # Create an error log based on port number, or pid. The only way to
    # get a port number is to have it suplied on the process_sip.rb
    # command line. Remember: rubymatica is asynchronous so there is
    # nothing we inherit from the parent process.
    
    def err_name
      if (defined? @port_num)
        return "error_#{@port_num}.log"
      else
        return "error_#{Process.pid}.log"
      end
    end


    def gsub_first(var, sub_val)
      # Substitute for the first instance of a regex match, and remove
      # subsequence matches. This is specialized to he processing of TAPER
      # xml.
      count = 1
      var.gsub!(/(.)/) {|s|
        res = ""
        if (count == 1)
          puts "1:" + s[0].to_s 
          res = s[0].to_s
        else
          puts "2:" + s + "$1:" + $1
          res = $1
        end
        count = count + 1
        # Use next to create an explicit return value. Apparently it
        # also works to simply put a nake "res" on a line by itself.
        next res;
      }
      return var
    end

    def self.this_method
      # Just a little trick to get the name of the current method.
      caller[0]=~/`(.*?)'/
      $1
    end

    def detox_dir(file, dry_run_flag)
      # Test a directory name. We lazily escape everything. detox only
      # escapes particularily dangerouse chars such as &, but does not
      # escape " " (space). Curious.
      path_changed = false
      d_out = "Scanning: #{Escape.shell_command(file)}\n"
      new_file = String.new(file)

      # , ; : = + % @ may be ok, but they are just too weird, we
      # won't allow them.  Other non-allowed chars actually cause
      # problems in various scenarios. Allow / because these are directories.

      # Make our output string exactly match that of detox so calling
      # code can parse our results.

      if new_file.gsub!(/[^A-Za-z0-9\.\-_\/]+/, '_')
        # Remove any multiple underscores
        new_file.gsub!(/_+/, '_')
        print "nf: #{new_file} fi: #{file}\n"
        if File.exists?(new_file)
          d_out.concat(sprintf("Cannot rename %s to %s: file already exists\n",
                               Escape.shell_command(file),
                               new_file))
        else
          if (! dry_run_flag)
            # Maybe we should check for success or errors here?
            print "renaming: #{file} to #{new_file}\n"
            File.rename(file, new_file)
            path_changed = true
          end
          d_out.concat(sprintf("%s -> %s",
                               Escape.shell_command(file),
                               new_file))
        end
      end
      return [d_out, path_changed]
    end


    def detox_test(file)
      if File.file?(file)
        d_out = `#{Detox_exe} -nv #{Escape.shell_command(file)} 2>&1`
      else
        # detox_dir(file, dry_run_flag)
        # Ignore path_changed since it is always false when dry_run_flag is true.
        d_out, path_changed = detox_dir(file, true) 
      end
      return d_out;
    end
    
    def detox_do(file)
      path_changed = false
      if File.file?(file)
        d_out = `#{Detox_exe} -v #{Escape.shell_command(file)} 2>&1`
      else
        # file, dry_run_flag
        d_out, path_changed = detox_dir(file, false) 
      end
      return [d_out, path_changed]
    end

    def run_detox(working_path, log_full_name, brief_log_full_name)
      # Helper method to run detox.  Long term we need to parse the output
      # of detox and save the original and final names in a db. We probably
      # also need some notes about any interim names as a sanity check.

      # Note that detox doesn't allow a dry run on a single directory,
      # although it does allow dry run on a file. detox_do() and
      # detox_test() compensate by calling Ruby code to test dir
      # names, and the Ruby code returns the same format string as
      # detox.

      # This wasn the original, simple command:
      #  `#{Detox_exe} -rv #{tub} >> #{igl_dest}/#{Fclean} 2>&1`

      path_changed = false
      detox_log_text = "";
      detox_brief = ""
      
      # Note that a file could be a file or dir. Keep "file" as the
      # original file name. The new name (if we need one) is
      # working_fn and the interim previous name is old_fn.
      
      # Set up some vars that we'll use in the while loop. extname
      # includes the leading "." dot. Convince basename to exclude the
      # extension.

      Find.find(working_path) { |file|
        # test a file name
        d_out = detox_test(file)
        
        working_fn = file
        old_fn = working_fn
        suffix = 1; # Counting number start with one
        my_ext = File.extname(file)
        my_base = File.basename(file,my_ext)
        my_dir = File.dirname(file)
        
        # Only save the detox message if we are going to change the
        # name. When we add a suffix we need to check if the proposed new
        # name already exists. Stop at suffix 200. When we find a new name
        # we like, we still have to test that with detox_test() and
        # iterate if that doesn't work.

        while (d_out.match(/Cannot rename/))
          detox_log_text.concat("#{d_out}")

          while (File.exists?(working_fn))
            # Don't add an extra leading dot before my_ext. Happily,
            # since extname retains the dot if there is an extension,
            # this algo works for directories and files which have no
            # extension.
            
            working_fn = my_dir + "/" + my_base + "_" + suffix.to_s + my_ext
            suffix += 1
            if (suffix > 200)
              print "Error: suffix exceeded\n";
              File.open(log_full_name, "wb") { |my_log|
                my_log.write(detox_log_text)
                my_log.write("Error: suffix exceeded\n")
              }
              exit
            end # end if
          end # end while

          detox_log_text.concat("Rename #{old_fn} to #{working_fn}\n")
          File.rename(old_fn, working_fn)
          old_fn = working_fn
          d_out = detox_test(working_fn)
        end # end while

        # Only call detox_do() if the test had "->" indicating that detox
        # wants to change the name.
        
        if (d_out.match(/(.*)\s+\-\>\s+(.*)/))
          interim_fn = $1
          final_fn = $2
          detox_log_text.concat("Originally #{file}\n")
          d_out, path_changed = detox_do(working_fn)
          detox_log_text.concat("#{d_out}\n")
          detox_brief.concat("Original: #{file} Final: #{final_fn}")
          if (! interim_fn.eql?(file))
            detox_brief.concat(" Interim: #{interim_fn}")
          end
          detox_brief.concat("\n")
        end # end if

        # If a directory name has changed, we stop work, and
        # return. The calling code will restart the recursive change
        # of the directory tree. Given that Find.find() is static
        # and can't be restarted, this break/recurse is necessary.
        
        if path_changed
          break
        end
      }
      
      # Write out the log files.

      File.open(log_full_name, "wb") { |my_log|
        my_log.write(detox_log_text)
      }

      File.open(brief_log_full_name, "wb") { |my_log|
        my_log.write(detox_brief)
      }
      return path_changed
    end # end def run_detox



    def run_fits(file, file_uuid, log_path, fits_home)
      # Helper method to run FIT file identification.

      # From runFITS.sh, $1 is file, $2 is directory uuid, $3 is file_uuid
      # See  /opt/archivematica/runFITS.sh, runFITS.py 
      # archivematica-read-only/includes/archivematica/runFITS.sh

      if (File.exists?(file))

        short_file = File.basename(file);
        full_log = "#{log_path}/FITS-#{file_uuid}-#{short_file}.xml"; 
        
        # Returns to old working dir after block.
        
        if true 
          `#{Fits_full} -i #{file} -o #{full_log}`
        else
          # Use the clever "cd block" trick that returns to the current
          # dir after the block.
          FileUtils.cd(fits_home) {
            `./fits.sh -i #{file} -o #{full_log}`
          }
        end
      end
    end


    def check_md5(check_folder, md5_digest, report_dir)
      # Helper method to check md5 checksums.

      # checkFolder with files to be checked =$1
      # md5Digest full path file =$2 
      # report directory

      # See /opt/archivematica/checkMD5NoGUI.sh md5_deep could set a
      # flag. If it has just run, then there's no point in checking the
      # checksums.

      # file names
      fail_tmp = "#{report_dir}/#{Fail_name}"
      pass_tmp = "#{report_dir}/#{Pass_name}"
      report_file = "#{report_dir}/#{Report_name}"
      
      curr_dir = FileUtils.pwd()
      FileUtils.cd(check_folder);

      #check for passing checksums
      `#{Md5deep_exe} -r -m #{md5_digest} . > #{pass_tmp}`

      #check for failing checksums
      `#{Md5deep_exe} -r -x #{md5_digest} . > #{fail_tmp}`
      FileUtils.cd(curr_dir);
      
      #Count number of Passed/Failed
      number_pass = `#{Wc_exe} -l #{pass_tmp}| cut -d" " -f1`.chomp!
      number_fail = `#{Wc_exe} -l #{fail_tmp}| cut -d" " -f1`.chomp!
      
      # Create report. Rewrite this with Ruby file output stuff.
      `#{Echo_exe} "PASSED" >> #{report_file}`
      `#{Cat_exe} #{pass_tmp} >> #{report_file}`
      `#{Echo_exe} " " >> #{report_file}`
      `#{Echo_exe} $numberPass "items passed integrity checking" >> #{report_file}`
      `#{Echo_exe} " " >> #{report_file}`
      `#{Echo_exe} " " >> #{report_file}`
      `#{Echo_exe} "FAILED" >> #{report_file}`
      `#{Cat_exe} #{fail_tmp} >> #{report_file}`
      `#{Echo_exe} " " >> #{report_file}`
      `#{Echo_exe} $numberFail "items failed integrity checking" >> #{report_file}`
      
      #cleanup
      `#{Rm_exe} -f #{fail_tmp} #{pass_tmp}`
      pl = "s"
      if (number_fail == 1)
        pl = ""
      end

      # You'll need to pass in dir_uuid if you want to uncomment these lines.
      # save_status(dir_uuid, "Checksum verification #{number_fail} failure#{pl}")
      # save_status(dir_uuid, "Wrote #{report_file}")
    end


    def easy_extract(path, log_path, dir_uuid)
      # Python easy_extract auto invokes the _extract method for the proper
      # class based on some magic with the ALLOWED_EXTENSIONS regex. We just
      # need a regex for either the "file" command or file extensions, same
      # as easy_extract. xtm is weird and we'll need a test file for that.

      # regexes for file extensions. What about rev recovery volume
      # sets? http://en.wikipedia.org/wiki/RAR

      # `'unrar-nonfree x %s ' % first_archive + output_folder`
      # re.compile('%s$' % ext, re.I) so put $ on the end of ext for regexp.
      # `7za x -o%s ' % output_folder + first_archive`


      # regexp for rar
      rar_exts = Regexp.new('\.(rar|part\d{2}.rar|r\d{2})$',
                            [Regexp::EXTENDED,
                             Regexp::IGNORECASE])
      
      # regexp for 7za
      seven_exts = Regexp.new('\.(arj|cab|chm|cpio|dmg|hfs|lzh|lzma|nsis|udf|wim|xar|z|zip|gzip|tar)$', 
                              [Regexp::EXTENDED,
                               Regexp::IGNORECASE])
      
      # find all the archives in the supplied path
      # open each archive
      # recurse into new folders and unarchive anything in there
      # report 

      new_dir = "";
      Find.find(path) {|found_file|

        if (File.file?(found_file))

          # New directory name is basename without the extension.
          # Extension includes leading dot (.).

          # We have some code duplication in the if clauses below. I'm
          # sure there's something clever to pull all that together, but
          # it would probably be harder to read. Lets just wait to fix
          # it until it becomes a bug.

          # New directory suffixes of the for _dir1, _dir2 .. _dirx. We
          # always have a number because these are counting numbers (1
          # .. x) and not array indexes, and it is easier to write a regex
          # against. (Which would be 0 based.)

          found_ext = File.extname(found_file)
          base_dir = File.dirname(found_file)
          stem = File.basename(found_file, found_ext)
          suffix = 1
          new_dir  = base_dir + "/" + stem + "_dir" + suffix.to_s
          while (File.exists?(new_dir))
            suffix += 1
            new_dir  = base_dir + "/" + stem + "_dir" + suffix.to_s
            if (suffix > 200)
              print "Error: suffix exceeded\n";
              Rubymatica.save_status(dir_uuid, "Error: exceeded max suffix creating dir for: #{base_dir}/#{stem}")
              exit
            end
          end

          if (found_ext.match(rar_exts))

            FileUtils.mkdir(new_dir)
            Rubymatica.save_status(dir_uuid, "unrar-nonfree x #{found_file} #{new_dir}")
            `#{Unrar_exe} x "#{found_file}" "#{new_dir}" >> #{log_path}/process_sip.log 2>&1`
            easy_extract(new_dir, log_path, dir_uuid)

          elsif (found_ext.match(seven_exts))

            # 7za will give a strange error if there is a space in a
            # directory name. The following error was from a space in the
            # output directory, aka -o, aka new_dir.
            
            #Error:
            #Cannot use absolute pathnames for this command

            FileUtils.mkdir(new_dir)
            Rubymatica.save_status(dir_uuid, "7za x -o#{new_dir} #{found_file}")
            `#{Sevenza_exe} x -o"#{new_dir}" "#{found_file}" >> #{log_path}/process_sip.log 2>&1`
            easy_extract(new_dir, log_path, dir_uuid)

          end
          
        end
      }
      return new_dir
    end


    def md5_deep(start_dir, dest_dir, out_full)
      # Helper method to call md5 and generate checksums.

      if (! File.exists?("#{out_full}"))
        `#{Md5deep_exe} -rl "#{start_dir}" > "#{out_full}"`
      end
      return "#{out_full}";
    end



    def create_dublin_core(dc_file, dir_uuid)
      # Helper method to create the dublin core in an ingest.

      # Just copy an empty dc file that sits in the same dir as this
      # source. The arg dc_file is a full path with file name where the
      # calling code expects us to write the dc file.

      if (! File.exists?(dc_file))
        FileUtils.cp(Orig_dc, dc_file)
        Rubymatica.save_status(dir_uuid, "Dublin core: Wrote #{dc_file}")
      else
        Rubymatica.save_status(dir_uuid, "Dublin core: File already exists #{dc_file}")
      end
    end


    def reproc_false(file)
      # Init a new ingest. Before we can process an ingest, we have to
      # initialize. The init is different for new and old ingests. For a new
      # ingest we call reproc_false().

      full_path = "#{Origin}/#{file}"
      extract_flag = false
      extract_orig = ""
      
      if ( File.extname(full_path) == ".tar" or
           File.extname(full_path) == ".zip" )
        extract_flag = true
        extract_orig = full_path
        # base_name = File.basename(full_path, File.extname(full_path))
        # full_path = "#{Origin}/#{base_name}"
      elsif (! File.directory?(full_path))
        
        # We are not reprocesing. Do a couple of sanity checks. full_path
        # must be a dir. If it is a file, something is very wrong.
        
        if (File.ftype(full_path) == 'file')
          print "Warning: #{full_path} is not a dir, .tar, or .zip. Exiting.\n"
        else
          print "Warning: #{full_path} is not a normal file. Exiting.\n"
        end
        return ;
      end

      dir_uuid = `#{Uuid_exe} -v 4`.chomp

      igl_dest = "#{Dest}/#{dir_uuid}/#{Ig_logs}"
      pv_dir = "#{Dest}/#{dir_uuid}/#{Pv}"
      md_dir = "#{Dest}/#{dir_uuid}/#{Meta}"
      ac_dir = "#{Dest}/#{dir_uuid}/#{Accession_dir}"

      # What did this variable do?
      # @mdd = md_dir;
      
      # Create meta data directory
      FileUtils.mkdir_p(md_dir);
      Rubymatica.save_status(dir_uuid, "Created dir #{md_dir}")

      FileUtils.mkdir_p("#{Dest}/#{dir_uuid}")
      Rubymatica.save_status(dir_uuid, "Created dir #{Dest}/#{dir_uuid}")
      
      FileUtils.mkdir_p(igl_dest)
      Rubymatica.save_status(dir_uuid, "Created dir #{igl_dest}")
      
      # Create the possible virus directory.
      FileUtils.mkdir_p(pv_dir);
      Rubymatica.save_status(dir_uuid, "Created dir #{pv_dir}")
      
      # Create ingest / accession directory
      FileUtils.mkdir_p(ac_dir);
      Rubymatica.save_status(dir_uuid, "Created dir #{ac_dir}")

      Rubymatica.save_status(dir_uuid, "Processing directory: #{Accession_dir} uuid: #{dir_uuid}")

      # For now do not leave the db open. Other code that needs it will
      # open it. Just create the db if necessary. Opening the db, leaving
      # it open, and closing it would be a nice use of class instantiation
      # and destruction.

      # It is ok to open an empty db, but you'll get an error if you try
      # to query the empty db. If the file is size zero or empty, then
      # init with the SQL in the status schema file.
      
      # File.size? returns nil if file_name doesn't exist or has zero
      # size, the size of the file otherwise. Therefore we can use it
      # instead of File.exists? when we want to check both exists and size
      # zero.

      db_file = "#{md_dir}/#{Db_name}"
      db = SQLite3::Database.new(db_file)
      if (! File.size?(db_file))
        sql_source = File.expand_path(File.dirname(__FILE__)) + "/" + Status_schema
        db.execute_batch(IO.read(sql_source))
      end
      db.close

      # Create some convenience methods to save stuff in the sql dbs.
      my_ig = Ingest.new(dir_uuid)

      # By extracting here, we can put the extract log into the proper
      # location rather than copying it to a tmp dir first. This code is
      # a tad messy. Extract, copy to dest, then clean up. These three
      # sections of code must be in this order. There are several blocks
      # of code, not just the if statement below.

      # Feb 18 2011 When we changed to using Accession_dir "accession" as
      # the top level of the accessioned files, the original directory
      # becomes the only folder at the top level of the ingest. It seems a
      # bit odd to always have the extra directory "accession" in the
      # destination directory tree uuid/accession/ingest_name but that is
      # the logical and easy to deal with as long as we are
      # consistent. The code is simplified when it comes to finding the
      # ingest directory. I though about removing the directory below
      # ./accession/ when the ingest was a .tar or .zip full of naked
      # files, but we must extract into a directory so we might as well
      # keep the directory we extracted into. We must extract into a
      # directory because we extract into ./orig/ and there are likely to
      # be other ingests in there. Besides, it (always) makes sense to
      # extract into a directory.

      if (extract_flag)
        # path, log_path, dir_uuid
        # writes all i/o to #{log_path}/process_sip.log
        extract_path = easy_extract(extract_orig, igl_dest, dir_uuid)
        if (extract_path.empty?)
          Rubymatica.save_status(dir_uuid, "Nothing to extract from #{extract_path}")
        else
          Rubymatica.save_status(dir_uuid, "Extracted #{extract_orig} to #{extract_path}")
          # If our unpacked archive resulted in a single top level
          # directory, make the ingest that top level
          # directory. Find.find() always finds the current dir as element
          # zero, so the first file or dir is element one.
          
          file_list = []
          Find.find(extract_path) { |file|
            file_list.push(file)
          }

          # Test file_list.length first otherwise we'll have an error from
          # directory?() on a nil string.
          
          if (file_list.length >=2 and File.directory?(file_list[1]))
            extract_path = file_list[1]
            Rubymatica.save_status(dir_uuid, "After extract, ingest folder: #{file_list[1]}")
          end
        end
      end

      # base_name used to be assigned, and then full_path was changed
      # afterwards. That relied on some conventions that were not well
      # enforced and eventually created a bug.

      if (extract_path.length > 0)
        base_name = File.basename(extract_path)
      else
        base_name = File.basename(full_path)
      end

      # Save ingest name to the db. Note that in some other places where
      # "ingest_name" is used, we have to use the const Accession_dir.
      my_ig.write_meta("ingest_name", base_name)


      # One more fix. Just in case the base name of full_path has wacky
      # chars, fix it. Don't bother with fixing things inside the dir
      # because detox will handle that later. The old fp_base goes away
      # when we start using Accession_dir, along with some convoluted
      # logic.

      Rubymatica.save_status(dir_uuid, "Ingesting from origin full_path: #{extract_path}")
      
      # I've left the code below here for historical reference. Someone
      # should make sure that there can't be funny chars in ingest
      # directory names.

      # if (fp_base.gsub!(/[^A-Za-z0-9\-_\.]/, '_'))
      #   tub = "#{Dest}/#{dir_uuid}/#{fp_base}"
      #   clean_fd = File.open("#{igl_dest}/#{Fclean}", "a")
      #   clean_fd.print("cleaned: #{full_path} to: #{tub}\n")
      #   clean_fd.close()
      # else
      #   tub = "#{Dest}/#{dir_uuid}/#{fp_base}"
      # end

      # tub memnonic for desT Uuid Base. Having switched to a fixed dir
      # name for the accession, tub may be an outdated concept. tub and
      # ac_dir are identical.

      tub = "#{Dest}/#{dir_uuid}/#{Accession_dir}"

      Rubymatica.save_status(dir_uuid, "Final ingest destination directory: #{tub}")

      FileUtils.mv(extract_path, tub)
      Rubymatica.save_status(dir_uuid, "Moved #{extract_path} to #{tub}")

      if (extract_path.match(/^(.*)\//))
        extract_parent = $1;
        if (Dir.entries(extract_parent).length == 2)
          Dir.delete(extract_parent)
          Rubymatica.save_status(dir_uuid, "Delete empty dir #{extract_parent}")
        end
      end

      if (extract_flag && File.exists?(extract_orig))

        # Feb 24 2011 It appears that if we extracted a .tar or .zip the
        # mv below will move the original archive to some location out of
        # the way. Presumably the extract was successful so now the files
        # are in Rubymatica. Keeping the original archive file merely an
        # excess of caution. I'm unclear why this code isn't further up
        # with the rest of the extract code.

        `#{Mv_exe} --backup=t #{extract_orig} #{Archive_path}`
        Rubymatica.save_status(dir_uuid, "Moved original  #{extract_orig} to #{Archive_path}")
      end
      return base_name,dir_uuid, my_ig, tub, igl_dest, pv_dir, md_dir, ac_dir, extract_flag
    end # end reproc_false


    # This ingest is being reprocessed. Lots of stuff we did before has to
    # be thrown away and redone.

    def reproc_true(file)
      full_path = file
      if (! File.exists?(full_path))
        # Rubymatica.save_status(dir_uuid, "Can't reprocess, #{full_path} does not exist.")
        print "Can't reprocess, #{full_path} does not exist.\n";
        exit
      end
      extract_flag = false
      dir_uuid = File.basename(full_path)
      
      # When reprocessing, the meta_data/info.db already exists (or else
      # this will fail), therefore we can look in the db for info such
      # as the name of this ingest.
      
      my_ig = Ingest.new(dir_uuid)
      
      base_name = my_ig.read_meta("ingest_name")
      tub = "#{Dest}/#{dir_uuid}/#{Accession_dir}"
      
      Rubymatica.save_status(dir_uuid, "Reprocessing #{Accession_dir} uuid: #{dir_uuid}")
      
      igl_dest = "#{Dest}/#{dir_uuid}/#{Ig_logs}"
      pv_dir = "#{Dest}/#{dir_uuid}/#{Pv}"
      md_dir = "#{Dest}/#{dir_uuid}/#{Meta}"
      ac_dir = "#{Dest}/#{dir_uuid}/#{Accession_dir}"
      
      # Delete any previously machine created files. Keeping files
      # would mean using previously created file uuid's and that
      # would be a mess. This codes doesn't have the architecture
      # for that.

      # Use an anonymous array because we can. Directories that we'll
      # clean up, followed by a list of files we will *not* delete.

      [igl_dest, pv_dir, md_dir].each { |path|
        Find.find(path) { |file|
          if (file.match(Dcx) or 
              file.match(Db_name))
            next;
          end

          # Great line of code. OOP totally rocks. Not! Class,
          # method and variable all the same name, and you thought
          # programmers didn't have a sense of humor.
          
          if (File.file?(file))
            File.delete(file)
          end
        }
      }
      return base_name,dir_uuid, my_ig, tub, igl_dest, pv_dir, md_dir, ac_dir, extract_flag
    end


    # Process an single ingest directory. Our convention is that any
    # directory in the origin dir is a separate ingest. Code that calls
    # process_one() will look at all depth=1 dirs and files in the orig
    # dir.

    def process_one(file, reproc)
      
      # We are a child process here. We can't simply close our output
      # streams, but we have to reopen and sync them as well. Send them to
      # a log file.

      log_file = File.expand_path(Script_path) + "/" +  err_name()
      $stdout.reopen(log_file, "a")
      $stdout.sync = true
      $stderr.reopen($stdout)

      extract_flag = false

      if (! reproc)
        base_name,
        dir_uuid, 
        my_ig,
        tub,
        igl_dest,
        pv_dir,
        md_dir,
        ac_dir,
        extract_flag = reproc_false(file)
      else
        base_name,
        dir_uuid,
        my_ig,
        tub,
        igl_dest,
        pv_dir,
        md_dir,
        ac_dir,
        extract_flag = reproc_true(file)
      end 
      
      # Why does Archivematica chmod the dir to 700? We don't have users
      # sharing, or even knowing about each other's dirs so changing
      # folder privs isn't necessary for us.
      
      create_dublin_core("#{md_dir}/#{Dcx}", dir_uuid)
      Rubymatica.save_status(dir_uuid, "Dublin core done")
      
      # If we have not already extracted files at the beginning of ingest,
      # then extract tar zip rar, etc. (directory_to_scan_for_archives,
      # log_directory). Archive unpack destination is named using our
      # usual convention for extract dire names (xyz_dir1). See def
      # easy_extract.

      if (! extract_flag)
        Rubymatica.save_status(dir_uuid, "Archive extract started...")
        easy_extract(tub, igl_dest, dir_uuid)
        Rubymatica.save_status(dir_uuid, "Archive extract done")
      end

      Rubymatica.save_status(dir_uuid, "Detox started...")

      # run_detox(working_path, log_full_name, brief_log_full_name)

      # If run_detox changes a path, it will immediately return with a
      # true value, and the while loop will start it all over
      # again. This may be crude but it is easier than dynamically
      # recursing down a directory tree.

      while(run_detox(tub, "#{igl_dest}/#{Fclean}", "#{igl_dest}/#{Fclean_brief}") == true)
      end

      Rubymatica.save_status(dir_uuid, "Wrote #{igl_dest}/#{Fclean} and #{igl_dest}/#{Fclean_brief}")
      Rubymatica.save_status(dir_uuid, "Detox done")

      # What is this? I think it might be the base name of this
      # ingest. Are we using it?

      clean_name = `#{Ls_exe} #{tub}/`.chomp

      # Scan for viruses. The summary is only printed once. Note that
      # infected files are moved to a temp directory by clamscan, then
      # Ruby code creates an appropriate relative path inside the
      # possible_virus directory, and moves the infected file
      # there. This prevents file name conflicts and insures that we
      # can always relate an infected file back to the original
      # directory location. Note also that tar, rar, and zip files
      # containing infected files will also be moved. We assume that
      # they have been un-archived by the time clamscan sees them, but
      # it could be confusing to be "missing" an archive file.

      # Perhaps ideally, we would *not* allow clamscan to move files,
      # but instead feed it a directory tree, and parse the output,
      # moving the infected files ourselves. Consider this as a future
      # feature.

      # --stdout sends any non-libclamav output to stdout. The
      # libclamav output goes to stderr and should be logged to
      # Vwarn. The option --move moves potentially infected files to a
      # directory. The option --quiet stops output except error
      # messages, and therefore --quiet is bad when you want to have a
      # record of what was done so I recommend not using
      # --quiet. Historically, --quiet was used during development,
      # but since it was quiet, the tests were not too meaningful.
      
      # Create a unique dir name via uuid. Use this as a temp staging
      # area. clamscan can't create dirs and we need the full original
      # path name (relative to the root dir of the ingest).
      
      pv_uuid = `#{Uuid_exe} -v 4`.chomp;
      pv_temp = "#{pv_dir}/#{pv_uuid}"
      FileUtils.mkdir_p(pv_temp)

      Rubymatica.save_status(dir_uuid, "Antivirus started...")
      
      # First time through, display the summary, so we know version number, etc.

      no_summary = ""
      Rubymatica.traverse(tub, false).each { |file|
        if (File.file?(file))
          fn = File.basename(file)
          Rubymatica.save_status(dir_uuid, "#{file} ...")
          cs_args = "--stdout #{no_summary} --move=#{pv_temp} #{file}"
          `#{Clamscan_exe} #{cs_args}  >>  #{igl_dest}/#{Vscan} 2>> #{igl_dest}/#{Vwarn}`
          
          if (no_summary.empty?)
            log_fd = File.open("#{igl_dest}/#{Vscan}", "a")
            log_fd.print("(Summary message above does not reflect accurate counts of files.)\n")
            log_fd.close()
          end
          no_summary = "--no-summary"

          # Check for our file in the possible_virus temp staging
          # area. If it exists, build a path based on the original
          # name, and move the file from the pv temp dir to the final
          # full-ingest-path pv dir. And write to the log file.

          pv_fn = "#{pv_temp}/#{fn}"
          if File.exists?(pv_fn)
            rel_path = file.match(/#{ac_dir}\/(.*)/)[1]
            pv_dest = File.dirname("#{pv_dir}/#{rel_path}")
            FileUtils.mkdir_p(pv_dest)
            FileUtils.mv(pv_fn, pv_dest)
            log_fd = File.open("#{igl_dest}/#{Vscan}", "a")
            log_fd.print("Moved (#{fn}): #{pv_fn} to #{pv_dest}/#{fn}\n")
            log_fd.close()
          end
        end
      }

      Rubymatica.save_status(dir_uuid, "AV done")

      # start_dir (where the files are),
      # dest_dir (where the checksum output goes),
      # out_full (full path to output file)
      # If a checksum already exists, it won't create a new one.

      cs_full = md5_deep(tub, igl_dest, "#{md_dir}/#{Csn}")
      Rubymatica.save_status(dir_uuid, "Generate md5 done")

      # Check the checksums. I'm guessing args are "origin", "checksum
      # file", "process_sip_check.log"

      Rubymatica.save_status(dir_uuid,"Check md5 checksum stared...")
      check_md5(tub, cs_full, "#{igl_dest}")
      Rubymatica.save_status(dir_uuid, "Check md5 done")

      # Run FITS for file id, and assign file uuids. While we're
      # crawling through the file list, write the uuid to file log
      # file that is used later to deconvolute the file uuids.

      Rubymatica.save_status(dir_uuid, "FITS started...")

      skip_fits = false;
      uuid_log_fd = File.open("#{igl_dest}/#{Uuid_log}", "w");
      Rubymatica.traverse(tub, false).each { |file|
        if (File.file?(file) and File.exists?(file))
          Rubymatica.save_status(dir_uuid, "#{file} ...")
          file_uuid = `#{Uuid_exe} -v 4`.chomp
          uuid_log_fd.print "#{file_uuid}\t#{file}\n"
          if (! skip_fits)
            run_fits(file, file_uuid, igl_dest, Fits_dir)
          end
        end
      }
      uuid_log_fd.close()

      # Create an empty FITS database in the log dir. Populate it via
      # insert statements from an xslt script. Put our code in a magical
      # Ruby cd block. This assumes that xsltproc and sqlite3 are in the
      # user's path.

      # fp is memnonic for "FITS processing" 

      fp_log_fd = File.open("#{igl_dest}/fits_processing.log", "w");
      FileUtils.cd(igl_dest) {
        fp_log_fd.print "initializing fits.db\n"
        fp_log_fd.print `#{Cat_exe} #{Script_path}/schema_fits.sql | sqlite3 fits.db`
        file_list = `#{Find_exe} ./ -maxdepth 1 -mindepth 1 -type f -iname "FITS-*.xml"`.split("\n")
        
        file_list.each { |file| 
          # Run xsltproc and pipe results directly to sqlite.
          fp_log_fd.print "inserting data from #{file} into fits.db\n"
          fp_log_fd.print `#{Xsltproc_exe} #{Script_path}/xml_fits2sql.xsl  "#{file}" | sqlite3 fits.db`
        }
      }
      fp_log_fd.print "fits processing complete\n"
      fp_log_fd.close()

      Rubymatica.save_status(dir_uuid, "Created #{igl_dest}/fits.db")
      Rubymatica.save_status(dir_uuid, "FITS done")

      # What happens in fileUUID.py? Maybe it reads the clean file
      # name and dir_uuid from somewhere and logs it. Check this.
      
      # The original AM code takes the ingest_Logs/$DIR_UUID as an
      # arg. Probably unnecessary for us.

      Rubymatica.save_status(dir_uuid, "Create METS started...")

      mets_xml = Create_mets.new(dir_uuid, base_name)
      mets_f = "#{md_dir}/METS.xml"
      File.open(mets_f, "w") { |fd|
        fd.print mets_xml.to_xml;
      }
      Rubymatica.save_status(dir_uuid, "Wrote #{mets_f}")
      Rubymatica.save_status(dir_uuid, "METS create done")
      Rubymatica.save_status(dir_uuid, "Processing complete")
    end # end of process_one()
  end # class Rubymatica
end 
