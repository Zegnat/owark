
<!--
    
    Remove the database
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
    xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">

        <p:processor name="oxf:xforms-submission">
            <p:input name="submission" href="oxf:/config.xml"
                transform="oxf:xslt">
                <xforms:submission xsl:version="2.0" method="delete"
                    action="{/config/exist-root}{/config/exist-db}"
                />
            </p:input>
            <p:input name="request">
                <empty/>
            </p:input>
            <p:output name="response" id="response1"/>
        </p:processor>

        <p:processor name="oxf:null-serializer">
            <p:input name="data" href="#response1"/>
        </p:processor>


</p:config>
