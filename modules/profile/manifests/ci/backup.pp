# SPDX-License-Identifier: Apache-2.0
class profile::ci::backup {
    require ::profile::backup::host

    backup::set { 'contint' : }
}
