# SPDX-License-Identifier: Apache-2.0
class profile::puppetserver::backup {
    include profile::backup::host
    backup::set { 'etc-puppet-puppetserver-ca': }
    backup::set { 'srv-puppet_fileserver-volatile': }
}
