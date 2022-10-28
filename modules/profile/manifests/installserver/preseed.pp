# SPDX-License-Identifier: Apache-2.0
# sets up preseeding dir and config on an install server
class profile::installserver::preseed {

    include install_server::preseed_server

    # Backup
    $sets = [ 'srv-autoinstall',
            ]
    backup::set { $sets : }

}
