# == Class profile::kubernetes::mwautopull
#
# Sets up a timer to automatically pull the MediaWiki image every minute.
# This works around the staging cluster not having SSDs, so it can't pull
# and unpack the image without hitting Kubernetes timeouts. By having the
# image most likely already be present, it should be safe to use.
#
# See T284628 for more background on this issue.
class profile::kubernetes::mwautopull(
    Wmflib::Ensure $ensure = lookup('profile::kubernetes::mwautopull::ensure', {default_value => 'absent'}),
) {
    systemd::timer::job { 'mwautopull':
        ensure      => $ensure,
        description => 'Automatically pull the MediaWiki image',
        command     => '/usr/bin/docker --config /var/lib/kubelet pull docker-registry.discovery.wmnet/restricted/mediawiki-multiversion:latest',
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00', # every minute
        }
    }
}
