<p:library version="1.0"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:t="https://github.com/Conal-Tuohy/TroveProxy"
	xmlns:l="http://xproc.org/library"
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:init-parameters="tag:conaltuohy.com,2015:webapp-init-parameters">
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="recursive-directory-list.xpl"/>
	
	<p:declare-step name="zip-directory" type="z:zip-directory" xmlns:pxp="http://exproc.org/proposed/steps">
		<p:input port="source"/><!-- a directory list -->
		<p:output port="result"/><!-- a zip manifest -->
		<p:option name="href" required="true"/>
		<!--  
			convert c:directory[c:file] to c:zip-manifest
			http://exproc.org/proposed/steps/other.html#zip
		-->
		<p:xslt name="convert-directory-list-to-zip-manifest">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/harvester/convert-directory-list-to-zip-manifest.xsl"/>
			</p:input>
		</p:xslt>
		<p:for-each name="zip-entry">
			<p:iteration-source select="/c:zip-manifest/c:entry">
				<p:pipe step="convert-directory-list-to-zip-manifest" port="result"/>
			</p:iteration-source>
			<p:variable name="entry-name" select="/c:entry/@name"/>
			<p:variable name="entry-href" select="/c:entry/@href"/>
			<p:xslt name="convert-zip-entry-to-http-request">
				<p:input port="parameters"><p:empty/></p:input>
				<p:input port="stylesheet">
					<p:document href="../xslt/harvester/convert-zip-entry-to-http-request.xsl"/>
				</p:input>
			</p:xslt>
			<p:http-request name="request"/>
			<p:add-attribute attribute-name="xml:base" match="/*">
				<p:with-option name="attribute-value" select="$entry-href"/>
			</p:add-attribute>
			<pxp:zip>
				<p:with-option name="href" select="resolve-uri($href, 'file:/')"/>
				<p:input port="manifest">
					<p:pipe step="convert-directory-list-to-zip-manifest" port="result"/>
				</p:input>
			</pxp:zip>
			<p:sink/>
		</p:for-each>
		<p:identity>
			<p:input port="source">
				<p:pipe step="convert-directory-list-to-zip-manifest" port="result"/>
			</p:input>
		</p:identity>
	</p:declare-step>
</p:library>