

Table of contents
-----------------
Introduction
Install required packages
Testing the install
How to install and run with Ruby Enterprise and CentOS 5
Troubleshooting
How to install Bagit
How to update a production instance
How to add a new controller
List of files
Testing TAPER integration with Rubymatica
How to install Tufts TAPER SABT
Potential errors while running TAPER


Introduction
------------

Rubymatica's purpose is to processes an ingest into a SIP (submission
information package). The ingest must be in the Origin directory, and
the SIP is created in a unique (uuid) directory in Dest (see
rmatic_constants.rb or rmatic_constants.rb.dist for the
constants). SIP creation involves a number of tasks, and the exact
tasks are evolving. See an existing status log (file or web page) to
get a better idea of what is run.

There are two ways to run Rubymatica: command line, web site. Both are
simply wrappers to call procss_one(). The command line is via
process_sip.rb. The web application is the hello_world_controller
Rails application in this directory tree. The web interface has some
documentation on the main (report) page. There are extensive comments
with each method in rubymatica.rb and hello_world_controller.rb.

With the exception of some external packages, Rubymatica is a Ruby on
Rails web application. It is based on Archivematica and uses the same
external applications. Archivematica is a loose collection of shell
and Python scripts. Rubymatica has many small improvements over
Archivematica's SIP creation, but over all is quite similar.




Install required packages
-------------------------


You can use the "git" command to check out Rubymatica from github, and
you can use it to retrieve updates as well:

# initial checkout
git clone http://github.com/twl8n/Rubymatica.git

# get updates
git pull



yum packages for:
clamscan (clamav), uuid, sqlite3, xsltproc, zip, unzip,

manually built from source:
detox, md5deep, unrar, 7za, (enterprise Ruby)

# According to the clamav web site, Dag Wieers has a good
# repository. In retrospect, this process might have been a little
# easier just going to wieers.com or packages.sw.be for the source
# packages.

http://www.clamav.net/lang/en/download/packages/packages-linux/

Two very good repositories are maintained by Dag Wieers dag at wieers*com:
http://packages.sw.be/clamav/
and Oliver Falk:
SRPMS: http://filelister.linux-kernel.at/?current=/packages/SRPMS/
FC devel: http://rpms.linux-kernel.at/?current=/lkernAT/fedora/core/development/i386
FC 3: http://rpms.linux-kernel.at/?current=/lkernAT/fedora/core/3/i386
RedHat 8.0: http://rpms.linux-kernel.at/?current=/lkernAT/redhat/extras/8.0/i386


# Since Centos clamav will almost certainly always be out of date,
# we'll have to install clamav from some other repo.

# Probably something like this worked for the initial install of the
# (out of date, but working) clamav:

yum -y install clamav clamav-update

[root@aims ~]# rpm -qa > rpm_list.txt
[root@aims ~]#  grep clam rpm_list.txt 
clamav-lib-0.95.1-1.el5
clamav-filesystem-0.95.1-1.el5
clamav-0.95.1-1.el5
clamav-update-0.95.1-1.el5
clamav-data-0.95.1-1.el5
[root@aims ~]#

# Comment out the Example line so the conf file will parse.

[root@aims ~]# emacs -nw /etc/freshclam.conf 

[root@aims ~]# freshclam 
ClamAV update process started at Wed Mar 23 10:23:59 2011
WARNING: Your ClamAV installation is OUTDATED!
...
Database updated (922925 signatures) from database.clamav.net (IP: 64.246.134.219)
[root@aims ~]# 

x install 7za aka p7 from sourceforge sources

   mst3k@aims Tue Mar 22 11:31:38 EDT 2011
   /home/mst3k
> sudo su -l root
[root@aims ~]#
...
wget http://downloads.sourceforge.net/project/p7zip/p7zip/9.20.1/p7zip_9.20.1_src_all.tar.bz2
bunzip2 p7zip_9.20.1_src_all.tar.bz2 
tar -xf p7zip_9.20.1_src_all.tar 
cd p7zip_9.20.1
make
make -n install
make install
[root@aims p7zip_9.20.1]# 

[root@aims p7zip_9.20.1]# make -n install
./install.sh /usr/local/bin /usr/local/lib/p7zip /usr/local/man /usr/local/share/doc/p7zip 
[root@aims p7zip_9.20.1]# less install.sh 
[root@aims p7zip_9.20.1]# make install
./install.sh /usr/local/bin /usr/local/lib/p7zip /usr/local/man /usr/local/share/doc/p7zip 
- installing /usr/local/bin/7za
- installing /usr/local/man/man1/7z.1
- installing /usr/local/man/man1/7za.1
- installing /usr/local/man/man1/7zr.1
- installing /usr/local/share/doc/p7zip/README
- installing /usr/local/share/doc/p7zip/ChangeLog
- installing HTML help in /usr/local/share/doc/p7zip/DOCS
[root@aims p7zip_9.20.1]# 


# Don't know where I got the source for unrar. I do know that I did
# not use the FC12 source rpm.

mv /home/mst3k/unrarsrc-3.9.10.tar.gz .
tar -xzf unrarsrc-3.9.10.tar.gz
cd unrar
# Look at the readme
less readme.txt 
make -f makefile.unix 
# verify that nothing weird happens when we install
make -nf makefile.unix  install
make -f makefile.unix  install

