
<!--
    
    Reinstall the database
    
-->

<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xforms="http://www.w3.org/2002/xforms"
    xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary">


    <p:processor name="oxf:pipeline">
        <p:input name="config" href="uninstall-db.xpl" />
    </p:processor>
    
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="install-db.xpl" />
    </p:processor>
    
    
</p:config>
