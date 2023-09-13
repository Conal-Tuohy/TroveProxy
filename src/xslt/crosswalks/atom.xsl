<xsl:stylesheet version="3.0" expand-text="yes" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns="http://www.w3.org/2005/Atom" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
>

	<!-- transform Trove's XML into Atom Syndication Format -->
	<!-- Atom: https://www.rfc-editor.org/rfc/rfc4287 -->
	
	<!-- the canonical URI of the request which if made to the proxy would generate this document; i.e. "self" -->
	<xsl:param name="request-uri"/>

	<xsl:template match="response/query"/>

	<xsl:template match="response">
		<feed>
			<title>{query}</title>
			<link rel="self" href="{$request-uri}"/>
			<updated>{current-dateTime()}</updated>
			<id>{$request-uri}</id>
			<xsl:apply-templates/>
		</feed>
	</xsl:template>
	
	<!-- newspaper articles -->
	<xsl:template match="article">
		<entry>
			<title>{heading}</title>
			<link rel="self" href="{@url}"/>
			<link rel="alternative" href="{troveUrl}"/>
			<id>{@url}</id>
			<updated>{
				(: the date of the last correction, or if that's missing, the publication date:)
				(lastCorrection/lastupdated, date)[1] 
		   	}</updated>
			<summary>{string-join(snippet, ' ')}</summary>
			<!-- TODO whatever other Trove fields can be squeezed into Atom format --> 
		</entry>
	</xsl:template>
	
	<!-- TODO every other Trove record type -->
	
	<!-- catch-all template to ignore any kind of record not yet explicitly crosswalked -->
	<xsl:template match="response/category/records/*" priority="-999">
		<xsl:comment>ignoring {local-name()} with id {@id} and url {@url}</xsl:comment>
	</xsl:template>

</xsl:stylesheet>