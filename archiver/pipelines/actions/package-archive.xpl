<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/">

  <p:param name="data" type="input"/>

  <!-- Read the archive index -->
  <p:processor name="oxf:pipeline">
    <p:input name="config" href="/data-access.xpl"/>
    <p:input name="data" transform="oxf:xslt" href="#data">
      <config xsl:version="2.0">
        <relpath>
          <xsl:value-of select="/action/@directory"/>
          <xsl:text>index.xml</xsl:text>
        </relpath>
        <operation>read</operation>
        <type>document</type>
      </config>
    </p:input>
    <p:input name="param">
      <empty/>
    </p:input>
    <p:output name="data" id="index" debug="index"/>
  </p:processor>

  <!-- Create a WARC file -->
  <p:processor name="oxf:file-serializer">
    <p:input name="config">
      <config>
        <scope>request</scope>
      </config>
    </p:input>
    <p:input name="data" transform="oxf:xslt" href="aggregate('root', #index, #data)">
      <xsl:stylesheet version="2.0">
        <xsl:import href="warc-lib.xsl"/>
        <xsl:template match="/">
          <xsl:variable name="content" as="node()*">
            <version/>
            <field>
              <name>WARC-Type</name>
              <value>warcinfo</value>
            </field>
            <field>
              <name>WARC-Date</name>
              <value>
                <xsl:value-of select="current-dateTime()"/>
              </value>
            </field>
            <field>
              <name>WARC-Record-ID</name>
              <value>
                <xsl:text>&lt;urn:uuid:</xsl:text>
                <xsl:value-of select="translate(substring(/root/action/@directory, 1, string-length(/root/action/@directory) - 1), '/', '-')"/>
                <xsl:text>></xsl:text>
              </value>
            </field>
            <field>
              <name>Content-Type</name>
              <value>application/warc-fields</value>
            </field>
            <!-- TODO: Content-Length: 381 -->
            <CRLF/>
            <field>
              <name>software</name>
              <value>Owark 0.3 http://owark.org</value>
            </field>
            <field>
              <name>format</name>
              <value>WARC file version 0.18</value>
            </field>
            <CRLF/>
            <CRLF/>
            <!--
              
              