git clone git://pkgs.fedoraproject.org/detox.git
less detox/detox.spec 
wget http://downloads.sourceforge.net/detox/detox-1.2.0.tar.gz
tar xzf detox-1.2.0.tar.gz 
cd detox-1.2.0
./configure 
make
make install

# Download Rubymatica from github, and to a few tasks to get things
# ready. The install directory is named "am_ruby" for historical
# purposes, and to be consistent with this documentation. You may name
# it anything you like.

cd /home/mst3k
git clone git@github.com:mst3k/Rubymatica.git am_ruby
cd am_ruby/
cp -a db_dist db
cp rmatic_constants.rb.dist rmatic_constants.rb
emacs rmatic_constants.rb
mkdir ~/orig
mkdir ~/dest
mkdir ~/archive
cat schema_puid.sql | sqlite3 puid.db
cat puid_list.txt | sqlite3 puid.db
mkdir tmp

Note that config/environment.rb has been modified from the
default. The hello_world_controller.rb works fine with a simple
"require 'rubymatica'" at the top of the file, but the Rails tests
fail due to being in a different path. Oddly the Rails root is not in
the default path. Add it:

  config.load_paths += %W( #{RAILS_ROOT}/ )



Testing the install
-------------------

cd test
./functional/hello_world_controller_test.rb 

or 

/usr/bin/env/ ruby functional/hello_world_controller_test.rb 

Use /usr/bin/env so that you get the correct ruby interpreter. You
must run the tests from the ./test/ directory.




How to install and run with Ruby Enterprise and CentOS 5
--------------------------------------------------------

The ruby and rails distro that is in the yum repo for Centos 5 does
not work. You'll have to install some other ruby stack and the
concensus seems to be Ruby Enterprise installed from source. Even with
Ruby Enterprise, there are issues with some gems, so certain gems have
to be removed and different versions installed. Happily this is easy.


# Installed as root to be system wide. Given the way Phusion Passenger
# mod_passenger works, you can probably install Ruby Enterprie in user
# space. When workin as root, I prefer to "sudo su -l root" one time,
# and then work as user root rather than using sudo for every command.

# You must visit the Ruby Enterprise web site and determine the most
# recent stable version and substitute it as necessary in the commands
# below.

# For this example you are userid "mst3k" on host
# "aims.lib.example.edu" which is a Centos 5 Linux server.

ssh mst3k@aims.lib.example.edu
sudo su -l root
wget http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2011.03.tar.gz
tar -xzf ruby-enterprise-1.8.7-2011.03.tar.gz 
./ruby-enterprise-1.8.7-2011.03/installer
/opt/ruby-enterprise-1.8.7-2011.03/bin/passenger-install-apache2-module

# Edit your Apache configuration file, and add various lines in
# appropriate sections. Remember that your passenger config may be
# different. Use the recommended config from the output of the
# passenger install (the previous command).

LoadModule passenger_module /opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.5/ext/apache2/mod_passenger.so
PassengerRoot /opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.5
PassengerRuby /opt/ruby-enterprise-1.8.7-2011.03/bin/ruby

# There are a few other directives you will probably need in httpd.conf

# Comment out the userdir disable in order to enable userdir.

    # UserDir disable

# Assuming you put the Donor Survey and TAPER submission tool in your
# public_html, give yourself full override privileges.

<Directory /home/mst3k/public_html>
    AllowOverride all
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    <Limit GET POST OPTIONS>
        Order allow,deny
        Allow from all
    </Limit>
    <LimitExcept GET POST OPTIONS>
        Order deny,allow
        Deny from all
    </LimitExcept>
</Directory>

NameVirtualHost *:80

<VirtualHost *:80 >
    ServerName aims.lib.example.edu
    # be sure to point to 'public'!
    DocumentRoot /home/mst3k/am_ruby/public
    setenv RailsEnv development
    # Based on config/environment.rb the var is all caps, with underscore
    # This works (but still serves the test instance)
    setenv RAILS_ENV development

    setenv PassengerLogLevel 3
    setenv PassengerUseGlobalQueue on
    setenv RailsFrameworkSpawnerIdleTime 0
    setenv RailsAppSpawnerIdleTime 0

    <Directory /home/mst3k/am_ruby/public >
       # relax Apache security settings
       AllowOverride all
       # MultiViews must be turned off
       Options -MultiViews
       AuthUserFile /home/mst3k/.htpasswd
       AuthGroupFile /dev/null
       AuthName Rubymatica
       AuthType Basic
       require valid-user
    </Directory>
</VirtualHost>

# See below for changes to the local .htaccess. Change .htaccess at
# the end when you are no longer logged in as root.

# Install without docs. I get all my docs on the www. Besides, there
# were errors or warnings when installing the docs.

/opt/ruby-enterprise-1.8.7-2011.03/bin/gem install sqlite3-ruby --version '1.2.5' --no-rdoc --no-ri
/opt/ruby-enterprise-1.8.7-2011.03/bin/gem list
...
sqlite3-ruby (1.2.5)
...

# There is a problem with rails 3.0.5 under Centos. Bad or
# incompatible version of rails, so go with 2.3.11 there was a web
# site with the error that script/server threw.

/opt/ruby-enterprise-1.8.7-2011.03/bin/gem uninstall rails
/opt/ruby-enterprise-1.8.7-2011.03/bin/gem install rails -v'2.3.11'  --no-rdoc --no-ri

# Rubymatica needs nokogiri and bagit.

/opt/ruby-enterprise-1.8.7-2011.03/bin/gem install nokogiri --no-rdoc --no-ri

cd ~/					   
git clone git://github.com/flazz/bagit.git
cd bagit/
/opt/ruby-enterprise-1.8.7-2011.03/bin/gem install bagit validatable --no-rdoc --no-ri

/etc/init.d/httpd restart

exit

cd ~/public_html/min_lims

# Edit or create the .htaccess and put in everything between -- below.
  
emacs .htaccess
--
# Necessary to disable passenger for non-rails directories. 
# Causes an error if passenger is not running, but that's easy enough to fix.

PassengerEnabled off 

Options indexes
DirectoryIndex index.pl

AddHandler cgi-script .pl
Options ExecCGI All
--

Rubymatica:

http://aims.lib.example.edu/

Donor Survey:

http://aims.lib.example.edu/~mst3k/min_lims/

which should redirect to:

http://aims.lib.example.edu/~mst3k/min_lims/login.pl



Troubleshooting
---------------

These suggestions have not been well tested, so your actual commands
may be somewhat different. Several problems were enountered with ruby
from the centos yum repo.

Ruby script/server may give more debugging information that
mod_passenger. You can install ruby, rails, rubygems, and maybe some
other packages via yum. I am unclear about what happens to gems
installed by yum when you run the gem command. The gem command seems
to work.

The yum installed Ruby and associated gems had several issues, but
after getting Ruby Enterprise working, it might be possible to apply
the same fixes and get the standard ruby working as well.

sudo su -l root
yum install ruby rubygem-rake rubygem-rails rubygem-nokogiri 

# Change the standard rails to an older version that works with
# script/server.  You'll need an older version of sqlite3-ruby also.

gem uninstall rails
gem install rails -v'2.3.11' --no-rdoc --no-ri

gem install rubygems-update --no-rdoc --no-ri
update_rubygems
gem install rails passenger sinatra --no-rdoc --no-ri
passenger-install-apache2-module
exit
cd am_ruby
script/server





How to install Bagit
--------------------

# These notes apply to development. See the more up-to-date notes
# above.

> git clone git://github.com/flazz/bagit.git
Cloning into bagit...
remote: Counting objects: 1151, done.
remote: Compressing objects: 100% (548/548), done.
remote: Total 1151 (delta 611), reused 964 (delta 511)
Receiving objects: 100% (1151/1151), 1.74 MiB, done.
Resolving deltas: 100% (611/611), done.

> cd bagit/

> ls
bagit.gemspec  lib  LICENSE.txt  Rakefile  README.md  spec

> gem install bagit validatable
Successfully installed semver-0.1.0
Successfully installed bagit-0.1.0
Successfully installed validatable-1.6.7
3 gems installed
Installing ri documentation for semver-0.1.0...
Installing ri documentation for bagit-0.1.0...
Installing ri documentation for validatable-1.6.7...
Installing RDoc documentation for semver-0.1.0...
Installing RDoc documentation for bagit-0.1.0...
Installing RDoc documentation for validatable-1.6.7...

> 



How to update a production instance
-----------------------------------


# cd into the main directory for your Rubymatica instance. Run all
# these as a normal user, not as root.

cd am_ruby

# If you are running webrick in the backghround find the old server
# and stop it. If you are running apache/passenger there is no need to
# stop the web server before the update.

ps aux | grep script
kill -9 987654321

# Get the new code from the source code repository.

svn update

# Either manually look at the diff for the consts, or make a diff file
# and edit it. If the only differences are changes you made, just skip
# the patching.

# You can use compare_config.pl in the min_lims project to compare two
# consts files. compare_config.pl will tell you which configs are
# missing from each file, regardless of the order of the lines. Diff
# won't do that.

~/public_html/min_lims/compare_config.pl rmatic_constants.rb rmatic_constants.rb.dist

# "diff old new" or "diff original changed" where "new" is the file
# most recently changed. The issue we are addressing is changes made
# to the .dist file. There may be new consts that you need.

diff rmatic_constants.rb rmatic_constants.rb.dist > rc.diff

# Back up your constants, just to be safe.

cp rmatic_constants.rb rc_safe.txt

# Edit the diff to remove any sections that you don't want
# changed. Expecially Script_path. Yes, diff files are kind of hard to
# read.

emacs rc.diff

patch rmatic_constants.rb rc.diff

# If you are running Phusion Passgenger aka mod_passenger, touch the
# restart file to restart.

tmp/restart.txt


# If you are using webrick, start the updated server on the default
# port 3000. Logs are in log/development.log

script/server > /dev/null 2>&1 &





How to add a new controller
---------------------------

1) Add a new method to class HelloWorldController in
app/controllers/hello_world_controller.rb

