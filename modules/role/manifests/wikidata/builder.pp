# filtertags: labs-project-wikidata-build
class role::wikidata::builder {
    include ::role::gerrit::client
    include ::wikidatabuilder
}

