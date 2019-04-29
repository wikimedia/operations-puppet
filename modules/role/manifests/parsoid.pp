# == Class: role::parsoid
#
# filtertags: labs-project-deployment-prep
class role::parsoid {

    system::role { 'parsoid':
        description => "Parsoid ${::realm}"
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::parsoid
}
