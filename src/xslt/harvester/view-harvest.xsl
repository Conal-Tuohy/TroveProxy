<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	expand-text="true"
>
	<xsl:param name="if-modified-since"/>
	<xsl:param name="name"/>
	
	<xsl:template match="/c:directory">
		<xsl:variable name="last-modified" select="
			format-dateTime(
				xs:dateTime(harvest/@last-updated),
				'[FNn,3-3], [D01] [MNn,3-3] [Y] [H01]:[m01]:[s01] GMT',
				'en', 
				(), 
				'GMT'
			)
		"/>
		<xsl:choose>
			<xsl:when test="$last-modified = $if-modified-since">
				<c:response status="304"><!-- not modified -->
					<c:header name="Access-Control-Allow-Origin" value="*"/>
				</c:response>
			</xsl:when>
			<xsl:otherwise>
				<c:response status="200">
					<c:header name="Access-Control-Allow-Origin" value="*"/>
					<c:header name="Last-Modified" value="{$last-modified}"/>
					<c:body content-type="application/xhtml+xml">
						<html>
							<head>
								<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
								<xsl:if test="not(harvest/@status=('completed', 'aborted'))">
									<meta http-equiv="refresh" content="10" />
								</xsl:if>
								<title>{@name}</title>
								<style xsl:expand-text="false">
									ul.files {
										column-width: 10em;
										/*column-rule: 1px solid rgb(75, 70, 74);*/
									}
									body {
										font-family: sans-serif;
									}
									th {
										text-align: left;
									}
									div.status {
										background-color: #FCF7E8;
										padding: 1em;
									}
								</style>
							</head>
							<body>
								<h1>{@name}</h1>
								<xsl:apply-templates select="harvest"/>
								<xsl:variable name="metadata" select="c:file[@name='ro-crate-metadata.json']"/>
								<xsl:apply-templates select="$metadata"/>
								<xsl:variable name="error" select="c:file[@name='error.xml']"/>
								<xsl:apply-templates select="$error"/>
								<h2>Data files</h2>
								<ul class="files">
									<xsl:for-each select="c:file except ($metadata | $error)">
										<xsl:sort select="@name"/>
										<li><a href="{@name}">{@name}</a></li>
									</xsl:for-each>
								</ul>
							</body>
						</html>
					</c:body>
				</c:response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="c:file[@name='ro-crate-metadata.json']">
		<h2>RO-Crate metadata</h2>
		<p><a href="{@name}">{@name}</a></p>
	</xsl:template>
	
	<xsl:template match="c:file[@name='error.xml']">
		<h2>Harvest error</h2>
		<p><a href="{@name}">{@name}</a></p>
	</xsl:template>
	
	<xsl:template match="c:response">
		<h2>Error</h2>
		<p>{.}</p>
	</xsl:template>
	
	<xsl:template match="harvest">
		<xsl:variable name="date-format" select=" '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [z,6-6]' "/>
		<div class="status">
			<h2>Harvest status</h2>
			<table>
				<tr><th>status</th><td>{@status}</td></tr>
				<tr><th>requests</th><td>{@requests}</td></tr>
				<tr><th>started</th><td data-date="{@started}">{format-dateTime(@started, $date-format)}</td></tr>
				<tr><th>updated</th><td data-date="{@last-updated}">{format-dateTime(@last-updated, $date-format)}</td></tr>
			</table>
			<!-- display dates in browser's local time zone -->
			<script xsl:expand-text="false">
			const dateFormat = new Intl.DateTimeFormat(
				[], 
				{
					year: 'numeric', 
					month: 'numeric', 
					day: 'numeric',
					hour: 'numeric', 
					minute: 'numeric', 
					second: 'numeric',
					hour12: true,
					timeZoneName: 'long'
				}
			);
			document
				.querySelectorAll("*[data-date]")
				.forEach(
					function(dateContainer) {
						dateContainer.innerText = dateFormat.format(new Date(dateContainer.dataset.date));
					}
				);
			</script>
			<p class="table-footnote"><a href="status.xml">view status as xml</a></p>
		</div>
	</xsl:template>
	
</xsl:stylesheet>