2) Create a new .html.erb file with a matching name in app/views/hello_world

3) When we used static routes, it was necessary to create a new static
route in config/routes.rb. However, now routes are dynamic and they
should just work.




List of files
-------------

Several directories referred to in rmatic_constants.rb must be
manually created as part of the Rubymatica install. See
rmatica_constants.rb.dist for details.


--
./7.xml

Used for testing the def update_taper. See "Testing" in this document.

--
./10.xml

Used for testing the def update_taper. See "Testing" in this document.


--
./rmatic_constants.rb.dist

Distribution copy of rmatic_contstants.rb. Copy to rmatic_constants.rb
and edit for each install.

--
./schema.sql

Not used.

--
./rmatic_constants.rb

Install instance constants.

--
./status_schema.sql

Used to create info.db. Search code for DB_name. Data is managed via
Class Ingest, however the database is created in def reproc_false just
before calling Ingest.new().

Schema for the info.db which is the meta data information for each
ingest. This file is used to create the database prior to inserting
information.

--
./readme.txt

This file.

--
./xml_fits2sql.xsl

XSLT to generate sql insert statements from FITS xml data.

--
./puid_list.txt

A temp file of SQL insert statements used to initially populate
puid.db which is the database of PRONOM puids. I think the current
version was created by running several Emacs keyboard macros on the
DROID signature file: DROID_SignatureFile_V35.xml. puid_list.txt is
used to populate the database of categories which are used for the
overview in def file_list hello_world_controller.rb.

