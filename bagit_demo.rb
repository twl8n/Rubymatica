#! /usr/bin/ruby 

# Create a directory with only files and folders you wish to bag. Your
# original directory tree will not be changed. This script will create
# a "bag" dir in your main directory. All of your files will be copies
# to bag/data in order to create the bag.

# Create the data dir in the dir_uuid directory, copy everything into
# it, then run this. If the data dir is empty, there won't be
# manifest-* files.

require 'rubygems'
require 'bagit'
require 'fileutils'

dir_uuid = "/home/twl8n/dest/7578b42a-c2c9-446c-8ec9-3ebfa15e9fe9"

# If a bag dir already exists, then exit. File.exist? works for dirs
# too. There is no Dir.exist?.

if (File.exist?(File.join(dir_uuid, "bag")))
  print "#{File.join(dir_uuid, "bag")} exists.\n"
  print "Cannot overwrite or modify an existing bag directory. Exiting.\n";
  exit
end

# Save the list of top level files and dirs before the bag dir is
# created. Use the pure Ruby method of getting the top level list of
# files and directories.

top_level_list = Dir[File.join(dir_uuid, '*')]

# New bagit object also creates ./bag and /bag/data

bag = BagIt::Bag.new "#{dir_uuid}/bag"

# copy files from dir_uuid into bag/data by each()ing through the
# list. Don't forget to chomp the copy_me origins because they came
# from a backticked command.

top_level_list.each { |copy_me|
  copy_me.chomp!
  printf "copying #{copy_me}\n";
  `cp -a #{copy_me} #{dir_uuid}/bag/data`

  # cp_r has a bug. Do not use. The pure Ruby solution below uses
  # cp_r. Use File.join as a valiant attempt to be OS
  # portable. Preserve timestamps. (I guess :preserve is like cp -a,
  # but the Ruby docs don't say what each option does, so we have to
  # guess.)  Unfortunately, cp_r has a bug, and fails to preserve
  # directory timestamps. See Note 1 below.
  
  # FileUtils.cp_r(copy_me, File.join(dir_uuid, "bag", "data"), :preserve => true)
}

puts "bag files:";
bag.bag_files.sort.each { |tf|
  puts tf
}

puts "tag files pre manifest creation";
bag.tag_files.sort.each { |tf|
  puts tf
}

# bag_files are all files in data_dir, recursive
# tag_files are only files in the top level bag dir.

bag.manifest!

puts "tag files post manifest creation";
bag.tag_files.sort.each { |tf|
  puts tf
}

bag.tagmanifest!

puts "tag files post tag-manifest creation";
bag.tag_files.sort.each { |tf|
  puts tf
}

# See Note 2 below. Generate a list of all methods, sorted. The BagIt
# docs don't list available methods.

#  puts bag.methods.sort


exit

# Note 1.

# The results of using cp -a. All mod times are preserved.

# > find /home/twl8n/dest/7578b42a-c2c9-446c-8ec9-3ebfa15e9fe9/bag/data/ -printf "%12t %f\n"
# Thu Nov  4 10:59:37.0176703590 2010 data/
# Wed Sep 22 16:41:47.0044833591 2010 possible_virus
# Fri Oct 29 15:38:43.0152684153 2010 ingest_1
# Wed Aug 18 15:15:09.0688870638 2010 readme.txt
# Wed Sep 22 16:41:52.0593691139 2010 meta_data
# Wed Sep 22 16:41:52.0593691139 2010 info.db
# Wed Sep 22 16:41:47.0083847376 2010 dublin_core.xml
# Wed Sep 22 16:41:52.0584879480 2010 METS.xml
# Wed Sep 22 16:41:47.0154714575 2010 md5checksum.txt
# Wed Sep 22 16:41:52.0504995098 2010 ingest_logs
# Wed Sep 22 16:41:52.0513698555 2010 FITS-83861067-452b-4f31-b4b3-0f3ea8b3566f-readme.txt.xml
# Wed Sep 22 16:41:52.0567024450 2010 file_uuid.log
# Wed Sep 22 16:41:47.0339784734 2010 checksum_report.txt
# Wed Sep 22 16:41:47.0112669158 2010 file_name_clean_up.log


# The results of using cp_r with :preserve => true. Directories do not have their original modified time.

# > find /home/twl8n/dest/7578b42a-c2c9-446c-8ec9-3ebfa15e9fe9/bag/data/ -printf "%12t %f\n"
# Thu Nov  4 11:05:19.0657290149 2010 data/
# Wed Sep 22 16:41:47.0000000000 2010 possible_virus
# Thu Nov  4 11:05:19.0655245615 2010 ingest_1
# Wed Aug 18 15:15:09.0000000000 2010 readme.txt
# Thu Nov  4 11:05:19.0657290149 2010 meta_data
# Wed Sep 22 16:41:52.0000000000 2010 info.db
# Wed Sep 22 16:41:47.0000000000 2010 dublin_core.xml
# Wed Sep 22 16:41:52.0000000000 2010 METS.xml
# Wed Sep 22 16:41:47.0000000000 2010 md5checksum.txt
# Thu Nov  4 11:05:19.0657290149 2010 ingest_logs
# Wed Sep 22 16:41:52.0000000000 2010 FITS-83861067-452b-4f31-b4b3-0f3ea8b3566f-readme.txt.xml
# Wed Sep 22 16:41:52.0000000000 2010 file_uuid.log
# Wed Sep 22 16:41:47.0000000000 2010 checksum_report.txt
# Wed Sep 22 16:41:47.0000000000 2010 file_name_clean_up.log


# Note 2. List of all methods for a bag object. You'll have to read
# the source to figure out what each one does. 


# ==
# ===
# =~
# __id__
# __send__
# add_error
# add_file
# add_remote_file
# all_validations
# bag_dir
# bag_files
# bag_info
# bag_info_txt_file
# bagit
# bagit_txt_file
# class
# clone
# complete?
# consistent?
# data_dir
# display
# dup
# empty_manifests
# eql?
# equal?
# errors
# extend
# fetch!
# fetch_txt_file
# fixed?
# freeze
# frozen?
# gc!
# hash
# id
# increment_times_validated_for
# inspect
# instance_eval
# instance_eval_with_params
# instance_of?
# instance_variable_defined?
# instance_variable_get
# instance_variable_set
# instance_variables
# is_a?
# kind_of?
# manifest!
# manifest_file
# manifest_files
# manifested_files
# method
# methods
# nil?
# object_id
# private_methods
# protected_methods
# public_methods
# read_info_file
# remove_file
# respond_to?
# run_before_validations
# run_validation
# send
# singleton_methods
# tag_files
# tagmanifest!
# tagmanifest_file
# tagmanifest_files
# taint
# tainted?
# times_validated
# times_validated_hash
# to_a
# to_s
# type
# unmanifested_files
# untaint
# valid?
# valid_for_group?
# validate
# validate_only
# validation_levels
# validations_for_level_and_group
# write_bag_info
# write_bagit
# write_info_file
