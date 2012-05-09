<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl" xmlns:xsltu="http://xsltunit.org/0/"
  xmlns:owk="http://owark.org/xslt/" exclude-result-prefixes="exsl">
  <xsl:import href="../actions/mediatypes/common-rewrite.xsl"/>
  <xsl:import href="xsltunit.xsl"/>
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="index" select="doc('local-names.xml')/index"/>
  <xsl:variable name="resource" select="$index/resource[uri='http://gmpg.org/xfn/11']"/>
  <xsl:key name="log-by-uri" match="/log/entry" use="uri"/>
  <xsl:template match="/">
    <xsltu:tests>
      <xsltu:test id="is-relative1">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'is-relative'"/>
          <xsl:with-param name="nodes1">
            <is-relative>true</is-relative>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <is-relative>
              <xsl:value-of select="owk:is-relative('/foo')"/>
            </is-relative>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>
      <xsltu:test id="is-relative2">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'is-relative'"/>
          <xsl:with-param name="nodes1">
            <is-relative>false</is-relative>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <is-relative>
              <xsl:value-of select="owk:is-relative('http://example.com/foo')"/>
            </is-relative>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>
      <xsltu:test id="safer-resolve-uri1">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'is-relative'"/>
          <xsl:with-param name="nodes1">
            <uri>http://example.com/foo</uri>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <uri>
              <xsl:value-of select="owk:safer-resolve-uri('/foo', 'http://example.com/')"/>
            </uri>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>
      <xsltu:test id="safer-resolve-uri2">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'is-relative'"/>
          <xsl:with-param name="nodes1">
            <uri>http://owark.org/foo</uri>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <uri>
              <xsl:value-of select="owk:safer-resolve-uri('http://owark.org/foo', 'http://example.com/')"/>
            </uri>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>
      <xsltu:test id="safer-resolve-uri3">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'is-relative'"/>
          <xsl:with-param name="nodes1">
            <uri>http://owark.org/foo{{{{}}}}</uri>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <uri>
              <xsl:value-of select="owk:safer-resolve-uri('http://owark.org/foo{{{{}}}}', 'http://example.com/')"/>
            </uri>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>
      <xsltu:test id="url-rewrite">
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'rewrite1'"/>
          <xsl:with-param name="nodes1">
            <uri>http://gmpg.org/foo</uri>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <uri>
              <xsl:value-of select="owk:url-rewrite('/foo')"/>
            </uri>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="xsltu:assertEqual">
          <xsl:with-param name="id" select="'rewrite2'"/>
          <xsl:with-param name="nodes1">
            <uri>../gmpg.org/11-1.html</uri>
          </xsl:with-param>
          <xsl:with-param name="nodes2">
            <uri>
              <xsl:value-of select="owk:url-rewrite('/xfn/11')"/>
            </uri>
          </xsl:with-param>
        </xsl:call-template>
      </xsltu:test>

    </xsltu:tests>
  </xsl:template>
</xsl:stylesheet>
