<xsl:stylesheet version="3.0" expand-text="yes"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/2005/Atom"
	xmlns:c="http://www.w3.org/ns/xproc-step">

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
			<summary>
				<xsl:if test="string-length(snippet)&gt;0">
					<xsl:value-of select="snippet"/>
				</xsl:if>
				<xsl:if test="string-length(snippet)=0">
					<xsl:value-of select="substring(articleText,1,150)"/>
				</xsl:if>
			</summary>
			<category term="{//query}"/>
			<!--Add Tags as Category + keywords as category-->
			<category term="{category}"/>
			<xsl:for-each select="tag">
				<category term="{value}"/>
			</xsl:for-each>

			<!-- TODO whatever other Trove fields can be squeezed into Atom format -->
		</entry>
	</xsl:template>

	<xsl:template match="work">
		<entry>
			<title>{title}</title>
			<link rel="self" href="{@url}"/>
			<link rel="alternative" href="{troveUrl}"/>
			<id>{@url}</id>
			<updated>{
				(: the date of the last correction, or if that's missing, the publication date:)
				(lastCorrection/lastupdated, date)[1] 
		   	}</updated>
			<summary>{snippet}</summary>
			<category term="{//query}"/>
			<category term="{Type}"/>
			<xsl:for-each select="subject">
				<category term="{.}"/>
			</xsl:for-each>
			<xsl:for-each select="tag">
				<category term="{value}"/>
			</xsl:for-each>

			<!-- TODO whatever other Trove fields can be squeezed into Atom format -->
		</entry>
	</xsl:template>
	<xsl:template match="people">
		<entry>
			<title>{primaryName}</title>
			<link rel="self" href="{@url}"/>
			<link rel="alternative" href="{troveUrl}"/>
			<id>{@url}</id>
			<updated>{
				(: the date of the last update:)
				occupation
		   	}</updated>
			<xsl:copy-of select="."/>
			<summary>{snippet}</summary>
			<category term="{//query}"/>
			<category term="{type}"/>
			<xsl:for-each select="occupation">
				<category term="{.}"/>
			</xsl:for-each>
			<!-- TODO whatever other Trove fields can be squeezed into Atom format -->
		</entry>
	</xsl:template>

	<!-- TODO every other Trove record type -->

	<!-- catch-all template to ignore any kind of record not yet explicitly crosswalked -->
	<xsl:template match="response/category/records/*" priority="-999">
		<xsl:comment>ignoring {local-name()} with id {@id} and url {@url}</xsl:comment>
	</xsl:template>

</xsl:stylesheet>