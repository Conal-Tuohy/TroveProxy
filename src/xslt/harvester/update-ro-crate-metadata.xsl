<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xpath-default-namespace="http://www.w3.org/2005/xpath-functions"
	xmlns="http://www.w3.org/2005/xpath-functions"
	expand-text="true"
>
	<xsl:param name="filename"/>
	<xsl:param name="request-number"/>
	<xsl:param name="content-type"/>
	<xsl:param name="trove-harvester-version"/>
	<!-- 
		The input document is a map with two map properties: "local" and "downloaded".
		The processing consists of two stages:
			Firstly, if the "local" map is null, then the downloaded map is transformed into a new base map.
				The new base map describes a dataset with an empty hasPart array
		Otherwise, the "local" map is the base map.
		Secondly, the base map is then transformed to include details about the data file from the "downloaded"
		map, and also harvester's operation. 
	-->

	<xsl:variable name="base-ro-crate">
		<xsl:choose>
			<xsl:when test="/map/null[@key='local']">
				<!-- there's no local RO-Crate metadata, hence this is the first request in the harvest -->
				<xsl:message>there's no local RO-Crate metadata, hence this is the first request in the harvest</xsl:message>
				<!-- start with a copy of this RO-Crate, but with its root dataset's hasPart array cleared -->
				<xsl:apply-templates select="/map/map[@key='downloaded']" mode="create-base-ro-crate"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- we have an existing "local" RO-Crate to add to -->
				<xsl:message>there's already a local RO-Crate metadata which will be updated</xsl:message>
				<xsl:sequence select="/map/map[@key='local']"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="downloaded-resource-descriptions" select="
		/map
			/map[@key='downloaded']
				/array[@key='@graph']
					/map
	"/>

	<xsl:variable name="proxy-create-action" select="
		$downloaded-resource-descriptions
			[string[@key='@type']='CreateAction']
	"/>	
	
	<xsl:variable name="proxied-resource-uri" select="
		$proxy-create-action
			/map[@key='result']/string[@key='@id']
	"/>
	
	<xsl:variable name="trove-resource-uri" select="
		$proxy-create-action
			/map[@key='object']/string[@key='@id']
	"/>
	
	<xsl:variable name="proxied-resource-description" select="
		$downloaded-resource-descriptions
			[string[@key='@id']=$proxied-resource-uri]
	"/>
	
	<xsl:variable name="trove-resource-description" select="
		$downloaded-resource-descriptions
			[string[@key='@id']=$trove-resource-uri]
	"/>
	
	<xsl:variable name="trove-harvester-software-id" select=" 'https://github.com/Conal-Tuohy/TroveProxy/blob/main/doc/harvester.md' "/>
	
	<xsl:template match="/">
		<!-- get the base RO-Crate and update it -->
		<xsl:apply-templates select="$base-ro-crate" mode="update-ro-crate"/>
	</xsl:template>
	
	<xsl:mode name="update-ro-crate" on-no-match="shallow-copy"/>

	<!-- discard the root map's "key" attribute (either "local" or "downloaded") since it's now the root of a JSON doc -->
	<xsl:template mode="update-ro-crate" match="/map/@key"/>
	
	<xsl:template mode="update-ro-crate" match="/map/array[@key='@graph']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- copy the graph -->
			<xsl:copy-of select="*"/>
			<!-- add (only) the new data from the downloaded ro-crate -->
			<xsl:apply-templates mode="update-ro-crate" select="
				($proxy-create-action, $proxied-resource-description, $trove-resource-description)
			"/>
			<!-- add a description of the newly saved file -->
			<map>
				<string key='@id'>{$filename}</string>
				<string key='@type'>File</string>
				<!-- the downloaded file has the same type as the file it's a copy of -->
				<xsl:copy-of select="$proxied-resource-description/*[@key='encodingFormat']"/>
			</map>
			<!-- add provenance of the new file to the graph -->
			<map>
				<string key="@id">#download-{$request-number}</string>
				<string key="@type">CreateAction</string>
				<string key="name">Downloaded</string>
				<string key="description">The data file was downloaded from the proxy</string>
				<string key="endTime">{current-dateTime()}</string>
				<map key="instrument">
					<string key="@id">{$trove-harvester-software-id}</string>
				</map>
				<map key="object">
					<string key="@id">{$proxied-resource-uri}</string>
				</map>
				<map key="result">
					<string key="@id">{$filename}</string>
				</map>
			</map>	
		</xsl:copy>
	</xsl:template>
	
	<!-- insert a reference to the new file into the root dataset's hasPart array -->
	<xsl:template mode="update-ro-crate" match="
		map
			/array[@key='@graph']
				/map[string[@key='@id']='./'] (: map describing the root dataset :)
					/array[@key='hasPart'] (: the content of the root dataset :)
	">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="update-ro-crate"/>
			<map>
				<string key='@id'>{$filename}</string>
			</map>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template mode="update-ro-crate" match="
		map[string[@key='@type']='CreateAction']
			/string[@key='@id']
				/text()
	">
		<xsl:sequence select="concat(., '-', $request-number)"/>
	</xsl:template>
	
	<xsl:mode name="create-base-ro-crate" on-no-match="shallow-copy"/>
	<!-- clear the 'hasPart' array of the root dataset -->
	<xsl:template mode="create-base-ro-crate" match="
		map[@key='downloaded']
			/array[@key='@graph']
				/map[string[@key='@id']='./'][string[@key='@type'] = 'Dataset'] (: map describing the root dataset :)
					/array[@key='hasPart'] (: the list of files that make up the content of the root dataset :)
						/map (: the map identifying the single item in this dataset :)
	"/>
	
	<!-- discard the two files (Trove API call and Proxied API call) when creating the base ro crate -->
	<xsl:template mode="create-base-ro-crate" match="
		map[@key='downloaded']
			/array[@key='@graph']
				/map[string[@key='@type'] = 'File'] (: map describing a File :)
	"/>
	
	<!-- discard description of transformation of the Trove API call into the Proxied version -->
	<xsl:template mode="create-base-ro-crate" match="
		map[@key='downloaded']
			/array[@key='@graph']
				/map[string[@key='@type'] = 'CreateAction'] (: map describing the conversion process :)
	"/>
	
	<!-- insert ontological data -->
	<xsl:template mode="create-base-ro-crate" match="
		map[@key='downloaded']
			/array[@key='@graph']
	">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- description of Harvester -->
			<xsl:apply-templates mode="create-base-ro-crate"/>
			<map>
				<string key="@id">{$trove-harvester-software-id}</string>
				<string key="@type">SoftwareApplication</string>
				<string key="url">{$trove-harvester-software-id}</string>
				<string key="name">TroveProxyHarvester</string>
				<string key="version">{$trove-harvester-version}</string>
				<string key="description">A harvester for retrieving bulk data from the National Library of Australia's Trove API</string>
			</map>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>