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
	
	<!--<p:variable name="request-uri" select="/c:request/@href"/>-->
	
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
	<z:parse-request name="parsed-request"/>
	<p:group name="access-log">
		<cx:message>
			<p:with-option name="message" select="
				string-join(
					(
						'proxy:', 
						upper-case(/c:request/@method), 
						/c:request/@href
(:						/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value,
						for $p in /c:request/c:param-set[@xml:id='parameters']/c:param return $p/@name || '=' || $p/@value
:)
					),
					' '
				)
			"/>
		</cx:message>
	</p:group>
	<!--debug-->
	<!--
	<z:dump href="/tmp/parsed-request.xml" indent="true"/>
	-->
	
	<p:choose name="generate-either-citation-metadata-or-query-results">
		<p:variable name="proxy-metadata-format" select="/c:request/c:param-set[@xml:id='parameters']/c:param[@name='proxy-metadata-format']/@value"/>
		<p:when test="$proxy-metadata-format">
			<z:generate-citation>
				<p:with-option name="metadata-format" select="$proxy-metadata-format"/>
			</z:generate-citation>
		</p:when>
		<p:otherwise>
			<z:proxy-request/>
		</p:otherwise>
	</p:choose>

	<p:declare-step name="generate-citation" type="z:generate-citation">
		<p:documentation>
			Performs a format crosswalk to the desired format by applying a conventionally named stylesheet:
			If the $metadata-format option equals "x" then the stylesheet "../xslt/citation-formats/x.xsl" will be applied.
			If the $metadata-format option is not supplied, then the source data will be returned untransformed.
		</p:documentation>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="metadata-format" required="true"/>
		<p:documentation>Apply a crosswalk to the request to return it as a citation in the specified format</p:documentation>
		<p:load name="crosswalk">
			<p:with-option name="href" select="concat('../xslt/metadata-formats/', $metadata-format, '.xsl')"/>
		</p:load>
		<p:xslt name="transformation">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="source">
				<p:pipe step="generate-citation" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="crosswalk" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="proxy-request" type="z:proxy-request">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- the URI of the request made to this XProc pipeline -->
		<p:variable name="request-uri" select="/c:request/@href"/>
		<!-- the base URI of the upstream API -->
		<p:variable name="upstream-base-uri" select=" 'https://api.trove.nla.gov.au/' "/>
		<!-- regular expression to parse the request URI -->
		<p:variable name="uri-parser" select=" '(.*?//.*?/proxy/)(.*)' "/>
	
		<p:variable name="proxy-base-uri" select="replace($request-uri, $uri-parser, '$1')"/>
		<p:variable name="relative-uri" select="replace($request-uri, $uri-parser, '$2')"/>
		
		<p:documentation>The output format for the proxy</p:documentation>
		<p:variable name="proxy-format" select="/c:request/c:param-set[@xml:id='parameters']/c:param[@name='proxy-format']/@value"/>
		
		<p:documentation>
			Set to 'true' to include related eac-cpf from People Australia into Trove 'people' records
		</p:documentation>
		<p:variable name="proxy-include-people-australia" select="/c:request/c:param-set[@xml:id='parameters']/c:param[@name='proxy-include-people-australia']/@value"/>
		
		<p:documentation>
			Parameters which are directed at the proxy server itself, rather than at the Trove API, such as proxy-format, 
			are recorded so that they can be appended to URIs returned in Trove responses
		</p:documentation>
		<p:variable name="proxy-parameter-string" select="
			string-join(
				/c:request/c:param-set[@xml:id='parameters'] (: the URI parameters :)
					/c:param[starts-with(@name, 'proxy-')][@value != ''] (: ... whose name starts with 'proxy-' and which have a non-null value :)
						/concat(@name, '=', @value), (: stick the name and value together :)
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
		
		<!--
		-->
		<z:dump href="/tmp/trove-http-request.xml"/>
		
		<p:documentation>Actually issue the request to the Trove API and receive a response</p:documentation>
		<p:http-request name="issue-request-to-trove-api"/>
		
		<!--
		-->
		<z:dump href="/tmp/trove-http-response.xml"/>
		
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
			<p:with-param name="proxy-parameter-string" select="$proxy-parameter-string"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/rewrite-trove-uris-as-proxy-uris.xsl"/>
			</p:input>
		</p:xslt>
		
		<p:documentation>Now process just the body of the Trove API response</p:documentation>
		<p:viewport match="/c:response/c:body/*" name="trove-response-body">
	
			<p:documentation>Include additional data for people listed in the response</p:documentation>
			<z:enhance-people-data>
				<p:with-option name="include-people-australia" select="$proxy-include-people-australia"/>
			</z:enhance-people-data>
			
			<p:documentation>Convert the Trove XML response into the appropriate format</p:documentation>
			<z:apply-crosswalk>
				<p:with-option name="proxy-format" select="$proxy-format"/>
				<p:with-option name="request-uri" select="$request-uri"/>
			</z:apply-crosswalk>
		</p:viewport>
		
		<p:documentation>
			Convert the output of the crosswalk step into the appropriate serialization format.
			A crosswalk can return JSON to the client by returning an XML document whose
			root element belongs to the XML vocabulary defined for the XPath 3.1 functions 
			json-to-xml and xml-to-json.
			A crosswalk can return csv to the client by returning a document whose root element
			is <table xmlns="http://www.w3.org/1999/xhtml"/>. 
		</p:documentation>
		<z:serialize>
			<p:with-option name="proxy-format" select="$proxy-format"/>
		</z:serialize>
		
		<p:documentation>Transform the HTTP layer of the response</p:documentation>
		<p:xslt name="make-proxy-http-response">
			<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
			<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/make-proxy-http-response.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="serialize" type="z:serialize">
		<p:documentation>
			Serializes an XML document into a non-XML text format.
		</p:documentation>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="proxy-format" required="true"/>
		<p:choose>
			<p:when test="$proxy-format = 'csv'">
				<p:xslt name="serialize-csv">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="../xslt/serialize-csv.xsl"/>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise>
				<p:documentation>No non-xml serialization needed: return the XML output of the crosswalk</p:documentation>
				<p:identity name="plain-xml"/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
		
	<p:declare-step name="apply-crosswalk" type="z:apply-crosswalk">
		<p:documentation>
			Performs a format crosswalk to the desired format by applying a conventionally named stylesheet:
			If the $proxy-format option equals "x" then the stylesheet "../xslt/crosswalks/x.xsl" will be applied.
			If the $proxy-format option is not supplied, then the source data will be returned untransformed.
			The $request-uri parameter specifies the URI of the request which the pipeline is fulfilling.
		</p:documentation>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="proxy-format"/>
		<p:option name="request-uri" required="true"/>
		<p:choose>
			<p:when test="$proxy-format">
				<p:documentation>Apply a crosswalk to Trove's XML response</p:documentation>
				<p:load name="crosswalk">
					<p:with-option name="href" select="concat('../xslt/crosswalks/', $proxy-format, '.xsl')"/>
				</p:load>
				<p:xslt name="transformation">
					<p:with-param name="request-uri" select="$request-uri"/>
					<p:input port="source">
						<p:pipe step="apply-crosswalk" port="source"/>
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
	</p:declare-step>

	<p:declare-step name="enhance-people-data" type="z:enhance-people-data">
		<p:option name="include-people-australia"/>
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
			<p:when test="$include-people-australia='true' and exists(//people[@id])">
				<p:xslt name="make-people-australia-http-request">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="../xslt/make-people-australia-http-request.xsl"/>
					</p:input>
				</p:xslt>
				<p:try>
					<p:group>
						<cx:message>
							<p:with-option name="message" select="concat('enhancing people data with EAC-CPF from ', /c:request/@href)"/>
						</cx:message>
						<p:http-request name="query-people-australia" cx:timeout="10000"/><!-- timeout = 10s -->
						<cx:message xmlns:eac="urn:isbn:1-931666-33-4" xmlns:srw="http://www.loc.gov/zing/srw/">
							<p:with-option name="message" select="
								concat('received ', /c:response/c:body/srw:searchRetrieveResponse/srw:numberOfRecords, ' EAC-CPF records')
							"/>
						</cx:message>
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
					</p:group>
					<p:catch>
						<!-- if an HTTP timeout occurs calling the SRU service, simply return
						the unenhanced people data -->
						<p:identity>
							<p:input port="source">
								<p:pipe step="enhance-people-data" port="source"/>
							</p:input>
						</p:identity>
					</p:catch>
				</p:try>
			</p:when>
			<p:otherwise>
				<p:identity name="no-people-to-enhance"/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
</p:declare-step>
