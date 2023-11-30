<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns="http://www.w3.org/1999/xhtml"
	expand-text="true"
>
	<xsl:param name="harvests-uri"/>
	<xsl:param name="name"/>
	<xsl:template match="/c:directory">
		<html>
			<head>
				<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
				<title>{@name}</title>
				<style xsl:expand-text="false">
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
				<h2>Data files</h2>
				<ul class="files">
					<xsl:for-each select="c:file">
						<xsl:sort select="@name"/>
						<li><a href="{@name}">{@name}</a></li>
					</xsl:for-each>
				</ul>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="harvest">
		<xsl:variable name="date-format" select=" '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [z,6-6]' "/>
		<div class="status">
			<h2>Harvest status</h2>
			<table>
				<tr><th>status</th><td>{@status}</td></tr>
				<tr><th>requests</th><td>{@requests}</td></tr>
				<tr><th>started</th><td>{format-dateTime(@started, $date-format)}</td></tr>
				<tr><th>updated</th><td>{format-dateTime(@last-updated, $date-format)}</td></tr>
			</table>
			<p class="table-footnote"><a href="status.xml">Download status file</a></p>
		</div>
	</xsl:template>
	
</xsl:stylesheet>
