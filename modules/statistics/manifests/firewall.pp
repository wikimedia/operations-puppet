# this class is setting firewall rules on stat[0-9] servers

class statistics::firewall  {
    if $::realm == 'production' {
        ferm::rule { 'redis_internal':
            rule => 'proto tcp dport 6379 { saddr $INTERNAL ACCEPT; }',
        }
    }
    # Labs has security groups, and as such, doesn't need firewall rules
}
