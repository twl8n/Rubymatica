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

# Create an XML document with Builder, and add inner (child) elements
# in a separate method. In this example, the new elements are added
# inside the initialize() method, as opposed to being called later,
# after the object has been fully instantiated. See noko_late_child.rb
# for the "later" example.

class Test_child

  # Define create_new_element before calling it below. 

  def create_new_element(arg, fs_parent)
    
    # We build the new element independent of the rest of the
    # tree. This is a new Builder object.

    fbuilder = Nokogiri::XML::Builder.new {
      new_element(:ID => "stuff", :USE => "directory") {
        inner_element(arg)
      }
    }

    # Note that after calling add_child, the root element is *moved*
    # to fs_parent, not just copied. Method add_child() modifies its
    # argument, thus we have a side effect you need to be aware of.

    print "pre: #{fbuilder.doc}\n"
    fs_parent.add_child("<test_ele>literal string element add</test_ele>")
    fs_parent.add_child(fbuilder.doc.root)
    print "post: #{fbuilder.doc}\n"
  end

  # Test_child.new will call this initialize() method. 

  def initialize

    # This call to Builder creates our main XML document. 

    @builder = Nokogiri::XML::Builder.new {
      wrap_it( 'WRAP' => "demo") {
        # The parent element is "wrap_it", thus method parent()
        # returns a Nokogiri::XML::Element that we can operate on later.
        @fs_parent = parent;
      }
      
      # This is our home grown accessor method since @fs_parent is an
      # instance variable and is normally private.

      def fs_parent
        return @fs_parent;
      end
    }

    print "Parent class: #{@builder.fs_parent.class}\n"

    # Create two new child elements just to demonstrate how we use an
    # parameter to the method. We are still in method initialize() so
    # the code below runs during Test_child.new(). In some cases you
    # may want to create the Builder object, have some instance
    # variables for elements to be expanded, and add those child
    # elements long after initialize() has been called.

    create_new_element("one", @builder.fs_parent);
    create_new_element("two", @builder.fs_parent);
  end

  # A simple accessor method for the @builder private instance
  # variable.

  def builder
    return @builder
  end

end

# Create new Test_child which will build the whole XML document,
# including the child elements. builder() returns the XML document,
# and to_xml() renders is as text.

puts Test_child.new.builder.to_xml
