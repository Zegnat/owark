<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

 <xsl:variable name="action" select="/action"/>

 <xsl:template match="/">
  <xsl:apply-templates select="doc('crawler-beans-template.cxml')/*"/>
 </xsl:template>

 <xsl:template match="@* | node()">
  <xsl:copy>
   <xsl:apply-templates select="@* | node()"/>
  </xsl:copy>
 </xsl:template>

 <xsl:template match="url">
  <xsl:value-of select="$action/@url"/>
 </xsl:template>

</xsl:stylesheet>
