<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/">

  <p:param name="data" type="input"/>

  <!-- Look if the resource has already been archived for that set -->
  <p:processor name="oxf:pipeline">
    <p:input name="config" href="/data-access.xpl"/>
    <p:input name="data" transform="oxf:xslt" href="#data">
      <config xsl:version="2.0">
        <relpath>
          <xsl:value-of select="/action/@directory"/>
          <xsl:text>index.xml</xsl:text>
        </relpath>
        <operation>read</operation>
        <type>xquery</type>
        <parameter name="url" type="string">
          <xsl:value-of select="/action/@url"/>
        </parameter>
      </config>
    </p:input>
    <p:input name="param">
      <xquery><![CDATA[
        
boolean(//archive[@url = $(url)])
                
                ]]></xquery>
    </p:input>
    <p:output name="data" id="duplicate" debug="duplicate"/>
  </p:processor>

  <p:choose href="#duplicate">

    <p:when test="/*/* = 'true'">
      <!-- Already archived, nothing to do -->
      <!-- Update the queue -->
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
      </p:processor>
    </p:when>

    <p:otherwise>
      <!-- Otherwise, archive the resource... -->
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
        <p:input name="config" href="/data-access.xpl"/>
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
        <p:when test="/archive/response/document/@content-type=('text/html', 'text/css')">

          <!-- Call the corresponding pipeline to extract the links and rewrite them -->
          <p:processor name="oxf:url-generator">
            <p:input name="config" transform="oxf:xslt" href="#archive">
              <config xsl:version="2.0">
                <url>
                  <xsl:text>oxf:/actions/mediatypes/</xsl:text>
                  <xsl:value-of select="substring-after(/archive/response/document/@content-type, '/')"/>
                  <xsl:text>.xpl</xsl:text>
                </url>
              </config>
            </p:input>
            <p:output name="data" id="pipeline"/>
          </p:processor>

          <p:processor name="oxf:pipeline">
            <p:input name="config" href="#pipeline"/>
            <p:input name="archive" href="#archive"/>
            <p:output name="rewritten" id="rewritten"/>
            <p:output name="links" id="links"/>
          </p:processor>

          <!-- It's a hack so that the document is not submitted as text through the xforms:submit processor... -->
          <p:processor name="oxf:xslt">
            <p:input name="config">
              <document xsl:version="2.0">
                <xsl:copy-of select="/"/>
              </document>
            </p:input>
            <p:input name="data" href="#rewritten"/>
            <p:output name="data" id="rewritten-embedded"/>
          </p:processor>

          <!-- Store the rewritten document in the database -->
          <p:processor name="oxf:pipeline">
            <p:input name="config" href="/data-access.xpl"/>
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
            <p:input name="param" href="#rewritten-embedded"/>
            <p:output name="data" id="response3"/>
          </p:processor>
          <p:processor name="oxf:null-serializer">
            <p:input name="data" href="#response3"/>
          </p:processor>



          <!-- Update the archive index -->
          <p:processor name="oxf:pipeline">
            <p:input name="config" href="/data-access.xpl"/>
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
        insert <archive url=$(url) href=$(filename) href-rewritten=$(filename-rewritten) dateTime="{current-dateTime()}"/> 
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
            <p:input name="config" href="/data-access.xpl"/>
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
                <parameter name="priority" type="string">
                  <xsl:value-of select="/root/action/@priority"/>
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

for $q in /queue[$links/link/@abs-href]
  return
    update 
        insert 
          for $href in distinct-values($links/link/@abs-href)
            let $link := $links/link[@abs-href = $href][1]
            return <action priority=$(priority) uuid="{util:uuid()}" type="archive-resource" url="{$link/@abs-href}" directory=$(directory) filename="{$link/@filename}"/> 
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
            <p:input name="config" href="/data-access.xpl"/>
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
        insert <archive url=$(url) href=$(filename) dateTime="{current-dateTime()}"/> 
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
          </p:processor>

        </p:otherwise>

      </p:choose>
    </p:otherwise>
  </p:choose>



</p:config>
