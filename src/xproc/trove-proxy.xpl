<p:declare-step version="1.0" name="trove-proxy"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z">

	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

	<p:input port='source' primary='true'/>
	<!-- e.g.
		<request xmlns="http://www.w3.org/ns/xproc-step"
		  method = NCName
		  href? = anyURI
		  detailed? = boolean
		  status-only? = boolean
		  username? = string
		  password? = string
		  auth-method? = string
		  send-authorization? = boolean
		  override-content-type? = string>
			 (c:header*,
			  (c:multipart |
				c:body)?)
		</request>
	-->
	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	
	<p:import href="xproc-z-library.xpl"/>
	
	<p:variable name="request-uri" select="/c:request/@href"/>
	
	<p:documentation>
		Parse the request URI
	</p:documentation>
	<z:parse-request name="parsed-request"/>

	<!--
	TODO process the request parameters
	the make-trove-http-request step should strip out any request parameters directed at the proxy so they don't get sent on to trove
	we should also remove any "encoding" parameter since we're always requesting XML (and using an Accept header to do so)
	"key" parameter should be stripped out of the request URI sent to Trove, since we will send it via an X-API-KEY header
	questions:
		should the proxy override the "encoding" parameter used by trove and extend it e.g. to include new values "tei", "atom", etc?
		or define its own parameter? e.g. proxy-output-format="tei"
	-->
	<p:group name="proxy-request">
		
		<!-- the base URI of the upstream API -->
		<p:variable name="upstream-base-uri" select=" 'https://api.trove.nla.gov.au/' "/>
		<!-- regular expression to parse the request URI -->
		<p:variable name="uri-parser" select=" '(.*?//.*?/proxy/)(.*)' "/>
	
		<p:variable name="proxy-base-uri" select="replace($request-uri, $uri-parser, '$1')"/>
		<p:variable name="relative-uri" select="replace($request-uri, $uri-parser, '$2')"/>
		
		<p:variable name="proxy-format" select="/c:request/c:param-set[@xml:id='parameters']/c:param[@name='proxy-format']/@value"/>
		
		<p:documentation>
			Parameters which are directed at the proxy server itself, rather than at the Trove API, such as proxy-format, 
			are recorded so that they can be appended to URIs returned in Trove responses
		</p:documentation>
		<p:variable name="proxy-parameters" select="
			string-join(
				/c:request/c:param-set[@xml:id='parameters']/c:param[starts-with(@name, 'proxy-')]/concat(@name, '=', @value),
				'&amp;'
			)
		"/>
		
		<p:documentation>Take the request received from the client, and transform it into a request directed at the Trove API</p:documentation>
		<p:xslt name="make-trove-http-request">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/make-trove-http-request.xsl"/>
			</p:input>
		</p:xslt>
		
		<z:dump href="/tmp/trove-http-request.xml"/>
		
		<p:documentation>Actually issue the request to the Trove API and receive a response</p:documentation>
		<p:http-request name="issue-request-to-trove-api"/>
		
		<p:documentation>Fix corrigible errors in the response received from Trove</p:documentation>
		<p:xslt name="fix-trove-response">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/fix-trove-response.xsl"/>
			</p:input>
		</p:xslt>
	
		<p:documentation>
			Rewrite Trove API URIs in the response to be proxy URIs.
		</p:documentation>
		<p:xslt name="rewrite-trove-uris-as-proxy-uris">
			<p:with-param name="request-uri" select="$request-uri"/>
			<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
			<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
			<p:with-param name="proxy-parameters" select="$proxy-parameters"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/rewrite-trove-uris-as-proxy-uris.xsl"/>
			</p:input>
		</p:xslt>
		
		<p:documentation>Now process just the body of the Trove API response</p:documentation>
		<p:filter select="/c:response/c:body/*" name="trove-response-body"/>

		<p:documentation>Include additional data for people listed in the response</p:documentation>
		<z:enhance-people-data/>
		
		<p:documentation>Convert the Trove XML response into the appropriate format</p:documentation>
		<p:choose>
			<p:when test="$proxy-format">
				<p:documentation>Apply a crosswalk to Trove's XML response</p:documentation>
				<p:load name="crosswalk">
					<p:with-option name="href" select="concat('../xslt/crosswalks/', $proxy-format, '.xsl')"/>
				</p:load>
				<p:xslt name="apply-crosswalk">
					<p:with-param name="request-uri" select="$request-uri"/>
					<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
					<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
					<p:input port="source">
						<p:pipe step="trove-response-body" port="result"/>
					</p:input>
					<p:input port="stylesheet">
						<p:pipe step="crosswalk" port="result"/>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise>
				<p:documentation>No transformation requested: return Trove XML</p:documentation>
				<p:identity name="trove-xml"/>
			</p:otherwise>
		</p:choose>
		
		<p:documentation>Transform the HTTP layer of the response</p:documentation>
		<p:xslt name="make-proxy-http-response">
			<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
			<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/make-proxy-http-response.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response/>
	</p:group>
	
	<p:declare-step name="parse-request" type="z:parse-request">
		<!-- TODO decide if the c:param-set[@xml:id='uri'] is even needed in the output -->
		<p:documentation>
			Parses an HTTP request (<c:request/> element) received by the proxy.
			The result document is the same <c:request/> with two additional child <c:param-set/> elements,
			one containing the request URI parsed into its main components, and the other containing
			the set of parameters in the query portion of the URI.
			e.g.
			<c:request href="http://localhost:8080" method="get">
				<c:param-set xml:id="uri">
					<c:param name="scheme" value="http or https"/>
					<c:param name="host" value="the host name"/>
					<c:param name="port" value="either a port number, or blank"/>
					<c:param name="path" value="the component of the request URI preceding any '?' character"/>
					<c:param name="query" value="the query portion of the URI"/>
				</c:param-set>
				<c:param-set xml:id="parameters">
					<c:param name="q" value="Mr Right"/>
					<c:param name="bulkHarvest" value="true"/>
					<c:param name="key" value="XXXXXXXXXX-1234567890-ABCDEFGHIJ"/>
					<c:param name="category" value="newspaper"/>
					<c:param name="category" value="book"/>
				</c:param-set>
				<c:header name="accept" value="application/xml"/>
				<c:header name="X-API-KEY" value="XXXXXXXXXX-1234567890-ABCDEFGHIJ"/>
			</c:request>
		</p:documentation>
		<p:input port="source"/>
		<p:output port="result"/>
		<z:parse-request-uri unproxify="true"/>
		<p:add-attribute name="uri" match="/*" attribute-name="xml:id" attribute-value="uri"/>
		<p:www-form-urldecode>
			<p:with-option name="value" select="substring-after(/c:param-set/c:param[@name='query']/@value, '?')"/>
		</p:www-form-urldecode>
		<p:add-attribute name="parameters" match="/*" attribute-name="xml:id" attribute-value="parameters"/>
		<p:insert name="parsed-request" match="/*" position="first-child">
			<p:input port="source">
				<p:pipe step="parse-request" port="source"/>
			</p:input>
			<p:input port="insertion">
				<p:pipe step="uri" port="result"/>
				<p:pipe step="parameters" port="result"/>
			</p:input>
		</p:insert>
	</p:declare-step>
	
	<p:declare-step name="enhance-people-data" type="z:enhance-people-data">
		<p:documentation>
			Trove <people/> records are quite minimal, but there are more detailed EAC-CPF records available via an SRU service
			which can be imported into each <people/> record.
		</p:documentation>
	
		<p:documentation>
			Source document is a Trove XML result which may contain <people/> elements
		</p:documentation>
		<p:input port="source"/>
		<p:documentation>
			Result document is a Trove XML result whose <people/> elements have 
			each had their associated <eac-cpf/> element inserted as a child element.
		</p:documentation>
		<p:output port="result"/>
		<p:choose>
			<p:when test="//people[@id]">
				<p:xslt name="make-people-australia-http-request">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="../xslt/make-people-australia-http-request.xsl"/>
					</p:input>
				</p:xslt>
				<p:http-request name="query-people-australia"/>
				<p:wrap-sequence wrapper="trove-response-and-people-australia-response">
					<p:input port="source">
						<p:pipe step="enhance-people-data" port="source"/>
						<p:pipe step="query-people-australia" port="result"/>
					</p:input>
				</p:wrap-sequence>
				<p:xslt name="merge-eac-cpf-into-people">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="../xslt/merge-eac-cpf-into-people.xsl"/>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise>
				<p:identity name="no-people-to-enhance"/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
</p:declare-step>
