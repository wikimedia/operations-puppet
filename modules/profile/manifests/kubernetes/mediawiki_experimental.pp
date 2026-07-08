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
# mw-experimental nodes now also host mw-parsoid pods, so they need to pull parsoid
# code and have it available at /srv/parsoid-testing, which is also mounted via
# hostPath volumes T386246
#
# mw-experimental nodes MUST have the following labels and taints
#
# profile::kubernetes::node::kubelet_node_labels:
#   - dedicated=mw-experimental
#
# profile::kubernetes::node::kubelet_node_taints:
#   - dedicated=mw-experimental:NoExecute
#   - dedicated=mw-experimental:NoSchedule

class profile::kubernetes::mediawiki_experimental(
    Boolean $is_mw_experimental         = lookup('profile::kubernetes::node::mw_experimental'),
    Stdlib::Host $deployment_server     = lookup('deployment_server'),
    Stdlib::Unixpath $general_dir       = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Optional[String] $deployment_group  = lookup('deployment_group', { default_value => undef }),
) {
    if $is_mw_experimental {
        require profile::mediawiki::system_users
        # Taken from mediawiki::scap class
        $mediawiki_deployment_dir = '/srv/mediawiki'

        # Directory should be at least present before kubelet starts, even if empty.
        file { $mediawiki_deployment_dir:
            ensure  => directory,
            owner   => 'mwdeploy',
            group   => 'deployment',
            mode    => '2775',
            require => User['mwdeploy'],
            before  => Service['kubelet'],
        }

        # On deployment server, the /etc/helmfile-defaults/mediawiki/release contains
        # the latest mediawiki release to be used by every deployment. We are syncing
        # this directory to the mw-experimental nodes so that they can use the latest
        # mediawiki release. We should create the parent directories

        file { $general_dir:
            ensure => directory,
            mode   => '0775',
        }
        file { "${general_dir}/mediawiki":
            ensure  => directory,
            mode    => '0775',
            require => File[$general_dir],
        }

        $kubernetes_release_dir = "${general_dir}/mediawiki/release"
        file { $kubernetes_release_dir:
            ensure => directory,
            mode   => '2775',
            owner  => 'mwdeploy',
            group  => 'deployment',
        }
        # Pull parsoid code. CTT updates the parsoid code
        # on demand T386246
        git::clone { 'mediawiki/services/parsoid':
            branch    => 'master',
            owner     => 'root',
            group     => 'wikidev',
            directory => '/srv/parsoid-testing',
            shared    => true,
        }

        rsync::quickdatacopy { 'releases':
            ensure      => present,
            auto_sync   => true,
            source_host => $deployment_server,
            dest_host   => $facts['networking']['fqdn'],
            module_path => $kubernetes_release_dir,
            chown       => 'mwdeploy:deployment',
            require     => File[$kubernetes_release_dir],
        }

        # fix-staging-perms is copied from profile::mediawiki::deployment::server
        # it fixes ownership and permissions of /srv/mediawiki
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
        $mw_experimental_update_script_name = 'mw-experimental-mediawiki-image-update'
        $mw_experimental_update_script_path = "/usr/local/sbin/${mw_experimental_update_script_name}"

        file { $mw_experimental_update_script_path:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => "puppet:///modules/profile/kubernetes/node/${mw_experimental_update_script_name}.sh",
        }

        systemd::timer::job { $mw_experimental_update_script_name:
            description => 'Update /srv/mediawiki with the latest mediawiki image every hour',
            command     => "${mw_experimental_update_script_path} -f",
            user        => 'root',
            team        => 'ServiceOps',
            require     => File[$mw_experimental_update_script_path],
            interval    => {
                'start'    => 'OnUnitActiveSec',
                'interval' => '1 hour',
            },
        }
        # TODO: check if the lock is active.
        $motd_content = "\nThis is a mw-experimental host. This k8s hosts only mw-experimental and mw-parsoid pods.  To ensure you have the latest code, you should:\n* login to the deployment server and run helmfile in helmfile.d/services/mw-experimental (or mw-parsoid)\n* refresh /srv/mediawiki on this host by running sudo systemctl restart mw-experimental-mediawiki-image-update.service.\n\n"
        motd::message { 'mw-experimental-tldr':
            ensure   => present,
            priority => 99,
            message  => $motd_content,
        }
    }
}
