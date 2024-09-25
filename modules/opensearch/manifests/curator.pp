# SPDX-License-Identifier: Apache-2.0
# = Class: opensearch::curator
#
# This class installs elasticsearch-curator and all of the curator
# actions. Individual clusters to manage must be defined with
# opensearch::curator::cluster.
#
class opensearch::curator (
    Optional[String] $version = undef
) {
    if $version {
        $curator_version = $version
    } else {
        if debian::codename::le('buster') {
            $curator_version = '5.8.5-1~wmf3'
        } elsif debian::codename::eq('bullseye') {
            $curator_version = '5.8.5-1~wmf5+deb11u1'
        } elsif debian::codename::eq('bookworm') {
            $curator_version = '5.8.5-1~wmf5+deb12u1'
        } else {
            notify { 'curator unsupported':
                message => 'ElasticSearch Curator with OpenSearch support is not yet available for this version of Debian.'
            }
        }
    }

    # TODO: use fork when available (T301017)
    package { 'elasticsearch-curator':
        ensure => $curator_version
    }

    file { '/etc/curator/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }
    opensearch::curator::config {
        'disable-shard-allocation':
            source => 'puppet:///modules/opensearch/curator/disable-shard-allocation.yaml';
        'enable-shard-allocation':
            source => 'puppet:///modules/opensearch/curator/enable-shard-allocation.yaml';
    }
}
