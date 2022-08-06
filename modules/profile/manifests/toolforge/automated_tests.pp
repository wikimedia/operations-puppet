# @summary sets up the toolforge automated test suite
# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::automated_tests () {
    class { 'cmd_checklist_runner': }
    class { 'toolforge::automated_toolforge_tests':
        envvars => {},
    }
}