A script or XSLT should be written to parse the signature file into
the requisite SQL statements.

--
./noko_late_parse_add.rb

Nokogiri example code. Not part of Rubymatica.

--
./dublin_core.xml

An empty Dublin Core xml file which is copied into each
ingest. Presumably there will be a UI to edit this file, eventually.

--
./schema_fits.sql

SQL schema for the FITS file info saved in each ingest. Part of
FITS. See rubymatica.rb.

--
./bagit_demo.rb

Example code to make a bagit bag. Not part of Rubymatica.

--
./noko_late_child.rb

Nokogiri example code. Not part of Rubymatica.

--
./noko_transcript.txt

Nokogiri example code. Not part of Rubymatica. This is a transcript of
what you should see when running the Nokogiri examples.

--
./rails_readme.txt

Not used.

--
./noko_simple_parse_add.rb

Nokogiri example code. Not part of Rubymatica.

--
./METS.xml

Used by Nokogiri example code. Not part of Rubymatica. 

The Rubymatica METS.xml is generated on the fly by Nokogiri.


--
./example_noko.rb

Nokogiri example code. Not part of Rubymatica.

--
./rmatic.db

SQL database with session status messages for Rubymatica. Messages for
each user are saved here, based on IP address. See msg_schema.sql.

--
./puid.db

SQL database of PRONOM puids used to manage categories which are used
in def file_list in hello_world_controller.rb

--
./process_sip.rb

The command line wrapper for Rubymatica. See ./process_sip.rb --help

--
./schema_puid.sql

