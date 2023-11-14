<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
>
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- ensure there's exactly one 'access-control-allow-origin' header -->
	<!-- fix for Trove bug https://github.com/Conal-Tuohy/TroveProxy/issues/24 -->
	<xsl:template match="c:header
		[lower-case(@name) = 'access-control-allow-origin']
		[preceding-sibling::c:header[lower-case(@name) = 'access-control-allow-origin']]
	"/>
	
	<xsl:template match="category[@code]/records/@next[contains(., '?')]">
		<xsl:variable name="category-code" select="ancestor::category/@code"/>
		<xsl:variable name="base-uri" select="substring-before(., '?')"/>
		<xsl:variable name="query" select="
			.
			=> substring-after('?')
			(: Fix Trove API's failure to encode spaces in URIs :) 
			(: https://librariesaustraliaref.nla.gov.au/reft205.aspx?pmi=288697844889961888  :)
			=> translate(' ', '+')
		"/>
		<xsl:variable name="parameters" select="$query => tokenize('&amp;')"/>
		<!-- throw out any category parameters that don't match current category -->
		<xsl:variable name="refined-parameters" select="
			(
				$parameters[not(substring-before(., '=') = ('category', 'facet'))], (: ditch any categories and facets :)
				concat('category=', $category-code), (: add the current category back :)
				(: parse comma-separated lists in 'facet' parameters and create multiple 'facet' parameters with single values :)
				for $facet in 
					$parameters[substring-before(., '=') = 'facet'] 
				return 
					for $facet-value in 
						$facet => substring-after('=') => tokenize('%2C')
					return 
						concat('facet=', $facet-value) 
			)
		"/>
		<xsl:attribute name="next" select="
			concat($base-uri, '?', string-join($refined-parameters, '&amp;'))
		"/>
	</xsl:template>
	<!-- 
		Some troveUrl values have a spurious extra . at the start of the domain name.
		See https://github.com/GLAM-Workbench/trove-api-intro/issues/49#issuecomment-1709466290
	-->
	<xsl:template match="troveUrl/text()[starts-with(., 'https://.')]">
		<xsl:sequence select="concat('https://', substring-after(., 'https://.'))"/>
	</xsl:template>
	
	<!-- 
	Trove newspapers 'articleText' content contains what is apparently escaped HTML, but the
	escaping is only applied to the angle brackets used to tag p and span elements, and is not 
	used with ampersands or with other usage of angle brackets in the actual text content.
	Consequently it's not possible to just use the parse-xml-fragment function to parse it. 
	-->
	<xsl:template match="articleText/text()">
		<xsl:analyze-string select="." regex="&lt;p&gt;(.*?)&lt;/p&gt;">
			<xsl:matching-substring>
				<xsl:element name="p">
					<xsl:analyze-string select="regex-group(1)" regex="&lt;span&gt;(.*?)&lt;/span&gt;">
						<xsl:matching-substring>
							<xsl:element name="span">
								<xsl:value-of select="regex-group(1)"/>
							</xsl:element>
						</xsl:matching-substring>
					</xsl:analyze-string>
				</xsl:element>
			</xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	<!-- 
	Trove 'snippet' elements can contain what is apparently escaped HTML, but the
	escaping is only applied to the angle brackets used to tag b elements (which enclose
	words that match the user's query), and is not used with ampersands or with other 
	usage of angle brackets in the actual text content.
	Consequently it's not possible to just use the parse-xml-fragment function to parse it, 
	and instead we use a regular expression to parse the <b> elements.
	-->
	<xsl:template match="snippet/text()">
		<xsl:analyze-string select="." regex="&lt;b&gt;(.*?)&lt;/b&gt;">
			<xsl:matching-substring>
				<xsl:element name="b">
					<xsl:value-of select="regex-group(1)"/>
				</xsl:element>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="."/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>
</xsl:stylesheet>
