# SPDX-License-Identifier: Apache-2.0
# sets up preseeding dir and config on an install server
class profile::installserver::preseed(
    $preseed_per_ip = lookup('profile::installserver::preseed::preseed_per_ip', {'default_value' => {}}),
    $preseed_per_hostname = lookup('profile::installserver::preseed::preseed_per_hostname', {'default_value' => {}}),
){
    class { 'install_server::preseed_server':
        preseed_per_ip       => $preseed_per_ip,
        preseed_per_hostname => $preseed_per_hostname,
    }

    # Backup
    $sets = [ 'srv-autoinstall',
            ]
    backup::set { $sets : }

}
