# SPDX-License-Identifier: Apache-2.0
# @param enabled if the default_mail_relay is enabled
# @param template the template to use
# @param smarthosts a list of smarthosts that handle general mail
# @param mediawiki_smarthosts a list of smarthosts that handle midiawiki mail
class profile::mail::default_mail_relay (
    Boolean             $enabled              = lookup('profile::mail::default_mail_relay::enabled'),
    String              $template             = lookup('profile::mail::default_mail_relay::template'),
    Array[Stdlib::Fqdn] $smarthosts           = lookup('profile::mail::default_mail_relay::smarthosts'),
    Array[Stdlib::Fqdn] $mediawiki_smarthosts = lookup('profile::mail::default_mail_relay::mediawiki_smarthosts'),
) {
    if $enabled {
        class { 'exim4':
            queuerunner => 'combined',
            config      => template($template),
        }

        profile::auto_restarts::service { 'exim4': }
    }
}
