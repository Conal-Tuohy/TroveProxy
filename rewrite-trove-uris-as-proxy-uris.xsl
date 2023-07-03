<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">

	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:param name="proxy-base-uri"/>
	<xsl:param name="upstream-base-uri"/>
	
	<xsl:template name="rewrite-uri">
		<xsl:sequence select="
			concat(
				$proxy-base-uri,
				substring-after(., $upstream-base-uri)
			)
		"/>
	</xsl:template>
	
	<xsl:template match="@next">
		<xsl:attribute name="next">
			<xsl:call-template name="rewrite-uri"/>
		</xsl:attribute>
	</xsl:template>

</xsl:stylesheet>