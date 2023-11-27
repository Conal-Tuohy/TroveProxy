<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="yes" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns="http://www.w3.org/2005/xpath-functions">
	
	<!-- converts an HTTP request received by the proxy into a citation in RO-Crate metadata format -->
	<!-- e.g. -->
	
	<c:request xmlns:c="http://www.w3.org/ns/xproc-step" detailed="true" href="http://localhost:8080/proxy/v3/result?key=&amp;proxy-format=tei&amp;n=10&amp;sortby=relevance&amp;reclevel=brief&amp;include=articleText&amp;category=newspaper&amp;q=(((scone+recipe)))&amp;proxy-metadata-format=ro-crate&amp;proxy-metadata-license-uri=https://creativecommons.org/licenses/by-nc-sa/3.0/au/&amp;proxy-metadata-name=Scone+recipes&amp;proxy-metadata-description=A+collection+of+scone+recipes" method="GET" status-only="false">
		<!-- the request URI parsed into its top-level components -->
		<c:param-set xmlns:fn="http://www.w3.org/2005/xpath-functions" xml:id="uri">
			<c:param name="scheme" value="http:"/>
			<c:param name="host" value="localhost"/>
			<c:param name="port" value=":8080"/>
			<c:param name="path" value="/proxy/v3/result"/>
			<c:param name="query" value="?key=&amp;proxy-format=tei&amp;n=10&amp;sortby=relevance&amp;reclevel=brief&amp;include=articleText&amp;category=newspaper&amp;q=(((scone+recipe)))&amp;proxy-metadata-format=ro-crate&amp;proxy-metadata-license-uri=https://creativecommons.org/licenses/by-nc-sa/3.0/au/&amp;proxy-metadata-name=Scone+recipes&amp;proxy-metadata-description=A+collection+of+scone+recipes"/>
		</c:param-set>
		<!-- the request URI's parameters -->
		<c:param-set xml:id="parameters">
			<c:param name="key" value=""/>
			<c:param name="proxy-format" value="tei"/>
			<c:param name="n" value="10"/>
			<c:param name="sortby" value="relevance"/>
			<c:param name="reclevel" value="brief"/>
			<c:param name="include" value="articleText"/>
			<c:param name="category" value="newspaper"/>
			<c:param name="q" value="(((scone recipe)))"/>
			<c:param name="proxy-metadata-format" value="ro-crate"/>
			<c:param name="proxy-metadata-license-uri" value="https://creativecommons.org/licenses/by-nc-sa/3.0/au/"/>
			<c:param name="proxy-metadata-name" value="Scone recipes"/>
			<c:param name="proxy-metadata-description" value="A collection of scone recipes"/>
		</c:param-set>
		<!-- the HTTP request headers -->
		<c:header name="host" value="localhost:8080"/>
		<c:header name="user-agent" value="Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"/>
		<c:header name="accept" value="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"/>
		<c:header name="accept-language" value="en-US,en;q=0.5"/>
		<c:header name="accept-encoding" value="gzip, deflate, br"/>
		<c:header name="connection" value="keep-alive"/>
		<c:header name="cookie" value="JSESSIONID=node01gwstz6jaikejjvpha9fklydd3.node0"/>
		<c:header name="upgrade-insecure-requests" value="1"/>
		<c:header name="sec-fetch-dest" value="document"/>
		<c:header name="sec-fetch-mode" value="navigate"/>
		<c:header name="sec-fetch-site" value="none"/>
		<c:header name="sec-fetch-user" value="?1"/>
	</c:request>

	<xsl:template match="/">
		<!-- we transform the above XML into JSON-XML (see <https://www.w3.org/TR/xslt-30/#json-to-xml-mapping>)
		and serialize that as JSON inside a c:response/c:body which XProc-Z will return as a JSON-LD file -->
		<c:response status="200">
			<c:body content-type="application/ld+json">
				<xsl:variable name="json-xml">
					<xsl:apply-templates/>
				</xsl:variable>
				<xsl:sequence select="xml-to-json($json-xml)"/>
			</c:body>
		</c:response>
	</xsl:template>
	
	<!-- render the TroveProxy API call as a description in RO-Crate metadata format -->
	<xsl:template match="/c:request">
		<!--
			For RO-Crate examples see: <https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#minimal-example-of-ro-crate>
			For JSON-XML syntax see: <https://www.w3.org/TR/xslt-30/#json-to-xml-mapping>
		-->
		<map>
			<string key="@context">https://w3id.org/ro/crate/1.1/context</string>
			<array key="@graph">
				<!-- description of this RO-Crate metadata entity -->
				<map>
					<string key="@id">ro-crate-metadata.json</string>
					<map key="conformsTo">
						<string key="@id">https://w3id.org/ro/crate/1.1</string>
					</map>
					<map key="about">
						<string key="@id">./</string>
					</map>
				</map>
				<!-- description of the root entity (the dataset) -->
				<map>
					<string key="@id">./</string>
					<!-- TODO strip out the proxy-metadata-* parameters from the 'identifier' URI --> 
					<string key="identifier">{@uri}</string>
					<string key="@type">Dataset</string>
					<xsl:apply-templates select="c:param-set[@xml:id='parameters']"/>
				</map>
			</array>
		</map>
	</xsl:template>

	<xsl:template match="c:param[@name='proxy-metadata-name']">
		<string key="name">{@value}</string>
	</xsl:template>
	
	<xsl:template match="c:param[@name='proxy-metadata-description']">
		<string key="description">{@value}</string>
	</xsl:template>
	
	<xsl:template match="c:param[@name='proxy-metadata-license-uri']">
		<map key="license">
			<string key="@id">{@value}</string>
		</map>
	</xsl:template>

	
</xsl:stylesheet>