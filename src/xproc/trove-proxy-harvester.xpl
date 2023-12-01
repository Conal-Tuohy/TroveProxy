<p:declare-step version="1.0" name="trove-proxy"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:t="https://github.com/Conal-Tuohy/TroveProxy"
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:init-parameters="tag:conaltuohy.com,2015:webapp-init-parameters">

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
	<z:parse-request/>
	<p:group>
		<p:variable name="path" select="/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value"/>
		<p:variable name="method" select="upper-case(/c:request/@method)"/>
		<cx:message>
			<p:with-option name="message" select="concat('harvester: ', $method, ' ', $path)"/>
		</cx:message>
		<p:choose>
			<p:when test="$path='/harvester/harvest/'">
				<!-- either GET a list of the existing harvests, or POST a new harvest -->
				<p:choose>
					<p:when test="$method = 'POST' ">
						<t:create-harvest/>
					</p:when>
					<p:when test="$method = 'GET' ">
						<t:list-harvests/>
					</p:when>
					<p:otherwise>
						<z:method-not-allowed>
							<p:with-option name="method" select="$method"/>
						</z:method-not-allowed>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="starts-with($path, '/harvester/harvest/')">
				<!-- either a request for a harvest description, a harvest data file, 
				or an internal request to run a harvest -->
				<p:variable name="sub-path" select="substring-after($path, '/harvester/harvest/')"/>
				<p:choose>
					<p:when test="ends-with($path, '/run')">
						<p:choose>
							<p:when test="$method = 'POST' ">
								<t:run-harvest/>
							</p:when>
							<p:otherwise>
								<z:method-not-allowed>
									<p:with-option name="method" select="$method"/>
								</z:method-not-allowed>
							</p:otherwise>
						</p:choose>
					</p:when>
					<p:when test="ends-with($path, '/')">
						<t:view-harvest/>
					</p:when>
					<p:otherwise>
						<t:download-data-file/>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:otherwise>
				<p:identity/>
				<z:make-http-response/>
			</p:otherwise>
		</p:choose>
	</p:group>

	<p:declare-step name="download-data-file" type="t:download-data-file">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="filename" select="
			concat(
				$harvests-directory,
				substring-after(
					/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value,
					'/harvester/harvest/'
				)
			)
		"/>
		<p:variable name="extension" select="replace($filename, '.*(\..*)', '$1')"/>
		<p:choose>
			<p:when test="$extension = '.xml'">
				<p:load>
					<p:with-option name="href" select="$filename"/>
				</p:load>
				<z:make-http-response/>
			</p:when>
			<p:otherwise>
				<p:template name="load-request">
					<p:with-param name="url" select="$filename"/>
					<p:input port="template">
						<p:inline>
							<c:request href="{$url}" method="GET" override-content-type="text/plain"/>
						</p:inline>
					</p:input>
				</p:template>
				<p:http-request/>
				<p:add-attribute match="/c:body" attribute-name="content-type">
					<p:with-option name="attribute-value" select="if ($extension = '.csv') then 'text/csv' else 'text/plain'"/>
				</p:add-attribute>
				<p:wrap match="/c:body" wrapper="c:response"/>
				<p:add-attribute match="/c:response" attribute-name="status" attribute-value="200"/>
			</p:otherwise>
		</p:choose>
		<!--
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="text/plain">data file goes here</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
		-->
	</p:declare-step>
	
	<p:declare-step name="view-harvest" type="t:view-harvest">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="path" select="/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value"/>
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="harvest-name" select="substring-after($path, '/harvester/harvest/')"/>
		<p:variable name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
		<p:directory-list>
			<p:with-option name="path" select="$harvest-directory"/>
		</p:directory-list>
		<p:viewport match="/c:directory/c:file[@name='status.xml']">
			<p:load>
				<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
			</p:load>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet"><p:document href="../xslt/harvester/view-harvest.xsl"/></p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
	
	<p:declare-step name="list-harvests" type="t:list-harvests">
		<p:input port="source"/>
		<p:output port="result"/>
		<!--
		<p:variable name="uri-components" select="/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value"/>
		-->
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>

		<p:variable name="example-harvest-url" select=" 'the URL of your query' "/>
		<file:mkdir>
			<p:with-option name="href" select="$harvests-directory"/>
		</file:mkdir>
		<p:directory-list>
			<p:with-option name="path" select="$harvests-directory"/>
		</p:directory-list>
		<p:xslt>
			<p:with-param name="example-harvest-url" select="$example-harvest-url"/>
			<p:input port="stylesheet"><p:document href="../xslt/harvester/view-harvests.xsl"/></p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>

	<p:declare-step name="create-harvest" type="t:create-harvest">
		<p:input port="source"/>
		<p:documentation>
			The output port produces a sequence of two documents: 
			a <c:response/> to return to the client to point them to the new harvest, and 
			a <c:request/> to be handled internally by XProc-Z to actually launch the harvest
		</p:documentation>
		<p:output port="result" sequence="true"/> 
		<p:variable name="harvests-uri" select="/c:request/@href"/>
		<p:variable name="harvester-base-uri" select="
			/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value 
			=> substring-before('harvester/harvests/')
		"/>
		<p:www-form-urldecode name="post-data">
			<p:with-option name="value" select="/c:request/c:body[@content-type='application/x-www-form-urlencoded']"/>
		</p:www-form-urldecode>
		<p:group>
			<p:variable name="harvest-name" select="/c:param-set/c:param[@name='name']/@value"/>
			<p:variable name="harvest-url" select="/c:param-set/c:param[@name='url']/@value"/>
			<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
			<p:variable name="harvest-directory" select="concat($harvests-directory, encode-for-uri($harvest-name))"/>
			<!--<p:try>-->
				<p:group>
					<file:mkdir>
						<p:with-option name="href" select="$harvest-directory"/>
					</file:mkdir>
					<p:template name="create-harvest-initial-state">
						<p:with-param name="harvest-url" select="$harvest-url"/>
						<p:input port="source"><p:empty/></p:input>
						<p:input port="template">
							<p:inline exclude-inline-prefixes="#all">
								<harvest
									status="starting"
									started="{current-dateTime()}" 
									last-updated="{current-dateTime()}" 
									requests="0"
								>
									<pending url="{$harvest-url}"/>
								</harvest>
							</p:inline>
						</p:input>
					</p:template>
					<p:store indent="true">
						<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
					</p:store>
					<!-- actually launch the harvest -->
					<p:template name="create-harvest-run-request">
						<p:with-param name="name" select="$harvest-name"/>
						<p:input port="source"><p:empty/></p:input>
						<p:input port="template">
							<p:inline exclude-inline-prefixes="#all">
								<c:request href="http://localhost:8080/harvester/harvest/{encode-for-uri($name)}/run" method="POST"/>
							</p:inline>
						</p:input>
					</p:template>
					<p:template name="redirect-to-new-harvest">
						<p:with-param name="harvest-name" select="$harvest-name"/>
						<p:input port="source"><p:empty/></p:input>
						<p:input port="template">
							<p:inline>
								<c:response status="302">
									<c:header name="Location" value="{encode-for-uri($harvest-name)}/"/>
								</c:response>
							</p:inline>
						</p:input>
					</p:template>
					<p:identity name="respond-to-create-and-launch-harvest">
						<p:input port="source">
							<p:pipe step="redirect-to-new-harvest" port="result"/>
							<p:pipe step="create-harvest-run-request" port="result"/>
						</p:input>
					</p:identity>
				</p:group>
				<!--
				<p:catch name="failed">
					<p:identity>
						<p:input port="source">
							<p:pipe step="failed" port="error"/>
						</p:input>
					</p:identity>
					<z:make-http-response content-type="application/xml"/>
				</p:catch>
			</p:try>
			-->
		</p:group>
	</p:declare-step>
	
	<!-- runs in the background -->
	<p:declare-step name="run-harvest" type="t:run-harvest">
		<p:input port="source"/>
		<p:documentation>
			The output port produces a sequence of two documents: 
			a <c:response/> which is notionally returned to the client, though XProc-Z will discard it unread 
			a <c:request/> to be handled internally by XProc-Z to actually launch the harvest
		</p:documentation>
		<p:output port="result" sequence="true"/>
		<p:documentation>
			Expected input:
			<c:request xmlns:c="http://www.w3.org/ns/xproc-step" href="/harvester/harvest/test%20of%20harvest3/run" method="POST"/>
		</p:documentation>
		<!-- find the harvest folder -->
		<p:variable name="request-path" select="/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value"/>
		<p:variable name="harvest-name" select="$request-path => substring-after('/harvester/harvest/') => substring-before('/run')"/>
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
		<!-- open the status.xml file -->
		<p:load name="harvest-status-before-trove-query">
			<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
		</p:load>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					'Harvest &quot;', $harvest-name, '&quot;, ',
					'created: ', /harvest/@started, ', ',
					'last updated: ', /harvest/@last-updated, ', ',
					'status: ', /harvest/@status, ', ',
					'requests issued: ', /harvest/@requests
				)
			"/>
		</cx:message>
		<!-- if the harvest is not already complete, run it -->
		<p:choose name="running-harvest">
			<p:when test="/harvest/@status='completed'">
				<!-- the harvest had already completed, so this request to run it should not have been made -->
				<p:identity>
					<p:input port="source">
						<p:inline exclude-inline-prefixes="#all">
							<c:response status="400"><!-- bad request -->
								<c:body content-type="text/plain">harvest was already complete</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:identity>
			</p:when>
			<p:otherwise>
				<p:variable name="requests" select="1 + number(/harvest/@requests)"/>
				<p:variable name="url" select="/harvest/pending[1]/@url"/>
				<!-- download and save the resource named by the request number -->
				<p:template name="create-trove-request">
					<p:with-param name="url" select="$url"/>
					<p:input port="template">
						<p:inline exclude-inline-prefixes="#all">
							<c:request method="GET" href="{$url}" detailed="true"/>
						</p:inline>
					</p:input>
				</p:template>
				<p:http-request name="data"/>
				<p:group name="save">
					<p:variable name="extension" select="
						if (c:response/c:header[lower-case(@name) = 'content-type']/@value = 'text/csv') then 
							'.csv' 
						else 
							'.xml'
					"/>
					<p:variable name="filename" select="
						concat(
							format-integer($requests, '296635227'), 
							$extension
						)
					"/>
					<p:choose>
						<p:when test="$extension = '.xml'">
							<p:store name="save-xml" method="xml">
								<p:input port="source" select="/c:response/c:body/*">
									<p:pipe step="data" port="result"/>
								</p:input>
								<p:with-option name="href" select="concat($harvest-directory, '/', $filename)"/>
							</p:store>
						</p:when>
						<p:otherwise>
							<p:store name="save-plain-text" method="text">
								<p:input port="source" select="/c:response/c:body">
									<p:pipe step="data" port="result"/>
								</p:input>
								<p:with-option name="href" select="concat($harvest-directory, '/', $filename)"/>
							</p:store>
						</p:otherwise>
					</p:choose>
					<!-- update the status.xml file 
						the incremented request number,
						remove the downloaded URL,
						add any new 'next' or 'section' links from the downloaded resource 
					-->
					<p:for-each name="new-pending-links">
						<p:iteration-source select="
							/c:response/c:header
								[lower-case(@name)='link']
								[@value => lower-case() => substring-after(' rel=') = ('next', 'section')]
						">
							<p:pipe step="data" port="result"/>
						</p:iteration-source>
						<p:output port="result"/>
						<p:template name="pending-url">
							<p:with-param name="url" select="substring-before(substring-after(/c:header/@value, '&lt;'), '&gt;')"/>
							<p:input port="template">
								<p:inline exclude-inline-prefixes="#all">
									<pending url="{$url}"/>
								</p:inline>
							</p:input>
						</p:template>
					</p:for-each>
					<p:sink/>
					<p:load name="harvest-status-after-trove-query">
						<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
					</p:load>
					<p:add-attribute match="/harvest" attribute-name="requests">
						<p:with-option name="attribute-value" select="$requests"/>
					</p:add-attribute>
					<p:delete match="/harvest/pending[1]"/>
					<p:insert match="/harvest" position="last-child">
						<p:input port="insertion">
							<p:pipe step="new-pending-links" port="result"/>
						</p:input>
					</p:insert>
					<p:choose>
						<p:when test="not(/harvest/pending)">
							<p:add-attribute match="/harvest" attribute-name="status" attribute-value="completed"/>
							<cx:message>
								<p:with-option name="message" select="concat('harvester completed harvest &quot;', $harvest-name, '&quot;')"/>
							</cx:message>
						</p:when>
						<p:otherwise>
							<p:add-attribute match="/harvest" attribute-name="status" attribute-value="running"/>
						</p:otherwise>
					</p:choose>
					<p:add-attribute match="/harvest" attribute-name="last-updated">
						<p:with-option name="attribute-value" select="current-dateTime()"/>
					</p:add-attribute>
					<p:identity name="updated-status"/>
					<p:store name="save-updated-status" indent="true">
						<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
					</p:store>
					<cx:message cx:depends-on="save-updated-status" message="run-harvest saved updated status">
						<p:input port="source"><p:empty/></p:input>
					</cx:message>
					<p:identity>
						<p:input port="source">
							<p:pipe step="updated-status" port="result"/>
						</p:input>
					</p:identity>
					<p:choose>
						<p:when test="/harvest/@status='completed'">
							<!-- respond with a "finished" message -->
							<p:identity name="harvest-complete">
								<p:input port="source">
									<p:inline>
										<c:response status="200">
											<c:body content-type="text/plain">harvest complete</c:body>
										</c:response>
									</p:inline>
								</p:input>
							</p:identity>
						</p:when>
						<p:otherwise>
							<p:identity name="harvest-continuing">
								<p:input port="source">
									<p:inline>
										<c:response status="202"><!-- accepted for ongoing processing -->
											<c:body content-type="text/plain">harvest continuing</c:body>
										</c:response>
									</p:inline>
									<!-- repeat the current request -->
									<p:pipe step="run-harvest" port="source"/>
								</p:input>
							</p:identity>
						</p:otherwise>
					</p:choose>
				</p:group>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
		
</p:declare-step>