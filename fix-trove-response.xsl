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
			$parameters[substring-before(., '=') != 'category' or substring-after(., '=') = $category-code] 
		"/>
		<xsl:attribute name="next" select="
			concat($base-uri, '?', string-join($refined-parameters, '&amp;'))
		"/>
	</xsl:template>
</xsl:stylesheet>
