<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<!-- converts an HTTP request received by the proxy into an HTTP request ready to be forwarded to Trove -->  
	<xsl:mode on-no-match="shallow-copy"/>
	

	<!--
	strip out any request parameters directed at the proxy so they don't get sent on to trove
	we should also remove any "encoding" parameter since we're always requesting XML (and using an Accept header to do so)
	"key" parameter should be stripped out of the request URI sent to Trove, since we will send it via an X-API-KEY header
	-->	
	
	<!-- 
		TODO at least some of these URI variables need to be defined in the calling XProc pipeline since they'll be needed
		to convert URIs in the Trove response into URIs referring to the proxy service
	-->
	
	<xsl:template match="/c:request">
		<xsl:copy>
			<!-- 
				Setting 'detailed' to 'true' means the response to our http-request will be a result document whose root element is c:response, containing
				• a c:header element for each HTTP response header, and 
				• a c:body element containing the Trove XML
			-->
			<xsl:attribute name="detailed">true</xsl:attribute>
			<xsl:apply-templates select="@*"/>
			<c:header name="accept" value="application/xml"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="/c:request/c:param-set"/>

	<xsl:template match="/c:request/@href">
		<!-- the base URI of the upstream API -->
		<xsl:variable name="upstream-base-uri" select=" 'https://api.trove.nla.gov.au/' "/>
	
		<!-- regular expression to parse the request URI -->
		<xsl:variable name="uri-parser" select=" '^(.*?//.*?/proxy/)(.*?)(\?.*)$' "/>
		<xsl:variable name="api-path-component" select="replace(/c:request/@href, $uri-parser, '$2')"/>
		<xsl:variable name="query-component" select="replace(/c:request/@href, $uri-parser, '$3')"/>
		<xsl:variable name="parameters" select="$query-component => substring-after('?') => tokenize('&amp;')"/> 
		<xsl:variable name="purified-parameters" select="$parameters[not(starts-with(., 'proxy-'))]"/>
		<xsl:attribute name="href" select="
			string-join(
				(
					concat($upstream-base-uri, $api-path-component),
					$purified-parameters => string-join('&amp;')
				),
				'?'
			)
		"/>
	</xsl:template>
	
	<!--TODO cookie management-->
	<!-- Proxy user may have specified their Trove API key using the "key" URI parameter, which we should remove from the request URI, and replace with an X-API-KEY header -->
	<!-- Proxy user may specify their Trove API key using a cookie, which we will find in a set-cookie header, and which we can marshall into an X-API-KEY header -->

	<!-- delete "host" header which if it exists will specify the hostname of the proxy service, rather than "api.trove.nla.gov.au" -->
	<xsl:template match="/c:request/c:header[lower-case(@name)='host']"/>

	<!-- delete any existing "accept" header which we'll replace with "application/xml" in every case -->
	<xsl:template match="/c:request/c:header[lower-case(@name)='accept']"/>

</xsl:stylesheet>