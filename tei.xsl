<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">
	<!-- HTTP -->
	<xsl:template match="c:response | c:body | c:header">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="@*">
		<xsl:copy/>
	</xsl:template>
	<!-- remove any payload headers from the response, because we'll have invalidated them by modifying and retransmitting the result -->
	<xsl:template match="c:header[lower-case(@name)=('content-length', 'content-range', 'trailer', 'transfer-encoding')]"/>
	
	<xsl:param name="proxy-base-uri"/>
	<xsl:param name="upstream-base-uri"/>
	
	<xsl:template name="rewrite-uri">
		<xsl:sequence select="
			concat(
				$proxy-base-uri,
				substring-after(., $upstream-base-uri)
			)
		"/>
	</xsl:template>
	
	<!-- TEI -->
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
				<xsl:for-each select="@next">
					<!-- The @next attribute in Trove's response is nominally a URL but it does not encode spaces -->
					<!-- reported as https://librariesaustraliaref.nla.gov.au/reft205.aspx?pmi=288697844889961888 -->
					<xsl:attribute name="next">
						<xsl:call-template name="rewrite-uri"/>
					</xsl:attribute>
				</xsl:for-each>
				<!-- TODO expand to cover all Trove's content, not just newspaper articles -->
				<xsl:apply-templates select="article"/>
			</teiCorpus>
		</xsl:where-populated>
	</xsl:template>
	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="article">
		<TEI n="{@id}">
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>{heading} [digital transcription]</title>
					</titleStmt>
					<publicationStmt>
						<p>
						<!-- Information about distribution of the resource -->
						</p>
					</publicationStmt>
					<sourceDesc>
						<p>
						<!-- Information about source from which the resource derives -->
						</p>
					</sourceDesc>
				</fileDesc>
			</teiHeader>
			<text>
				<body>
					<xsl:analyze-string select="articleText" regex="&lt;p&gt;(.*?)&lt;/p&gt;">
						<xsl:matching-substring>
							<xsl:element name="p">
								<xsl:analyze-string select="regex-group(1)" regex="&lt;span&gt;(.*?)&lt;/span&gt;">
									<xsl:matching-substring>
										<xsl:if test="position() != 1"><lb/></xsl:if>
										<xsl:value-of select="regex-group(1)"/>
									</xsl:matching-substring>
								</xsl:analyze-string>
							</xsl:element>
						</xsl:matching-substring>
					</xsl:analyze-string>
				</body>
			</text>
		</TEI>
	</xsl:template>

</xsl:stylesheet>