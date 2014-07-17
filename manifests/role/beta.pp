# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    include beta::autoupdater
    include beta::fatalmonitor
    include beta::syncsiteresources

    # Bring scap related scripts such as mw-update-l10n
    include ::beta::scap::master

    file { '/data/project/apache':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
    }
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
    system::role { 'role::beta::rsync_slave':
        description => 'Scap rsync fanout server'
    }

    require ::role::labs::lvm::srv
    include ::beta::scap::rsync_slave

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/scap-proxies or scap will
    # not communicate with that host.
}

# Class: role::beta::scap_target
#
# Provision a target host for scap in beta
#
class role::beta::scap_target {
    system::role { 'role::beta::scap_target':
        description => 'Scap deployment target'
    }

    require ::role::labs::lvm::srv
    include ::beta::common
    include ::beta::scap::target

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/mediawiki-installation or scap will
    # not communicate with that host.
}

class role::beta::appserver {
    system::role { 'role::beta::appserver': }

    include role::beta::scap_target

    include ::mediawiki
    include ::mediawiki::multimedia
    include standard
    include geoip

    include ::beta::common

    class { '::mediawiki::syslog':
        apache_log_aggregator => 'deployment-bastion.eqiad.wmflabs:8420',
    }

    class { '::mediawiki::php':
        fatal_log_file => 'udp://deployment-bastion.eqiad.wmflabs:8420',
    }

    class { '::mediawiki::web': }

    # bug 38996 - Apache service does not run on start, need a fake
    # sync to start it up though don't bother restarting it is already
    # running.
    exec { 'beta_apache_start':
        command => '/etc/init.d/apache2 start',
        unless  => '/bin/ps -C apache2',
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
}

class role::beta::videoscaler {
    include role::beta::scap_target
    include role::mediawiki::videoscaler
}

class role::beta::jobrunner {
    include role::beta::scap_target
    include role::mediawiki::common

    class { '::mediawiki::jobrunner':
        aggr_servers  => [ '10.68.16.146' ],
        queue_servers => [ '10.68.16.146' ],
    }
}
