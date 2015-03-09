# vim: set sw=4 ts=4 expandtab:

class role::beta::bastion {
    system::role { 'role::beta::bastion':
        description => 'Bastion and work machine for beta cluster'
    }

    include beta::autoupdater
    include beta::syncsiteresources
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

# = Class: role::beta::puppetmaster
# Add nice things to the beta puppetmaster.
class role::beta::puppetmaster {
    class { 'puppetmaster::reporter::logstash':
        logstash_host => 'deployment-logstash1.eqiad.wmflabs',
        logstash_port => 5229,
    }
}
