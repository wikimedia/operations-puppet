# == Class: graphite::carbon_c_relay
#
# This class configures carbon-c-relay to take carbon-relay's place in
# routing metrics around using line-protocol.
#
# Two copies of carbon-c-relay are run:
# * local-relay: takes metrics on port 1903 and forwards to all configured
# carbon-cache processes on the local machine ('carbon-cache' list in config)
# * frontend-relay: listen on standard port 2003 and mirror metrics to all
# configured backends ('backends' list in config).
#
# The frontend also supports metric tapping ('teeing' data inline) and
# metric routing (no duplication) to specific clusters. Respectively via
# 'cluster_tap' and 'cluster_routes' maps c_relay_settings.
#
class graphite::carbon_c_relay( $c_relay_settings ) {
    package { 'carbon-c-relay':
        ensure => present,
    }

    # make sure the global carbon-c-relay doesn't run
    file { '/etc/init/carbon-c-relay.override':
        content => "manual\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'carbon-c-relay':
        ensure   => stopped,
    }

    systemd::service { 'carbon-frontend-relay':
        ensure  => present,
        restart => true,
        content => systemd_template('frontend-relay'),
    }

    file { '/etc/carbon/frontend-relay.conf':
        content => template('graphite/frontend-relay.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['carbon-frontend-relay'],
    }

    systemd::service { 'carbon-local-relay':
        ensure  => present,
        restart => true,
        content => systemd_template('local-relay'),
    }

    file { '/etc/carbon/local-relay.conf':
        content => template('graphite/local-relay.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['carbon-local-relay'],
    }
}
