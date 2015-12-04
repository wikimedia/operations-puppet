class smokeping::web {
    file { '/usr/share/smokeping/www/smokeping.fcgi':
        source => "puppet:///modules/${module_name}/smokeping.fcgi",
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    include ::apache::mod::fcgid
    include ::apache::mod::headers

    apache::site { 'smokeping.wikimedia.org':
        source => 'puppet:///modules/smokeping/apache.conf',
    }
}
