class role::phabricator {

    #This must exist git to be applicable
    $current_tag = 'rt7264'

    if $::realm == 'production' {

        class { '::phabricator':
            git_tag   => $current_tag,
            lock_file => '/var/run/phab_repo_lock',
            settings  => {
                'storage.upload-size-limit'          => '10M',
                'darkconsole.enabled'                => false,
                'phabricator.base-uri'               => 'http://phabricator.wikimedia.org',
                'metamta.mail-adapter'               => 'PhabricatorMailImplementationPHPMailerAdapter',
                'phpmailer.mailer'                   => 'stmp',
                'phpmailer.smtp-port'                => "25",
                'phpmailer.smtp-host'                => 'mchenry.wikimedia.org',
                'mysql.host'                         => 'localhost',
                'mysql.pass'                         => 'foo',
                'phabricator.show-beta-applications' =>  true,
            },
        }
    }
}
