<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
	<xsl:mode on-no-match="shallow-copy"/>
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
				$parameters[substring-before(., '=') != 'category'], (: ditch any categories :)
				concat('category=', $category-code) (: add the current category back :)
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
</xsl:stylesheet>
