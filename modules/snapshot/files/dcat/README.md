DCAT-AP for Wikibase
=================

A project aimed at generating a [DCAT-AP](https://joinup.ec.europa.eu/system/files/project/c3/22/18/DCAT-AP_Final_v1.00.html)
document for [Wikibase](http://wikiba.se) installations
in general and [Wikidata](http://wikidata.org) in particular.

Takes into account access through:

*   Content negotiation (various formats)
*   MediaWiki api (various formats)
*   Entity dumps e.g. json, ttl (assumes that these are gziped)

Current result can be found at [lokal-profil / dcat-wikidata.rdf](https://gist.github.com/lokal-profil/8086dc6bf2398d84a311)


## To use

1.  Copy `config.example.json` to `config.json` and change the contents
    to match your installation. Refer to the *Config* section below for
    an explanation of the individual configuration parameters.
2.  Copy `catalog.example.json` to a suitable place (e.g. on-wiki) and
    update the translations to fit your wikibase installation. Set this
    value as `catalog-i18n` in the config file.
3.  Create the dcatap.rdf file by running `php -r "require 'DCAT.php'; run('<PATH>');"`
    where `<PATH>` is the relative path to the directory containing the
    dumps (if any) and where the dcatap.rdf file should be created.
    `<PATH>` can be left out if already supplied through the `directory`
    parameter in the config file.


## Translations

*   Translations which are generic to the tool can be submitted as pull
    requests and should be in the same format as the files in the `i18n`
    directory.
*   Translations which are specific to a project/catalog are added to
    the location specified in the `catalog-i18n` parameter of the config
    file.


## Config

Below follows a key by key explanation of the config file.

*   `directory`: Relative path to the directory containing the dump
    subcategories (if any) and for the final dcat file.
*   `api-enabled`: (`Boolean`) Is API access activated for the MediaWiki
    installation?
*   `dumps-enabled`: (`Boolean`) Is JSON dump generation activated for the
    WikiBase installation?
*   `uri`: URL used as basis for rdf identifiers,
    e.g. *http://www.example.org/about*
*   `catalog-homepage`: URL for the homepage of the WikiBase installation,
    e.g. *http://www.example.org*
*   `catalog-issued`: ISO date at which the WikiBase installation was
    first issued, e.g. *2000-12-24*
*   `catalog-license`: License of the catalog, i.e. of the dcat file
    itself (not the contents of the WikiBase installation),
    e.g. *http://creativecommons.org/publicdomain/zero/1.0/*
*   `catalog-i18n`: URL or path to json file containing i18n strings for
    catalog title and description. Can be an on-wiki page,
    e.g. *https://www.example.org/w/index.php?title=MediaWiki:DCAT.json&action=raw*
*   `keywords`: (`array`) List of keywords applicable to all of the datasets
*   `themes`: (`array`) List of thematic ids in accordance with
    [Eurovoc](http://eurovoc.europa.eu/), e.g. *2191* for
    http://eurovoc.europa.eu/2191
*   `publisher`:
    *   `name`: Name of the publisher
    *   `homepage`: URL for or the homepage of the publisher
    *   `email`: Contact e-mail for the publisher, should be a function
        address, e.g. *info@example.org*
    *   `publisherType`: Publisher type according to [ADMS](http://purl.org/adms/publishertype/1.0),
        e.g. *NonProfitOrganisation*
*   `contactPoint`:
    *   `name`: Name of the contact point
    *   `email`: E-mail for the contact point, should ideally be a
        function address, e.g. *support@example.org*
    *   `vcardType`: Type of contact point, either `Organization` or
        `Individual`
*   `ld-info`:
    *   `accessURL`: URL to the content negotiation endpoint of the
        WikiBase installation, e.g. *http://www.example.org/entity/*
    *   `mediatype`: (`object`) List of [IANA media types](http://www.iana.org/assignments/media-types/)
        available through content negotiation in the format *file-ending:media-type*
    *   `license`: License of the data in the distribution, e.g.
        *http://creativecommons.org/publicdomain/zero/1.0/*
*   `api-info`:
    *   `accessURL`: URL to the MediaWiki API endpoint of the wiki,
        e.g. *http://www.example.org/w/api.php*
    *   `mediatype`: (`object`) List of non-deprecated formats available
        thorough the API, see ld-info:mediatype above for formatting
    *   `license`: See ld-info:license above
*   `dump-info`:
    *   `accessURL`: URL to the directory where the *.json.gz* files
        reside (`$1` is replaced on the fly by the actual filename),
        e.g. *http://example.org/dumps/$1*
    *   `mediatype`: (`object`) List of media types. In practice this is
        always `{"json": "application/json"}` ... for now
    *   `license`: See ld-info:license above
