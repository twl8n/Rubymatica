#!/usr/bin/env ruby 

$LOAD_PATH.push(":#{File.expand_path(File.dirname(__FILE__))}")

# $:.concat(":",Script_path)

require 'rubymatica'
require 'optparse'
require 'sqlite3'

include Rmatic

redo_dir = ""
arg = ""
ingest_dir = ""
op = OptionParser.new { |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  
  opts.on("-d", "--dir [uuid]", "Re-process directory uuid in #{Dest}") { |dd|
    redo_dir = dd
    arg = "dd"
  }

  opts.on("-i", "--ingest [ingest_name]", "Process directory or archive file ingest_name") { |ii|
    ingest_dir = ii
    arg = "in"
  }

  opts.on("-p", "--port [port]", "Use port number instead of pid for error log name") { |pp|
    @port_num = pp
  }


}
op.parse!

if (arg == "dd")
  if (! redo_dir.empty? and File.exists?("#{Dest}/#{redo_dir}"))
    Rubymatica.new("#{Dest}/#{redo_dir}", true)
  end
elsif (arg == "in")
  Rubymatica.new(ingest_dir, false)
else
  Rubymatica.new("", false)
end
