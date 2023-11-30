<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns="http://www.w3.org/1999/xhtml"
>
	<xsl:param name="example-harvest-url"/>
	<xsl:template match="/c:directory">
		<html>
			<head>
				<title>Harvests</title>
				<style type="text/css">
					body, input, select, button {
						font-family: sans-serif;
					}
					h1 {
						text-align: center;
					}
					form {
						display: grid;
						grid-template-columns: 8em 1fr;
						gap: 0.5em;
					}
					form label {
						text-align: right;
						font-size: 0.8em;
					}
				</style>
			</head>
			<body>
				<h1>Harvests</h1>
				<xsl:choose>
					<xsl:when test="c:directory">
						<xsl:for-each select="c:directory">
							<p><a href="{encode-for-uri(@name)}/"><xsl:value-of select="@name"/></a></p>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<p>There are no harvests.</p>
					</xsl:otherwise>
				</xsl:choose>
				<h2>Begin a new harvest</h2>
				<form method="POST" target="">
					<label for="name">Name</label>
					<input type="text" xml:id="name" name="name" placeholder="my harvest"/>
					<label for="url">URL</label>
					<input type="text" xml:id="url" name="url" placeholder="{$example-harvest-url}"/>
					<button type="submit">Begin harvest</button>
				</form>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
