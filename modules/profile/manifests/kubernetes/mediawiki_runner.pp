# SPDX-License-Identifier: Apache-2.0
# @summary Class to add specific data to a k8s node running mediawiki
class profile::kubernetes::mediawiki_runner(
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] })
) {
    # For now, assume we can use any node that's not marked as dedicated.
    $ensure = (/dedicated=.*/ in $kubelet_node_labels).bool2str('absent', 'present')
    $command = '/usr/local/sbin/mediawiki-image-download'
    file { $command:
        ensure => $ensure,
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/kubernetes/node/mediawiki-image-download.sh'
    }
    ## Scap "client"
    # Please note: if we ever want to actually use the scap client to not just deliver commands but to
    # distribute the code, we should include profile::mediawiki::scap_client instead
    # The following is copied over from mediawiki::users; TODO: refactor and DRY
    group { 'mwdeploy':
        ensure => $ensure,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => $ensure,
        shell      => '/bin/bash',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'mwdeploy':
        ensure  => $ensure,
        content => secret('keyholder/mwdeploy.pub'),
    }
    # Grant mwdeploy sudo rights to download the mediawiki image.
    sudo::user { 'mwdeploy':
        ensure     => $ensure,
        privileges => [
            "ALL = (root) NOPASSWD: ${command} *",
        ]
    }

    class { 'scap::ferm':
        ensure => $ensure,
    }
}
