<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<!-- converts a Trove record which contains at least one people element into an HTTP request for more information about those people -->  
	<xsl:template match="/">
		<c:request method="get" href="{
			concat(
				'http://www.nla.gov.au/apps/srw/search/peopleaustralia?',
				'version=1.1&amp;',
				'operation=searchRetrieve&amp;',
				'recordSchema=urn%3Aisbn%3A1-931666-33-4&amp;',
				'maximumRecords=100&amp;',
				'query=',
				string-join(
					for $id in //people/@id return concat('oai.identifier+%253D+',$id),
					'+OR+'
				)
			)
		}">
			<!-- 
				Setting 'detailed' to 'true' means the response to our http-request will be a result document whose root element is c:response, containing
				• a c:header element for each HTTP response header, and 
				• a c:body element containing the Trove XML
			-->
			<xsl:attribute name="detailed">true</xsl:attribute>
			<c:header name="accept" value="application/xml"/>
		</c:request>
	</xsl:template>

</xsl:stylesheet>