# == Class: beta::scap::rsync_slave
#
# Provisions scap components for a scap slave rsync server.
#
class beta::scap::rsync_slave {
    include ::beta::config
    include ::beta::scap::target
    include rsync::server

    # Run an rsync server
    rsync::server::module { 'common':
        path        => $::beta::config::scap_deploy_dir,
        read_only   => 'yes',
        hosts_allow => $::beta::config::rsync_networks,
    }

    file { '/usr/local/apache':
        ensure  => directory,
    }
}
