# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::email_verification_reminder(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    # Send monthly reminders to active users with an unverified email to verify their email address (T58074)
    # Argument to the script is the number of seconds in a month, used to ensure only users active
    # in the last month are notified.
    profile::mediawiki::periodic_job { 'email_verification_reminder':
        command                 => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/sendVerifyEmailReminderNotification.php --wiki=metawiki 2592000',
        interval                => '*-*-17 17:00',
        cron_schedule           => '0 17 17 * *',
        kubernetes              => true,
        team                    => $team,
        script_label            => 'sendVerifyEmailReminderNotification.php',
        description             => 'Send monthly reminders to active users with an unverified email to verify their email address (T58074).',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
}