PUID database table schema. Run the commands below one time when
Rubymatica is installed. (This is already documented in the "Install
required packages" section.)

cat schema_puid.sql | sqlite3 puid.db
cat puid_list.txt | sqlite3 puid.db


--
./rubymatica.rb

The main Rubymatica ruby source. The main entry method is def
process_one. Some of the classes are used by
hello_world_controller.rb. 

--
./mets_builder.rb

Demo or example. Not part of Rubymatica. Probably outdated.

--
./bag-info.txt

Example bag-info.txt file.


--
./noko_test.xml

Use by Nokogiri example code. Not part of Rubymatica.

--
./app/views/hello_world/show_logs.html.erb

View for def show_logs in hello_world_controller.rb

--
./app/views/hello_world/full_status.html.erb

View for def full_status in hello_world_controller.rb

--
./app/views/hello_world/offer_upload.html.erb

View for def offer_upload in hello_world_controller.rb

--
./app/views/hello_world/get_file.erb

View for def get_file in hello_world_controller.rb
--
./app/views/hello_world/test.html.erb

Example code. View for def test in hello_world_controller.rb

--
./app/views/hello_world/file_list.html.erb

View for def file_list in hello_world_controller.rb

--
./app/views/hello_world/offer_import_meta.html.erb

View for def offer_import_meta in hello_world_controller.rb

--
./app/views/hello_world/report.html.erb

View for def report in hello_world_controller.rb This is the
Rubymatica home page.

--
./app/views/hello_world/show_puid_list.html.erb

View for def show_puid_list in hello_world_controller.rb

--
./app/controllers/application_controller.rb

Example or not used.

--
./app/controllers/hello_world_controller.rb

The controller.

--
./app/helpers/application_helper.rb

Example or not used.

--
./app/helpers/hello_world_helper.rb

The helper.

--
./config/environments/development.rb

Standard part of Rails.

--
./config/environments/test.rb

Standard part of Rails.

--
./config/environments/production.rb

Standard part of Rails.

--
./config/boot.rb

Standard part of Rails.

--
./config/database.yml

Probably not used. We have our own db code.

--
./config/environment.rb

Standard part of Rails.

--
./config/routes.rb

We use static routes to make our pages load via a shorter
path. Normally the URL would be
http://hostname/hellow_world_controller/report but by using a static
route for each page we can use shorter urls: http://hostname/report

--
./msg_schema.sql

The SQL schema for messages saved for each user session in
rmatic.db. Rubymatica will build this db if necessary so there is no
need to initialize it. See rmatic.db.

--
./noko_test_child.rb

Nokogiri example code. Not part of Rubymatica.





Testing TAPER integration with Rubymatica
-----------------------------------------


Copy each test xml file one at a time to ~/orig/taper_submission.xml
and from the web page import into an ingest. Click "Update TAPER" and
verify updated values for accessionNumber, respectDeFonds, extent,
dateSpan. In the case of 10.xml, there is no respectDeFonds, so this
element is added after </history>.




How to install Tufts TAPER SABT
-------------------------------

http://sourceforge.net/projects/tutaper/
http://tutaper.svn.sourceforge.net/viewvc/tutaper/

# Forgot to record the original install command. Probably:
svn co https://tutaper.svn.sourceforge.net/svnroot/tutaper tutaper 

# To run the web site, I only used the code in the production
# branch. I copied ./tutaper/production/TAPER/ to ~/public_html/
# although any web accessible directory should work.


# Catalyst is huge and it should be installed via yum and/or some
# bundle if possible. Installing via cpan is very time consuming, but
# if the Makefile.PL script works at least it is more or less
# automatic. Unfortunately, Makefile.PL does *not* work under Centos
# 5. The instructions below are for Fedora Linux (FC12). At one point
# during a lengthy cpan install I discovered Task::Catalyst which seems
# to include most of what Catalyst needs.

sudo su -l root
grep -i cpan yum_list.txt 
yum -y install perl-CPAN
cd /home/mst3k/tutaper/production/TAPER/
perl Makefile.PL 
ls
make
cpan 

# After installing Fedora Linux, I always runt a 
# "yum list all > yum_list.txt"
# because yum is sooo sloooow in checking the repo databases. When I
# need to know a package name, I grep the yum_list.txt.

grep -i catal yum_list.txt 
yum -y install perl-Catalyst-Model-DBIC-Schema.noarch

# as mst3k
script/taper_server.pl 

# an error
Base class package "Catalyst::Model::DBIC::Schema" is empty.

# You can run a command with an environment variable prefixing the
# command. I think taper_server.pl also understands -p 3030

TAPER_PORT=3030 script/taper_server.pl 

# Don't edit Auth.pm, but the idea is amusing, and it sort of
# works. You could force the authentication conditional to true with 1
# || $c->authentication, but don't do that. Instead add
# userid/password combos to the taper.conf as shown below.

cd /home/mst3k/tutaper/production/TAPER
emacs lib/TAPER/Controller/Auth.pm

# Opps. No MySQL db. I wonder how we create that?
[error] DBIx::Class::ResultSet::search(): DBI Connection failed: DBI
connect('taper','root',...) failed: Can't connect to local MySQL
server through socket '/var/lib/mysql/mysql.sock' (2) at
/usr/local/lib/perl5/site_perl/5.10.0/DBIx/Class/Storage/DBI.pm line
1257

# yum install mysql (or whatever). Before using mysql we have to set
# or reset the mysql root password. By default TAPER connects as root
# with no password. You'll have to edit one of the TAPER source files
# to set a password. Yes, you can set up mysql with no root password,
# and the TAPER mysql login is actually 'root', but don't go
# there. Just do the extra steps and add some proper security.

# The steps below also include building the TAPER sql database. You'll
# need the taper.sql file which I got from the original directory
# where I unpacked TAPER.

> cd tutaper
> find . -name 'taper*.sql' -ls
1221515    8 -rw-r--r--   1 mst3k    users        4921 Nov 29 15:35 ./trunk/sql/taper.sql
1336815    8 -rw-r--r--   1 mst3k    users        4921 Nov 29 15:35 ./production/sql/taper.sql
> 

# No password yet, so -p is not needed.  Every account needs a
# password, especially root. You must "flush privileges" for the new
# password to take effect. I quit the mysql shell and start again
# just to make sure the privs changed.

mysql -u root
update mysql.user set password=password('foo') where user='root';
flush privileges;
quit;
mysql -u root -p
create database taper;
use taper;
source taper.sql;
show tables;

# The output:

+-----------------+
| Tables_in_taper |
+-----------------+
| office          | 
| role            | 
| rsa             | 
| ssa             | 
| user            | 
| user_office     | 
| user_role       | 
+-----------------+
7 rows in set (0.00 sec)


# While we are in the db, we need to do some mysql admin tasks.

# The non-root user *must* have two mysql accounts as you'll see
# below. Postgres handles this much better.

# http://dev.mysql.com/doc/refman/5.1/en/adding-users.html

# It is necessary to have both accounts for monty to be able to
# connect from anywhere as monty. Without the localhost account, the
# anonymous-user account for localhost that is created by
# mysql_install_db would take precedence when monty connects from the
# local host. As a result, monty would be treated as an anonymous
# user. The reason for this is that the anonymous-user account has a
# more specific Host column value than the 'monty'@'%' account and
# thus comes earlier in the user table sort order. (user table sorting
# is discussed in Section 5.4.4, \u201cAccess Control, Stage 1:
# Connection Verification\u201d.)

create user 'taper'@'localhost' identified by 'foobarbaz';
grant all privileges on *.* to 'taper'@'localhost' with grant option;
create user 'taper'@'%' identified by 'foobarbaz';
grant all privileges on *.* to 'taper'@'%' with grant option;
select host,user,password from mysql.user;

# The output:


+-----------------------+-------+------------------+
| host                  | user  | password         |
+-----------------------+-------+------------------+
| localhost             | root  | 7a8cd9854ef31c3c | 
| aims.lib.example.edu  | root  | 7a8cd9854ef31c3c | 
| 127.0.0.1             | root  | 7a8cd9854ef31c3c | 
| localhost             |       |                  | 
| aims.lib.example.edu  |       |                  | 
| %                     | taper | 0654d346211e7caf | 
+-----------------------+-------+------------------+
6 rows in set (0.00 sec)

flush privileges;
quit;
mysql -u taper taper -p
select * from user;

# The output:

Empty set (0.00 sec)

# Insert one user to be the first TAPER admin.

insert into user (username,first_name,last_name,is_dca) values ('mst3k','Merry', 'Terry',1);
quit;

# Go fix the TAPER source to use a non-root user and password.

cd ./lib/TAPER/Model/
emacs -nw TAPERDB.pm
__PACKAGE__->config(
                    schema_class => 'TAPER::Schema',
                    connect_info => [
                                     'dbi:mysql:taper',
                                     'taper',
                                     'foobarbaz'
                                     ],
                    );


# Test any mysql userid and privilege changes by adding a new TAPER
# user from the TAPER web pages, which reads and writes the db. (At
# least I'm fairly certain it reads and writes the db.)

# After this, login to taper as mst3k, "DCA TAPER Tools", "Manage
# Users", "Click here to add a new user." This adds the new user to
# the database. If you don't do this, a user can login, but they get
# the "You are logged in but you aren't approved" or something like
# that.

# Edit taper.conf and change ldap stuff to use a user auth store in
# the conf file. This is based on the Catalyst authentication CPAN docs.

<authentication>
    default_realm local
    <realms>
        <local>
            <credential>
                class Password
                password_field password
                password_type clear
            </credential>
	    <store>
		class Minimal
		<users>
			<mst3k>
				password="foobarbaz"
			</mst3k>
		</users>
            </store>
    	</local>
    </realms>
</authentication>


You should (must?) also set reasonable values for the other
configuration values. In the examples below, the admin is
mst3k@virginia.edu and the taper_run directory is in the admin's home
directory.

# App-wide email-related config
dca_staff_email mst3k@virginia.edu

from_name Submission Agreement Builder Tool
#from_address jmac@jmac.org
from_address mst3k@virginia.edu

# Outgoing email config
email SMTP
email cms.mail.virginia.edu

rsa_staging_directory /home/mst3k/taper_run/staging
ssa_directory /home/mst3k/taper_run/ssa


You must also create the taper_run directory and give it permissions
so that TAPER/fcgi/Catalyst will be able to mkdir and create files.

> cd /home/mst3k/taper_run/
> chmod go+w .



# quick command line test for TAPER. (No. Catalyst apps require
# mod_perl or mod_fastcgi.) taper w/apache or at command line.

HTTP_HOST=localhost REMOTE_ADDR=aims.lib.example.edu SERVER_PORT=80 script/taper_cgi.pl

REQUEST_METHOD=GET HTTP_HOST=localhost REMOTE_ADDR=aims.lib.example.edu SERVER_PORT=80 script/taper_cgi.pl

# If you have Apache httpd running with UserDir enabled and user
# public_html is allowed to ExecCGI, then you can probably use a URL
# like the one below to run TAPER. I've only got one virtual host and
# it is devoted to a Rails application. I suppose I should ask our
# hostmaster for another hostname, but for now I'm perfectly happy
# hosting out of a public_html directory. The script taper_cgi.pl is
# very, very slow apparently due to the Catalyst overhead. Yes, the
# second URL has a trailing / (slash).

http://aims.lib.example.edu/~mst3k/TAPER/script/taper_cgi.pl/auth/login
http://aims.lib.example.edu/~mst3k/TAPER/script/taper_cgi.pl/

# If you get "Page not found" then you probably forgot the trailing
# slash. This interesting URL format is due to Catalyst.


# The line below probably runs the server with verbose debugging
# output. Probably useful if your installation isn't quite running
# right.

perl -MCarp=verbose script/taper_server.pl -p 3030





# I don't think I did any of the stuff below. This probably comes from
# some web page on how to reset the root password for mysql.

[root@tull ~]# man mysqld_safe 
[root@tull ~]# mysqld_safe --init-file=mysql_reset.sql
101201 11:29:44 mysqld_safe Logging to '/var/log/mysqld.log'.
101201 11:29:44 mysqld_safe Starting mysqld daemon with databases from /var/lib/mysql
101201 11:29:49 mysqld_safe mysqld from pid file /var/run/mysqld/mysqld.pid ended
[root@tull ~]# /etc/init.d/mysqld start
Starting MySQL:                                            [  OK  ]
[root@tull ~]# cat mysql_reset.sql
UPDATE mysql.user SET Password=PASSWORD('foo') WHERE User='root';
FLUSH PRIVILEGES;
[root@tull ~]# 


# Now that TAPER runs with the taper_script.pl script it is time to
# get it running under Apache httpd with mod_fcgid. TAPER was not
# intended to use mod_perl and it works very poorly. There are rumors
# that mod_fastcgi is deprecated. Since I have to run TAPER on both a
# Fedora Core Linux server and a Centos Linux server I chose mod_fcgid
# which has yum packages.

# On Centos I installed the fcgi package. I didn't install this on
# Fedora Linux and I'm pretty sure fcgi is not required.


sudo su -l root
yum -y install mod_fcgid

# Now you'll have a file /etc/httpd/conf.d/fcgid.conf. If you have
# Centos, then you have the old version of this file. It works fine,
# but the commant should read:

# Use FastCGI to process .fcg .fcgi & .fpl scripts as long as
# mod_fastcgi is not already doing this. mod_fcgid and mod_fastcgi
# conflict with each other.

# If not mod_fastcgi then use fcgid-script for various fastcgi related
# file extensions.

cd /etc/httpd/conf/
# make a backup of httpd.conf
emacs httpd.conf
      
# Add the lines below, modified for your server. Note that I'm running
# Rubymatica via mod_passenger and that config is here as well. This
# should be everything you need in httpd.conf for Rubymatica, TAPER,
# and the donor survey.


# ... clip ...
# Use name-based virtual hosting.

# NOTE: NameVirtualHost cannot be used without a port specifier 
# (e.g. :80) if mod_ssl is being used, due to the nature of the
# SSL protocol.

# The modern way is each vhost is :80 with a different ServerName.
# http://httpd.apache.org/docs/current/vhosts/name-based.html

NameVirtualHost *:80

LoadModule passenger_module /opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.5/ext/apache2/mod_passenger.so
PassengerRoot /opt/ruby-enterprise-1.8.7-2011.03/lib/ruby/gems/1.8/gems/passenger-3.0.5
PassengerRuby /opt/ruby-enterprise-1.8.7-2011.03/bin/ruby

<VirtualHost *:80 >
    ServerName aims.lib.virginia.edu
    # be sure to point to 'public'!
    DocumentRoot /home/mst3k/am_ruby/public

    # setenv RailsEnv production

    # Based on config/environment.rb the var is all caps, with underscore
    setenv RAILS_ENV production

    # default is 3
    setenv PassengerLogLevel 5
    setenv PassengerUseGlobalQueue on
    setenv RailsFrameworkSpawnerIdleTime 0
    setenv RailsAppSpawnerIdleTime 0

    <Directory /home/mst3k/am_ruby/public >
       # relax Apache security settings
       AllowOverride all
       # MultiViews must be turned off
       Options -MultiViews

       AuthUserFile /home/mst3k/.htpasswd
       AuthGroupFile /dev/null
       AuthName Rubymatica
       AuthType Basic
       require valid-user

    </Directory>
</VirtualHost>

# Settings for TAPER. Must have mod_fcgid. See also conf.d/fcgid.conf
# http://blog.hjksolutions.com/articles/2007/07/19/catalyst-deployment-with-apache-2-and-mod_fcgid

<IfModule mod_fcgid.c>
  Alias /taper/static /home/mst3k/public_html/TAPER/root/static

  <Location /taper/static>
    # http://hostname/taper/static/images/leftside_photo_34x342.jpg
    SetHandler default-handler
  </Location>

  Alias /taper /home/mst3k/public_html/TAPER/script/taper_fastcgi.pl/

  <Location /taper>
    Options ExecCGI
    Order allow,deny
    Allow from all
    AddHandler fcgid-script .pl
  </Location>
</IfModule>

# end of httpd.conf

# as root

/etc/init.d/httpd restart
exit



# Access TAPER via a URL that has /taper as the apparent document root.

# http://aims.lib.virginia.edu/taper/

# mod_fcgid knows to run taper_fastcgi.pl due to the Alias above
# combined with the "AddHandler fcgid-script .pl" in the Location
# directive for /taper.

# On the other hand /taper/static is using the default handler, aka
# whatever Apache httpd would normally do. This is good because things
# like images are simply loaded via httpd without the Catalyst overhead.


# The script is running from /home/mst3k/public_html/TAPER/script (the
# dir containing taper_fastcgi.pl) and it tried to mkdir run/session/b
# in that dir. However, suexec apparently doesn't work with mod_fcgid,
# so it fails. "chmod -R go+w ./run"

[Tue Apr 12 15:36:16 2011] [warn] [client 128.143.166.245] mod_fcgid: stderr: [error] Caught exception in engine "mkdir run/session/b: Permission denied at /usr/local/lib/perl5/site_perl/5.10.0/Cache/FileBackend.pm line 222", referer: http://aims.lib.virginia.edu/taper/auth/login

# Do the chmod as a normal user, not root. See output of id:

> id
uid=522(mst3k) gid=100(users) groups=100(users)

cd ~/public_html/TAPER/script
chmod -R go+w ./run

# Or put this in your VirtualHost directive:
      
    # This works to run scripts from anywhere in document root as a
    # non-apache user.  Coexists fine with mod_passenger and
    # mod_fcgi. If you want a Rails or Catalyst app to run as a
    # non-apache user, you'll probably have to use a directory in /var/www.

    Alias /test /var/www/html/test
    SuexecUserGroup mst3k users
    <Directory /var/www/html/test >
        Options ExecCGI
    </Directory>


# This version of TAPER is essentially a beta release, and has a
# couple of small issues. The images are hard coded to come from a
# server at tufts.edu.

# I copied ./TAPER/root/lib/wrapper to ./TAPER/root/lib/wrapper.dist
# and then changed the links to something that is easy to search and
# replace like %%images/yadayada.jpg. To make a "working" version
# simply copy wrapper.dist to wrapper and do the substitutions. You'll
# need to download the images with wget or curl. I put my images in
# "./TAPER/root/static/images". Here is an example src="/taper/static/images/tufts_logo_226x78.jpg"

> pwd
/home/mst3k/public_html/TAPER/root/static/images
> ls -l
total 132
-rw-r--r-- 1 mst3k users   341 2011-04-07 15:53 bg_190x15.jpg
-rw-r--r-- 1 mst3k users  3826 2011-03-28 16:39 btn_120x50_built.png
-rw-r--r-- 1 mst3k users  3681 2011-03-28 16:39 btn_120x50_built_shadow.png
-rw-r--r-- 1 mst3k users  3862 2011-03-28 16:39 btn_120x50_powered.png
-rw-r--r-- 1 mst3k users  3673 2011-03-28 16:39 btn_120x50_powered_shadow.png
-rw-r--r-- 1 mst3k users  2517 2011-03-28 16:39 btn_88x31_built.png
-rw-r--r-- 1 mst3k users  2274 2011-03-28 16:39 btn_88x31_built_shadow.png
-rw-r--r-- 1 mst3k users  2542 2011-03-28 16:39 btn_88x31_powered.png
-rw-r--r-- 1 mst3k users  2304 2011-03-28 16:39 btn_88x31_powered_shadow.png
-rw-r--r-- 1 mst3k users 13710 2011-03-28 16:39 catalyst_logo.png
-rw-r--r-- 1 mst3k users 43032 2011-04-07 15:53 dca__17.jpg
-rw-r--r-- 1 mst3k users 10573 2011-04-07 15:53 leftside_photo_34x342.jpg
-rw-r--r-- 1 mst3k users   817 2011-04-07 15:53 logo_bottom_226x26.jpg
-rw-r--r-- 1 mst3k users   488 2011-04-07 15:53 site_header_bottom.jpg
-rw-r--r-- 1 mst3k users  6653 2011-04-07 15:53 site_header_top.jpg
-rw-r--r-- 1 mst3k users  7110 2011-04-07 15:53 tufts_logo_226x78.jpg
>


Potential errors while running TAPER
------------------------------------

File permissions can be an issue with TAPER due to the needs of
Catalyst. I found it necessary to chmod the ./run/ directory tree.

cd ~/public_html/TAPER
chmod -R go+w ./run

Here is the error text from /etc/httpd/error_log:

[Tue May 31 09:43:13 2011] [warn] mod_fcgid: stderr: [error] Caught exception in engine "mkdir run/session/3: Permission denied at /usr/lib/perl5/site_perl/5.8.8/Cache/FileBackend.pm line 222"
[Tue May 31 09:43:13 2011] [error] [client 127.0.0.1] Premature end of script headers: taper_fastcgi.pl, referer: http://aims.lib.virginia.edu/taper/auth/login


The MySQL daemon must also be runnnig for TAPER to work. I'm not clear
if httpd and mysqld have to be restarted in a particular order. It
probably makes sense to start mysqld first, then httpd so that if (or
when) TAPER requests a connection to the database, the database is
already running.


[Tue May 31 09:40:18 2011] [warn] mod_fcgid: stderr: [error] DBIx::Class::ResultSet::search(): DBI Connection failed: DBI connect('t
aper','taper',...) failed: Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (111) at /usr/lib/perl5/si
te_perl/5.8.8/DBIx/Class/Storage/DBI.pm line 1262



An error when creating a SSA or RSA is probably due to
permissions. See the Apache httpd logs and change directory permission
as necessary. The warning about printing to a closed filehandle
doesn't seem to effect anything.


[Fri Jun 03 14:08:38 2011] [warn] mod_fcgid: stderr: printf() on closed filehandle OUT at /home/mst3k/public_html/TAPER/script/../lib/TAPER/Controller/Dca.pm line 28.
[Fri Jun 03 14:08:38 2011] [warn] mod_fcgid: stderr: [error] Caught exception in TAPER::Controller::Dca::Ssa->create "mkdir /home/mst3k/taper_run/ssa: Permission denied at /home/mst3k/public_html/TAPER/script/../lib/TAPER/Model/SSA.pm line 64"


