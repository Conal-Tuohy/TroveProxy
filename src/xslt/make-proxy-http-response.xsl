<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<xsl:mode on-no-match="shallow-copy"/>
	
	<xsl:param name="content-type"/>
	
	<!-- remove any payload headers from the response, because we'll have invalidated them by modifying and retransmitting the result -->
	<xsl:template match="c:header[lower-case(@name)=('content-length', 'content-range', 'trailer', 'transfer-encoding')]"/>
		
	<xsl:template match="c:body/@content-type">
		<xsl:attribute name="content-type">{$content-type}</xsl:attribute>
	</xsl:template>
	
</xsl:stylesheet>