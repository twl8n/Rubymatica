#!/usr/bin/env ruby

require 'test_helper'
@top_2 = require 'rubygems'
require 'sqlite3'

# http://guides.rubyonrails.org/testing.html
# http://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing

class T_help
  
  def initialize()
    @rh = Hash.new()
    $LOADED_FEATURES.each { |feat| 
      @rh[feat] = 1
    }
  end

  def check_feat(feat)
    return @rh.has_key?(feat)
  end
end

class HelloWorldControllerTest < ActionController::TestCase

  # Apparently there is no :before or :all for TestCase so people
  # recommend switching to RSpec. We brute force initialization by
  # just instantiating T_help where necssary. 

  # http://stackoverflow.com/questions/1032114/check-for-ruby-gem-availability

  # begin
  #   gem "somegem"
  #   # with requirements
  #   gem "somegem", ">=2.0"
  # rescue GEM::LoadError
  #   # not installed
  # end

  # Gem.available?('somegem')
  # # You can use regex expressions too. Handy if I want to allow 'rcov'
  # # and GitHub variants like 'relevance-rcov':
  # Gem.available?(/-?rcov$/)


  # Some tests are (also) indirect via environment.rb:
  # config.gem "nokogiri"
  # config.gem "bagit"
  # config.gem "escape"
  # config.gem "validatable"

  test "bagit" do
    th = T_help.new()
    assert(th.check_feat("bagit.rb"), "Required module bagit not loaded")
  end

  test "nokogiri" do
    th = T_help.new()
    assert(th.check_feat("nokogiri.rb"), "Required module nokogiri not loaded")
  end

  test "escape" do
    th = T_help.new()
    assert(th.check_feat("escape.rb"), "Required module escape not loaded")
  end

  test "validatable" do
    th = T_help.new()
    assert(th.check_feat("validatable.rb"), "Required module validatable not loaded")
  end

  # require returns true the first time a module is loaded. If the
  # module has already been loaded, perhaps by a previous require,
  # then false is returned. Try $LOADED_FEATURES instead.
  if false
    print "all_gems next. top_2: #{@top_2} (should be true) #{@top_2.class}\n"
    test "all_gems" do 
      ['bagit', 'nokogiri'].each { |test_gem|
        print "Testing: #{test_gem}\n"
        rg_result = require 'rubygems'
        gem_result = require test_gem
        print "rg_result: #{rg_result} test gem: #{gem_result} for #{test_gem}\n"
        assert(gem_result, "Could not find gem: #{test_gem}")
      }
    end
  end

  # Kind of a roundabout way to test for existence of a module. At
  # least it works. I suspect that if these modules didn't exist, or
  # did not load, we would get an error from the require at the top of
  # this file.

  test "rubygems" do 
    assert(Gem.is_a?(Module), "Required module rubygems not loaded")
  end

  test "sqlite" do 
    assert(SQLite3.is_a?(Module), "Required module sqlite3 not loaded")
  end

  test "Archive_path" do
    assert(File.exists?(Archive_path), "Missing path: #{Archive_path}")
  end

  test "Puid_db" do
    assert(File.exists?("#{RAILS_ROOT}/#{Puid_db}"),
           "Missing PUID database: #{RAILS_ROOT}/#{Puid_db}")
  end

  test "Rmatic_constants" do
    assert(File.exists?("#{RAILS_ROOT}/rmatic_constants.rb"), "Missing file: rmatic_constants.rb. Copy rmatic_constansts.rb.dist and edit.")
  end

  test "Dest" do
    assert(File.exists?(Dest), "Missing path: #{Dest}")
  end

  test "Zip_exe" do
    assert(File.exists?(Zip_exe), "Missing utility: #{Zip_exe}")
  end

  test "Xsltproc_exe" do
    assert(File.exists?(Xsltproc_exe), "Missing utility: #{Xsltproc_exe}")
  end

  test "Wc_exe" do
    assert(File.exists?(Wc_exe), "Missing utility: #{Wc_exe}")
  end

  test "Uuid_exe" do
    assert(File.exists?(Uuid_exe), "Missing utility: #{Uuid_exe}")
  end

  test "Unrar_exe" do
    assert(File.exists?(Unrar_exe), "Missing utility: #{Unrar_exe}")
  end

  test "Sevenza_exe" do
    assert(File.exists?(Sevenza_exe), "Missing utility: #{Sevenza_exe}")
  end

  test "Rmdir_exe" do
    assert(File.exists?(Rmdir_exe), "Missing utility: #{Rmdir_exe}")
  end

  test "Rm_exe" do
    assert(File.exists?(Rm_exe), "Missing utility: #{Rm_exe}")
  end

  test "Origin" do
    assert(File.exists?(Origin), "Missing path: #{Origin}")
  end

  test "Mv_exe" do
    assert(File.exists?(Mv_exe), "Missing utility: #{Mv_exe}")
  end

  test "Md5deep_exe" do
    assert(File.exists?(Md5deep_exe), "Missing utility: #{Md5deep_exe}")
  end

  test "Ls_exe" do
    assert(File.exists?(Ls_exe), "Missing utility: #{Ls_exe}")
  end

  test "Fits_full" do
    assert(File.exists?(Fits_full), "Missing utility: #{Fits_full}")
  end

  test "Fits_dir" do
    assert(File.exists?(Fits_dir), "Missing path: #{Fits_dir}")
  end

  test "Find_exe" do
    assert(File.exists?(Find_exe), "Missing utility: #{Find_exe}")
  end

  test "Echo_exe" do
    assert(File.exists?(Echo_exe), "Missing utility: #{Echo_exe}")
  end

  test "Detox_exe" do
    assert(File.exists?(Detox_exe), "Missing utility: #{Detox_exe}")
  end

  test "Clamscan_exe" do
    assert(File.exists?(Clamscan_exe), "Missing utility: #{Clamscan_exe}")
  end

  test "Cp_exe" do
    assert(File.exists?(Cp_exe), "Missing utility: #{Cp_exe}")
  end

  test "Cat_exe" do
    assert(File.exists?(Cat_exe), "Missing utility: #{Cat_exe}")
  end

end
