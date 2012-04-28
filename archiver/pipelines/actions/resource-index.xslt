<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:owk="http://owark.org/xslt/" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs xd owk" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 26, 2012</xd:p>
            <xd:p><xd:b>Author:</xd:b> vdv</xd:p>
            <xd:p>Create a resource index with links and local names from the Heritrix crawl log in XML format</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:variable name="source" select="/"/>

    <xsl:variable name="common-extensions">
        <content-type name="application/x-shockwave-flash">
            <extension>swf</extension>
        </content-type>
    </xsl:variable>

    <xsl:key name="extension" match="content-type" use="@name"/>

    <xsl:function name="owk:add-extension" as="xs:string">
        <xsl:param name="entry" as="element(entry)"/>
        <xsl:param name="last-token" as="xs:string"/>
        <xsl:sequence select="
            if (contains($last-token, '.')) 
                then ''
                else concat('.', 
                    if (key('extension', $entry/content-type, $common-extensions))
                        then key('extension', $entry/content-type, $common-extensions)
                        else if (contains($entry/content-type, '/')) 
                            then substring-after($entry/content-type, '/')
                            else 'unknown') "/>
    </xsl:function>


    <xsl:function name="owk:local-name" as="xs:string">
        <xsl:param name="entry" as="element(entry)"/>
        <xsl:variable name="is-seed" select="$entry/discovery-path='-'"/>
        <xsl:variable name="tokens" select="tokenize(if (contains($entry/uri, '?')) then substring-before($entry/uri, '?') else $entry/uri, '/')"/>
        <xsl:sequence
            select="if ($is-seed) 
            then 'index.html' 
            else concat(
                $tokens[3], 
                '/', 
                if ($tokens[last()] = '') then 'index' else $tokens[last()], 
                owk:add-extension($entry, $tokens[last()]))"
        />
    </xsl:function>

    <xsl:function name="owk:unique-local-name" as="xs:string">
        <xsl:param name="entry" as="element(entry)"/>
        <xsl:variable name="local-name" select="owk:local-name($entry)"/>
        <xsl:sequence
            select="if (count(key('entry-by-name', $local-name, $source)) = 1)
                        then $local-name
                        else concat(
                            substring-before($local-name, '/'),
                            '/',
                            substring-before(substring-after($local-name, '/'), '.'),
                            '-',
                            count($entry/preceding-sibling::entry[owk:local-name(.) = $local-name]) + 1,
                            '.',
                            substring-after(substring-after($local-name, '/'), '.')
                        )"
        />
    </xsl:function>

    <xsl:key name="entry-by-name" match="entry[substring-before(uri, '://') = ('http', 'https')]" use="owk:local-name(.)"/>

    <xsl:template match="/log">
        <index>
            <xsl:apply-templates select="entry[substring-before(uri, '://') = ('http', 'https') and code = 200]"/>
        </index>
    </xsl:template>

    <xsl:template match="entry">
        <resource>
            <xsl:variable name="is-seed" select="discovery-path='-'"/>
            <uri seed="{$is-seed}">
                <xsl:value-of select="uri"/>
            </uri>
            <local-name>
                <xsl:value-of select="owk:unique-local-name(.)"/>
            </local-name>
            <type>
                <xsl:choose>
                    <xsl:when test="content-type = 'text/html'">html</xsl:when>
                    <xsl:when test="content-type = 'application/xhtml+xml'">html</xsl:when>
                    <xsl:when test="content-type = 'text/plain'">text</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring-after(content-type, '/')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </type>
            <xsl:apply-templates select="." mode="redirect"/>
            <xsl:apply-templates select="/log/entry[referer = current()/uri and ends-with(discovery-path, 'E')]" mode="embedding"/>
        </resource>
    </xsl:template>

    <xsl:template match="*" mode="redirect"/>
    <xsl:template match="entry[ends-with(discovery-path, 'R')]" mode="redirect">
        <same-as seed="{discovery-path='-'}">
            <xsl:value-of select="referer"/>
        </same-as>
        <xsl:apply-templates select="/log/entry[uri = current()/referer]" mode="redirect"/>
    </xsl:template>

    <xsl:template match="entry" mode="embedding">
        <embeds>
            <xsl:value-of select="uri"/>
        </embeds>
    </xsl:template>

</xsl:stylesheet>
