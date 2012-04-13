<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 13, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> vdv</xd:p>
            <xd:p>Template library to produce WARC documents</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:variable name="CRLF" select="'&#13;&#10;'"/>
    <xsl:variable name="version">WARC/0.18</xsl:variable>
    <xsl:template match="CRLF" mode="warc">
        <xsl:value-of select="$CRLF"/>
    </xsl:template>
    <xsl:template match="version" mode="warc">
        <xsl:value-of select="$version"/>
        <xsl:value-of select="$CRLF"/>
    </xsl:template>
    <xsl:template match="field" mode="warc">
        <xsl:value-of select="name"/>
        <xsl:text>: </xsl:text>
        <xsl:value-of select="value"/>
        <xsl:value-of select="$CRLF"/>
    </xsl:template>
    <xsl:template match="line" mode="warc">
        <xsl:value-of select="."/>
        <xsl:value-of select="$CRLF"/>
    </xsl:template>

    <xsl:template match="request" mode="warc">
        <line>
            <xsl:value-of select="method"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="location"/>
            <xsl:text> </xsl:text>
            <!-- TODO: get the HTTP version -->
            <xsl:text>HTTP/1.0</xsl:text>
        </line>
        <xsl:apply-templates select="header" mode="warc"/>
    </xsl:template>

    <xsl:template match="response" mode="warc">
        <line>
            <!-- TODO: get the HTTP version and status-->
            <xsl:text>HTTP/1.1 </xsl:text>
            <xsl:value-of select="code"/>
            <xsl:text> OK</xsl:text>
        </line>
        <xsl:apply-templates select="header" mode="warc"/>
    </xsl:template>

    <xsl:template match="header" mode="warc">
        <field>
            <name>
                <xsl:value-of select="@name"/>
            </name>
            <value>
                <xsl:value-of select="."/>
            </value>
        </field>
    </xsl:template>

    <xsl:template match="text()" mode="warc"/>


</xsl:stylesheet>
