# Simple nginx HTTP load balancer for ores
class ores::lb(
    $realservers,
) {
    nginx::site { 'ores-lb':
        content => template('ores/lb.nginx.erb'),
    }
}
