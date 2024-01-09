# Trove Proxy Harvester

The Trove Proxy Harvester is a feature within the TroveProxy application which can iteratively issue
requests to the TroveProxy (which in turn queries the Trove API), and save the results of each query
into a file, along with metadata about the harvest.

The Harvester is launched by issuing an HTTP POST request to `/harvester/harvest/`, containing
`www-form-urlencoded` data, consisting of a single parameter with the name `url` and whose value
is the URL of a TroveProxy query.

In response, the Harvester will create a new directory to contain harvested files, and return a redirect
to a web page showing the newly created harvest, and launching a background process to iteratively
make requests to the TroveProxy, starting with the URL specified in the `url` parameter, and continuing
with a sequence of URLs extracted from the response to the previous request.

The harvest web page will display the ongoing status of the harvest, and list the files downloaded so
far, alongside an RO-Crate metadata file.

