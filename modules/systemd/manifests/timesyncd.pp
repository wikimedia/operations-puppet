# @summary class to configure systemd timesyncd
# @param ntp_servers list of ntpr_servers
# @param ensure if we should ensure the class
class systemd::timesyncd (
    Array[Stdlib::Host] $ntp_servers,
    Wmflib::Ensure      $ensure = 'present',
) {
    # only purge ntp if we are ensuring timesyncd
    if $ensure == 'present' {
        package { 'ntp':
            ensure => purged,
        }
    }

    file { '/etc/systemd/timesyncd.conf':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('systemd/timesyncd.conf.erb'),
        notify  => Service['systemd-timesyncd'],
    }

    service { 'systemd-timesyncd':
        ensure => stdlib::ensure($ensure, 'service'),
        enable => true,
    }
}
