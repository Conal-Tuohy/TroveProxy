<xsl:stylesheet version="3.0" expand-text="yes"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:c="http://www.w3.org/ns/xproc-step">

	<!-- transform an HTML table into CSV -->
	<xsl:mode on-no-match="shallow-copy"/>
	
	<xsl:template match="c:body/@content-type">
		<xsl:attribute name="content-type">text/csv</xsl:attribute>
	</xsl:template>

	<xsl:template match="xhtml:table">
		<xsl:apply-templates select=".//xhtml:tr"/>
	</xsl:template>
	
	<xsl:template match="xhtml:tr">
		<xsl:apply-templates select="*"/>
		<xsl:value-of select="codepoints-to-string((13, 10))"/><!-- CR LF -->
	</xsl:template>

	<xsl:template match="xhtml:th | xhtml:td">
		<xsl:if test="preceding-sibling::*">,</xsl:if>
		<xsl:text>"</xsl:text>
		<xsl:value-of select="replace(., '&quot;', '&quot;&quot;')"/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>