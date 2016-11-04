class mediawiki::maintenance::generatecaptcha( $ensure = present ) {
    cron { 'generatecaptcha':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        monthday => '*/1',
        hour    => 1,
        minute  => 0,
        command => '/usr/local/bin/mwscript extensions/ConfirmEdit/maintenance/GenerateFancyCaptchas.php aawiki --wordlist=/home/aaron/words --font=/usr/share/fonts/truetype/freefont/FreeMonoBoldOblique.ttf --blacklist /home/aaron/badwords --fill=10000 >/dev/null 2>&1',
    }
}
