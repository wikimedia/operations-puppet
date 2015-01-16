# vim: set ts=4 et sw=4:

class role::cxserver (
    $port = 8080,
) {
    system::role { 'role::cxserver':
        description => 'content translation server'
    }

    include ::cxserver

    monitoring::service { 'cxserver':
        description   => 'cxserver',
        check_command => "check_http_on_port!${port}",
    }
}

class role::cxserver::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where cxserver is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update cxserver whenever a
    # change is made on mediawiki/services/cxserver (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
