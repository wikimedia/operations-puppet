# SPDX-License-Identifier: Apache-2.0
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
#   Hash of catalog properties. If the catalog specifies a directory
#   to use with the Alluxio SDK cache and that caching is enabled,
#   then this directory will be created with the required permissions.
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

    if $properties['cache.base-directory'] {
        $directory_ensure = $properties['cache.enabled'] ? {
            true    => directory,
            default => absent,
        }
        file { "${title}-alluxio-cache":
            ensure => $directory_ensure,
            path   => $properties['cache.base-directory'],
            owner  => 'presto',
            group  => 'presto',
            mode   => '0750',
        }
    }
}
