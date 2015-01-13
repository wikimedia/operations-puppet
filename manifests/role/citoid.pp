# vim: set ts=4 et sw=4:
class role::citoid {
    system::role { 'role::citoid': }

    include ::citoid

    monitoring::service { 'citoid':
        description   => 'citoid',
        check_command => 'check_http_on_port!1970',
    }

    # Beta citoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow citoid port 1970
    ferm::service { 'citoid':
        proto => 'tcp',
        port  => '1970',
    }
}

class role::citoid::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where citoid is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update citoid whenever a
    # change is made on mediawiki/services/citoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