software: Heritrix 1.12.0 http://crawler.archive.org
hostname: crawling017.archive.org
ip: 207.241.227.234
isPartOf: testcrawl-20050708
description: testcrawl with WARC output
operator: IA_Admin
http-header-user-agent:
 Mozilla/5.0 (compatible; heritrix/1.4.0 +http://crawler.archive.org)
format: WARC file version 0.18
conformsTo:
 http://www.archive.org/documents/WarcFileFormat-0.18.html-->
          </xsl:variable>
          <document xsl:version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" content-type="text/plain">
            <xsl:apply-templates select="$content" mode="warc"/>
          </document>
        </xsl:template>
      </xsl:stylesheet>
    </p:input>
    <p:output name="data" id="warc" debug="warc"/>
  </p:processor>

  <!-- Loop over the index to retrieve the documents -->

  <p:for-each href="#index" select="/archive-set/archive" id="files" root="files">

    <!-- Read the document -->
    <p:processor name="oxf:pipeline">
      <p:input name="config" href="/data-access.xpl"/>
      <p:input name="data" transform="oxf:xslt" href="aggregate('root', #data, current())">
        <config xsl:version="2.0">
          <relpath>
            <xsl:value-of select="/root/action/@directory"/>
            <xsl:value-of select="/root/archive/@href"/>
          </relpath>
          <operation>read</operation>
          <type>document</type>
        </config>
      </p:input>
      <p:input name="param">
        <empty/>
      </p:input>
      <p:output name="data" id="document" debug="document"/>
    </p:processor>

    <!-- Add the request and start of response records -->
    <p:processor name="oxf:file-serializer">
      <p:input name="config" transform="oxf:xslt" href="#warc">
        <config xsl:version="2.0">
          <file>
            <xsl:value-of select="substring-after(/url, 'file:')"/>
          </file>
          <make-directories>false</make-directories>
          <append>true</append>
        </config>
      </p:input>
      <p:input name="data" transform="oxf:xslt" href="#document">
        <xsl:stylesheet version="2.0">
          <xsl:import href="warc-lib.xsl"/>
          <xsl:template match="/">
            <xsl:variable name="content" as="node()*">
              <!-- Request -->
              <version/>
              <field>
                <name>WARC-Type</name>
                <value>request</value>
              </field>
              <field>
                <name>WARC-Target-URI</name>
                <value>
                  <xsl:value-of select="/archive/request/location"/>
                </value>
              </field>
              <field>
                <name>WARC-Date</name>
                <value>
                  <!-- TODO: replace that by the archive sate -->
                  <xsl:value-of select="current-dateTime()"/>
                </value>
              </field>
              <field>
                <name>WARC-Record-ID</name>
                <value>
                  <xsl:text>&lt;urn:uuid:</xsl:text>
                  <xsl:value-of select="translate(substring(/root/action/@directory, 1, string-length(/root/action/@directory) - 1), '/', '-')"/>
                  <xsl:text>></xsl:text>
                </value>
              </field>
              <field>
                <name>Content-Type</name>
                <value>application/http;msgtype=request</value>
              </field>
              <!-- TODO: Content-Length: 381 -->
              <CRLF/>
              <xsl:apply-templates select="/archive/request" mode="warc"/>
              <CRLF/>
              <CRLF/>
              <!-- Response -->
              <version/>
              <field>
                <name>WARC-Type</name>
                <value>response</value>
              </field>
              <field>
                <name>WARC-Target-URI</name>
                <value>
                  <xsl:value-of select="/archive/request/location"/>
                </value>
              </field>
              <field>
                <name>WARC-Date</name>
                <value>
                  <!-- TODO: replace that by the archive sate -->
                  <xsl:value-of select="current-dateTime()"/>
                </value>
              </field>
              <field>
                <name>WARC-Record-ID</name>
                <value>
                  <xsl:text>&lt;urn:uuid:</xsl:text>
                  <xsl:value-of select="translate(substring(/root/action/@directory, 1, string-length(/root/action/@directory) - 1), '/', '-')"/>
                  <xsl:text>></xsl:text>
                </value>
              </field>
              <field>
                <name>Content-Type</name>
                <value>application/http;msgtype=response</value>
              </field>
              <!-- TODO: Content-Length: 381 -->
              <CRLF/>
              <xsl:apply-templates select="/archive/response" mode="warc"/>
              <CRLF/>
              
            </xsl:variable>
            <document xsl:version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" content-type="text/plain">
              <xsl:apply-templates select="$content" mode="warc"/>
            </document>
          </xsl:template>
        </xsl:stylesheet>
      </p:input>
    </p:processor>

    <!-- Add the response document to finalize the response record -->
    <p:processor name="oxf:file-serializer">
      <p:input name="config" transform="oxf:xslt" href="#warc">
        <config xsl:version="2.0">
          <file>
            <xsl:value-of select="substring-after(/url, 'file:')"/>
          </file>
          <make-directories>false</make-directories>
          <append>true</append>
        </config>
      </p:input>
      <p:input name="data" href="#document#xpointer(/archive/response/document)"/>
    </p:processor>
    
    <p:processor name="oxf:identity">
      <p:input name="data" href="current()"/>
      <p:output name="data" ref="files"/>
    </p:processor>


  </p:for-each>

  <p:processor name="oxf:null-serializer">
    <p:input name="data" href="#files"/>
  </p:processor>

  <p:processor name="oxf:zip">
    <p:input name="data" transform="oxf:xslt" href="#warc">
      <files xsl:version="2.0" file-name="archive.zip">
        <file name="archive.warc">
          <xsl:value-of select="/url"/>
        </file>
      </files>
    </p:input>
    <p:output name="data" id="zip"/>
  </p:processor>

  <p:processor name="oxf:file-serializer">
    <p:input name="config">
      <config>
        <file>/tmp/archive.zip</file>
      </config>
    </p:input>
    <p:input name="data" href="#zip"/>

  </p:processor>

  <!--
  <!-\- Update the queue -\->
  <p:processor name="oxf:pipeline">
    <p:input name="config" href="/data-access.xpl"/>
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
  </p:processor>-->


</p:config>
