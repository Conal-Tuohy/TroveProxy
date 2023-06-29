<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" version="1.0" name="trove-proxy">

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
	
	<!-- the base URI of the upstream API -->
	<p:variable name="upstream-base-uri" select=" 'https://api.trove.nla.gov.au/' "/>
	<!-- regular expression to parse the request URI -->
	<p:variable name="uri-parser" select=" '(.*?//.*?/proxy/)(.*)' "/>
	<p:variable name="proxy-base-uri" select="replace(/c:request/@href, $uri-parser, '$1')"/>
	<p:variable name="relative-uri" select="replace(/c:request/@href, $uri-parser, '$2')"/>

	<p:add-attribute match="/c:request" attribute-name="href">
		<p:with-option name="attribute-value" select="concat($upstream-base-uri, $relative-uri)"/>
	</p:add-attribute>
	
	<p:add-attribute match="/c:request" attribute-name="detailed" attribute-value="true"/>

	<p:documentation>TODO cookie management </p:documentation>

	<p:documentation>delete "host" header which if it exists will specify the hostname of the proxy service, rather than "api.trove.nla.gov.au"</p:documentation>
	<p:delete match="/c:request/c:header[lower-case(@name)='host']"/>

	<p:documentation>replace any existing "accept" header with a header asking for xml</p:documentation>
	<p:delete match="/c:request/c:header[lower-case(@name)='accept']"/>
	<p:insert match="/c:request" position="first-child">
		<p:input port="insertion">
			<p:inline>
				<c:header name="accept" value="application/xml"/>
			</p:inline>
		</p:input>
	</p:insert>
	
	<p:http-request name="issue-request-to-trove-api"/>
	
    	<p:documentation>Fix corrigible errors in the response received from Trove</p:documentation>
	<p:xslt name="fix-trove-response">
		<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
		<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
		<p:input port="stylesheet">
			<p:document href="fix-trove-response.xsl"/>
		</p:input>
	</p:xslt>
    	<p:documentation>Transform the response received from Trove</p:documentation>
	<p:xslt name="convert-to-tei">
		<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
		<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
		<p:input port="stylesheet">
			<p:document href="tei.xsl"/>
		</p:input>
	</p:xslt>
	
	<p:documentation>delete http transport layer headers</p:documentation>
	<p:delete name="response" match="/c:response/c:header[@name='Transfer-Encoding']"/>

</p:declare-step>
