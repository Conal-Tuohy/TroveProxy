<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:json="http://www.w3.org/2005/xpath-functions"
	expand-text="true"
>
	<xsl:param name="filename"/>
	<xsl:param name="content-type"/>
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:template match="c:body">
		<xsl:copy>
			<xsl:variable name="json-xml" select="json-to-xml(.)"/>
			<xsl:variable name="output">
				<xsl:apply-templates select="$json-xml"/>
			</xsl:variable>
			<xsl:sequence select="xml-to-json($output, map{'indent': true()})"/> 
		</xsl:copy>
	</xsl:template>
	<xsl:template match="json:map
		[json:string[@key='@id'] = './']
		[json:string[@key='@type'] = 'Dataset']
	">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="* except json:array[@key='hasPart']"/>
			<json:array key="hasPart">
				<xsl:copy-of select="json:array[@key='hasPart']/*"/>
				<json:map>
					<json:string key='@id'>{$filename}</json:string>
					<json:string key='@type'>File</json:string>
					<json:string key='encodingFormat'>{$content-type}</json:string>
				</json:map>
			</json:array>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>