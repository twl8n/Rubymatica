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

# The call to Builder creates our main XML document. The resulting
# object has a variable for a node of the XML where we will later add
# an XML document read (parsed) from disk.

# parent() is a Nokogiri::XML::Element

# The variable fits_xml is a Nokogiri::XML::Document

# fits_xml.root is a Nokogiri::XML::Element

# *Note* After calling add_child(fits_xml.root), fits_xml.root becomes
# NilClass, in other words, it is gone, presumably moved into the Builder document.

# The error "... in `add_child': Document already has a root node
# (RuntimeError)..." can mean that you have an uninitialized variable,
# not that you are trying to add a duplicate root node

def xml_fun
  
  @builder = Nokogiri::XML::Builder.new {
    mdWrap( 'MDTYPE' => "FITS") {
      xmlData {
        @f_node = parent()
      }
    }
  }
  
  # This is just an accessor method so we don't have to think about
  # Ruby's treatment of object instance variables.

  def get_fn
    return @f_node
  end

  # We should be explicit about what we're returning.

  return @builder
end

def add_fits(parent)
  fits_xml = Nokogiri::XML(IO.read("noko_test.xml"))
  
  print "class type of fits_xml is: #{fits_xml.class}\n";
  print "class type of fits_xml.root is: #{fits_xml.root.class}\n";
  print "class type of parent is: #{parent.class}\n"
  
  parent.add_child(fits_xml.root)
  
  print "after calling add_child() class type of fits_xml.root is: #{fits_xml.root.class}\n";
  
end

# Create our main document object. The object has an instance variable
# f_node (which is private), and an accessor method get_fn (which is
# public).

main_doc = xml_fun()

add_fits(main_doc.get_fn)

# Uncomment the following line to see a confusing error about add_child.
# puts main_doc.builder.stuff

print "\nThe created XML:\n\n #{main_doc.to_xml}\n"

