class profile::mail::default_mail_relay (
    Boolean $enabled = lookup('profile::mail::default_mail_relay::enabled')
) {
    if $enabled {
        class { 'exim4':
            queuerunner => 'combined',
            config      => template("standard/mail/exim4.minimal.${::realm}.erb"),
        }

        profile::auto_restarts::service { 'exim4': }
    }
}
