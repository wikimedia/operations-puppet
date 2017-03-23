# http://oss.oetiker.ch/smokeping/
class role::smokeping {

    system::role { 'smokeping': description => 'smokeping server' }

    include ::smokeping
    include ::smokeping::web

    ferm::service { 'smokeping-http':
        proto => 'tcp',
        port  => '80',
    }

    backup::set {'smokeping': }

}

