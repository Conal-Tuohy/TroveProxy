# TroveProxy
A transforming proxy for the National Library of Australia's Trove API

The proxy consists of a docker container containing:
- The web server Apache Tomcat
- The web servlet XProc-Z
- An XProc pipeline implementing the proxy
- XSLT transformations for converting the output of the Trove API into various other formats 

## API Usage
Access the proxied Trove API as you would normally access the Trove API, except replacing 
`https://api.trove.nla.gov.au/` with `http://localhost:8080/proxy/` as the base URI of the API service.

The proxied API accepts some additional parameters:

|Parameter name|Values|
|------------------------|----------|
|proxy-include-people-australia|If set to `true` then additional information about people will be added from People Australia|
|proxy-format|Set to `tei` to return TEI XML, or `atom` to return Atom Syndication XML, or leave blank for Trove XML|


## Developing
To build the docker application, naming the image `trove-proxy`:

```bash
docker build -t trove-proxy .
```

To launch the `trove-proxy` image:
```bash
docker run --publish 8080:8080 trove-proxy 
```

For convenience while developing the proxy application, you can use the `--mount` command to 
mount the `src` folder into the container, so that you can edit the XProc and XSLT code and have the changes reflected in the running container 
immediately, without having to rebuild the docker image. If accessing the application using a web browser, you can just refresh the browser to
see the effect of any changes to the code.
```bash
docker run --publish 8080:8080 --mount type=bind,src=`pwd`/src,dst=/src trove-proxy
```

## Running
With the container running, the proxied API can be accessed as if it were the Trove API, but substituting 
`http://localhost:8080/proxy/` in place of `https://api.trove.nla.gov.au/`.  

For example: http://localhost:8080/proxy/v3/result?category=newspaper&category=book&q=water+dragon&include=all&proxy-format=tei&n=10&reclevel=full&bulkHarvest=true

In addition to Trove's own query syntax, the URI should typically contain the parameter `proxy-format`, 
whose value determines the output format of the proxy; values should be either `tei`, `atom`, or if the
`proxy-format` parameter is missing from the URI, or if it's left blank, the proxy will return Trove's XML 
without transformation, beyond the rectification of a few errors and infelicities.

## XSLT
XSLT transformations should be placed in the `src/xslt/crosswalks` folder, and named for the format which they produce, e.g. `tei.xsl` to output `tei`. To install a new output
format, it's enough to add the appropriately named XSLT file into that folder.

Before the XML retrieved from the Trove API is supplied to the crosswalk stylesheets, it will have been slightly altered by the `fix-trove-response.xsl` pre-processing stylesheet: 
- The partially-escaped markup found in the `articleText` element of a newspaper article will be replaced 
with embedded `<p>` and `<span>` elements (i.e. the `articleText` element will be "mixed content").
- Some errors which have been detected in the new (v3) API will be worked around.
If any new errors are detected in the Trove API, work-arounds should be inserted in that stylesheet, rather than in specific
crosswalk stylesheets, so that all the crosswalks can benefit from the workaround.

A second pre-processor `rewrite-trove-uris-as-proxy-uris.xsl` will also replace URIs within the Trove XML which 
are identifiers for individual works with proxied URIs which should resolve to proxied versions of those works. 
Crosswalk stylesheets should not need to change these URIs and should be able to simply copy them into the
appropriate place for their output format.

The crosswalk stylesheets will be passed a `request-uri` parameter, which will be the URI of the proxied resource 
(i.e. it's usable as a `self` reference).

