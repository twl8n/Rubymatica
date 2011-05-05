#! /usr/bin/ruby 

# Also see example_noko.rb

# Builder tutorial: http://nokogiri.org/Nokogiri/XML/Builder.html

require 'nokogiri'


# Normal variables aren't accessible inside the block for
# Builder.new. Dunno why. There's some comment in the Nokogiri docs
# about Builder.new with and without an argument list. The easy
# solution is globals. A closure would be nice, but closures in Ruby
# are exciting.

# Just use a new class.

Tmp = "/home/twl8n/dest/tmp"
Ig_logs = "ingest_logs"
Uuid_log = "file_uuid.log"

class Detox_dic

  def initialize(dir_uuid)
    ig_dest = "#{Tmp}/#{dir_uuid}/#{Ig_logs}"
    @detox_dic = Hash.new
    @detox_dic['xx'] = "orig_xx #{ig_dest}"
  end

  def get(key)
    return @detox_dic[key]
  end
end


builder = Nokogiri::XML::Builder.new { 

  dd = Detox_dic.new('stuff')
  puts dd.get('xx')

  mets('xmlns:dcterms' => 'http://purl.org/dc/terms/',
       'xmlns:mets' => "http://www.loc.gov/METS/",
       'xmlns:premis' => "info:lc/xmlns/premis-v2",
       'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
       'xsi:schemaLocation' => "http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/version18/mets.xsd info:lc/xmlns/premis-v2 http://www.loc.gov/standards/premis/premis.xsd http://purl.org/dc/terms/ http://dublincore.org/schemas/xmls/qdc/2008/02/11/dcterms.xsd" ) do
    
    dmdsec(:ID => "SIP-description") {
      mdWrap {
        xmlData {
          dublincore()
        }
      }
    }
    
    amdSec {
      Find.find(path) { |file|
        if (! File.file?(file))
          # If not a file, skip. Ugly code structure, but saves
          # another level of indentation.
          next;
        end
        

        digiprovMD( :ID => "digiprov-#{file_base_name}-{#file_uuid}") {
          # premis record for the file
          mdWrap( 'MDTYPE' => "PREMIS") {
            xmlData {
              long_str = "info:lc/xmlns/premis-v2 http://www.loc.gov/standards/premis/premis.xsd"
              premis('xmlns' => "info:lc/xmlns/premis-v2",
                     'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                     'version' =>"2.0",
                     'xsi:schemaLocation' => long_str) { |obj|
                object( 'type' => "file") {
                  objectIdentifier {
                    objectIdentifierType "UUID"
                    objectIdentifierValue "17dabc78-3dd5-4915-ade7-bef8abda3d41"
                    
                    # Can we always put in this element, and either
                    # leave it blank if no detox name, or put the
                    # original name in if not changed? Or add an element
                    # "detox_changed_name" as a boolean?

                    file = 'xx'
                    # if (detox_dic(file))
                    #   originalName detox_dic(file)
                    # end
                    
                    if ($detox_dic.has_key?(file))
                      originalName $detox_dic[file]
                    end

                  }
                }
              }
            }

            # wrap the FITS data for this file
            mdWrap( 'MDTYPE' => "FITS") {
              xmlData {
                fits("xmlns" => "http://hul.harvard.edu/ois/xml/ns/fits/fits_output", 
                     "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", 
                     "version" => "0.3.2", 
                     "xsi:schemaLocation" => "http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd") {
                  
                  # The AM python code parsed the fits xml. I don't see
                  # a reason to parse something we aren't inspecting so
                  # we'll just shove the whole file in.
                  
                  # fitsTree = etree.parse(sys.argv[1]+"/FITS-"+ uuid + "-" + os.path.basename(filename)+".xml")
                  # fitsRoot = fitsTree.getroot()
                  # fits.append(fitsRoot)
                  
                  fits_file_here "stuff"
                }
              }
            }
          }
        }
      }
    }

    # Just run through the directory tree again. I think this is
    # simpler than trying to add nodes. The downside is that if the
    # directory crawl changed for some reason, we'd have to change the
    # directory crawl in 3 places.
    
    # This code assumes that directories are traversed as they are
    # enountered, so I guess that is depth-first.

    fileSec {
      fileGrp(:ID => file, :USE => "Objects package")
      Find.find(path) { |file|
        if (File.directory?(file))
          fileGrp(:ID => file, :USE => "directory")
        elsif (File.file?(file))
          file("xmlns:xlink" => "http://www.w3.org/1999/xlink",
               :ID => "file-#{item}-#{file_uuid}",
               :ADMID => "digiprov-#{item}\#{file_uuid}")
          Flocat("xlink:href" => "#{path}/${file_name}",
                 :locType => "other",
                 :otherLocType => "system")
        end
      }
    }
    
    structMap {
      div(:DMDID => "SIP-description",  :LABEL => top_level,  :TYPE => "directory")
      Find.find(path) { |file|
        if (File.directory?(file))
          div(:LABEL => current_dir_basename, :TYPE => "directory")
        elsif (File.file?(file))
          file("xmlns:xlink" => "http://www.w3.org/1999/xlink",
               :ID => "file-#{item}-#{file_uuid}",
               :ADMID => "digiprov-#{item}\#{file_uuid}")
          Flocat("xlink:href" => "#{path}/${file_name}",
                 :locType => "other",
                 :otherLocType => "system")
        end
      }
    }
  end
}
puts builder.to_xml
