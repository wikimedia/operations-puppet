# SPDX-License-Identifier: Apache-2.0
class profile::mail::default_mail_relay (
    Boolean $enabled  = lookup('profile::mail::default_mail_relay::enabled'),
    String  $template = lookup('profile::mail::default_mail_relay::template'),
) {
    if $enabled {
        class { 'exim4':
            queuerunner => 'combined',
            config      => template($template),
        }

        profile::auto_restarts::service { 'exim4': }
    }
}
