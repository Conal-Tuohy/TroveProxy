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
					<th>troveUrl</th>
					<th>title</th>
					<th>creator</th>
					<th>date</th>
					<th>publisher</th>
					<th>category</th>
					<th>partOf</th>
					<th>page</th>
					<th>snippet</th>
					<th>type</th>
					<th>subject</th>
					<th>format</th>
					<th>extent</th>
					<th>abstract</th>
					<th>text</th>
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
			<td>{troveUrl}</td>
			<td>{
				(heading, title, primaryName)[1] 
			}</td><!-- one way to deal with the different records schemas: just pick the first of whatever field in each schema best matches the output col -->
			<td>{contributor => string-join("|")}</td>
			<td>{
				(date,issued, descendant::*[local-name()="existDates"][not(ancestor::*[local-name()="alternativeSet"])]//@standardDate => string-join("/"))[1]
			}</td>
			<td>{descendant::publisher => string-join("|")}</td>
			<td>{
				(category,descendant::type[@type="category"]/value => string-join("|"))[1]
				}</td>
			<td>{
				(title/title, isPartOf/value =>string-join("|"))[1]
			}</td>
			<td>{
				(page,descendant::bibliographicCitation[@type="pagination"]/value => string-join("|"))[1]
				}</td>
			<td>{snippet}</td>
			<td>{type => string-join("|")}</td>			<!-- is that the best way to deal with multi-valued fields in CSV? -->
			<td>{
				(descendant::subject => string-join("|"), occupation => string-join("|"))[1]
				}</td>
			<td>{descendant::format => string-join("|")}</td>
			<td>{
				(descendant::extent => string-join("|"), wordCount)[1]
			}</td>
			<td>{
				(abstract, descendant::*[local-name()="abstract"])[1]
				}</td>
			<td>{
				(articleText,descendant::description[@type="open_fulltext"]/value)[1]
				}</td>

			<!-- TODO all the rest -->
		</tr>
	</xsl:template>


</xsl:stylesheet>