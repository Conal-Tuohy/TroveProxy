<p:declare-step version="1.0" name="trove-proxy"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:t="https://github.com/Conal-Tuohy/TroveProxy"
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:l="http://xproc.org/library"
	xmlns:init-parameters="tag:conaltuohy.com,2015:webapp-init-parameters">

	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="zip.xpl"/>
	<p:import href="recursive-directory-list.xpl"/>

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
				<!-- a request relating to an existing harvest -->
				<p:choose>
					<p:when test="$method = 'POST' ">
						<!-- an internal request to run a harvest -->
						<p:variable name="harvest-name" select="$path => substring-after('/harvester/harvest/') => substring-before('/')"/>
						<!--
						<z:dump href="/tmp/run-harvest-request.xml"/>
						-->
						<t:run-harvest>
							<p:with-option name="harvest-name" select="$harvest-name"/>
						</t:run-harvest>
					</p:when>
					<p:when test="$method = 'DELETE' ">
						<!-- a request to delete a completed harvest -->
						<p:variable name="harvest-name" select="$path => substring-after('/harvester/harvest/') => substring-before('/')"/>
						<!--
						<z:dump href="/tmp/run-harvest-request.xml"/>
						-->
						<t:delete-harvest>
							<p:with-option name="harvest-name" select="$harvest-name"/>
						</t:delete-harvest>
					</p:when>
					<p:otherwise>
						<p:variable name="sub-path" select="substring-after($path, '/harvester/harvest/')"/>
						<cx:message>
							<p:with-option name="message" select="concat('sub-path is [', $sub-path, ']')"/>
						</cx:message>
						<p:choose>
							<p:when test="ends-with($path, '/')">
								<!-- request for a page describing the harvest -->
								<p:variable name="harvest-name" select="substring-after($path, '/harvester/harvest/')"/>
								<t:view-harvest>
									<p:with-option name="harvest-name" select="$harvest-name"/>
								</t:view-harvest>
							</p:when>
							<p:otherwise>
								<!-- request for one of the harvest's files -->
								<p:variable name="filename" select="
									/c:request/c:param-set[@xml:id='uri']/c:param[@name='path']/@value
									=> substring-after('/harvester/harvest/')
								"/>
								<t:download-data-file>
									<p:with-option name="filename" select="$filename"/>
								</t:download-data-file>
							</p:otherwise>
						</p:choose>
					</p:otherwise>
				</p:choose>
			</p:when>
		</p:choose>
	</p:group>

	<p:declare-step name="download-data-file" type="t:download-data-file">
		<p:output port="result"/>
		<!-- filename is relative to the "harvests" folder -->
		<p:option name="filename" required="true"/>
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="extension" select="replace($filename, '.*(\..*)', '$1')"/>
		<p:choose>
			<p:when test="$extension = '.xml'">
				<p:load>
					<p:with-option name="href" select="concat($harvests-directory, '/', $filename)"/>
				</p:load>
				<z:make-http-response/>
			</p:when>
			<p:otherwise>
				<p:template name="load-request">
					<p:with-param name="url" select="concat($harvests-directory, '/', $filename)"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<c:request href="{$url}" method="GET"/>
						</p:inline>
					</p:input>
				</p:template>
				<p:http-request/>
				<p:add-attribute match="/c:body" attribute-name="content-type">
					<p:with-option name="attribute-value" select="
						(
							map{
								'.csv': 'text/csv',
								'.zip': 'application/zip'
							}($extension),
							'application/octet-stream'
						)[1]
					"/>
				</p:add-attribute>
				<p:wrap match="/c:body" wrapper="c:response"/>
				<p:add-attribute match="/c:response" attribute-name="status" attribute-value="200"/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<p:declare-step name="view-harvest" type="t:view-harvest">
		<p:output port="result"/>
		<p:option name="harvest-name" required="true"/>
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
		<p:load name="status">
			<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
		</p:load>
		<p:directory-list>
			<p:with-option name="path" select="$harvest-directory"/>
		</p:directory-list>
		<p:insert position="first-child" match="/c:directory/c:file[@name='status.xml']">
			<p:input port="insertion">
				<p:pipe step="status" port="result"/>
			</p:input>
		</p:insert>
		<!-- XML Calabash's p:zip step creates a temp file which we'll ignore -->
		<p:delete match="c:file[starts-with(@name, 'calabash-temp')]"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet"><p:document href="../xslt/harvester/view-harvest.xsl"/></p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="list-harvests" type="t:list-harvests">
		<p:input port="source"/>
		<p:output port="result"/>
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
			<p:variable name="harvest-url" select="/c:param-set/c:param[@name='url']/@value"/>
			<p:variable name="harvest-name" select="
				substring-after(
					(
						substring-after($harvest-url, '?') => tokenize('&amp;'),
						'proxy-metadata-name=unnamed%20harvest'
					)[starts-with(., 'proxy-metadata-name=')][1],
					'='
				) => replace('\+', '%20')
			"/>
			<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
			<p:variable name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
			<!--<p:try>-->
				<p:group>
					<file:mkdir>
						<p:with-option name="href" select="$harvest-directory"/>
					</file:mkdir>
					<!-- we are starting or restarting a harvest, so any prior error can be forgiven -->
					<file:delete fail-on-error="false">
						<p:with-option name="href" select="concat($harvest-directory, '/error.xml')"/>
					</file:delete>
					<p:try>
						<p:group>
							<!-- Attempt to load existing status.xml file for this dataset -->
							<!-- If it exists, the dataset will be appended to -->
							<p:load>
								<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
							</p:load>
							<p:add-attribute match="/harvest" attribute-name="status" attribute-value="restarting harvest..."/>
							<p:add-attribute match="/harvest" attribute-name="last-updated">
								<p:with-option name="attribute-value" select="current-dateTime()"/>
							</p:add-attribute>
							<p:insert match="harvest" position="first-child">
								<p:input port="insertion">
									<p:inline>
										<download/>
									</p:inline>
								</p:input>
							</p:insert>
							<p:add-attribute match="/harvest/download[not(@url)][last()]" attribute-name="url">
								<p:with-option name="attribute-value" select="$harvest-url"/>
							</p:add-attribute>
							<p:insert match="harvest" position="last-child">
								<p:input port="insertion">
									<p:inline>
										<zip/>
									</p:inline>
								</p:input>
							</p:insert>
						</p:group>
						<p:catch>
							<!-- create an initial status.xml since it doesn't already exist -->
							<p:template name="create-harvest-initial-state">
								<p:with-param name="harvest-url" select="$harvest-url"/>
								<p:input port="source"><p:empty/></p:input>
								<p:input port="template">
									<p:inline exclude-inline-prefixes="#all">
										<harvest
											status="starting"
											started="{current-dateTime()}" 
											last-updated="{current-dateTime()}" 
											requests-made="0"
										>
											<download url="{$harvest-url}"/>
											<zip/>
										</harvest>
									</p:inline>
								</p:input>
							</p:template>
						</p:catch>
					</p:try>
					<p:store indent="true">
						<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
					</p:store>
					<!-- actually launch the harvest -->
					<p:template name="create-harvest-run-request">
						<p:with-param name="name" select="$harvest-name"/>
						<p:input port="source"><p:empty/></p:input>
						<p:input port="template">
							<p:inline exclude-inline-prefixes="#all">
								<c:request href="http://localhost:8080/harvester/harvest/{$name}/" method="POST"/>
							</p:inline>
						</p:input>
					</p:template>
					<p:template name="redirect-to-new-harvest">
						<p:with-param name="harvest-name" select="$harvest-name"/>
						<p:input port="source"><p:empty/></p:input>
						<p:input port="template">
							<p:inline>
								<c:response status="302">
									<c:header name="Location" value="{$harvest-name}/"/>
									<c:header name="Access-Control-Allow-Origin" value="*"/>
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
	
	<p:declare-step name="delete-harvest" type="t:delete-harvest">
		<p:option name="harvest-name" required="true"/>
		<p:documentation>
			The input port provides the http request
		</p:documentation>
		<p:input port="source"/>
		<p:documentation>
			The output port produces a <c:response/> which redirects the client to the main "harvests" page
		</p:documentation>
		<p:output port="result" sequence="true"/>
		<p:documentation>
			Expected input:
			<c:request xmlns:c="http://www.w3.org/ns/xproc-step" href="/harvester/harvest/test%20of%20harvest3/" method="DELETE"/>
		</p:documentation>
		<!-- find the harvest folder -->
		<p:variable name="harvests-directory" select="p:system-property('init-parameters:harvester.harvest-directory')"/>
		<p:variable name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
		<file:delete recursive="true">
			<p:with-option name="href" select="$harvest-directory"/>
		</file:delete>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="303">
						<c:header name="Location" value=".."/>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
	
	<!-- Another pipeline, responding to an HTTP request, will launch this pipeline as a background task. -->
	<!-- The output of this pipeline is not connected to a user's HTTP request; it will simply be discarded by the XProc-Z runtime. -->
	<!-- The pipeline reads the harvest's "status.xml" file, executes the first command in it, and then recurses to -->
	<!-- continue the harvest, until complete --> 
	<p:declare-step name="run-harvest" type="t:run-harvest">
		<p:option name="harvest-name" required="true"/>
		<p:documentation>
			The input port provides the http request that caused this harvest to run a single iteration; 
			if this iteration has not completed the harvest then the request will be returned to XProc-Z's,
			bounce off the "trampoline" and cause the pipeline to run again. 
		</p:documentation>
		<p:input port="source"/>
		<p:documentation>
			The output port produces a sequence of two documents: 
			a <c:response/> which is notionally returned to the client, though XProc-Z will discard it unread 
			a <c:request/> to be handled internally by XProc-Z to actually launch the harvest
		</p:documentation>
		<p:output port="result" sequence="true"/>
		<p:documentation>
			Expected input:
			<c:request xmlns:c="http://www.w3.org/ns/xproc-step" href="/harvester/harvest/test%20of%20harvest3/" method="POST"/>
		</p:documentation>
		<!-- find the harvest folder -->
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
					'requests issued: ', /harvest/@requests-made
				)
			"/>
		</cx:message>
		<!-- if the harvest is not already complete, run it -->
		<p:choose name="which-action-to-perform-next">
			<p:when test="/harvest/download">
				<p:variable name="requests-made" select="1 + number(/harvest/@requests-made)"/>
				<p:variable name="url" select="/harvest/download[1]/@url"/>
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
				<p:choose>
					<p:when test="/c:response/@status = '200'">
						<t:process-trove-response name="ingest-harvested-resource">
							<p:with-option name="requests-made" select="$requests-made"/>
							<p:with-option name="harvest-directory" select="$harvest-directory"/>
							<p:with-option name="harvest-name" select="$harvest-directory"/>
						</t:process-trove-response>
						<!-- strip the c:param-set elements out of the c:request, turning it back into an unparsed HTTP request -->
						<p:delete name="repeat-request" match="c:param-set">
							<p:input port="source">
								<p:pipe step="run-harvest" port="source"/>
							</p:input>
						</p:delete>
						<p:identity>
							<p:input port="source">
								<p:pipe step="ingest-harvested-resource" port="result"/>
								<!-- repeat the current request -->
								<p:pipe step="repeat-request" port="result"/>
							</p:input>
						</p:identity>
					</p:when>
					<p:otherwise>
						<!-- Failed to retrieve the data -->
						<p:store>
							<p:with-option name="href" select="concat($harvest-directory, '/error.xml')"/>
						</p:store>
						<p:load>
							<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
						</p:load>
						<p:add-attribute match="/harvest" attribute-name="status" attribute-value="aborted"/>
						<p:delete match="/harvest/*"/>
						<p:store>
							<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
						</p:store>
						<p:identity>
							<p:input port="source">
								<p:inline>
									<c:response status="500">
										<c:body content-type="text/plain">Failed to retrieve data</c:body>
									</c:response>
								</p:inline>
							</p:input>
						</p:identity>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:when test="/harvest/zip">
				<!-- there are no pending downloads, but there's a pending zip task -->

				<!-- update the status file -->
				<p:load>
					<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
				</p:load>
				<p:add-attribute match="/harvest" attribute-name="status" attribute-value="zipping..."/>
				<p:store>
					<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
				</p:store>
				<t:zip-harvest name="zip">
					<p:with-option name="zip-file" select="concat($harvest-directory, '/', $harvest-name, '.zip')"/>
					<p:with-option name="harvest-directory" select="concat($harvests-directory, $harvest-name)"/>
				</t:zip-harvest>
				<!-- update the status file -->
				<p:load cx:depends-on="zip">
					<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
				</p:load>
				<p:add-attribute match="/harvest" attribute-name="status" attribute-value="harvested and zipped"/>
				<p:delete match="/harvest/zip"/>
				<p:store>
					<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
				</p:store>
				<!-- generate a pro forma response for XProc-Z's trampoline client to ignore -->
				<p:template>
					<p:with-param name="harvest-name" select="$harvest-name"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline exclude-inline-prefixes="#all">
							<c:response status="201"><!-- created -->
								<c:header name="Location" value="{$harvest-name}.zip"/>
								<c:body content-type="text/plain">Zip file created</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
			</p:when>
			<p:otherwise>
				<!-- there are no further tasks, so this request to run it should not have been made -->
				<p:identity>
					<p:input port="source">
						<p:inline exclude-inline-prefixes="#all">
							<c:response status="400"><!-- bad request -->
								<c:body content-type="text/plain">harvest was already complete</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:identity>
			</p:otherwise>			
		</p:choose>
	</p:declare-step>
	
	<p:declare-step name="process-trove-response" type="t:process-trove-response">
		<p:input port="source"/>
		<p:output port="result" sequence="true"/>
		<p:option name="requests-made" required="true"/>
		<p:option name="harvest-directory" required="true"/>
		<p:option name="harvest-name" required="true"/>
		<p:variable name="query-response-status" select="/c:response/@status"/>
		<p:variable name="content-type" select="/c:response/c:header[lower-case(@name) = 'content-type']/@value"/>
		<p:variable name="extension" select="
			if ($content-type = 'text/csv') then 
				'.csv' 
			else 
				'.xml'
		"/>
		<p:variable name="filename" select="
			concat(
				format-integer($requests-made, '296635227'), (: Trove contains ~300M items :)
				$extension
			)
		"/>
		<p:choose>
			<p:when test="$extension = '.xml'">
				<p:store name="save-xml" method="xml">
					<p:input port="source" select="/c:response/c:body/*">
						<p:pipe step="process-trove-response" port="source"/>
					</p:input>
					<p:with-option name="href" select="concat($harvest-directory, '/', $filename)"/>
				</p:store>
			</p:when>
			<p:otherwise>
				<p:store name="save-plain-text" method="text">
					<p:input port="source" select="/c:response/c:body">
						<p:pipe step="process-trove-response" port="source"/>
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
		<p:for-each name="new-downloads">
			<p:iteration-source select="
				/c:response/c:header
					[lower-case(@name)='link']
					[@value => lower-case() => substring-after(' rel=') = ('next', 'section')]
			">
				<p:pipe step="process-trove-response" port="source"/>
			</p:iteration-source>
			<p:output port="result"/>
			<p:template name="download">
				<p:with-param name="url" select="substring-before(substring-after(/c:header/@value, '&lt;'), '&gt;')"/>
				<p:input port="template">
					<p:inline exclude-inline-prefixes="#all">
						<download url="{$url}"/>
					</p:inline>
				</p:input>
			</p:template>
		</p:for-each>
		<p:sink/>
		<!--
		<p:load name="harvest-status-before-trove-query">
			<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
		</p:load>
		-->
		<p:load name="harvest-status-after-trove-query">
			<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
		</p:load>
		<p:add-attribute match="/harvest" attribute-name="requests-made">
			<p:with-option name="attribute-value" select="$requests-made"/>
		</p:add-attribute>
		<p:delete match="/harvest/download[1]"/>
		<p:insert match="/harvest" position="last-child">
			<p:input port="insertion">
				<p:pipe step="new-downloads" port="result"/>
			</p:input>
		</p:insert>
		<p:choose>
			<p:when test="$query-response-status != '200'">
				<p:add-attribute match="/harvest" attribute-name="status" attribute-value="aborted"/>
				<cx:message>
					<p:with-option name="message" select="concat('harvester aborted harvest &quot;', $harvest-name, '&quot;')"/>
				</cx:message>
			</p:when>
			<p:when test="not(/harvest/download)">
				<p:add-attribute match="/harvest" attribute-name="status" attribute-value="harvest completed"/>
				<cx:message>
					<p:with-option name="message" select="concat('harvester completed harvest &quot;', $harvest-name, '&quot;')"/>
				</cx:message>
			</p:when>
			<p:otherwise>
				<p:add-attribute match="/harvest" attribute-name="status" attribute-value="harvesting..."/>
			</p:otherwise>
		</p:choose>
		<p:add-attribute match="/harvest" attribute-name="last-updated">
			<p:with-option name="attribute-value" select="current-dateTime()"/>
		</p:add-attribute>
		<p:identity name="updated-status"/>
		<p:store name="save-updated-status" indent="true">
			<p:with-option name="href" select="concat($harvest-directory, '/status.xml')"/>
		</p:store>
		<!-- Update RO-Crate metadata -->
		<!-- 
			Retrieve an RO-Crate metadata description of the just-harvested resource.
			Attempt to load a pre-existing RO-Crate metadata resource (or return <json:null/>)
			Construct a new JSON map containing both RO-Crate maps.
		-->
		<!-- load already-harvested RO-Crate object -->
		<t:load-ro-crate-metadata>
			<p:with-option name="href" select="
				concat(
					$harvest-directory, 
					'/ro-crate-metadata.json'
				)
			"/>
		</t:load-ro-crate-metadata>
		<p:add-attribute name="local-ro-crate-metadata" match="/*" attribute-name="key" attribute-value="local"/> 
		<!-- download new RO-Crate object -->
		<t:load-ro-crate-metadata>
			<p:with-option name="href" select="
				substring-before(
					substring-after(
						/c:response/c:header
							[lower-case(@name)='link']
							[@value => lower-case() => substring-after(' rel=') = 'describedby'][1]/@value,
						'&lt;'
					), 
					'&gt;'
				)
			">
				<p:pipe step="process-trove-response" port="source"/>
			</p:with-option>
		</t:load-ro-crate-metadata>
		<p:add-attribute name="downloaded-ro-crate-metadata" match="/*" attribute-name="key" attribute-value="downloaded"/> 
		<!-- add the two crates as members of a single map for subsequent merging -->
		<p:wrap-sequence name="ro-crate-metadata-old-and-new" wrapper-namespace="http://www.w3.org/2005/xpath-functions" wrapper="map">
			<p:input port="source">
				<p:pipe step="local-ro-crate-metadata" port="result"/>
				<p:pipe step="downloaded-ro-crate-metadata" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<!--
		<z:dump href="/tmp/merged-ro-crate.xml"/>
		-->
		
		<!-- update it -->
		<p:xslt name="update-ro-crate-metadata">
			<p:with-param name="filename" select="$filename"/>
			<p:with-param name="request-number" select="$requests-made"/>
			<p:with-param name="content-type" select="$content-type"/>
			<p:with-param 
				name="trove-harvester-version" 
				xmlns:init-parameters="tag:conaltuohy.com,2015:webapp-init-parameters" 
				select="p:system-property('init-parameters:harvester.version')"/> 
			<p:input port="stylesheet">
				<p:document href="../xslt/harvester/update-ro-crate-metadata.xsl"/>
			</p:input>
		</p:xslt>
		<!--
		<z:dump href="/tmp/merged-and-updated-ro-crate.xml"/>
		-->

		<!-- save the updated RO-Crate file -->
		<t:save-ro-crate-metadata>
			<p:with-option name="href" select="concat($harvest-directory, '/ro-crate-metadata.json')"/>
		</t:save-ro-crate-metadata>

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
			<p:when test="/harvest/@status='aborted'">
				<!-- respond with a "aborted" message -->
				<p:identity name="harvest-complete">
					<p:input port="source">
						<p:inline>
							<c:response status="500">
								<c:body content-type="text/plain">harvest aborted</c:body>
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
					</p:input>
				</p:identity>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	<!-- writes JSON XML to specified href as JSON-LD -->
	<p:declare-step name="save-ro-crate-metadata" type="t:save-ro-crate-metadata">
		<p:option name="href" required="true"/>
		<p:input port="source"/>
		<p:template name="convert-to-json">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:body content-type="text/plain" xmlns:map="http://www.w3.org/2005/xpath-functions/map">{
						xml-to-json(
							/, 
							map:entry('indent', true())
						)
					}</c:body>
				</p:inline>
			</p:input>
		</p:template>
		<p:store method="text">
			<p:with-option name="href" select="$href"/>
		</p:store>
	</p:declare-step>
		
	<!-- reads JSON-LD from specified href, convert to JSON-XML -->
	<p:declare-step name="load-ro-crate-metadata" type="t:load-ro-crate-metadata">
		<p:option name="href" required="true"/>
		<p:output port="result"/>
		<p:try name="ro-crate">
			<p:group>
				<p:template name="prepare-to-load-ro-crate">
					<p:with-param name="href" select="$href"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<c:request href="{$href}" method="GET" override-content-type="text/plain"/>
						</p:inline>
					</p:input>
				</p:template>
				<cx:message>
					<p:with-option name="message" select="concat('harvester: Reading RO-Crate metadata from ''', /c:request/@href, ''' ...')"/>
				</cx:message>
				<!-- returns a c:body containing the JSON or throws not found error -->
				<p:http-request name="json-in-body-element"/>
				<!-- convert JSON body to JSON XML for ease of subsequent processing -->
				<!--
				<p:template>
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>{json-to-xml(.)}</p:inline>
					</p:input>
				</p:template>
				-->
				<!--
				<p:identity>
					<p:input port="source" select="json-to-xml(/)">
						<p:pipe step="json-in-body-element" port="result"/>
					</p:input>
				</p:identity>
				-->
				<p:filter select="json-to-xml(/)"/>
			</p:group>
			<p:catch name="load-metadata-failed">
				<p:identity name="no-metadata">
					<p:input port="source">
						<p:inline>
							<null xmlns="http://www.w3.org/2005/xpath-functions"/>
						</p:inline>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
	</p:declare-step>
	
	<p:declare-step name="zip-harvest" type="t:zip-harvest">
		<p:documentation>
			The output port produces a sequence of two documents: 
			a <c:response/> which is notionally returned to the client, though XProc-Z will discard it unread 
			a <c:request/> to be handled internally by XProc-Z to actually continue the harvest
		</p:documentation>
		<p:output port="result" sequence="true"/>
		<p:option name="zip-file" required="true"/>
		<p:option name="harvest-directory" required="true"/>
		<!-- List the files to be zipped -->
		<l:recursive-directory-list>
			<p:with-option name="path" select="$harvest-directory"/>
		</l:recursive-directory-list>
		<!-- Don't include the status.xml or any existing zip file in the zip file -->
		<p:delete match="c:file[ends-with(@name, '.zip') or @name='status.xml']"/>
		<z:zip-directory>
			<p:with-option name="href" select="$zip-file"/>
		</z:zip-directory>
		<z:make-http-response/>
	</p:declare-step>
	
	<p:declare-step name="set-harvest-status">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="status" required="true"/>
		<p:option name="harvest-directory" required="true"/>
		
	</p:declare-step>
	
</p:declare-step>