<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	expand-text="true"
>
	<xsl:param name="if-modified-since"/>
	<xsl:param name="name"/>

	<xsl:variable name="files" select="/c:directory/c:file"/>
	<xsl:variable name="ro-crate-metadata" select="$files[@name='ro-crate-metadata.json']"/>
	<xsl:variable name="status" select="$files[@name='status.xml']"/>
	<xsl:variable name="error" select="$files[@name='error.xml']"/>
	<xsl:variable name="zip" select="$files[ends-with(@name, '.zip')]"/>
	<xsl:variable name="data" select="$files except ($ro-crate-metadata | $error | $status | $zip)"/>
	<xsl:variable name="harvest" select="$status/harvest"/>
	<xsl:variable name="last-modified" select="
		format-dateTime(
			xs:dateTime($harvest/@last-updated),
			'[FNn,3-3], [D01] [MNn,3-3] [Y] [H01]:[m01]:[s01] GMT',
			'en', 
			(), 
			'GMT'
		)
	"/>
	<xsl:variable name="date-format" select=" '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [z,6-6]' "/>
		
	<xsl:template match="/c:directory">
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
								<xsl:if test="$harvest/* (: the harvest still contains child elements which represent tasks still to do :)">
									<meta http-equiv="refresh" content="5" />
								</xsl:if>
								<title>{@name}</title>
								<style xsl:expand-text="false">
									ul.files {
										display: flex;
										flex-wrap: wrap;
										padding-left: 0;
										column-gap: 1em;
										row-gap: 1em;
										align-items: start;
										justify-content: start;
									}
									ul.files li {
										display: block;
										padding: 0.5em;
									}
									body {
										font-family: sans-serif;
										box-sizing: border-box;
									}
									th {
										text-align: left;
									}
									div.status {
										background-color: #FCF7E8;
										padding: 1em;
										margin-bottom: 1em;
									}
									a.file {
										display: inline-block;
										background-color: #1F9EDE;
										color: #FFFFFF;
										padding: 0.5em 1em;
										border-radius: 0.5em;
										text-decoration: none;
									}
									a[href$=".zip"] {
										background-color: #00AB00;
									}
									a[href="status.xml"] {
										background-color: #55CC80;
									}
									a[href="error.xml"] {
										background-color: #FF0000;
									}
									a[href="ro-crate-metadata.json"] {
										background-color: #002EAD;
									}
								</style>
							</head>
							<body>
								<h1>{@name}</h1>
								<div class="status">
									<table>
										<tr><th>status</th><td>{$harvest/@status}</td></tr>
										<tr><th>requests</th><td>{$harvest/@requests-made}</td></tr>
										<tr><th>started</th><td data-date="{$harvest/@started}">{format-dateTime($harvest/@started, $date-format)}</td></tr>
										<tr><th>updated</th><td data-date="{$harvest/@last-updated}">{format-dateTime($harvest/@last-updated, $date-format)}</td></tr>
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
								</div>
								<h2>Files</h2>
								<!-- dataset package file, various metadata files -->
								<ul class="files">
									<xsl:for-each select="($zip, $error, $ro-crate-metadata, $status)">
										<li><a href="{@name}" class="file">{@name}</a></li>
									</xsl:for-each>
								</ul>
								<!-- individual dataset files -->
								<ul class="files">
									<xsl:for-each select="$data">
										<xsl:sort select="@name"/>
										<li><a href="{@name}" class="data file">{@name}</a></li>
									</xsl:for-each>
								</ul>
							</body>
						</html>
					</c:body>
				</c:response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="c:file">
		<li><a href="{@name}" class="data file">{@name}</a></li>
	</xsl:template>
	
	<xsl:template match="c:response">
		<h2>Error</h2>
		<p>{.}</p>
	</xsl:template>
	
</xsl:stylesheet>
