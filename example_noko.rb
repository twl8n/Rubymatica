#! /usr/bin/ruby 


# mkdir /tmp/1234
# touch filenameCleanup.log
# touch /home/twl8n/am_ruby/FileUUIDs.log
# /home/twl8n/archivematica-read-only/includes/archivematica/xmlScripts/createMETS.py /home/twl8n/am_ruby 1234 clean
# less METS.xml 


require 'nokogiri'
doc = Nokogiri::XML(File.open("METS.xml"))
h3 = Nokogiri::XML::Node.new "h3", doc
h3.content = "1977 - 1984"

fileSec = doc.at_css "fileSec"

fileSec.add_next_sibling(h3)

puts doc.to_xml()
