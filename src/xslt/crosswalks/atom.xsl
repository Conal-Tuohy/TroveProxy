<xsl:stylesheet version="3.0" expand-text="yes"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/2005/Atom"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	exclude-result-prefixes="#all">

	<!-- transform Trove's XML into Atom Syndication Format -->
	<!-- Atom: https://www.rfc-editor.org/rfc/rfc4287 -->

	<!-- the canonical URI of the request which if made to the proxy would generate this document; i.e. "self" -->
	<xsl:param name="request-uri"/>

	<xsl:template match="response/query"/>

	<xsl:template match="response">
		<feed>
			<title>{query}</title>
			<link rel="self" href="{$request-uri}"/>
			<xsl:for-each select="category/records/@next">
				<link rel="next" href="{$request-uri}"/>
			</xsl:for-each>
			<updated>{current-dateTime()}</updated>
			<id>{$request-uri}</id>
			<xsl:apply-templates/>
		</feed>
	</xsl:template>

	<!-- newspaper articles -->
	<xsl:template match="article">
		<entry>
			<title>{heading, 'from', concat(title/title,'; ',date)}</title>
			<link rel="self" href="{@url}"/>
			<link rel="alternate" href="{troveUrl}"/>
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
			<!-- render article text -->
			<!-- if no articleText then link to the trove resource, 
			because a content element is mandatory -->
			<xsl:choose>
				<xsl:when test="articleText">
					<content type="html">
						<xsl:variable name="html">
							<xsl:apply-templates select="articleText"/>
						</xsl:variable>
						<xsl:sequence select="
							serialize(
								$html, 
								map{
									'method': 'html', 
									'html-version': 5
								}
							)
						"/>
					</content>
				</xsl:when>
				<xsl:otherwise>
					<content src="{troveUrl}"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="//query">
				<category term="{'query:',//query}"/>
			</xsl:if>
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
			<link rel="alternate" href="{troveUrl}"/>
			<id>{@url}</id>
			<updated>{
				(: the date of the last correction, or if that's missing, the publication date:)
				(lastCorrection/lastupdated, date, issued/value)[1] 
		   	}</updated>
			<summary>{
				(abstract, descendant::description[not(./@type='open_fulltext')])[1]
				}</summary>
				<content src="{@url}"/>
			<xsl:if test="//query">
				<category term="{'query:',//query}"/>
			</xsl:if>
			<category term="{type}"/>
			<xsl:for-each select=".//type[@type='category']">
				<category term="{value}"/>
			</xsl:for-each>
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
		<!-- EAC elements are referenced using the local-name() functon because the EAC
		documents sourced from People Australia data may or may not use a namespace,--> 
		<entry>
			<title>{primaryName}</title>
			<link rel="self" href="{@url}"/>
			<link rel="alternate" href="{troveUrl}"/>
			<id>{@url}</id>
			<updated>{
				(: the date of the last update:) (descendant::*[local-name()="maintenanceEvent"][last()]//@standardDateTime,current-dateTime())[1]
		   	}</updated>
			<!--<xsl:copy-of select="."/>-->
			<summary>{descendant::*[local-name()="abstract"]}</summary>
			<content src="{@url}"/>
			<xsl:if test="//query">
				<category term="{'query:',//query}"/>
			</xsl:if>
			<category term="{type}"/>
			<xsl:for-each select="occupation">
				<category term="{.}"/>
			</xsl:for-each>
			<!-- TODO whatever other Trove fields can be squeezed into Atom format -->
		</entry>
	</xsl:template>

	<!-- copy the Trove p element to create an HTML p element -->
	<xsl:template match="p">
		<xsl:copy copy-namespaces="no"><xsl:apply-templates/></xsl:copy>
		<xsl:sequence select="codepoints-to-string(10)"/>
	</xsl:template>
	<!-- Trove's span elements represent typographical lines; insert an HTML br between adjacent lines -->
	<xsl:template match="span[preceding-sibling::span]">
		<xsl:element name="br" xmlns=""/>
		<xsl:sequence select="codepoints-to-string(10)"/>
		<xsl:apply-templates/>
	</xsl:template>
	<!-- TODO every other Trove record type -->

	<!-- catch-all template to ignore any kind of record not yet explicitly crosswalked -->
	<xsl:template match="response/category/records/*" priority="-999">
		<xsl:comment>ignoring {local-name()} with id {@id} and url {@url}</xsl:comment>
	</xsl:template>

</xsl:stylesheet>
