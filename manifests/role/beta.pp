# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    include beta::autoupdater
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
    include ::beta::scap::target

    # Allow ssh inbound from deployment-bastion.eqiad.wmflabs for scap
    ferm::rule { 'deployment-bastion-scap-ssh':
        ensure  => present,
        rule    => "proto tcp dport ssh saddr ${::beta::config::bastion_ip} ACCEPT;",
    }

    # FIXME: Each host that has this role applied must also be
    # manually added to the dsh group file found in
    # modules/beta/files/dsh/group/mediawiki-installation or scap will
    # not communicate with that host.
}

class role::beta::trebuchet_testing {
    system::role { 'role::beta::trebuchet_testing':
        description => 'Trebuchet testing host'
    }

    include ::beta::config
    include ::role::deployment::test

    # Allow ssh inbound from deployment-bastion.eqiad.wmflabs for testing
    ferm::rule { 'deployment-bastion-trebuchet-testing-ssh':
        ensure  => present,
        rule    => "proto tcp dport ssh saddr ${::beta::config::bastion_ip} ACCEPT;",
    }
}

class role::beta::appserver {
    system::role { 'role::beta::appserver': }

    include role::beta::scap_target

    include ::mediawiki
    include ::mediawiki::multimedia
    include standard
    include geoip

    include ::mediawiki::web
    include ::mediawiki::web::beta_sites

    monitoring::service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page',
    }

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => {
            'memcached' => {
                auto_eject_hosts     => true,
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                preconnect           => true,
                server_connections   => 2,
                server_failure_limit => 3,
                timeout              => 250,
                servers              => hiera('mediawiki_memcached_servers')
            },
        },
    }


    # Beta application servers have some ferm DNAT rewriting rules (bug
    # 45868) so we have to explicitly allow http (port 80)
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }
}

# = Class: role::beta::puppetmaster
# Add nice things to the beta puppetmaster.
class role::beta::puppetmaster {
    class { 'puppetmaster::reporter::logstash':
        logstash_host => 'deployment-logstash1.eqiad.wmflabs',
        logstash_port => 5229,
    }
}
