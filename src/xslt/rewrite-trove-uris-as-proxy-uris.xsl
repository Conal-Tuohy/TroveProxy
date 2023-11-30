<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"  xmlns="http://www.tei-c.org/ns/1.0" expand-text="yes" xmlns:c="http://www.w3.org/ns/xproc-step">

	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:param name="request-uri"/>
	<xsl:param name="proxy-base-uri"/>
	<xsl:param name="upstream-base-uri"/>
	<xsl:param name="key"/>
	<!-- this is the request URI received by the proxy, with any parameters stripped off -->
	<xsl:variable name="request-base-uri" select="if (contains($request-uri, '?')) then substring-before($request-uri, '?') else $request-uri"/>
	<!-- these are all the parameters of the request URI -->
	<xsl:variable name="request-parameters" select="substring-after($request-uri, '?') => tokenize('&amp;')"/>
	<!-- the request parameters which belong to the proxy rather than to Trove -->
	<xsl:variable name="proxy-parameters" select="$request-parameters[starts-with(., 'proxy-')]"/>
	<!-- the request parameters which belong to Trove rather than proxy-specific parameters -->
	<!--<xsl:variable name="trove-parameters" select="$request-parameters[not(starts-with(., 'proxy-'))]"/>--> 
	<xsl:variable name="proxy-max-requests-parameter" select="$proxy-parameters[starts-with(., 'proxy-max-requests=')]"/>
	<xsl:variable name="proxy-max-requests" select="
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
	
	<!-- TODO comment and tidy up -->
	<xsl:template name="rewrite-uri">
		<xsl:param name="key" select="()"/>
		<xsl:param name="proxy-metadata-format" select="()"/>
		<xsl:param name="proxy-max-requests" select="()"/>
		<xsl:variable name="query-component" select="replace(., '^.*(\?.*)$', '$1')"/>
		<xsl:variable name="uri-before-query-component" select="substring-before(., $query-component)"/>
		<xsl:variable name="parameters" select="$query-component => substring-after('?') => tokenize('&amp;')"/>

		<!--
		<xsl:message expand-text="true">parameters: {$parameters}, parameter: {$proxy-max-requests-parameter}, effective value: {$proxy-max-requests}</xsl:message>
		-->

		<!-- output a URL unless proxy-max-requests has already fallen to 1 -->
		<xsl:if test="not($proxy-max-requests = '1')">
			<!-- collect the parameters to add to the Trove URI -->
			<xsl:variable name="parameters" select="
				string-join(
					(
						(: copy all the proxy parameters such as proxy-format back onto the URI :)
						(: but discarding parameters with null values, and specifically excluding the 
						proxy-max-requests parameter which will be appended with a decremented value :)
						$proxy-parameters[normalize-space()][not(starts-with(., 'proxy-max-requests='))],
						(: append the proxy-max-requests parameter, only if it's been provided to this template :)
						concat('proxy-max-requests=', number($proxy-max-requests) - 1)[exists($proxy-max-requests)],
						(: add the Trove API 'key' parameter if it was provided and is desired (we don't include
						it in the body of the resources returned, but we will include it in HTTP Link headers) :)
						concat('key=', $key)[exists($key)],
						(: add the proxy's proxy-metadata-format if it's provided :)
						concat('proxy-metadata-format=', $proxy-metadata-format)[exists($proxy-metadata-format)]
					),
					'&amp;'
				)[normalize-space(.)]
			"/>
			<!-- construct the full URL -->
			<xsl:sequence select="
				string-join(
					(
						concat($proxy-base-uri, substring-after(., $upstream-base-uri)),
						$parameters
					),
					(: if the Trove URL already had a query component, then join our additional
					parameters on with an '&amp;', otherwise use '?' :)
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
					<xsl:call-template name="rewrite-uri">
						<xsl:with-param name="key" select="$key"/>
						<xsl:with-param name="proxy-max-requests" select="$proxy-max-requests"/>
					</xsl:call-template>
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
	
	<xsl:template match="@url ">
		<xsl:variable name="url">
			<xsl:call-template name="rewrite-uri"/>
		</xsl:variable>
		<xsl:if test="normalize-space($url)">
			<xsl:attribute name="{local-name()}" select="$url"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="@next">
		<xsl:variable name="url">
			<xsl:call-template name="rewrite-uri">
				<!-- next URLs should include a proxy-max-requests parameter -->
				<!-- NB if the value falls to 0 then this will suppress the @next URL altogether -->
				<xsl:with-param name="proxy-max-requests" select="$proxy-max-requests"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="normalize-space($url)">
			<xsl:attribute name="{local-name()}" select="$url"/>
		</xsl:if>
	</xsl:template>	
	
</xsl:stylesheet>