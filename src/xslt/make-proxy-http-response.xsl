<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- remove any payload headers from the response, because we'll have invalidated them by modifying and retransmitting the result -->
	<xsl:template match="c:header[lower-case(@name)=('content-length', 'content-range', 'trailer', 'transfer-encoding')]"/>
	
	<!--TODO cookie management-->
	<!-- Proxy user may have specified their Trove API key using a "key" URI parameter, which we should return as a set-cookie header -->
	
</xsl:stylesheet>