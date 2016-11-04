class mediawiki::maintenance::generatecaptcha( $ensure = present ) {
    file { '/etc/fancycaptcha/words':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => secret('fancycaptcha/words');
    }
    
    file { '/etc/fancycaptcha/badwords':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => secret('fancycaptcha/badwords');
    }
    
    cron { 'generatecaptcha':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        monthday => '*/1',
        hour     => 1,
        minute   => 0,
        command  => '/usr/local/bin/mwscript extensions/ConfirmEdit/maintenance/GenerateFancyCaptchas.php aawiki --wordlist=/etc/fancycaptcha/words --font=/usr/share/fonts/truetype/freefont/FreeMonoBoldOblique.ttf --blacklist=/etc/fancycaptcha/badwords --fill=10000 >/dev/null 2>&1',
    }
}
