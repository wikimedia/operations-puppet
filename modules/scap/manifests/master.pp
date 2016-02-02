# = class: scap::master
#
# Sets up a scap master (currently tin and mira)
class scap::master(
    $common_path        = '/srv/mediawiki',
    $common_source_path = '/srv/mediawiki-staging',
    $rsync_host         = "deployment.${::site}.wmnet",
    $statsd_host        = 'statsd.eqiad.wmnet',
    $statsd_port        = 8125,
    $deployment_group   = 'wikidev',
) {
    include scap::scripts
    include scap::dsh
    include rsync::server
    include network::constants
    include mediawiki::scap

    package { 'dsh':
        ensure => present,
    }

    git::clone { 'operations/mediawiki-config':
        ensure    => present,
        directory => $common_source_path,
        owner     => 'mwdeploy',
        group     => $deployment_group,
        shared    => true,
        before    => Exec['fetch_mediawiki'],
    }

    # Install the commit-msg hook from gerrit

    file { "${common_source_path}/.git/hooks/commit-msg":
        ensure  => present,
        owner   => 'mwdeploy',
        group   => $deployment_group,
        mode    => '0775',
        source  => 'puppet:///modules/scap/commit-msg-hook',
        require => Git::Clone['operations/mediawiki-config'],
    }

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    class { 'scap::l10nupdate':
        deployment_group => $deployment_group,
    }

    file { '/usr/local/bin/scap-master-sync':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/scap-master-sync',
    }

    # Allow rsync of common module to mediawiki-staging as root.
    # This is for master-master sync of /srv/mediawiki-staging
    sudo::user { 'scap-master-sync':
        user       => 'mwdeploy',
        privileges => [
            'ALL = (root) NOPASSWD: /usr/local/bin/scap-master-sync',
        ]
    }
}
