# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    class { 'misc::maintenance::geodata': enabled => true }

    include beta::autoupdater
    include beta::fatalmonitor
    include beta::syncsiteresources

    # Bring scap related scripts such as mw-update-l10n
    include ::beta::scap::master

}

# To be applied on deployment-upload.eqiad.wmflabs
# Queried by Varnish upload cache whenever we need to serve thumbnails
# There is a hacked nginx on it and a php5 cgi service
class role::beta::uploadservice {

    system::role { 'role::beta::uploadservice':
        description => 'Upload/thumbs backend used by Varnish'
    }

    ferm::rule { 'allow_http':
        rule => 'proto tcp dport http ACCEPT;'
    }

}

# Should be applied on any instance that needs to access DNS entries pointing
# back to the beta cluster. This should be applied at a minimum on any instance
# running MediaWiki.
#
# WARNING: this will enable firewall (managed by ferm) with a default DROP policy
class role::beta::natfix {
    system::role { 'role::beta::natfix':
        description => 'Server has beta NAT fixup'
    }

    include ::beta::natfix
}

# Class: role::beta::rsync_slave
#
# Provision an rsync slave server for scap in beta
#
class role::beta::rsync_slave {
    include labs_lvm

    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
    }

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/mediawiki-installation or scap will
    # not communicate with that host.
    class { '::beta::scap::rsync_slave':
        require => Labs_lvm::Volume['second-local-disk'],
    }
}


class role::beta::appserver {
    system::role { 'role::beta::appserver': }

    include ::mediawiki
    include standard
    include geoip

    include ::beta::hhvm

    include ::imagescaler::cron
    include ::imagescaler::packages
    include ::imagescaler::files


    class { '::mediawiki::syslog':
        apache_log_aggregator => 'deployment-bastion.eqiad.wmflabs:8420',
    }

    class { '::mediawiki::php':
        fatal_log_file => 'udp://deployment-bastion.eqiad.wmflabs:8420',
    }

    class { '::mediawiki::web':
        maxclients => $maxclients,
    }

    monitor_service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page',
    }

    # Beta application servers have some ferm DNAT rewriting rules (bug
    # 45868) so we have to explicitly allow http (port 80)
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/mediawiki-installation or scap will
    # not communicate with that host.
    class { '::beta::scap::target':
        require => Labs_lvm::Volume['second-local-disk'],
    }

    include labs_lvm

    # Eqiad instances do not mount additional disk space
    labs_lvm::volume { 'second-local-disk': mountat => '/srv' }
}
