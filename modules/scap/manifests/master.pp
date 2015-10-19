# = class: scap::master
#
# Sets up a scap master (currently tin)
class scap::master(
    $common_path        = '/srv/mediawiki',
    $common_source_path = '/srv/mediawiki-staging',
    $rsync_host         = 'tin.eqiad.wmnet',
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

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    class { 'scap::l10nupdate':
        deployment_group => $deployment_group,
    }

    # Allow rsync of common module to mediawiki-staging as GID=wikidev
    # This is for master-master sync of /srv/mediawiki-staging
    sudo::user { 'scap-master-sync':
        user       => 'mwdeploy',
        privileges => [
            'ALL = (mwdeploy:wikidev) NOPASSWD: /usr/bin/rsync *\:\:common /srv/mediawiki-staging',
        ]
    }
}
