# TODO: define this
# old lost CA, need to remove from all over
class certificates::wmf_ca {

    include certificates::base

    file { '/usr/local/share/ca-certificates/wmf-ca.crt':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/ssl/wmf-ca.crt',
        require => Package['openssl'],
        notify  => Exec['update-ca-certificates'],
    }

}

