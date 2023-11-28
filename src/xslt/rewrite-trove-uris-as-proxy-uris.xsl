<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">

	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:param name="request-uri"/>
	<xsl:param name="proxy-base-uri"/>
	<xsl:param name="upstream-base-uri"/>
	<xsl:param name="proxy-parameter-string"/>
	
	<!-- TODO comment and tidy up -->
	<xsl:template name="rewrite-uri">
		<xsl:variable name="query-component" select="replace(., '^.*(\?.*)$', '$1')"/>
		<xsl:variable name="uri-before-query-component" select="substring-before(., $query-component)"/>
		<xsl:variable name="parameters" select="$query-component => substring-after('?') => tokenize('&amp;')"/>
		<xsl:variable name="proxy-parameters" select="$proxy-parameter-string => tokenize('&amp;')"/>
		<xsl:variable name="proxy-max-requests-parameter" select="$proxy-parameters[starts-with(., 'proxy-max-requests=')]"/>
		<xsl:variable name="max-requests" select="
			if ($proxy-max-requests-parameter) then
				let 
					$proxy-max-requests-value:= substring-after($proxy-max-requests-parameter, '=')
				return
					if ($proxy-max-requests-value = '') then 
						'1' (: parameter value missing; effective value = 1 :)
					else
						$proxy-max-requests-value
			else (: parameter missing; effective value = 1 :)
				'1' 
		"/>
		<xsl:message expand-text="true">parameters: {$parameters}, parameter: {$proxy-max-requests-parameter}, effective value: {$max-requests}</xsl:message>

		<!-- output a URL unless this is a "next" url and max-requests has already fallen to 1 -->
		<xsl:if test="not(local-name() = 'next' and $max-requests = '1')">
			<xsl:sequence select="
				string-join(
					(
						concat(
							$proxy-base-uri,
							substring-after(., $upstream-base-uri)
						),
						(: copy all the proxy parameters such as proxy-format back onto the URI :)
						(: but discarding parameters with null values, and specifically excluding the 
						proxy-max-requests parameter which will be appended with a decremented value :)
						$proxy-parameters[normalize-space()][not(starts-with(., 'proxy-max-requests='))],
						(: append add the proxy-max-requests parameter, decremented by one, but only if 
						the parameter exists and has not reached 0, and only for @next URLs, not @url, 
						because the @url attributes point to leaf resources without further @next links :)
						if (local-name(.) = 'url') then 
							() (: omit the @next parameter altogether :) 
						else 
							concat('proxy-max-requests=', number($max-requests) - 1)
					),
					if (contains(., '?')) then '&amp;' else '?'
				)
			"/>
		</xsl:if>
	</xsl:template>
	
	<!-- remove any "canonical" link because we will be adding a new one pointing to the proxied URL -->
	<xsl:template match="c:response/c:header[ends-with(@name, '; rel=&quot;canonical&quot;')]"/>
	<!-- add a "canonical" link pointing to the current (proxied) resource -->
	<xsl:template match="c:response">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- TODO actually canonicalise this URI, removing any API key parameter from it, sorting the params in alpha order, etc -->
			<c:header name="Link" value="&lt;{$request-uri}&gt;; rel=canonical"/>
			<!-- add link to metadata -->
			<c:header name="Link" value="&lt;{
				string-join(
					($request-uri, 'proxy-metadata-format=ro-crate'), 
					if (contains($request-uri, '?')) then
						'&amp;'
					else
						'?'
				)
			}&gt;; rel=describedby"/>
			<xsl:variable name="next-links" select="//*/@next"/>
			<xsl:for-each select="$next-links">
				<xsl:variable name="url">
					<xsl:call-template name="rewrite-uri"/>
				</xsl:variable>
				<xsl:if test="normalize-space($url)">
					<xsl:choose>
						<xsl:when test="count($next-links) = 1">
							<c:header name="Link" value="&lt;{$url}&gt;; rel=next"/>
						</xsl:when>
						<xsl:otherwise>
							<c:header name="Link" value="&lt;{$url}&gt;; rel=section"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@next | @url">
		<xsl:variable name="url">
			<xsl:call-template name="rewrite-uri"/>
		</xsl:variable>
		<xsl:if test="normalize-space($url)">
			<xsl:attribute name="{local-name()}" select="$url"/>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>