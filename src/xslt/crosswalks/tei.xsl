<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes">

	<xsl:template match="response">
		<teiCorpus n="{query}">
			<xsl:apply-templates/>
		</teiCorpus>
	</xsl:template>
	<xsl:template match="response/query"/>
	<xsl:template match="response/category/records">
		<xsl:where-populated>
			<teiCorpus>
				<xsl:attribute name="type" select="ancestor::category/@code"/>
				<!-- the corpus may continue on another page of Trove API results -->
				<xsl:copy-of select="@next"/>
				<!-- TODO expand to cover all Trove's content, not just newspaper articles -->
				<xsl:apply-templates select="article"/>
			</teiCorpus>
		</xsl:where-populated>
	</xsl:template>
	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>
	<!-- convert newspaper articles-->
	<xsl:template match="article">
		<TEI n="{@id}">
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>{heading} [digital transcription]</title>
					</titleStmt>
					<publicationStmt>
						<publisher>National Library of Australia</publisher>
						<pubPlace>Canberra, ACT</pubPlace>
						<extent>{wordCount}</extent>
						<availability>
							<p>Available from Trove Australia</p>
						</availability>
						<ptr target="{identifier}"/>
					</publicationStmt>
					<sourceDesc>
						<bibl>
							<title level="j">{title/title}</title>
						</bibl>
						<date>{date}</date>
						<ptr target="https://nla.gov.au/nla.news-title{title/@id}"/>
					</sourceDesc>
				</fileDesc>
			</teiHeader>
			<text>
				<body>
					<xsl:apply-templates select="articleText"/>
				</body>
			</text>
		</TEI>
	</xsl:template>

	<xsl:template match="work">

	</xsl:template>

	<!-- convert the unnamespaced Trove p element into a TEI p -->
	<xsl:template match="p">
		<p>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	<!-- Trove's span elements represent typographical lines; insert a TEI lb between adjacent lines -->
	<xsl:template match="span">
		<xsl:if test="position() != 1">
			<lb/>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

</xsl:stylesheet>