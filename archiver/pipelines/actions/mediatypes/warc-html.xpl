<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/">

  <p:param name="record" type="input"/>
  <p:param name="index-entry" type="input"/>
  <p:param name="index" type="input"/>
  <p:param name="rewritten" type="output"/>


  <!-- Store the document -->
  <p:processor name="oxf:file-serializer">
    <p:input name="config">
      <config>
        <scope>session</scope>
        <encoding>utf-8</encoding>
        <force-encoding>true</force-encoding>
      </config>
    </p:input>
    <p:input name="data" href="#record#xpointer(/record/content/document)"/>
    <p:output name="data" id="url-written"/>
  </p:processor>

  <!-- And read it as HTML -->
  <p:processor name="oxf:url-generator">
    <p:input name="config" transform="oxf:xslt" href="#url-written">
      <config xsl:version="2.0">
        <url>
          <xsl:value-of select="/*"/>
        </url>
        <encoding>utf-8</encoding>
        <force-encoding>true</force-encoding>
        <content-type>text/html</content-type>
        <force-content-type>true</force-content-type>
        <mode>html</mode>
      </config>
    </p:input>
    <p:output name="data" id="html" debug="html"/>
  </p:processor>

  <!-- Update the links -->
  <!-- TODO: support links in inline CSS -->
  <!-- TODO: support iframes and objects -->


  <p:processor name="oxf:unsafe-xslt">
    <p:input name="data" href="#html"/>
    <p:input name="index-entry" href="#index-entry"/>
    <p:input name="index" href="#index"/>
    <p:input name="config">
      <xsl:stylesheet version="2.0">
        <xsl:variable name="index" select="doc('input:index')/*"/>
        <xsl:variable name="resource" select="doc('input:index-entry')/resource"/>
        <xsl:variable name="base" select="$resource/uri"/>
        <xsl:template match="@*|node()">
          <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
          </xsl:copy>
        </xsl:template>
        <xsl:template match="link[@rel='stylesheet']/@href|img/@src|script/@src">
          <xsl:attribute name="{name(.)}">
            <xsl:variable name="abs" select="substring-before(concat(resolve-uri(., $base), '#'), '#')"/>
            <xsl:variable name="local-name" select="$index/resource[(uri, same-as) = $abs][1]/local-name"/>
            <xsl:value-of select="if ($local-name) then concat(if ($resource/uri/@seed = 'false') then '../' else '', $local-name) else resolve-uri(., $base)"/>
          </xsl:attribute>
        </xsl:template>
        <xsl:template match="link[@rel!='stylesheet']/@href|a/@href">
          <xsl:attribute name="{name(.)}">
            <xsl:value-of select="resolve-uri(., $base)"/>
          </xsl:attribute>
        </xsl:template>
      </xsl:stylesheet>
    </p:input>
    <p:output name="data" id="html-rewritten" debug="rewritten"/>
  </p:processor>

  <p:processor name="oxf:html-converter">
    <p:input name="config">
      <config>
        <content-type>application/xml</content-type>
        <encoding>utf-8</encoding>
      </config>
    </p:input>
    <p:input name="data" href="#html-rewritten"/>
    <p:output name="data" ref="rewritten"/>
  </p:processor>

</p:config>
