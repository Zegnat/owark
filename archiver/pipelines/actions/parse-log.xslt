<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 26, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> vdv</xd:p>
            <xd:p>See https://webarchive.jira.com/wiki/display/Heritrix/Logs</xd:p>
        </xd:desc>
    </xd:doc>


    <xsl:template match="/document">
        <log>
            <xsl:for-each select="tokenize(., '\n')[. != '']">
                <entry>
                    <date-time>
                        <xsl:value-of select="substring(., 1, 24)"/>
                    </date-time>
                    <code>
                        <xsl:value-of select="normalize-space(substring(., 26, 5))"/>
                    </code>
                    <size>
                        <xsl:value-of select="normalize-space(substring(., 33, 10))"/>
                    </size>
                    <xsl:variable name="tail" select="substring(., 43)"/>
                    <xsl:variable name="tokens" select="tokenize($tail, ' ')"/>
                    <uri>
                        <xsl:value-of select="$tokens[1]"/>
                    </uri>
                    <discovery-path>
                        <xsl:value-of select="$tokens[2]"/>
                    </discovery-path>
                    <referer>
                        <xsl:value-of select="$tokens[3]"/>
                    </referer>
                    <content-type>
                        <xsl:value-of select="$tokens[4]"/>
                    </content-type>
                    <timestamp>
                        <xsl:value-of select="$tokens[6]"/>
                    </timestamp>
                    <sha1-digest>
                        <xsl:value-of select="$tokens[7]"/>
                    </sha1-digest>
                </entry>
            </xsl:for-each>
        </log>
    </xsl:template>

</xsl:stylesheet>
