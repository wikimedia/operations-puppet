# SPDX-License-Identifier: Apache-2.0
# @summary Class to add specific data to a k8s node running mediawiki
#
# If a node is marked as mw-experimental, it will be used to run mw-experimental
# a mediawiki deployment where the mediawiki code is mounted from the node itself.
# via hostPath volumes.
#
# The update-mediawiki-image systemd service, checks if the mediawiki image present
# on the node is up to date, and if not, it will download the latest mediawiki image
#
# mw-experimental nodes MUST have the following labels and taints
#
# profile::kubernetes::node::kubelet_node_labels:
#   - dedicated=mw-experimental
#
# profile::kubernetes::node::kubelet_node_taints:
#   - dedicated=mw-experimental:NoExecute
#   - dedicated=mw-experimental:NoSchedule


class profile::kubernetes::mediawiki_runner(
    Boolean $is_mw_experimental                  = lookup('profile::kubernetes::node::mw_experimental'),
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] }),
    Optional[String] $deployment_group           = lookup('deployment_group', { default_value => undef }),
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

    # TODO: The rest of this code should become a separate profile
    # as it is strictly for mw-experimental

    if $is_mw_experimental {

        # Taken from mediawiki::scap class
        $mediawiki_deployment_dir = '/srv/mediawiki'

        # Directory should be at least present before kubelet starts, even if empty.
        file { $mediawiki_deployment_dir:
            ensure  => directory,
            owner   => 'mwdeploy',
            group   => 'mwdeploy',
            mode    => '0775',
            require => User['mwdeploy'],
            before  => Service['kubelet'],
        }

        # fix-staging-perms is copied from profile::mediawiki::deployment::server
        # it fixes ownership and permissions of /srv/mediawiki
        ::monitoring::icinga::bad_directory_owner { $mediawiki_deployment_dir: }

        file { '/usr/local/etc/fix-staging-perms.sh':
            content => "deployment_group=\"${deployment_group}\"\ndeployment_dirs=\"/srv/mediawiki\"\n",
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
        }

        # A command that group 'deployment' can execute to fix common file permission snafus
        # inside /srv/mediawiki-staging.
        file { '/usr/local/sbin/fix-staging-perms':
            mode    => '0555',
            source  => 'puppet:///modules/profile/mediawiki/deployment/fix-staging-perms.sh',
            owner   => 'root',
            group   => 'root',
            require => File['/usr/local/etc/fix-staging-perms.sh'],
        }

        # Script and timer for mw-experimental mediawiki image updates
        # TODO: Add timer
        $mw_experimental_update_script_name = 'mw-experimental-mediawiki-image-update'
        $mw_experimental_update_script_path = "/usr/local/sbin/${mw_experimental_update_script_name}"

        file { $mw_experimental_update_script_path:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0544',
            source => "puppet:///modules/profile/kubernetes/node/${mw_experimental_update_script_name}.sh",
        }


    }
}
