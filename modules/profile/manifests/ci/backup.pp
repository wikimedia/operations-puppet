# SPDX-License-Identifier: Apache-2.0
class profile::ci::backup {
    require ::profile::backup::host

    backup::set {'var-lib-jenkins-config': }
    backup::set { 'contint' : }
}
