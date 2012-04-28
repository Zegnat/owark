<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl" xmlns:xsltu="http://xsltunit.org/0/"
  xmlns:owk="http://owark.org/xslt/" exclude-result-prefixes="exsl">
  <xsl:import href="../actions/resource-index.xslt"/>
  <xsl:import href="xsltunit.xsl"/>
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="local-names" select="doc('local-names.xml')/index"/>
  <xsl:key name="log-by-uri" match="/log/entry" use="uri"/>
  <xsl:template match="/">
    <xsltu:tests>
      <xsl:for-each select="$local-names/resource">
        <xsltu:test id="{uri}">
          <xsl:call-template name="xsltu:assertEqual">
            <xsl:with-param name="id" select="uri"/>
            <xsl:with-param name="nodes1">
              <local-name>
                <xsl:value-of select="owk:local-name(key('log-by-uri', current()/uri, $source ))"/>
              </local-name>
            </xsl:with-param>
            <xsl:with-param name="nodes2">
              <xsl:copy-of select="local-name"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsltu:test>
      </xsl:for-each>
    </xsltu:tests>
  </xsl:template>
</xsl:stylesheet>
