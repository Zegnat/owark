
<!--
    
    Scheduler
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">

    <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data">
            <config>
                <relpath>queue.xml</relpath>
                <operation>read</operation>
                <type>xquery</type>
            </config>
        </p:input>
        <p:input name="param">
            <xquery><![CDATA[

/queue/action[@priority=max(/queue/action/@priority)]
                
                ]]></xquery>
        </p:input>
        <p:output name="data" id="actions" debug="actions"/>
    </p:processor>

    <p:for-each href="#actions" select="/*/action">

        <p:processor name="oxf:url-generator">
            <p:input name="config" transform="oxf:xslt" href="current()">
                <config xsl:version="2.0">
                    <url>
                        <xsl:text>oxf:/</xsl:text>
                        <xsl:value-of select="/action/@type"/>
                        <xsl:text>.xpl</xsl:text>
                    </url>
                </config>
            </p:input>
            <p:output name="data" id="pipeline"/>
        </p:processor>

        <p:processor name="oxf:pipeline">
            <p:input name="config" href="#pipeline"/>
            <p:input name="data" href="current()"/>
        </p:processor>

    </p:for-each>


</p:config>
