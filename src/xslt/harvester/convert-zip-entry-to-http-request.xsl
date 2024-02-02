<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
>
	<xsl:template match="c:entry">
		<c:request href="{@href}" method="GET"/>
	</xsl:template>

</xsl:stylesheet>
