#! /usr/bin/ruby 

# Created by Tom Laudeman 2010
# Copyright 2010 University of Virginia

# This program is free software: you can redistribute it and/or modify
# it under the terms of the Lesser GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Lesser
# GNU General Public License for more details.

# You should have received a copy of the Lesser GNU General Public
# License along with this program. If not, see
# http://www.gnu.org/licenses/ or
# http://www.gnu.org/licenses/lgpl.html


require 'rubygems'
require 'nokogiri'
require 'find'

# The call to Builder creates our main XML document. This example
# demonstrates parsing an external XML file and adding it to a
# specific node in our Builder object. This is the simple case because
# the external XML is added 'inline' in the Builder code, as opposed
# to saving the parent and adding a child node later.

# parent() is a Nokogiri::XML::Element

# The variable fits_xml is a Nokogiri::XML::Document

# fits_xml.root is a Nokogiri::XML::Element

# *Note* After calling add_child(fits_xml.root), fits_xml.root becomes
# NilClass, in other words, it is gone, presumably moved into the Builder document.

def self.xmlfun
  
  @builder = Nokogiri::XML::Builder.new {
    mdWrap( 'MDTYPE' => "FITS") {
      xmlData {
        fits_xml = Nokogiri::XML(IO.read("noko_test.xml"))

        print "class type of fits_xml is: #{fits_xml.class}\n";
        print "class type of fits_xml.root is: #{fits_xml.root.class}\n";
        print "class type of parent is: #{parent.class}\n"

        parent.add_child(fits_xml.root)

        print "after calling add_child() class type of fits_xml.root is: #{fits_xml.root.class}\n";
      }
    }
  }
  
  # We should be explicit about what we're returning.

  return @builder
end

# Running the exciting xmlfun() method returns a Builder object which
# has the to_xml() method which will print the XML we just created.

print "\nThe created XML:\n\n #{xmlfun.to_xml}\n"

