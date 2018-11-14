# Systemd fails to start/cleanup session scope under load, periodically cleanup as a bandaid.
# See also https://phabricator.wikimedia.org/T199911

class toil::systemd_scope_cleanup (
    Wmflib::Ensure $ensure = 'present',
) {
    cron { 'systemd_scope_cleanup':
        ensure  => $ensure,
        minute  => fqdn_rand(59, "toil_${title}"),
        hour    => '*',
        command => 'systemctl reset-failed \*.scope',
    }
}
