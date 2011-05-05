# Constant names must be capitalized. Script_path below is the most
# common const that needs to be changed for a given install.

# The name of the directory that holds the accession ingest
# files. This is #{Dest}/#{uuid}/#{Accession_dir} where uuid is a variable determined at runtime.
Accession_dir = "accession"

Archive_path = "/home/#{ENV['USER']}/archive"
# Bagit_file = "bag.zip"
Cat_exe = "/bin/cat"
# Full path to cp
Cp_exe = "/bin/cp"
Clamscan_exe = "/usr/bin/clamscan"
Csn = "md5checksum.txt" # memnonic: check sum name
# Some info about an ingest. Created automatically.
Db_name = "info.db"
# Empty DC file copied into an ingest.
Dcx = "dublin_core.xml"
# You must create this directory as part of the Rubymatica install.
Dest = "/home/#{ENV['USER']}/dest"
Detox_exe = "/usr/local/bin/detox"
Echo_exe = "/bin/echo"
Fail_name = "fail.txt"
Fclean = "file_name_clean_up.log"
#Find_exe = "/usr/bin/find"

Foo_bar = stuff

# Use the standard Archivematica path to FITS. 
Fits_dir = "/opt/externals/fits"
Fits_full = "/opt/externals/fits/fits.sh"

Generic_xml = /.*\.xml/i

# Log files from various ingest processes. In #{Desr}/#{uuid}/#{Ig_logs}
Ig_logs = "ingest_logs"
Ls_exe = "/bin/ls"
Logs = "logs"
Md5deep_exe = "/usr/local/bin/md5deep"
# Meta data directory name in each ingest.
Meta = "meta_data"
Mets_file = "METS.xml"
Msg_schema = "msg_schema.sql"
Mv_exe = "/bin/mv"

# Look for the dublin core file in the dir where this script is
# running. This saves yet another "where are my config files"
# question.

Orig_dc = File.expand_path(File.dirname(__FILE__)) + "/" + Dcx

# You must create the orig directory as part of the Rubymatica install.
Origin = "/home/#{ENV['USER']}/orig"
Pass_name = "pass.txt"
Puid_db = "puid.db"
# Quarantine directory. Automatically created as necessary. Per ingest.
Pv = "possible_virus"
Report_name = "checksum_report.txt"
# Single session message db. Automatically created. Per Rubymatica instance.
Rmatic_db = "rmatic.db"
# Full path to rm
Rm_exe = "/bin/rm"
Rmdir_exe = "/bin/rmdir"
Se = "sip_errors"
Sevenza_exe = "/usr/local/bin/7za"
Status_schema = "status_schema.sql"

# Stupid Rails or Webrick doesn't cd back to the script's starting dir
# when redirecting. If the script does a chdir, it can't remember
# where it's home directory was. Just create a constant for it. Real
# pita will have to be edited for each installation. Oh well. The
# Orig_db trick might work, but then again, it might re-init for the
# redirect.

Script_path = "/home/#{ENV['USER']}/aims_1/am_ruby"
Taper_file = "taper_submission.xml"
# This has to match what is in the alias in /etc/httpd/conf/httpd.conf
Taper_url = "/taper"
Tmp = "#{Dest}"
Unrar_exe = "/usr/bin/unrar"
Uuid_exe = "/usr/bin/uuid"
Uuid_log = "file_uuid.log"
Vscan = "virus_scan.log"
Vwarn = "virus_warn.log"
Wc_exe = "/usr/bin/wc"
Xsltproc_exe = "/usr/bin/xsltproc"
# Full path to zip
Zip_exe = "/usr/bin/zip"
