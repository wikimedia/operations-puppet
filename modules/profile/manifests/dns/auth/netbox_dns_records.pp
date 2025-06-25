# SPDX-License-Identifier: Apache-2.0
# @ summary syncronize dns zone files generated from Netbox data
#
class profile::dns::auth::netbox_dns_records (
    Stdlib::HTTPSUrl    $netbox_dns_records_repo = lookup('profile::dns::netbox::gitrepo'),
    Stdlib::Unixpath    $netbox_dns_records_dir  = lookup('profile::dns::netbox::netbox_dns_records::dir'),
) {
    file { dirname($netbox_dns_records_dir):
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }


    git::clone { $netbox_dns_records_dir:
        directory => $netbox_dns_records_dir,
        origin    => $netbox_dns_records_repo,
        branch    => 'master',
        timeout   => 600,   # 10 minutes
    }

}

