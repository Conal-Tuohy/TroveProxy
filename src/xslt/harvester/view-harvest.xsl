<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	expand-text="true"
>
	<xsl:param name="if-modified-since"/>
	<xsl:param name="name"/>
	<xsl:param name="request-uri"/>

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
	
	<xsl:template match="/c:errors">
		<c:response status="404"><!-- not found -->
			<c:header name="Access-Control-Allow-Origin" value="*"/>
			<c:body content-type="text/plain">Dataset not found</c:body>
		</c:response>
	</xsl:template>
		
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
									h2 {
										margin-top: 1.5em;
										font-weight: normal;
										font-size: large;
									}
									ul.files {
										display: flex;
										flex-wrap: wrap;
										padding-left: 0;
										column-gap: 1em;
										row-gap: 1em;
										align-items: start;
										justify-content: start;
									}
									details {
										display: block;
									}
									details summary {
										display: block;
										list-style: none;
									}
									details summary span {
										background-color: #FFFF00;
										color: #000000;
										margin: 0.5em;
										font-size: 1em;
										display: inline-block;
										padding: 0.5em 1em;
										border-radius: 0.5em;
										text-decoration: none;
										border-width: 0;
										font-weight: bold;
										cursor: pointer;
									}
									details summary span.hide {
										display: none;
									}
									details[open] summary span.hide {
										display: inline;
									}
									details[open] summary span.show {
										display: none;
									}
									details textarea {
										margin: 0.5em;
										height: 
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
									button {
										margin: 0.5em;
										font-size: 1em;
										display: inline-block;
										padding: 0.5em 1em;
										border-radius: 0.5em;
										text-decoration: none;
										border-width: 0;
										font-weight: bold;
									}
									button#delete {
										background-color: #FF0000;
										color: #FFFFFF;
										cursor: pointer;
									}
									a.file {
										font-weight: bold;
										font-size: 1em;
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
									<xsl:if test="not($harvest/*) (: the harvest is finished as it contains no child elements which represent tasks still to do :)">
										<button id="delete">Delete dataset</button>
										<script xsl:expand-text="false">
											var deleteButton = document.getElementById("delete");
											deleteButton.addEventListener(
												"click", 
												function(event) {
													if (confirm("Are you sure you want to delete the harvested dataset?")) {
														fetch(
															document.location,
															{
																method: "DELETE", 
																mode: "cors", // no-cors, *cors, same-origin
																cache: "no-cache", // *default, no-cache, reload, force-cache, only-if-cached
																credentials: "same-origin", // include, *same-origin, omit
																/*headers: {
																	'Content-Type': 'application/x-www-form-urlencoded',
																},*/
																redirect: "follow", // manual, *follow, error
																referrerPolicy: "no-referrer", // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
																//body: urlSearchParams
															}
														).then(
															function(response) {
																window.location.href= response.url;
															}
														);
													}
												}
											);
										</script>
									</xsl:if>
								</div>
								<!-- dataset package file -->
								<xsl:for-each select="$zip">
									<h2>ro-crate package of entire dataset</h2>
									<p><a href="{@name}" class="file">{@name}</a></p>
								</xsl:for-each>
								<!-- various metadata files -->
								<h2>metadata files</h2>
								<ul class="files">
									<xsl:for-each select="($error, $ro-crate-metadata, $status)">
										<li><a href="{@name}" class="file">{@name}</a></li>
									</xsl:for-each>
								</ul>
								<xsl:if test="$data">
									<h2>harvested data files</h2>
									<details>
										<summary><span class="show">Show dataset URLs</span><span class="hide">Hide dataset URLs</span> </summary>
										<div>
											<xsl:variable name="rows" select="count($data)"/>
											<xsl:variable name="cols" select="string-length($request-uri) + max($data/@name/string-length())"/>
											<textarea id="urls" rows="{$rows}" cols="{$cols}" style="width: {$cols}em; height: {1 + $rows}em;"><xsl:for-each select="$data">
												<xsl:sort select="@name"/>
												<xsl:if test="position() != 1"><xsl:value-of select="codepoints-to-string(10)"/></xsl:if>
												<xsl:value-of select="$request-uri || @name"/>
											</xsl:for-each></textarea>
											<script>
												document.getElementById("urls").select();
											</script>
										</div>
									</details>
									<!-- individual dataset files -->
									<ul class="files">
										<xsl:for-each select="$data">
											<xsl:sort select="@name"/>
											<li><a href="{@name}" class="data file">{@name}</a></li>
										</xsl:for-each>
									</ul>
								</xsl:if>
							</body>
						</html>
					</c:body>
				</c:response>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="c:response">
		<h2>Error</h2>
		<p>{.}</p>
	</xsl:template>
	
</xsl:stylesheet>
