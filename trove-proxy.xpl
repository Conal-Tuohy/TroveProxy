<p:declare-step version="1.0" name="trove-proxy"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z">

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
	<p:variable name="uri-parser" select=" '(.*?//.*?/)proxy/(.*)' "/>

	<p:variable name="proxy-base-uri" select="replace(/c:request/@href, $uri-parser, '$1')"/>
	<p:variable name="relative-uri" select="replace(/c:request/@href, $uri-parser, '$2')"/>

	<p:xslt name="make-trove-http-request">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet">
			<p:document href="make-trove-http-request.xsl"/>
		</p:input>
	</p:xslt>
	
	<p:http-request name="issue-request-to-trove-api"/>
	
	<p:documentation>Fix corrigible errors in the response received from Trove</p:documentation>
	<p:xslt name="fix-trove-response">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet">
			<p:document href="fix-trove-response.xsl"/>
		</p:input>
	</p:xslt>

	<p:documentation>Rewrite Trove API URIs in the response to be proxy URIs</p:documentation>
	<p:xslt name="rewrite-trove-uris-as-proxy-uris">
		<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
		<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
		<p:input port="stylesheet">
			<p:document href="rewrite-trove-uris-as-proxy-uris.xsl"/>
		</p:input>
	</p:xslt>
	
	<p:documentation>Transform Trove's XML response into TEI</p:documentation>
	<p:xslt name="convert-to-tei">
		<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
		<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
		<p:input port="stylesheet">
			<p:document href="convert-trove-xml-to-tei.xsl"/>
		</p:input>
	</p:xslt>
	
	<p:documentation>Transform the HTTP layer of the response</p:documentation>
	<p:xslt name="make-proxy-http-response">
		<p:with-param name="proxy-base-uri" select="$proxy-base-uri"/>
		<p:with-param name="upstream-base-uri" select="$upstream-base-uri"/>
		<p:input port="stylesheet">
			<p:document href="make-proxy-http-response.xsl"/>
		</p:input>
	</p:xslt>
	<z:make-http-response/>
	
</p:declare-step>
