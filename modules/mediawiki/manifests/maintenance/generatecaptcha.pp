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

    logrotate::conf { 'generate-fancycaptcha':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/logrotate.d_generate-fancycaptcha',
    }

    cron { 'generatecaptcha':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        monthday => 1,
        hour     => 1,
        minute   => 0,
        require  => File['/etc/fancycaptcha/words', '/etc/fancycaptcha/badwords'],
        command  => '/usr/local/bin/mwscript extensions/ConfirmEdit/maintenance/GenerateFancyCaptchas.php enwiki --wordlist=/etc/fancycaptcha/words --font=/usr/share/fonts/truetype/freefont/FreeMonoBoldOblique.ttf --blacklist=/etc/fancycaptcha/badwords --fill=10000 --oldcaptcha --delete >/var/log/mediawiki/generate-fancycaptcha/cron.log 2>&1',
    }
}
