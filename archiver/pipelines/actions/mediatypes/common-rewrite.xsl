<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:owk="http://owark.org/xslt/"
    exclude-result-prefixes="xs xd owk" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> May 4, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> vdv</xd:p>
            <xd:p>Common functions and template for URL rewriting</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="owk:is-relative" as="xs:boolean">
        <xsl:param name="url" as="xs:string"/>
        <xsl:sequence select="not(substring-before($url, ':') = ('http', 'https'))"/>
    </xsl:function>
    <xsl:function name="owk:safer-resolve-uri" as="xs:string">
        <xsl:param name="relative" as="xs:string"/>
        <xsl:param name="hbase" as="xs:string"/>
        <xsl:sequence select="if (owk:is-relative($relative)) then resolve-uri($relative, $hbase) else $relative"/>
    </xsl:function>
    <xsl:function name="owk:url-rewrite" as="xs:string">
        <xsl:param name="url" as="xs:string"/>
        <xsl:variable name="no-fragment" select="substring-before(concat($url, '#'), '#')"/>
        <xsl:variable name="abs" select="owk:safer-resolve-uri($no-fragment, $base) cast as xs:string"/>
        <xsl:variable name="local-name" select="$index/resource[(for $u in (uri, same-as) return $u cast as xs:string) = $abs][1]/local-name"/>
        <xsl:message>local-name: <xsl:value-of select="$local-name"/></xsl:message>
        <xsl:sequence select="if ($local-name) then concat(if ($resource/uri/@seed = 'false') then '../' else '', $local-name) else owk:safer-resolve-uri($url, $base)"/>
    </xsl:function>

    <xsl:variable name="index" select="doc('input:index')/*"/>
    <xsl:variable name="resource" select="doc('input:index-entry')/resource"/>
    <xsl:variable name="base" select="$resource/uri"/>
</xsl:stylesheet>
