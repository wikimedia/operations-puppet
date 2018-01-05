class mailman::listserve {
    package { 'mailman':
        ensure => present,
    }

    file { '/etc/mailman/mm_cfg.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mailman/mm_cfg.py',
    }

    debconf::set { 'mailman/site_languages':
        value  => 'sk, gl, fa, ast, ar, ca, cs, da, de, en, es, et, eu, fi, fr, he, hr, hu, ia, it, ja, ko, lt, nl, no, pl, pt, pt_BR, ro, ru, sl, sr, sv, tr, uk, vi, zh_CN, zh_TW',
        notify => Exec['dpkg-reconfigure mailman'],
    }

    debconf::set { 'mailman/default_server_language':
        value  => 'en',
        notify => Exec['dpkg-reconfigure mailman'],
    }

    exec { 'dpkg-reconfigure mailman':
        command     => '/usr/sbin/dpkg-reconfigure -fnoninteractive mailman',
        refreshonly => true,
        require     => Class['::profile::locales::extended'],
        before      => Service['mailman'],
    }

    service { 'mailman':
        ensure    => running,
        hasstatus => false,
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman/mm_cfg.py'],
    }
}
