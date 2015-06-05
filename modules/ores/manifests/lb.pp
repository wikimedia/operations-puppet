# Simple nginx HTTP load balancer for ores
class ores::lb(
    $realservers,
    $cache,
) {
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
        content => template('ores/lb.nginx.erb'),
    }
}
