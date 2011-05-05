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

# This is noko late child because we add child nodes later in the
# process, after our main Builder object has been initialized and
# fully instantiated. The methods to add the new element are called
# from outside the class and thus the code has a slightly different
# structure.

class Test_child

  # Define create_new_element before calling it below. Normally, I'd
  # put initialize() as the first method in a class, but I don't know
  # if Rugy has a method to pre-declare methods.

  def create_new_element(arg, fs_parent)
    
    # We build the new element independent of the rest of the
    # tree. This is a new Builder object and has its own parse
    # tree. That's fine, but note below that we only use .doc.root of
    # our new Builder object.

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

  # Test_child.new() will call this initialize() method. 

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
      
      def inner
        return @fs_parent;
      end
    }
    
  end
  
  # Yet another accessor method to call the accessor method of
  # @builder.

  def outer
    return @builder.inner;
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

tc = Test_child.new()

# We really don't need the builder() method if we only want the inner
# fs_parent because outer() gets it. However, this demonstrates games
# you can play with methods and access to instance variables (which
# are by their nature private).

print "Parent class (accessor 1): #{tc.builder.inner.class}\n"
print "Parent class (accessor 2): #{tc.outer.class}\n"

# Create two new child elements just to demonstrate how we use an
# parameter to the method. 

tc.create_new_element("one", tc.outer);
tc.create_new_element("two", tc.outer);

puts tc.builder.to_xml
