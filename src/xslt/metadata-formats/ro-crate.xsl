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
	
	<xsl:param name="trove-proxy-version"/>
	
	<xsl:variable name="trove-proxy-software-id" select="'https://github.com/Conal-Tuohy/TroveProxy'"/>
	
	<!-- select the URI query parameters which belong to the public URI for the resource which this RO-Crate metadata resource describes -->
	<!-- NB this excludes the 'key' parameter because it should not be published, and the proxy-metadata-format parameter,
	because that belongs to this metadata resource but not to the resource which the metadata describes (e.g. a CSV file) -->
	<xsl:variable name="proxy-parameters" select="
		/c:request
			/c:param-set[@xml:id='parameters']
				/c:param
					[not(@name=('key', 'proxy-metadata-format'))]
					[normalize-space(@value)]
	"/>
	
	<xsl:variable name="proxied-resource-uri" select="
		concat(
			/c:request/@href => substring-before('?'),
			'?', 
			string-join($proxy-parameters/concat(@name, '=', encode-for-uri(@value)), '&amp;')
		)
	"/>
	
	<xsl:variable name="proxy-format" select="
		/c:request/c:param-set[@xml:id='parameters']/c:param[@name='proxy-format']/@value[normalize-space()]
	"/>
	
	<xsl:variable name="content-type" select="
		if ($proxy-format) then 
			(: look up the content-type corresponding to the proxy-format parameter :)
			map{
				'csv': 'text/csv',
				'tei': 'application/xml',
				'atom': 'application/atom+xml'
			}($proxy-format)
		else
			'application/xml' (: No 'proxy-format' implies Trove's native XML :)
	"/>
	
	<xsl:variable name="conversion-description" select="
		if ($proxy-format) then 
			map{
				'csv': 'Converted Trove''s XML into Comma Separated Values format (text/csv)',
				'tei': 'Converted Trove''s XML into Text Encoding for Interchange P5 corpus XML format (application/xml)',
				'atom': 'Converted Trove''s XML into Atom Syndication Feed XML format (application/atom+xml)'
			}($proxy-format)
		else
			'Enhanced Trove''s XML with various fixes and enrichments (application/xml)' (: No 'proxy-format' implies Trove's native XML :)
	"/>
	<!-- the parameters of the query sent to trove don't include the 'proxy-*' parameters -->
	<xsl:variable name="trove-parameters" select="
		$proxy-parameters[not(starts-with(@name, 'proxy-'))]
	"/>
	
	<xsl:variable name="trove-resource-uri" select="
		concat(
			'https://api.trove.nla.gov.au',
			substring-after(
				/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value,
				'/proxy'
			),
			'?', 
			string-join($trove-parameters/concat(@name, '=', encode-for-uri(@value)), '&amp;')
		)
	"/>	
	
	<xsl:variable name="license-id" select="
		(
			$proxy-parameters[@name='proxy-metadata-license-uri']/@value,
			'#unspecified-license'
		)[1]
	"/>
		
	<xsl:template match="/">
		<!-- we transform the above XML into JSON-XML (see <https://www.w3.org/TR/xslt-30/#json-to-xml-mapping>)
		and serialize that as JSON inside a c:response/c:body which XProc-Z will return as a JSON-LD file -->
		<c:response status="200">
			<c:body content-type="application/ld+json">
				<xsl:variable name="json-xml">
					<xsl:apply-templates/>
				</xsl:variable>
				<xsl:sequence select="xml-to-json($json-xml, map{'indent':true()})"/>
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
				<!-- See https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#ro-crate-metadata-file-descriptor -->
				<map>
					<string key="@type">CreativeWork</string>
					<string key="@id">ro-crate-metadata.json</string>
					<map key="conformsTo">
						<string key="@id">https://w3id.org/ro/crate/1.1</string>
					</map>
					<map key="about">
						<string key="@id">./</string>
					</map>
				</map>
				<!-- description of the root entity (the dataset) -->
				<!-- See https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#direct-properties-of-the-root-data-entity -->
				<map>
					<!-- mandatory RO-Crate Dataset properties: -->
					<!-- see https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#direct-properties-of-the-root-data-entity -->
					
					<!-- @type: MUST be Dataset -->
					<string key="@type">Dataset</string>
					
					<!-- @id: MUST end with / and SHOULD be the string ./ -->
					<string key="@id">./</string>
					
					<!-- name: SHOULD identify the dataset to humans well enough to disambiguate it from other RO-Crates -->
					<string key="name">{
						(
							$proxy-parameters[@name='proxy-metadata-name']/@value, 
							'unnamed dataset'
						)[1]
					}</string>

					<!-- description: SHOULD further elaborate on the name to provide a summary of the context in which the dataset is important. -->
					<!-- TODO generate a detailed description from the query URI -->
					<string key="description">{
						(
							$proxy-parameters[@name='proxy-metadata-description']/@value, 
							'no description supplied'
						)[1]
					}</string>

					<!-- datePublished: MUST be a string in ISO 8601 date format and SHOULD be specified to at least the precision of a day, 
					MAY be a timestamp down to the millisecond. -->
					<string key="datePublished">{current-dateTime()}</string>
					
					<!--
						license: SHOULD link to a Contextual Entity in the RO-Crate Metadata File 
						with a name and description. MAY have a URI (eg for Creative Commons or 
						Open Source licenses). MAY, if necessary be a textual description of how 
						the RO-Crate may be used.
					-->
					<map key="license">
						<string key="@id">{$license-id}</string>
					</map>
					
					<!-- the actual proxied resource -->
					<array key="hasPart">
						<map>
							<string key='@id'>{$proxied-resource-uri}</string>
						</map>
					</array>
					
					<!-- optional properties of a Dataset -->
					<!-- strip out the proxy-metadata-format and key parameters from the 'identifier' URI --> 
					<!--
					<xsl:variable name="uri-without-query-component" select="substring-before(@href, '?')"/>
					<xsl:variable name="output-parameters" select="
						$proxy-parameters[not(@name = ('key', 'proxy-metadata-format'))]
					"/>
					<string key="identifier">{
						concat(
							$uri-without-query-component, 
							'?', 
							string-join($output-parameters/concat(@name, '=', encode-for-uri(@value)), '&amp;')
						)
					}</string>
					-->
				</map>
				<map>
					<string key="@id">{$license-id}</string>
					<xsl:if test="not($proxy-parameters[@name='proxy-metadata-license-uri'])">
						<string key="name">Unspecified license</string>
					</xsl:if>
				</map>
				
				<!-- description of TroveProxy -->
				<map>
					<string key="@id">{$trove-proxy-software-id}</string>
					<string key="@type">SoftwareApplication</string>
					<string key="url">{$trove-proxy-software-id}</string>
					<string key="name">TroveProxy</string>
					<string key="version">{$trove-proxy-version}</string>
					<string key="description">A transforming proxy for the National Library of Australia's Trove API</string>
				</map>
				
				<!-- description of the trove resource -->
				<map>
					<string key="@id">{$trove-resource-uri}</string>
					<string key='@type'>File</string>
					<string key="name">Trove API response</string>
					<string key='encodingFormat'>application/xml</string>
				</map>
				
				<!-- description of the proxied resource -->
				<xsl:variable name="encoding-format-uri" select="
					if ($proxy-format) then 
						map{
							'tei': 'https://www.nationalarchives.gov.uk/PRONOM/fmt/1477',
							'csv': 'https://www.nationalarchives.gov.uk/PRONOM/x-fmt/18',
							'atom': 'https://datatracker.ietf.org/doc/html/rfc4287'							
						}($proxy-format)
					else
						'https://github.com/Conal-Tuohy/TroveProxy/blob/main/doc/enriched-trove-xml.md'
				"/>

				<map>
					<string key='@id'>{$proxied-resource-uri}</string>
					<string key='@type'>File</string>
					<string key="name">Transformed Trove API response</string>
					<array key='encodingFormat'>
						<string>{$content-type}</string>
						<map>
							<string key="@id">{$encoding-format-uri}</string>
						</map>
					</array>
				</map>
				
				<!-- description of the encoding format -->
				<map>
					<string key="@id">{$encoding-format-uri}</string>
					<string key="@type">Website</string>
					<string key="name">{
						if ($proxy-format) then
							map{
								'tei': 'TEI P5 XML - Corpus File',
								'csv': 'Comma Separated Values',
								'atom': 'Atom Syndication Format'
							}($proxy-format)
						else
							'Enriched Trove XML'
					}</string>
				</map>
						
				<!-- provenance of the data -->
				<map>
					<string key="@id">#transformation</string>
					<string key="@type">CreateAction</string>
					<string key="name">Proxied and transformed</string>
					<string key="description">{$conversion-description})</string>
					<string key="endTime">{current-dateTime()}</string>
					<map key="instrument">
						<string key="@id">{$trove-proxy-software-id}</string>
					</map>
					<map key="object">
						<string key="@id">{$trove-resource-uri}</string>
					</map>
					<map key="result">
						<string key="@id">{$proxied-resource-uri}</string>
					</map>
				</map>				
			</array>
		</map>
	</xsl:template>
	
</xsl:stylesheet>