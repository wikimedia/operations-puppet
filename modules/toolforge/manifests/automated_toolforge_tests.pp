# SPDX-License-Identifier: Apache-2.0
class toolforge::automated_toolforge_tests (
    Hash $envvars,
) {
    wmflib::dir::mkdir_p('/etc/toolforge')

    file { '/etc/toolforge/automated-toolforge-tests.yaml':
        ensure  => present,
        content => template('toolforge/automated-toolforge-tests.yaml.erb'),
    }
}
