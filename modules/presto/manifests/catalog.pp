# Define: presto::catalog
#
# Renders a Presto catalog properties file.
#
# == Parameters
#
# [*title*]
#   Name of the catalog. A properites file will be rendered into
#   /etc/presto/catalog/$title.properties.
#
# [*properties*]
#   Hash of catalog properties.
#
define presto::catalog (Hash $properties) {
    # catalog/ properties files should be installed
    # after the presto-server package, but before
    # the presto-server is started.
    Package['presto-server'] -> Presto::Catalog[$title]
    Presto::Catalog[$title] -> Service['presto-server']

    presto::properties { "catalog/${title}":
        properties => $properties,
    }
}
