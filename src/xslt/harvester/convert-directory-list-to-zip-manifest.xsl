<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
>
	<xsl:template match="c:directory">
		<c:zip-manifest>
			<xsl:variable name="base-uri" select="base-uri(.)"/>
			<xsl:for-each select="//c:file">
				<xsl:variable name="file-path" select="string-join((ancestor-or-self::*[parent::*])/@name, '/')"/>
				<c:entry href="{resolve-uri($file-path, $base-uri)}" name="{$file-path}"/>
			</xsl:for-each>
		</c:zip-manifest>
	</xsl:template>

</xsl:stylesheet>
