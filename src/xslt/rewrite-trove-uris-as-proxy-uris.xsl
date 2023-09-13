<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">

	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:param name="request-uri"/>
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
	
	<!-- remove any "canonical" link because we will be adding a new one pointing to the proxied URL -->
	<xsl:template match="c:response/c:header[ends-with(@name, '; rel=&quot;canonical&quot;')]"/>
	<!-- add a "canonical" link pointing to the current (proxied) resource -->
	<xsl:template match="c:response">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- TODO actually canonicalise this URI, removing any API key parameter from it, sorting the params in alpha order, etc -->
			<c:header name="Link" value="&lt;{$request-uri}&gt;; rel=canonical"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@next">
		<xsl:attribute name="next">
			<xsl:call-template name="rewrite-uri"/>
		</xsl:attribute>
	</xsl:template>

</xsl:stylesheet>