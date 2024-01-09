<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes">
	
	<xsl:variable name="request-parameters" select="/response/c:request/c:param-set[@xml:id='parameters']/c:param"/>
 
	<!-- the parameters of the query sent to trove don't include the 'proxy-*' parameters -->
	<xsl:variable name="trove-parameters" select="
		$request-parameters[not(starts-with(@name, 'proxy-'))][not(@name='key')]
	"/>
	
	<xsl:variable name="trove-resource-uri" select="
		concat(
			'https://api.trove.nla.gov.au',
			substring-after(
				/response/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value,
				'/proxy'
			),
			'?', 
			string-join($trove-parameters/concat(@name, '=', encode-for-uri(@value)), '&amp;')
		)
	"/>
	
	<xsl:variable name="corpus-title" select="($request-parameters[@name='proxy-metadata-name']/@value[normalize-space()], 'Untitled corpus')[1]"/>
	
	<xsl:template match="response">
		<teiCorpus n="{query}">
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>{$corpus-title}</title>
					</titleStmt>
					<publicationStmt>
						<p>Published by converting the results of a Trove API query into TEI XML.</p>
					</publicationStmt>
					<sourceDesc>
						<xsl:for-each select="$request-parameters[@name='proxy-metadata-description']/@value[normalize-space()]">
							<p>{.}</p>
						</xsl:for-each>
						<p>Derived from the results of the Trove API query <ref target="{$trove-resource-uri}">{/response/query}</ref></p>
					</sourceDesc>
				</fileDesc>
			</teiHeader>
			<xsl:apply-templates/>
		</teiCorpus>
	</xsl:template>
	<xsl:template match="response/query"/>
	<xsl:template match="response/category/records">
		<xsl:where-populated>
			<teiCorpus xml:id="{ancestor::category/@code}">
				<xsl:attribute name="type" select="ancestor::category/@code"/>
				<!-- the corpus may continue on another page of Trove API results -->
				<xsl:for-each select="@next">
					<xsl:attribute name="next" select="concat(., '#', ancestor::category/@code)"/>
				</xsl:for-each>
				<teiHeader>
					<fileDesc>
						<titleStmt>
							<title>{$corpus-title}</title>
							<title>({ancestor::category/@name})</title>
						</titleStmt>
					<publicationStmt>
						<p>Published by converting the results of a Trove API query into TEI XML.</p>
					</publicationStmt>
					<sourceDesc>
						<xsl:for-each select="request-parameters[@name='proxy-metadata-name'][normalize-space(@value)]">
							<p>{@value}</p>
						</xsl:for-each>
						<p>Derived from the <title>{ancestor::category/@name}</title> category contained within the results of the Trove API query <ref target="{$trove-resource-uri}">{/response/query}</ref></p>
					</sourceDesc>
					</fileDesc>
				</teiHeader>
				<xsl:apply-templates/>
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
						<xsl:for-each select="wordCount">
							<extent>{.} words</extent>
						</xsl:for-each>
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

	<xsl:template match="work[not(child::version)]"/>
	<xsl:template match="work[child::version]">
		<xsl:apply-templates select="version"/>
	</xsl:template>
	<xsl:template match="version">
		<TEI n="{@id}">
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>{record/metadata/dc/title}</title>
					</titleStmt>
					<publicationStmt>
						<publisher>{descendant::publisher}</publisher>
						<pubPlace>{substring-before(record[1]/metadata/dc/publisher, " : ")}</pubPlace>
						<date>{(descendant::issued/value,descendant::date/value,descendant::bibliographicCitation[@type='dateIssued']/value)[1]}</date>
						<availability>
							<p></p>
						</availability>
						<ptr target="{(identifier[@linktype='fulltext']/value, ancestor-or-self::work/troveUrl)[1]}"/>
					</publicationStmt>

				</fileDesc>
			</teiHeader>
			<xsl:if test="descendant::description[@type='open_fulltext'][1]">
				<text>
					<body>
						{descendant::description[@type='open_fulltext'][1]}
					</body>
				</text>
			</xsl:if>
		</TEI>
	</xsl:template>

	<xsl:template match="people">

		<TEI n="{@id}">
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>{primaryName}</title>
					</titleStmt>
					<!--<publicationStmt>
						<publisher>{substring-after(record[1]/metadata/dc/publisher, " : ")}</publisher>
						<pubPlace>{substring-before(record[1]/metadata/dc/publisher, " : ")}</pubPlace>
						<date>{record[1]/metadata/dc/issued/value||record[1]/metadata/dc/date/value}</date>
						<availability>
							<p></p>
						</availability>
						<ptr target="{identifier}"/>
					</publicationStmt>-->

				</fileDesc>
			</teiHeader>
			<!--<xsl:if test="record[1]/metadata/dc/description[@type='open_fulltext']">
				<text>
					<body>
						<xsl:apply-templates select="record[1]/metadata/dc/description[@type='open_fulltext']"/>
					</body>
				</text>
			</xsl:if>-->
			<xsl:copy-of select="."/>
		</TEI>
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