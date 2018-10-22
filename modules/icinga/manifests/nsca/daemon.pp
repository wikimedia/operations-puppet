# = Class: icinga::nsca::daemon
#
# Sets up an NSCA daemon for listening to passive check
# results from hosts
class icinga::nsca::daemon (
    $icinga_user,
    $icinga_group,
){

    package { 'nsca':
        ensure => 'present',
    }

    include ::passwords::icinga
    $nsca_decrypt_password = $::passwords::icinga::nsca_decrypt_password

    file { '/etc/nsca.cfg':
        content => template('icinga/nsca.cfg.erb'),
        owner   => 'root',
        mode    => '0400',
        require => Package['nsca'],
    }

    if os_version('debian >= stretch') {

        systemd::service { 'nsca':
            ensure  => 'present',
            content => systemd_template('nsca'),
            require => File['/etc/nsca.cfg'],
        }

    # FIXME: remove after we are off jessie
    } else {

        service { 'nsca':
            ensure  => running,
            require => File['/etc/nsca.cfg'],
        }
    }
}
