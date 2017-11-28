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

    # HACK systemd needs escaping for / in service names and carbonctl relies
    # on having everything in /etc/init/carbon. Remove once fully migrated to
    # jessie.
    if os_version('debian >= jessie') {
        $frontend_service_name = 'carbon-frontend-relay'
        $local_service_name = 'carbon-local-relay'
    } else {
        $frontend_service_name = 'carbon/frontend-relay'
        $local_service_name = 'carbon/local-relay'
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

    base::service_unit { $frontend_service_name:
        ensure  => present,
        upstart => upstart_template('frontend-relay'),
        systemd => systemd_template('frontend-relay'),
    }

    file { '/etc/carbon/frontend-relay.conf':
        content => template('graphite/frontend-relay.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$frontend_service_name],
    }

    base::service_unit { $local_service_name:
        ensure  => present,
        upstart => upstart_template('local-relay'),
        systemd => systemd_template('local-relay'),
    }

    file { '/etc/carbon/local-relay.conf':
        content => template('graphite/local-relay.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$local_service_name],
    }
}
