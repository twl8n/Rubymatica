require 'test_helper'

# http://guides.rubyonrails.org/testing.html
# http://en.wikibooks.org/wiki/Ruby_Programming/Unit_testing

class HelloWorldControllerTest < ActionController::TestCase

  test "Archive_path" do
    assert(File.exists?(Archive_path), "Missing path: #{Archive_path}")
  end
  # test "" do
  #   assert(File.exists?(), "Missing path: #{}")
  # end
  test "Zip_exe" do
    assert(File.exists?(Zip_exe), "Missing path: #{Zip_exe}")
  end
  test "Xsltproc_exe" do
    assert(File.exists?(Xsltproc_exe), "Missing path: #{Xsltproc_exe}")
  end
  test "Wc_exe" do
    assert(File.exists?(Wc_exe), "Missing path: #{Wc_exe}")
  end
  test "Uuid_exe" do
    assert(File.exists?(Uuid_exe), "Missing path: #{Uuid_exe}")
  end
  test "Unrar_exe" do
    assert(File.exists?(Unrar_exe), "Missing path: #{Unrar_exe}")
  end
  test "Sevenza_exe" do
    assert(File.exists?(Sevenza_exe), "Missing path: #{Sevenza_exe}")
  end
  test "Rmdir_exe" do
    assert(File.exists?(Rmdir_exe), "Missing path: #{Rmdir_exe}")
  end
  test "Rm_exe" do
    assert(File.exists?(Rm_exe), "Missing path: #{Rm_exe}")
  end
  test "Origin" do
    assert(File.exists?(Origin), "Missing path: #{Origin}")
  end
  test "Mv_exe" do
    assert(File.exists?(Mv_exe), "Missing path: #{Mv_exe}")
  end
  test "Md5deep_exe" do
    assert(File.exists?(Md5deep_exe), "Missing path: #{Md5deep_exe}")
  end
  test "Ls_exe" do
    assert(File.exists?(Ls_exe), "Missing path: #{Ls_exe}")
  end
  test "Fits_full" do
    assert(File.exists?(Fits_full), "Missing path: #{Fits_full}")
  end
  test "Fits_dir" do
    assert(File.exists?(Fits_dir), "Missing path: #{Fits_dir}")
  end
  test "Find_exe" do
    assert(File.exists?(Find_exe), "Missing path: #{Find_exe}")
  end
  test "Echo_exe" do
    assert(File.exists?(Echo_exe), "Missing path: #{Echo_exe}")
  end
  test "Detox_exe" do
    assert(File.exists?(Detox_exe), "Missing path: #{Detox_exe}")
  end
  test "Clamscan_exe" do
    assert(File.exists?(Clamscan_exe), "Missing path: #{Clamscan_exe}")
  end
  test "Cp_exe" do
    assert(File.exists?(Cp_exe), "Missing path: #{Cp_exe}")
  end
  test "Cat_exe" do
    assert(File.exists?(Cat_exe), "Missing path: #{Cat_exe}")
  end



end
