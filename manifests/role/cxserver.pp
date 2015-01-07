# vim: set ts=4 et sw=4:

class role::cxserver::production {
    system::role { 'role::cxserver::production':
        description => 'content translation server'
    }

    class { '::cxserver':
        base_path => '/srv/deployment/cxserver/cxserver',
        node_path => '/srv/deployment/cxserver/deploy/node_modules',
        conf_path => '/srv/deployment/cxserver/config.js',
        log_dir   => '/var/log/cxserver',
        parsoid   => 'http://parsoid-lb.eqiad.wikimedia.org',
        apertium  => 'http://apertium.svc.eqiad.wmnet',
    }

    # Define cxserver port
    $cxserver_port = '8080'

    # We have to explicitly open the cxserver port (bug T47868)
    ferm::service { 'cxserver_http':
        proto => 'tcp',
        port  => $cxserver_port,
    }

    monitoring::service { 'cxserver':
        description   => 'cxserver',
        check_command => "check_http_on_port!${cxserver_port}",
    }
}

class role::cxserver::beta {
    system::role { 'role::cxserver::beta':
        description => 'content translation server (on beta)'
    }

    class { '::cxserver':
        base_path => '/srv/deployment/cxserver/cxserver',
        node_path => '/srv/deployment/cxserver/deploy/node_modules',
        conf_path => '/srv/deployment/cxserver/config.js',
        log_dir   => '/data/project/cxserver/log',
        parsoid   => 'http://parsoid-lb.eqiad.wikimedia.org',
        apertium  => 'http://apertium-beta.wmflabs.org',
    }

    # Need to allow jenkins-deploy to reload cxserver
    sudo::user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service cxserver restart',
    ] }

    # Define cxserver port
    $cxserver_port = '8080'

    # We have to explicitly open the cxserver port (bug 45868)
    ferm::service { 'cxserver_http':
        proto => 'tcp',
        port  => $cxserver_port,
    }

    # Allow ssh access from the Jenkins master to the server where cxserver is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update cxserver whenever a
    # change is made on mediawiki/services/cxserver (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
