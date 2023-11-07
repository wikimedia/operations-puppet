# SPDX-License-Identifier: Apache-2.0
class profile::alertmanager::triage {
    class { 'alertmanager::triage':
        prefix => '/triage',
    }
}
