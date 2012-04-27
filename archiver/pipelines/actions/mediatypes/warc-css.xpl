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
      </config>
    </p:input>
    <p:input name="data" href="#record#xpointer(/record/content/document)"/>
    <p:output name="data" id="url-written"/>
  </p:processor>

  <!-- And read it as CSS -->
  <p:processor name="oxf:url-generator">
    <p:input name="config" transform="oxf:xslt" href="#url-written">
      <config xsl:version="2.0">
        <url>
          <xsl:value-of select="/*"/>
        </url>
        <content-type>text/css</content-type>
        <mode>text</mode>
      </config>
    </p:input>
    <p:output name="data" id="css" debug="css"/>
  </p:processor>


  <!-- Update the links -->
  <p:processor name="oxf:unsafe-xslt">
    <p:input name="data" href="#css"/>
    <p:input name="index-entry" href="#index-entry"/>
    <p:input name="index" href="#index"/>
    <p:input name="config">
      <xsl:stylesheet version="2.0">
        <xsl:variable name="index" select="doc('input:index')/*"/>
        <xsl:variable name="resource" select="doc('input:index-entry')/resource"/>
        <xsl:variable name="base" select="$resource/uri"/>
        <xsl:template match="/document">
          <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:analyze-string select="." regex="url\([&quot;']?([^)'&quot;]+)[&quot;']?\)" flags="">
              <xsl:matching-substring>
                <xsl:text>url(</xsl:text>
                <xsl:variable name="abs" select="substring-before(concat(resolve-uri(regex-group(1), $base), '#'), '#')"/>
                <xsl:value-of select="$index/resource[(uri, same-as) = $abs]/local-name"/>
                <xsl:text>)</xsl:text>
              </xsl:matching-substring>
              <xsl:non-matching-substring>
                <xsl:copy-of select="."/>
              </xsl:non-matching-substring>
            </xsl:analyze-string>
          </xsl:copy>
        </xsl:template>
      </xsl:stylesheet>
    </p:input>
    <p:output name="data" ref="rewritten" debug="rewritten"/>
  </p:processor>



</p:config>
