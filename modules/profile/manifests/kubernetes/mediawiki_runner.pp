# SPDX-License-Identifier: Apache-2.0
# @summary Class to add specific data to a k8s node running mediawiki
#
# If a node is marked as mw-experimental, it will be used to run mw-experimental
# a mediawiki deployment where the mediawiki code is mounted from the node itself.
# via hostPath volumes.
#
# The update-mediawiki-image systemd service, checks if the mediawiki image present
# on the node is up to date, and if not, it will download the latest mediawiki image

class profile::kubernetes::mediawiki_runner(
    Profile::Kubernetes::Feature_flags $feature_flags       = lookup('profile::kubernetes::node::feature_flags', { default_value => {} }),
    Optional[Array[String]]            $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] }),
) {
    # Treat the node as reserved if it is explicitly dedicated to a
    # purpose other than "mw-experimental". For now, we assume that
    # any node not marked as dedicated, or dedicated only to
    # "mw-experimental", is available for running mediawiki.
    $reserved_node = $kubelet_node_labels.any |$label| {
        $label =~ /^dedicated=(?!mw-experimental$).+/
    }

    $command = '/usr/local/sbin/mediawiki-image-download'

    if $reserved_node {
        # Just pretend to do it on the non-reserved nodes
        file { $command:
            ensure => link,
            target => '/bin/true',
        }
    } else {
        # Download the mediawiki image on the reserved nodes
        file { $command:
            ensure => present,
            mode   => '0544',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/profile/kubernetes/node/mediawiki-image-download.sh'
        }
    }

    ## Scap "client"
    # Please note: if we ever want to actually use the scap client to not just deliver commands but to
    # distribute the code, we should include profile::mediawiki::scap_client instead
    # The following is copied over from mediawiki::users; TODO: refactor and DRY
    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'mwdeploy':
        ensure  => present,
        content => secret('keyholder/mwdeploy.pub'),
    }
    # Grant mwdeploy sudo rights to download the mediawiki image.
    sudo::user { 'mwdeploy':
        ensure     => present,
        privileges => [
            "ALL = (root) NOPASSWD: ${command} *",
        ]
    }

    class { 'scap::firewall':
        ensure => present,
    }

    unless $reserved_node {
        ## GeoIP data
        # Make sure that the GeoIP data is copied locally on the node before starting the kubelet
        # service so it can be available to the mediawiki pods. T288375
        class { 'geoip::data::puppet':
            fetch_ipinfo_dbs => true,
            before           => Service['kubelet'],
        }
        if $feature_flags['allow_memcached_ports'] {
            $memcached_ports = [11211, 11214]
            ferm::rule { 'skip_memcached_conntrack_out':
                desc  => 'Skip outgoing connection tracking towards memcached',
                table => 'raw',
                chain => 'OUTPUT',
                rule  => "proto tcp dport (${memcached_ports.join(' ')}) NOTRACK;",
            }
        }
    }
}
