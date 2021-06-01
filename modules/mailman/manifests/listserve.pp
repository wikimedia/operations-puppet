class mailman::listserve (
    String $mailman_service_ensure = 'running'
) {

    package { 'mailman':
        ensure => absent,
    }

    file { '/etc/mailman/mm_cfg.py':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mailman/mm_cfg.py',
    }

    service { 'mailman':
        ensure    => $mailman_service_ensure,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman/mm_cfg.py'],
    }

    # to create random passwords for list password resets
    ensure_packages('pwgen')
}
