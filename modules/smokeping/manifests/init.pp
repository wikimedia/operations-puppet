# SmokePing - monitor network latency
# https://oss.oetiker.ch/smokeping
# https://github.com/oetiker/SmokePing
#
# parameters: $active_server
# In a multi-server setup, set $active_server to the FQDN
# of the server that should run the smokeping service
# and be the rsync source of RRD files.
class smokeping(
    Stdlib::Fqdn $active_server,
) {

    require_package('smokeping', 'dnsutils')

    file { '/etc/smokeping/config.d':
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/smokeping/config.d',
        require => Package['smokeping'],
    }

    if $active_server == $::fqdn {
        $service_ensure = 'running'
    } else {
        $service_ensure = 'stopped'
    }

    service { 'smokeping':
        ensure    => $service_ensure,
        require   => [
            Package['smokeping'],
            File['/etc/smokeping/config.d'],
        ],
        subscribe => File['/etc/smokeping/config.d'],
    }
}
