<xsl:stylesheet version="3.0" expand-text="yes"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:c="http://www.w3.org/ns/xproc-step">

	<!-- transform Trove's XML into an HTML table to be returned to the client as CSV -->
	<xsl:template match="response/query"/>

	<xsl:template match="/">
		<table>
			<thead>
				<tr>
					<th>url</th>
					<th>title</th>
					<th>type</th>
					<!-- TODO all the rest -->
				</tr>
			</thead>
			<tbody>
				<xsl:apply-templates/>
			</tbody>
		</table>
	</xsl:template>

	<!-- each record produces a table row -->
	<xsl:template match="article | work | people">
		<tr>
			<td>{@url}</td>
			<td>{
				(title, primaryName)[1] 
			}</td><!-- one way to deal with the different records schemas: just pick the first of whatever field in each schema best matches the output col -->
			<td>{type => string-join("|")}</td><!-- is that the best way to deal with multi-valued fields in CSV? -->
			<!-- TODO all the rest -->
		</tr>
	</xsl:template>

</xsl:stylesheet>