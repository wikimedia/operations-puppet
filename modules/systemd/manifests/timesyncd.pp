# @summary class to configure systemd timesyncd
# @param ntp_servers list of ntpr_servers
# @param ensure if we should ensure the class
class systemd::timesyncd (
    Array[Stdlib::Host] $ntp_servers,
    Wmflib::Ensure      $ensure = 'present',
) {
    # only purge ntp if we are ensuring timesyncd
    if $ensure == 'present' {
        ensure_packages(['ntp'], {'ensure' => 'purged'})
        ensure_packages(['systemd-timesyncd'])
        Package['systemd-timesyncd'] -> File['/etc/systemd/timesyncd.conf']
    }

    file { '/etc/systemd/timesyncd.conf':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('systemd/timesyncd.conf.erb'),
    }

    # Ideally we could just rely on stdlib::ensure below. However this causes an error
    # if the service is absented as in this case there is no systemd-timesync service
    # available to manage.
    if $ensure == 'present' {
        service { 'systemd-timesyncd':
            ensure => stdlib::ensure($ensure, 'service'),
            enable => true,
        }
        File['/etc/systemd/timesyncd.conf'] ~> Service['systemd-timesyncd']
    }
}
