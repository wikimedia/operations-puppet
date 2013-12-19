# memcached/config.pp

class memcached::config ($memcached_size, $memcached_port, $memcached_ip, $memcached_options) {

    file {
        "/etc/memcached.conf":
            content => template("${module_name}/memcached.conf.erb"),
            owner => root,
            group => root,
            mode => 0644;
        "/etc/default/memcached":
            source => "puppet:///modules/${module_name}/memcached.default",
            owner => root,
            group => root,
            mode => 0444;
    }

}
