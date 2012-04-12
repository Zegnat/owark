
<!--
    
    Database creation
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">

    <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data">
            <config>
                <relpath>index.xhtml</relpath>
                <operation>write</operation>
                <type>document</type>
            </config>
        </p:input>
        <p:input name="param">
            <html xml:lang="fr" >
                <head>
                    <title>Owark DB</title>
                </head>
                <body>
                    <p>Owark db</p>
                </body>
            </html>
        </p:input>
        <p:output name="data" id="response" debug="response"/>
    </p:processor>

    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response"/>
    </p:processor>


    <p:processor name="oxf:pipeline">
        <p:input name="config" href="data-access.xpl"/>
        <p:input name="data">
            <config>
                <relpath>queue.xml</relpath>
                <operation>write</operation>
                <type>document</type>
            </config>
        </p:input>
        <p:input name="param">
            <queue/>
        </p:input>
        <p:output name="data" id="response2" debug="response2"/>
    </p:processor>
    
    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#response2"/>
    </p:processor>
    

    <!-- Indexes -->
    <!--<p:processor name="oxf:pipeline">
        <p:input name="config" href="create-indexes.xpl"/>
    </p:processor>
    -->


</p:config>
