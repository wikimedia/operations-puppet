# == Define: diamond::collector::nginx
#
# Provisions an Nginx site that reports server metrics to local clients
# and configures the Diamond NginxCollector to poll it.
#
# See <https://github.com/BrightcoveOS/Diamond/wiki/collectors-NginxCollector>
#
# === Parameters
#
# [*port*]
#   Bind the Nginx status site to this port.
#
define diamond::collector::nginx(
    $ensure = present,
    $port   = 8080,
) {
    nginx::status_site { 'status':
        ensure => $ensure,
        port   => $port,
    }

    diamond::collector { 'Nginx':
        ensure   => 'absent',
        settings => {
            req_port => $port,
        },
    }
}
