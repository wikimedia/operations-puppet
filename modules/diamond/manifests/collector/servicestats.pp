# == Class: diamond::collector::servicestats
#
# ServiceStats will report system-level statistics for services ran by systemd
# and upstart. Default metrics include: CPU %, memory % and uptime.
#
# === Parameters
#
#   systemd_name: service name to be used with systemd, defaults to title
#   upstart_name: service name to be used with upstart, defaults to title
#
# === Examples
#
#   diamond::collector::servicestats { 'rsyslog': }

define diamond::collector::servicestats (
    $systemd_name = $title,
    $upstart_name = $title,
    $ensure = 'present',
) {
    validate_ensure($ensure)

    include ::diamond::collector::servicestats_lib

    file { "/etc/diamond/servicestats.d/${title}.conf":
      ensure  => $ensure,
      content => "[systemd]\nname=${systemd_name}\n[upstart]\nname=${upstart_name}\n",
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
    }
}

# support class, to be include'd multiple times
class diamond::collector::servicestats_lib {
    diamond::collector { 'ServiceStats':
        source   => 'puppet:///modules/diamond/collector/servicestats.py',
        settings => {
          initsystem => $::initsystem
        }
    }

    file { '/usr/share/diamond/collectors/servicestats/servicestats_lib.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/diamond/collector/servicestats_lib.py',
        require => Diamond::Collector['ServiceStats'],
    }

    file { '/etc/diamond/servicestats.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    package { ['python-psutil', 'python-configparser']:
        before => Diamond::Collector['ServiceStats'],
    }
}
