# Enriched Trove XML

When querying Trove through the TroveProxy application, if the `proxy-format` parameter is left blank,
The TroveProxy application will return Trove's own XML with certain enrichments which are listed here.

For details on Trove's own XML format, see the [Technical Guide](https://trove.nla.gov.au/about/create-something/using-api/v3/api-technical-guide) for the Trove API.

## Newspaper full text is unescaped

When querying Trove for newspaper full text, the textual content will appear in an `<articleText>` element.

The content of the `<articleText>` element is a single text node containing escaped HTML markup consisting of
`<p>` elements with  nested `<span>` elements, where the `<p>` elements represent paragraphs, and the 
`<span>` elements represent typograpical lines within those paragraphs.

Although the angle bracket markup is escaped, other constituents of the markup (such as `&` characters) are not.
This makes a standard "un-escaping" of the escaped markup problematic, as it can yield badly-formed markup.

For this reason, the TroveProxy application parses the content of `<articleText>` elements and replaces
it with actual `<p>` and `<span>` elements.

## People content can be enhanced with EAC data

When querying the Trove search API for information about people, using `category=people` in the query URL,
the API will return a `<people>` element containing summary information about each person, family, or 
organisation.

However, Trove has another service called People Australia which offers a separate SRW API for searching 
for information about people, which returns information in an XML format called _Encoded Archival Context 
for Corporate Bodies, Persons, and Families_ (EAC-CPF). This EAC-encoded data is generally much richer.

For this reason, the TroveProxy application accepts the `proxy-include-people-australia` parameter on query
URLs, which, if set to `true`, will cause the TroveProxy to take each `<people>` record returned by the
Trove API, look it up in _People Australia_, and insert the resulting `<eac-cpf>` element as the last
child of the `<people>` element.

## Temporary fixes for known bugs in the Trove API response

In some cases, the responses returned from Trove's API will include URLs which are intended to refer
to continuations of the current query response, but are formatted incorrectly. The TroveProxy application
attempts to correct any such errors.
