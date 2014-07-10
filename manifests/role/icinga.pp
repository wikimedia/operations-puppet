class role::icinga {

    system::role { 'role::icinga': description => 'icinga server' }

    class { '::icinga':
        site_name => 'icinga.wikimedia.org',
    }

}
