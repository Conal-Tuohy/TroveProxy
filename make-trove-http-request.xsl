<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<!-- converts an HTTP request received by the proxy into an HTTP request ready to be forwarded to Trove -->  
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- 
		TODO at least some of these URI variables need to be defined in the calling XProc pipeline since they'll be needed
		to convert URIs in the Trove response into URIs referring to the proxy service
	-->
	
	<!-- the base URI of the upstream API -->
	<xsl:variable name="upstream-base-uri" select=" 'https://api.trove.nla.gov.au/' "/>
	<!-- regular expression to parse the request URI -->
	<xsl:variable name="uri-parser" select=" '(.*?//.*?/proxy/)(.*)' "/>
	<xsl:variable name="proxy-base-uri" select="replace(/c:request/@href, $uri-parser, '$1')"/>
	<xsl:variable name="relative-uri" select="replace(/c:request/@href, $uri-parser, '$2')"/>

	<xsl:template match="/c:request">
		<xsl:copy>
			<xsl:attribute name="detailed">true</xsl:attribute>
			<xsl:apply-templates select="@*"/>
			<c:header name="accept" value="application/xml"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="/c:request/@href">
		<xsl:attribute name="href" select="concat($upstream-base-uri, $relative-uri)"/>
	</xsl:template>
	
	<!--TODO cookie management-->

	<!-- delete "host" header which if it exists will specify the hostname of the proxy service, rather than "api.trove.nla.gov.au" -->
	<xsl:template match="/c:request/c:header[lower-case(@name)='host']"/>

	<!-- delete any existing "accept" header which we'll replace with "application/xml" in every case -->
	<xsl:template match="/c:request/c:header[lower-case(@name)='host']"/>

</xsl:stylesheet>