class mediawiki::maintenance::generatecaptcha( $ensure = present ) {

    file { '/etc/fancycaptcha':
        ensure => 'directory',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/fancycaptcha/words':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => secret('fancycaptcha/words');
    }

    file { '/etc/fancycaptcha/badwords':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => secret('fancycaptcha/badwords');
    }

    file { '/var/log/mediawiki/generate-fancycaptcha':
        ensure => ensure_directory($ensure),
        mode   => '0775',
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
    }

    file { '/usr/local/bin/captchaloop':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/mediawiki/captchaloop',
    }

    $log_ownership_user = $::mediawiki::users::web
    $log_ownership_group = $::mediawiki::users::web
    logrotate::conf { 'generate-fancycaptcha':
        ensure  => $ensure,
        content => template('mediawiki/maintenance/logrotate.d_generate-fancycaptcha.erb'),
    }

    cron { 'generatecaptcha':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        weekday => 1,
        hour    => 1,
        minute  => 0,
        require => File['/etc/fancycaptcha/words', '/etc/fancycaptcha/badwords'],
        command => '/usr/local/bin/captchaloop >/var/log/mediawiki/generate-fancycaptcha/cron.log 2>&1',
    }
}
