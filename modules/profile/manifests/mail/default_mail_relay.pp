class profile::mail::default_mail_relay {
    class { '::exim4':
        queuerunner => 'combined',
        config      => template("standard/mail/exim4.minimal.${::realm}.erb"),
    }

    profile::auto_restarts::service { 'exim4': }
}
