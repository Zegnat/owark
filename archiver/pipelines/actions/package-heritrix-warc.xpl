
<!--
    
    Package an Heritrix WARC
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:saxon="http://saxon.sf.net/"
    xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">

    <p:param name="data" type="input"/>


    <!-- Download the WARC -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#data">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="/action/@warc-url"/>
                </url>
                <mode>binary</mode>
                <authentication>
                    <username>
                        <xsl:value-of select="doc('oxf:/config.xml')/config/heritrix/username"/>
                    </username>
                    <password>
                        <xsl:value-of select="doc('oxf:/config.xml')/config/heritrix/password"/>
                    </password>
                    <preemptive>false</preemptive>
                </authentication>
            </config>
        </p:input>
        <p:output name="data" id="warc"/>
    </p:processor>
    
    <!-- Store it in a temp file -->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>request</scope>
            </config>
        </p:input>
        <p:input name="data" href="#warc"/>
        <p:output name="data" id="warc-location" debug="warc-location"/>
    </p:processor>

    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:unsafe-xslt" href="aggregate('root', #warc-location)">
            <files xsl:version="2.0" file-name="archive.zip">
                <file name="archive.warc">
                    <xsl:value-of select="/root/url"/>
                </file>
                <!--<xsl:for-each select="/root/files/file[url]">
                    <xsl:choose>
                        <xsl:when test="position()=1">
                            <!-\- TODO: support non HTML documents... -\->
                            <file name="rewritten/index.html">
                                <xsl:value-of select="url"/>
                            </file>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="tokens" select="tokenize(archive/@url, '/')"/>
                            <xsl:variable name="last-token" select="$tokens[last()]"/>
                            <xsl:variable name="tokens2" select="tokenize($last-token, '\.')"/>
                            <xsl:variable name="extension" select="$tokens2[last()]"/>
                            <file name="rewritten/{saxon:string-to-hexBinary(substring(archive/@url, 1, string-length(archive/@url) - string-length($extension) - 1), 'utf-8')}.{$extension}">
                                <xsl:value-of select="url"/>
                            </file>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>-->
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
    
   <!-- <p:choose href="#heritrix-job">
        <p:when test="/job/crawlControllerState='FINISHED'">
            <!-\- The job is finished, we can get its archive... -\->
            <!-\- Scan the directory to find the name of the WARC file -\->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#heritrix-job">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="/job/configFiles/value[key='warcWriter.storePaths[0]']/url"/>
                        </url>
                        <authentication>
                            <username>
                                <xsl:value-of select="doc('oxf:/config.xml')/config/heritrix/username"/>
                            </username>
                            <password>
                                <xsl:value-of select="doc('oxf:/config.xml')/config/heritrix/password"/>
                            </password>
                            <preemptive>false</preemptive>
                        </authentication>
                    </config>
                </p:input>
                <p:output name="data" id="warc-dir-list" debug="warc-dir-list"/>
            </p:processor>
            <!-\- Next action: package  -\->
            <p:processor name="oxf:pipeline">
                <p:input name="config" href="/data-access.xpl"/>
                <p:input name="data" transform="oxf:xslt" href="aggregate('root', #data, #warc-dir-list)">
                    <config xsl:version="2.0">
                        <relpath>queue.xml</relpath>
                        <operation>write</operation>
                        <type>xquery</type>
                        <parameter name="uuid" type="string">
                            <xsl:value-of select="/root/action/@uuid"/>
                        </parameter>
                        <parameter name="url" type="string">
                            <xsl:value-of select="/root/action/@url"/>
                        </parameter>
                        <parameter name="directory" type="string">
                            <xsl:value-of select="/root/action/@directory"/>
                        </parameter>
                        <parameter name="heritrix-job-url" type="string">
                            <xsl:value-of select="/root/action/@heritrix-job-url"/>
                        </parameter>
                        <parameter name="priority" type="string">
                            <xsl:value-of select="/root/action/@priority"/>
                        </parameter>
                        <parameter name="warc-url" type="string">
                            <xsl:value-of select="/root/html/body/a[ends-with(., '.warc')][1]/@href"/>
                        </parameter>
                    </config>
                </p:input>
                <p:input name="param">
                    <xquery><![CDATA[
declare namespace util = "http://exist-db.org/xquery/util";

for $q in /queue return
    update 
        insert <action priority=$(priority) uuid="{util:uuid()}" type="package-heritrix-warc" url=$(url) directory=$(directory) heritrix-job-url=$(heritrix-job-url) warc-url=$(warc-url)/>
        into $q,
        
for $a in /queue/action where $a/@uuid = $(uuid) return
    update
        delete $a
        
                ]]></xquery>
                </p:input>
                <p:output name="data" id="response" debug="response"/>
            </p:processor>
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#response"/>
            </p:processor>
        </p:when>
        <p:otherwise>
            <!-\- The job is not finished yet, we'll check later on... -\->
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
                        <parameter name="next-time" type="string">
                            <xsl:value-of select="current-dateTime() +  xs:dayTimeDuration('PT1M')"/>
                        </parameter>
                    </config>
                </p:input>
                <p:input name="param">
                    <xquery><![CDATA[
for $a in /queue/action where $a/@uuid = $(uuid) return
        update value $a/@after with $(next-time)
        
                ]]></xquery>
                </p:input>
                <p:output name="data" id="response" debug="response"/>
            </p:processor>
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#response"/>
            </p:processor>
        </p:otherwise>
    </p:choose>


    <!-\-    <p:processor name="oxf:unsafe-xslt">
        <p:input name="data" href="aggregate('root', #data, #heritrix-engine, #heritrix-unpaused)"/>
        <p:input name="config">
            <config xsl:version="2.0">
                <relpath>queue.xml</relpath>
                <operation>write</operation>
                <type>xquery</type>
                <parameter name="directory" type="string">
                    <xsl:value-of select="translate(/root/action/@uuid, '-', '/')"/>
                    <xsl:text>/</xsl:text>
                </parameter>
                <parameter name="uuid" type="string">
                    <xsl:value-of select="/root/action/@uuid"/>
                </parameter>
                <parameter name="url" type="string">
                    <xsl:value-of select="/root/action/@url"/>
                </parameter>
                <parameter name="priority-warc" type="string">
                    <xsl:value-of select="/root/action/@priority + 1"/>
                </parameter>
                <parameter name="next-time" type="string">
                    <xsl:value-of select="current-dateTime() +  xs:dayTimeDuration('PT1M')"/>
                </parameter>
                <parameter name="heritrix-job-url" type="string">
                    <xsl:value-of select="/root/engine/jobs/value[shortName=/root/action/@uuid]/url"/>
                </parameter>
            </config>
        </p:input>
        <p:output name="data" id="data-access-data"/>
    </p:processor>
    
    
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="/data-access.xpl"/>
        <p:input name="data" transform="oxf:xslt" href="#data-access-data">
            <config xsl:version="2.0">
                <relpath>
                    <xsl:value-of select="/config/parameter[@name='directory']"/>
                    <xsl:text>index.xml</xsl:text>
                </relpath>
                <operation>write</operation>
                <type>document</type>
            </config>
        </p:input>
        <p:input name="param" transform="oxf:xslt" href="#data-access-data">
            <archive-set xsl:version="2.0" url="{/config/parameter[@name='url']}" uuid="{/config/parameter[@name='uuid']}">
                <heritrix-job url="{/config/parameter[@name='heritrix-job-url']}"/>
            </archive-set>
        </p:input>
        <p:output name="data" id="response2" debug="response2"/>
    </p:processor>
    
    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response2"/>
    </p:processor>
    

    <p:processor name="oxf:pipeline">
        <p:input name="config" href="/data-access.xpl"/>
        <p:input name="data" href="#data-access-data"/>
        <p:input name="param">
            <xquery><![CDATA[
declare namespace util = "http://exist-db.org/xquery/util";

for $q in /queue return
    update 
        insert <action priority=$(priority-warc) uuid="{util:uuid()}" type="get-heritrix-warc" url=$(url) directory=$(directory) heritrix-job-url=$(heritrix-job-url) after=$(next-time)/>
        into $q,
        
for $a in /queue/action where $a/@uuid = $(uuid) return
    update
        delete $a
        
                ]]></xquery>
        </p:input>
        <p:output name="data" id="response" debug="response"/>
    </p:processor>

    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response"/>
    </p:processor>-\->

-->
</p:config>
