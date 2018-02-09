class smokeping::web {
    file { '/usr/share/smokeping/www/smokeping.fcgi':
        source => "puppet:///modules/${module_name}/smokeping.fcgi",
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    httpd::site { 'smokeping.wikimedia.org':
        source => 'puppet:///modules/smokeping/apache.conf',
    }
}
