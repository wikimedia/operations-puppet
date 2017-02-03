# Simple nginx HTTP load balancer for ores
#
# filtertags: labs-project-ores
class role::labs::ores::lb {
    labs_lvm::volume { 'srv':
        mountat => '/srv',
    }
    $realservers = hiera('role::labs::ores::lb::realservers')
    $cache = str2bool(hiera('role::labs::ores::lb::cache', ''))

    if $cache {
        file { [
            '/srv/nginx/',
            '/srv/nginx/cache',
            '/srv/nginx/tmp',
        ]:
            ensure => directory,
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0775',
        }
    }
    nginx::site { 'ores-lb':
        content => template('role/ores/lb.nginx.erb'),
        require => Labs_lvm::Volume['srv'],
    }
}
