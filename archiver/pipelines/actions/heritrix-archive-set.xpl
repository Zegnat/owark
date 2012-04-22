
<!--
    
    Create a new archive through Heritrix
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:saxon="http://saxon.sf.net/"
    xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">

    <p:param name="data" type="input"/>


    <!-- Create a new Heritrix job-->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="oxf:/config.xml">
            <xforms:submission xsl:version="2.0" method="urlencoded-post" action="{/config/heritrix/rest-api}" xxforms:username="{/config/heritrix/username}"
                xxforms:password="{/config/heritrix/password}" xxforms:preemptive-authentication="false">
                <xforms:header combine="replace">
                    <xforms:name>Accept</xforms:name>
                    <xforms:value>application/xml</xforms:value>
                </xforms:header>
            </xforms:submission>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#data">
            <instance xsl:version="2.0">
                <action>create</action>
                <createpath>
                    <xsl:value-of select="/action/@uuid"/>
                </createpath>
            </instance>
        </p:input>
        <p:output name="response" id="heritrix-engine" debug="heritrix-engine"/>
    </p:processor>

    <!-- Create a job configuration -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="#data"/>
        <p:input name="config" href="cxml.xslt"/>
        <p:output name="data" id="cxml"/>
    </p:processor>

    <!-- Upload the job configuration -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="aggregate('root', #data, #heritrix-engine)">
            <xforms:submission xsl:version="2.0" method="put" action="{/root/engine/jobs/value[shortName=/root/action/@uuid]/primaryConfigUrl}"
                xxforms:username="{doc('oxf:/config.xml')/config/heritrix/username}" xxforms:password="{doc('oxf:/config.xml')//config/heritrix/password}" xxforms:preemptive-authentication="false"/>
        </p:input>
        <p:input name="request" href="#cxml"/>
        <p:output name="response" id="cxml-response" debug="cxml-response"/>
    </p:processor>


    <!-- Build the job -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="aggregate('root', #data, #heritrix-engine, #cxml-response)">
            <xforms:submission xsl:version="2.0" method="urlencoded-post" action="{/root/engine/jobs/value[shortName=/root/action/@uuid]/url}"
                xxforms:username="{doc('oxf:/config.xml')/config/heritrix/username}" xxforms:password="{doc('oxf:/config.xml')/config/heritrix/password}" xxforms:preemptive-authentication="false">
                <xforms:header combine="replace">
                    <xforms:name>Accept</xforms:name>
                    <xforms:value>application/xml</xforms:value>
                </xforms:header>
            </xforms:submission>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#data">
            <instance xsl:version="2.0">
                <action>build</action>
            </instance>
        </p:input>
        <p:output name="response" id="heritrix-built" debug="heritrix-built"/>
    </p:processor>

    <!-- Launch the job -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="aggregate('root', #data, #heritrix-engine, #heritrix-built)">
            <xforms:submission xsl:version="2.0" method="urlencoded-post" action="{/root/engine/jobs/value[shortName=/root/action/@uuid]/url}"
                xxforms:username="{doc('oxf:/config.xml')/config/heritrix/username}" xxforms:password="{doc('oxf:/config.xml')/config/heritrix/password}" xxforms:preemptive-authentication="false">
                <xforms:header combine="replace">
                    <xforms:name>Accept</xforms:name>
                    <xforms:value>application/xml</xforms:value>
                </xforms:header>
            </xforms:submission>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#data">
            <instance xsl:version="2.0">
                <action>launch</action>
            </instance>
        </p:input>
        <p:output name="response" id="heritrix-launched" debug="heritrix-launched"/>
    </p:processor>

    <!-- Unpause the job -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="aggregate('root', #data, #heritrix-engine, #heritrix-launched)">
            <xforms:submission xsl:version="2.0" method="urlencoded-post" action="{/root/engine/jobs/value[shortName=/root/action/@uuid]/url}"
                xxforms:username="{doc('oxf:/config.xml')/config/heritrix/username}" xxforms:password="{doc('oxf:/config.xml')/config/heritrix/password}" xxforms:preemptive-authentication="false">
                <xforms:header combine="replace">
                    <xforms:name>Accept</xforms:name>
                    <xforms:value>application/xml</xforms:value>
                </xforms:header>
            </xforms:submission>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#data">
            <instance xsl:version="2.0">
                <action>unpause</action>
            </instance>
        </p:input>
        <p:output name="response" id="heritrix-unpaused" debug="heritrix-unpaused"/>
    </p:processor>


    <p:processor name="oxf:unsafe-xslt">
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
    </p:processor>


</p:config>
