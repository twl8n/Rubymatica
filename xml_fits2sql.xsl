<?xml version="1.0"?>
<xsl:stylesheet version = "1.0"
		xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
		xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
		xmlns:fits = "http://hul.harvard.edu/ois/xml/ns/fits/fits_output"
		xmlns:my = 'http://xml.com/my-template-language'
		xmlns:fc = "http://www.nationalarchives.gov.uk/pronom/FileCollection"
		>
  <!--
     
     This naively assumes there are no single quotes in any text
     fields. If we ever get a single quote, the SQL statements will
     break. See string_replace.xsl for a function to perform string
     replacement.
     
    -->

  <!-- 
     
     We are creating SQL output which is just text as far as XML is
     concerned, with one important exception. Output method="text"
     disabled output escaping which means that the less-than char is
     output as a less-than, and not as "&lt;". The docs for
     disable-output-escaping don't suggest that it can be force to be
     enabled. In fact, they docs are clear that the setting is ignored
     for text.

     http://zvon.org/xxl/XSLTreference/W3C/xslt.html#disable-output-escaping
     
     So, we use html output.

     jan 10 2011 change over to getting the mime-type from the file
     utility output. This will be in the record where
     element='fileUtilityOutput'. If Droid has a mime-type it may be
     fine, but lacking that, the file utility mime-type seems the most
     trustworthy.

     jan 10 2011 Need a file_name variable since the file name is not
     part of FITS tool data for the file utility. Use this variable
     throughout the script instead of things like "../fc:FilePath".

    -->

  <xsl:output method="html"/>

  <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  
  <xsl:template match="/fits:fits">
    <!--
       There is only one fileinfo record. Use for-each to create a block
      -->

    begin transaction;

    <xsl:variable name="file_name" select="fits:fileinfo/fits:filename" />

    <xsl:variable name="checksum" select="fits:fileinfo/fits:md5checksum"/>
    <xsl:variable name="fs_last_modified" select="substring(fits:fileinfo/fits:fslastmodified,1,(string-length(fits:fileinfo/fits:fslastmodified)-3))"/>
    insert into file (name,size,checksum,fs_last_modified,status) values
    ('<xsl:value-of select="$file_name" />',
    <xsl:value-of select="fits:fileinfo/fits:size"/>,
    '<xsl:value-of select="fits:fileinfo/fits:md5checksum"/>',
    '<xsl:value-of select="substring(fits:fileinfo/fits:fslastmodified,1,(string-length(fits:fileinfo/fits:fslastmodified)-3))"/>',
    '<xsl:value-of select="fits:identification/@status"/>');

    delete from pk where name='file.id';
    insert into pk (id,name) values (last_insert_rowid(), 'file.id');
    
    <xsl:for-each select="fits:identification/fits:identity">
      
      <!--
	 tool_list is a denormalized list of all the toolnames that
	 gave this identity.
	-->

      <xsl:variable name="tool_list">
	<xsl:for-each select="fits:tool">
	  <xsl:value-of select="@toolname" /><xsl:text>,</xsl:text>
	</xsl:for-each>
      </xsl:variable>
      
      insert into identity (file_id,element,tool_name,format,mime_type,ext_id, ext_type, ext_tool) values
      ((select id from pk where name='file.id'),
      '<xsl:value-of select="local-name()"/>',
      '<xsl:value-of select="$tool_list"/>',
      '<xsl:value-of select="@format"/>',
      '<xsl:value-of select="@mimetype"/>',
      '<xsl:value-of select="fits:externalIdentifier"/>', 
      '<xsl:value-of select="fits:externalIdentifier/@type"/>',
      '<xsl:value-of select="fits:externalIdentifier/@toolname"/>');
    </xsl:for-each>

    <xsl:for-each select="fits:fileinfo/*">
      insert into info (file_id,tool_name,name,value) values
      ((select id from pk where name='file.id'),
      '<xsl:value-of select="@toolname"/>', 
      <!-- get the name of the element -->
      '<xsl:value-of select="name()"/>',
      <!-- get the value of the element -->
      '<xsl:value-of select="."/>');
    </xsl:for-each>
    
    <xsl:text>&#x0A;</xsl:text>
    <xsl:text>&#x0A;</xsl:text>

    <!--

       See the xsl header for the fc namespace alias Values for
       IdentQuality seem to be "Positive", "Tentative", "Not
       identified". If the IdentQuality or Status is Tentative, there
       may not be Version, and MimeType may be empty.
       
       Use a choose to only create an insert statement when we have an
       identification.

      -->

    <xsl:for-each select="toolOutput" >
      <xsl:for-each select="tool">
	<!-- oname is original name, iname is ignore-case name -->
	<xsl:variable name='oname' select="@name" />
	<xsl:variable name='iname' select="translate(@name, $smallcase, $uppercase)" />

	<xsl:if test="contains($iname, 'DROID')">
	  <xsl:for-each select="fc:FileCollection/fc:IdentificationFile/fc:FileFormatHit">
	    <xsl:choose>
	      <xsl:when test="contains(../@IdentQuality, 'Not identified')">
		<!-- do nothing -->
	      </xsl:when >
	      <xsl:otherwise>
		insert into identity
		(file_id,element,tool_name,format,mime_type,ext_id, ext_type, ext_version, ext_tool)
		values
		((select id from file where name='<xsl:value-of select="$file_name" />'),
		'<xsl:value-of select="local-name()"/>',
		'<xsl:value-of select="$oname"/>',
		'<xsl:value-of select="fc:Name"/>',
		'<xsl:value-of select="fc:MimeType"/>',
		'<xsl:value-of select="fc:PUID"/>', 
		'<xsl:value-of select="fc:MimeType"/>',
		'<xsl:value-of select="fc:Version"/>',
		'<xsl:value-of select="$oname"/>');
	      </xsl:otherwise >
	    </xsl:choose >
	  </xsl:for-each>
	</xsl:if>
	
	<!-- 

	   With the file utility, put the mime-type into the mime_type
	   field. As ext_id use the raw output (which is an format
	   string). The reasoning is that a) we have a mime-type field,
	   b) besides the extended format string, there's no "unique id" from the file utility.

	  -->

	<xsl:if test="contains($iname, 'FILE UTILITY')">
	  <xsl:for-each select="fileUtilityOutput">
	    insert into identity
	    (file_id,element,tool_name,format,mime_type,ext_id, ext_type, ext_version, ext_tool)
	    values
	    ((select id from file where name='<xsl:value-of select="$file_name" />'),
	    '<xsl:value-of select="local-name()"/>',
	    '<xsl:value-of select="$oname"/>',
	    '<xsl:value-of select="format"/>',
	    '<xsl:value-of select="mimetype"/>',
	    'rawOutput', 
	    '<xsl:value-of select="rawOutput"/>',
	    '<xsl:value-of select="../@version"/>',
	    '<xsl:value-of select="$oname"/>');
	  </xsl:for-each>

	</xsl:if>
      </xsl:for-each>
    </xsl:for-each>

  commit transaction;

  </xsl:template>

  <!-- <xsl:include href="fi2sql_inc.xsl"/> -->

 
</xsl:stylesheet>


