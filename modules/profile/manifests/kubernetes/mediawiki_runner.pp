# SPDX-License-Identifier: Apache-2.0
# @summary Class to add specific data to a k8s node running mediawiki
class profile::kubernetes::mediawiki_runner(
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] })
) {
    # For now, assume we can use any node that's not marked as dedicated.
    $reserved_node = /dedicated=.*/ in $kubelet_node_labels
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

    class { 'scap::ferm':
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
    }

}
