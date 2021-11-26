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
        # On systemd >247.3-6~bpo10+1 at least this service is handled by the systemd-timesyncd package
        # before it was installed by systemd
        if (debian::codename::ge('bullseye')) {
            ensure_packages(['systemd-timesyncd'])
            Package['systemd-timesyncd'] -> File['/etc/systemd/timesyncd.conf']
        }
    }

    file { '/etc/systemd/timesyncd.conf':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('systemd/timesyncd.conf.erb'),
    }

    # Ideally we could just rely on stdlib::ensure below. However this causes an error when:
    # * ensure => 'absent'
    # * debian::codename::ge bullseye
    # As in this case there is no systemd-timesync service available to manage.
    if (defined(Package['systemd-timesyncd']) or $ensure == 'present') {
        service { 'systemd-timesyncd':
            ensure => stdlib::ensure($ensure, 'service'),
            enable => true,
        }
        File['/etc/systemd/timesyncd.conf'] ~> Service['systemd-timesyncd']
    }
}
