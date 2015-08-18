<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method='html' version='1.0' encoding='UTF-8' indent='yes'/>

<!--
This file allows you to open a plate plans XML file directly
in a browser and it will convert the output into readable HTML.
This style sheet defines the output. Be sure the XML file contains a
direct reference to this file in its header, e.g.:

<?xml-stylesheet type="text/xsl" href="platePlans.xsl"?>

>> 2008.10.05, Demitri Muna, NYU
-->

<!-- Handy reference:
http://www.devguru.com/Technologies/XSLT/quickref/xslt_index_elements.html
-->

<!-- =========================== -->
<!-- set (global) variables here -->
<!-- =========================== -->

<!-- variable can be a block of html text, e.g.
 
	<xsl:variable name="table_header">
	<tr>
	<td><b>design id</b></td>
	<td><b>location id</b></td>
	</tr>
	</xsl:variable>

	This can then be printed using:
	<xsl:copy-of select="$table_header" />
-->

<!-- Or one tag, with: name = variable name, select = value -->
<xsl:variable name="designCount" select="count(/DESIGN_LIST/DESIGN)"/> <!-- number of designs in file -->
<!-- Also can be simply printed with: <xsl:copy-of select="count(/DESIGN_LIST/DESIGN)-1" /> -->


<!-- =========================== -->

<xsl:template match="/"> <!-- the whole document -->
	<!-- begin the html output here -->
	<html>
	<body>
	<!--
	<xsl:template match="DESIGN_LIST">
        <xsl:number count="DESIGN">
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
-->    
	<!-- define table header -->
	<h2>Plate Designs</h2>
	<xsl:text disable-output-escaping="yes">&amp;</xsl:text>nbsp;
	(<xsl:value-of select="$designCount" /> found)

		<!-- loop over each DESIGN in the file -->
		<xsl:for-each select="DESIGN_LIST/DESIGN">
		<xsl:sort select="DESIGN_ID"/>
		<!-- <xsl:number value="position()" format="1. " /> --> <!-- numbering -->

		<table border="1">
			<tr bgcolor="#9acd32">
				<th colspan="2">Design ID: <xsl:value-of select="DESIGN_ID"/></th>
			</tr>
	
			<tr>
				<td>Location ID</td>
				<td><xsl:value-of select="LOCATION_ID"/></td>
			</tr>
			<tr>
				<td>Drill Style</td>
				<td><xsl:value-of select="DRILL_STYLE"/></td>
			</tr>

			<tr>
				<td>Pointings (<xsl:value-of select="count(POINTING)"/>)</td>
				<td>
					<xsl:for-each select="POINTING">
					<table bgcolor="blue" border="0"><tr>
					<table bgcolor="white" border="0">
						<tr>
							<td>Filename:</td>
							<td><xsl:value-of select="FILENAME"/></td>
						</tr>
						<tr>
							<td>Pointing priority:</td>
							<td><xsl:value-of select="POINTING_PRIORITY"/></td>
						</tr>
						<tr>
							<td>Hour angle:</td>
							<td><xsl:value-of select="HOUR_ANGLE"/></td>
						</tr>
						<tr>
							<td>RA/DEC</td>
							<td><xsl:value-of select="RA_CEN"/> h / <xsl:value-of select="DEC_CEN"/>"</td>
						</tr>
						<tr>
							<td>RA/DEC Offset</td>
							<td><xsl:value-of select="RA_OFFSET"/> h / <xsl:value-of select="DEC_OFFSET"/>"</td>
						</tr>
						<tr>
							<td>Comment</td>
							<td><xsl:value-of select="POINTING_COMMENT"/></td>
						</tr>
					</table> <!-- pointings table -->
					</tr></table>
					</xsl:for-each>
				</td>
			</tr>

			<tr>
				<td>Plate Plans (<xsl:value-of select="count(PLATE_PLAN)"/>)</td>
				<td>
					<xsl:for-each select="PLATE_PLAN">
					<table bgcolor="green" border="0"><tr>
					<table bgcolor="white" border="0">
					
						<tr>
							<td>Plate id</td>
							<td><xsl:value-of select="PLATEID"/></td>
						</tr>
						<tr>
							<td>Temp</td>
							<td><xsl:value-of select="TEMP"/></td>
						</tr>
						<tr>
							<td>Epoch</td>
							<td><xsl:value-of select="EPOCH"/></td>
						</tr>
						<tr>
							<td>Rerun</td>
							<td><xsl:value-of select="RERUN"/></td>
						</tr>
						<tr>
							<td>Plate run</td>
							<td><xsl:value-of select="PLATE_RUN"/></td>
						</tr>
						<tr>
							<td>Plate name</td>
							<td><xsl:value-of select="PLATE_NAME"/></td>
						</tr>
						<tr>
							<td>Plate comment</td>
							<td><xsl:value-of select="PLATE_COMMENT"/></td>
						</tr>
					
					</table> <!-- pointings table -->
					</tr></table>
					</xsl:for-each>
				</td>
			</tr>

		</table>
		
		<p></p>
		
		</xsl:for-each>
		<!-- end loop over DESIGNs -->
	
	<h2>List of all input files</h2>
	(design id in parenthesis)<br/><br/>

	<xsl:for-each select="DESIGN_LIST/DESIGN/POINTING">
	<xsl:sort select="FILENAME"/>
		<xsl:value-of select="FILENAME"/> (<xsl:value-of select="../DESIGN_ID"/>)<br/>
	</xsl:for-each>
	</body>
	</html>  
</xsl:template>

</xsl:stylesheet>