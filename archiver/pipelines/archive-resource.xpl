<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/">

  <p:param name="data" type="input"/>

  <!-- Fetch the resource -->
  <p:processor name="oxf:url-generator">
    <p:input name="config" transform="oxf:xslt" href="#data">
      <config xsl:version="2.0">
        <url>
          <xsl:value-of select="/action/@url"/>
        </url>
        <header>
          <name>User-Agent</name>
          <value>
            <xsl:value-of select="doc('oxf:/config.xml')/config/user-agent"/>
          </value>
        </header>
        <mode>archive</mode>
      </config>
    </p:input>
    <p:output name="data" id="archive" debug="archive"/>
  </p:processor>


  <!-- Store the archive in the database -->
  <p:processor name="oxf:pipeline">
    <p:input name="config" href="data-access.xpl"/>
    <p:input name="data" transform="oxf:xslt" href="#data">
      <config xsl:version="2.0">
        <relpath>
          <xsl:value-of select="/action/@directory"/>
          <xsl:value-of select="/action/@filename"/>
        </relpath>
        <operation>write</operation>
        <type>document</type>
      </config>
    </p:input>
    <p:input name="param" href="#archive"/>
    <p:output name="data" id="response2"/>
  </p:processor>

  <p:processor name="oxf:null-serializer">
    <p:input name="data" href="#response2"/>
  </p:processor>


  <!-- Test the type of document to see if it needs to be rewritten -->
  <p:choose href="#archive">

    <!-- HTML document : need to update the links... -->
    <p:when test="/archive/response/document/@content-type='text/html'">

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
                  <xsl:message>
                    <xsl:value-of select="$last-token"/>
                  </xsl:message>
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
        <p:output name="data" id="links" debug="links"/>
      </p:processor>

      <!-- Update the links -->
      <p:processor name="oxf:unsafe-xslt">
        <p:input name="data" href="#html"/>
        <p:input name="request" href="#archive#xpointer(/archive/request)"/>
        <p:input name="links" href="#links"/>
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
        <p:output name="data" id="rewritten" debug="rewritten"/>
      </p:processor>

      <!-- Store the rewritten document in the database -->
      <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="#data">
          <config xsl:version="2.0">
            <relpath>
              <xsl:value-of select="/action/@directory"/>
              <xsl:text>rewritten-</xsl:text>
              <xsl:value-of select="/action/@filename"/>
            </relpath>
            <operation>write</operation>
            <type>document</type>
          </config>
        </p:input>
        <p:input name="param" href="#rewritten"/>
        <p:output name="data" id="response3"/>
      </p:processor>
      <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response3"/>
      </p:processor>



      <!-- Update the archive index -->
      <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="#data">
          <config xsl:version="2.0">
            <relpath>
              <xsl:value-of select="/action/@directory"/>
              <xsl:text>index.xml</xsl:text>
            </relpath>
            <operation>write</operation>
            <type>xquery</type>
            <parameter name="url" type="string">
              <xsl:value-of select="/action/@url"/>
            </parameter>
            <parameter name="filename" type="string">
              <xsl:value-of select="/action/@filename"/>
            </parameter>
            <parameter name="filename-rewritten" type="string">
              <xsl:text>rewritten-</xsl:text>
              <xsl:value-of select="/action/@filename"/>
            </parameter>
          </config>
        </p:input>
        <p:input name="param">
          <xquery><![CDATA[
for $as in /archive-set 
    return 
      update 
        insert <archive url=$(url) href=$(filename) href-rewritten=$(filename-rewritten)/> 
        into $as                
                ]]></xquery>
        </p:input>
        <p:output name="data" id="response1"/>
      </p:processor>
      <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response1"/>
      </p:processor>

      <!-- Update the queue -->
      <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="aggregate('root', #data, #links)">
          <config xsl:version="2.0">
            <relpath>queue.xml</relpath>
            <operation>write</operation>
            <type>xquery</type>
            <parameter name="directory" type="string">
              <xsl:value-of select="/root/action/@directory"/>
            </parameter>
            <parameter name="uuid" type="string">
              <xsl:value-of select="/root/action/@uuid"/>
            </parameter>
            <parameter name="links" type="node-set">
              <xsl:copy-of select="/root/links"/>
            </parameter>
          </config>
        </p:input>
        <p:input name="param">
          <xquery><![CDATA[
declare namespace util = "http://exist-db.org/xquery/util";
declare variable $links := $(links);

for $q in /queue return
    update 
        insert 
          for $href in distinct-values($links/link/@abs-href)
            let $link := $links/link[@abs-href = $href][1]
            return <action uuid="{util:uuid()}" type="archive-resource" url="{$link/@abs-href}" directory=$(directory) filename="{$link/@filename}"/> 
        into $q,
        
for $a in /queue/action where $a/@uuid = $(uuid) return
    update
        delete $a
        
                ]]></xquery>
        </p:input>
        <p:output name="data" id="response4" debug="response"/>
      </p:processor>
      <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response4"/>
      </p:processor>


    </p:when>

    <!-- Otherwise: no need to rewrite -->
    <p:otherwise>
      <!-- Update the archive index -->
      <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="#data">
          <config xsl:version="2.0">
            <relpath>
              <xsl:value-of select="/action/@directory"/>
              <xsl:text>index.xml</xsl:text>
            </relpath>
            <operation>write</operation>
            <type>xquery</type>
            <parameter name="url" type="string">
              <xsl:value-of select="/action/@url"/>
            </parameter>
            <parameter name="filename" type="string">
              <xsl:value-of select="/action/@filename"/>
            </parameter>
          </config>
        </p:input>
        <p:input name="param">
          <xquery><![CDATA[
for $as in /archive-set 
    return 
      update 
        insert <archive url=$(url) href=$(filename)/> 
        into $as                
                ]]></xquery>
        </p:input>
        <p:output name="data" id="response1"/>
      </p:processor>
      <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response1"/>
      </p:processor>

      <!-- Update the queue -->
      <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="#data">
          <config xsl:version="2.0">
            <relpath>queue.xml</relpath>
            <operation>write</operation>
            <type>xquery</type>
            <parameter name="uuid" type="string">
              <xsl:value-of select="/action/@uuid"/>
            </parameter>
          </config>
        </p:input>
        <p:input name="param">
          <xquery><![CDATA[

for $a in /queue/action where $a/@uuid = $(uuid) return
    update
        delete $a
        
                ]]></xquery>
        </p:input>
        <p:output name="data" id="response4" debug="response"/>
      </p:processor>
      <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response4"/>
      </p:processor>

    </p:otherwise>

  </p:choose>

</p:config>
