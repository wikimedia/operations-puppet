# SPDX-License-Identifier: Apache-2.0
# == Class: profile::beta::autoupdater
#
# Update MediaWiki based on a timer.
#
# === Parameters:
# [*update_interval*]
#   How often to run the update script as a systemd timer OnCalendar interval
#   (default: '*:0/10', every 10 minutes)
#
# [*run_updater*]
#   Run the update script on this node?
#   (default: false)
#
# [*apache_fqdn*]
#   Name of vhost responsible for exposing logs to the world
#   (default: beta-update.wmcloud.org)
#
# [*alert_on_failure*]
#   Send email alerts when the update job fails
#
# [*notify_email*]
#   Email address to notify when alert_on_failure=true and job fails
#
# [*max_runtime_seconds*]
#   Kill the update job if it runs longer than this many seconds
#   (default: 3600, i.e. 60 minutes)
#
class profile::beta::autoupdater(
    String        $update_interval     = lookup('profile::beta::autoupdater::update_interval', {'default_value' => '*:0/10'}),
    Boolean       $run_updater         = lookup('profile::beta::autoupdater::run_updater', {'default_value' => false}),
    String        $apache_fqdn         = lookup('profile::beta::autoupdater::apache_fqdn', {'default_value' => 'beta-update.wmcloud.org'}),
    Boolean       $alert_on_failure    = lookup('profile::beta::autoupdater::alert_on_failure', {'default_value' => true}),
    Stdlib::Email $notify_email        = lookup('profile::beta::autoupdater::notify_email', {'default_value' => 'releng@lists.wikimedia.org'}),
    Integer       $max_runtime_seconds = lookup('profile::beta::autoupdater::max_runtime_seconds', {'default_value' => 3600}),
) {
    class { '::beta::autoupdater':
        update_interval     => $update_interval,
        run_updater         => $run_updater,
        apache_fqdn         => $apache_fqdn,
        alert_on_failure    => $alert_on_failure,
        notify_email        => $notify_email,
        max_runtime_seconds => $max_runtime_seconds,
        require             => Class['::scap::scripts'],
    }
}
