<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="yes" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:eac="urn:isbn:1-931666-33-4"
	xmlns:srw="http://www.loc.gov/zing/srw/"
	>
	<xsl:key name="eac-cpf-by-people-id" 
		match="
			/trove-response-and-people-australia-response
				/c:response/c:body
					/srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData
						/eac:eac-cpf
		" 
		use="eac:control/eac:recordId"
	/>
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:template match="/trove-response-and-people-australia-response">
		<!-- copy the Trove response, merging eac-cpf records into each person -->
		<xsl:apply-templates select="response"/>
	</xsl:template>
	<xsl:template match="people[@id]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
			<!-- copy the eac-cpf record for this person -->
			<xsl:copy-of select="key('eac-cpf-by-people-id', @id)"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>