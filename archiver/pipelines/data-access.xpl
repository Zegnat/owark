<!--
    
    Database access

-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:saxon="http://saxon.sf.net/">


    <p:param name="param" type="input"/>
    <!-- XQuery request or default document to read when not found -->
    <p:param name="data" type="input"/>
    <!-- Request description :
            <config>
                <relpath>Relatuve path</relpath>
                <operation>read|write</operation>
                <type>xquery|document</type>
                <parameter></parameter>
                <parameter></parameter>
            </config>
        -->
    <p:param name="data" type="output"/>


    <p:choose href="#data">
        <p:when test="/config/type = 'document' and /config/operation='read'">
            <p:processor name="oxf:xslt">
                <p:input name="data" href="#data"/>
                <p:input name="config.xml" href="oxf:/config.xml"/>
                <p:input name="config">
                    <xsl:stylesheet version="2.0">
                        <xsl:template match="/">
                            <xsl:variable name="config" select="doc('input:config.xml')/config"/>
                            <xforms:submission method="get" replace="none" action="{$config/exist-root}{$config/exist-db}{/config/relpath}"/>
                        </xsl:template>
                    </xsl:stylesheet>
                </p:input>
                <p:output name="data" id="submission"/>
            </p:processor>

            <p:processor name="oxf:xforms-submission">
                <p:input name="submission" href="#submission"/>
                <p:input name="request" href="#param"/>
                <p:output name="response" id="document"/>
            </p:processor>
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#document"/>
                <p:output name="data" id="document-exception"/>
            </p:processor>
            <p:choose href="#document-exception">
                <p:when test="/exceptions">
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#param"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                </p:when>
                <p:otherwise>
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#document-exception"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                </p:otherwise>
            </p:choose>

        </p:when>
        <p:when test="/config/type = 'document' and /config/operation='write'">
            <p:processor name="oxf:xslt">
                <p:input name="data" href="#data"/>
                <p:input name="config.xml" href="oxf:/config.xml"/>
                <p:input name="config">
                    <xsl:stylesheet version="2.0">
                        <xsl:template match="/">
                            <xsl:variable name="config" select="doc('input:config.xml')/config"/>
                            <xforms:submission method="put" replace="none" action="{$config/exist-root}{$config/exist-db}{/config/relpath}"/>
                        </xsl:template>
                    </xsl:stylesheet>
                </p:input>
                <p:output name="data" id="submission"/>
            </p:processor>
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission" href="#submission"/>
                <p:input name="request" href="#param"/>
                <p:output name="response" ref="data"/>
            </p:processor>
        </p:when>

        <p:when test="/config/type = 'xquery' ">

            <p:processor name="oxf:unsafe-xslt">
                <p:input name="data" href="#data"/>
                <p:input name="config.xml" href="oxf:/config.xml"/>
                <p:input name="param" href="#param"/>
                <p:input name="config">
                    <xsl:stylesheet version="2.0">
                        <xsl:output name="output" method="xml" omit-xml-declaration="yes"/>
                        <xsl:template match="/">
                            <xsl:variable name="query">
                                <xsl:variable name="data" select="/"/>
                                <xsl:analyze-string select="string(doc('input:param'))" regex="\$\((\i\c*)\)" flags="">
                                    <xsl:matching-substring>
                                        <xsl:variable name="parameter" select="$data/config/parameter[@name = regex-group(1)]"/>
                                        <xsl:variable name="sanitized" select="if ($parameter/@type = 'node-set') then saxon:serialize($parameter/*, 'output') else replace(replace($parameter, '&amp;', '&amp;amp;'), '''', '&amp;apos;')"/>
                                        <xsl:choose>
                                            <xsl:when test="not($parameter)">
                                                <xsl:message terminate="yes">Parameter <xsl:value-of select="regex-group(1)"/> not found in query <xsl:value-of select="doc('input:param')"
                                                    /></xsl:message>
                                            </xsl:when>
                                            <xsl:when test="$parameter/@type='string'">
                                                <xsl:text>'</xsl:text>
                                                <xsl:value-of select="$sanitized"/>
                                                <xsl:text>'</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="$parameter/@type='node-set'">
                                                <xsl:copy-of select="$sanitized"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="$parameter/@type"/>
                                                <xsl:text>('</xsl:text>
                                                <xsl:value-of select="$sanitized"/>
                                                <xsl:text>')</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:variable>
                            <xsl:message>
                                <xsl:value-of select="$query"/>
                            </xsl:message>
                            <xsl:variable name="config" select="doc('input:config.xml')/config"/>
                            <xforms:submission method="get" replace="none"
                                action="{$config/exist-root}{$config/exist-db}{/config/relpath}?_howmany=10000&amp;_query={encode-for-uri(normalize-space($query))}"/>
                        </xsl:template>
                    </xsl:stylesheet>
                </p:input>
                <p:output name="data" id="submission"/>
            </p:processor>
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission" href="#submission"/>
                <p:input name="request" href="#param"/>
                <p:output name="response" ref="data"/>
            </p:processor>

        </p:when>

        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <not-implemented/>
                </p:input>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>
    </p:choose>



</p:config>
