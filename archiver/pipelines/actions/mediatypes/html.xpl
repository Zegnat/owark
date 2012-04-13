<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/">

  <p:param name="archive" type="input"/>
  <p:param name="rewritten" type="output"/>
  <p:param name="links" type="output"/>


  <!-- Store the document -->
  <p:processor name="oxf:file-serializer">
    <p:input name="config">
      <config>
        <scope>session</scope>
      </config>
    </p:input>
    <p:input name="data" href="#archive#xpointer(/archive/response/document)"/>
    <p:output name="data" id="url-written"/>
  </p:processor>

  <!-- And read it as HTML -->
  <p:processor name="oxf:url-generator">
    <p:input name="config" transform="oxf:xslt" href="#url-written">
      <config xsl:version="2.0">
        <url>
          <xsl:value-of select="/*"/>
        </url>
        <mode>html</mode>
      </config>
    </p:input>
    <p:output name="data" id="html" debug="html"/>
  </p:processor>

  <!-- Get a list of links to update -->
  <!-- TODO: support links in inline CSS -->
  <!-- TODO: support iframes and objects -->
  <p:processor name="oxf:unsafe-xslt">
    <p:input name="data" href="#html"/>
    <p:input name="request" href="#archive#xpointer(/archive/request)"/>
    <p:input name="config">
      <xsl:stylesheet version="2.0">
        <xsl:variable name="base" select="doc('input:request')/request/location"/>
        <xsl:template match="/">
          <links>
            <xsl:variable name="links" as="node()*">
              <xsl:apply-templates/>
            </xsl:variable>
            <xsl:for-each-group select="$links" group-by="@href">
              <xsl:variable name="abs-href" select="resolve-uri(@href, $base)"/>
              <xsl:variable name="tokens" select="tokenize($abs-href, '/')"/>
              <xsl:variable name="last-token" select="$tokens[last()]"/>
              <xsl:variable name="tokens2" select="tokenize($last-token, '\.')"/>
              <xsl:variable name="extension" select="$tokens2[last()]"/>
              <link abs-href="{$abs-href}" new-href="{saxon:string-to-hexBinary(substring($abs-href, 1, string-length($abs-href) - string-length($extension) - 1), 'utf-8')}.{$extension}"
                filename="{saxon:string-to-hexBinary($abs-href, 'utf-8')}.xml">
                <xsl:copy-of select="@*"/>
              </link>
            </xsl:for-each-group>
          </links>
        </xsl:template>
        <xsl:template match="text()"/>
        <xsl:template match="link[@rel='stylesheet']">
          <link>
            <xsl:copy-of select="@*"/>
          </link>
        </xsl:template>
        <xsl:template match="img">
          <link href="{@src}" type="image/*"/>
        </xsl:template>
        <xsl:template match="script[@src]">
          <link href="{@src}" type="{@type}"/>
        </xsl:template>
      </xsl:stylesheet>
    </p:input>
    <p:output name="data" id="links-local" debug="links"/>
  </p:processor>

  <p:processor name="oxf:identity">
    <p:input name="data" href="#links-local"/>
    <p:output name="data" ref="links"/>
  </p:processor>

  <!-- Update the links -->
  <p:processor name="oxf:unsafe-xslt">
    <p:input name="data" href="#html"/>
    <p:input name="request" href="#archive#xpointer(/archive/request)"/>
    <p:input name="links" href="#links-local"/>
    <p:input name="config">
      <xsl:stylesheet version="2.0">
        <xsl:variable name="links" select="doc('input:links')/links"/>
        <xsl:variable name="base" select="doc('input:request')/request/location"/>
        <xsl:key name="link" match="link" use="@href"/>
        <xsl:template match="@*|node()">
          <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
          </xsl:copy>
        </xsl:template>
        <xsl:template match="link[@rel='stylesheet']/@href|img/@src|script/@src">
          <xsl:attribute name="{name(.)}">
            <xsl:value-of select="$links/key('link', current())/@new-href"/>
          </xsl:attribute>
        </xsl:template>
        <xsl:template match="link[@rel!='stylesheet']/@href|a/@href">
          <xsl:attribute name="{name(.)}">
            <xsl:value-of select="resolve-uri(., $base)"/>
          </xsl:attribute>
        </xsl:template>
      </xsl:stylesheet>
    </p:input>
    <p:output name="data" ref="rewritten" debug="rewritten"/>
  </p:processor>

</p:config>
