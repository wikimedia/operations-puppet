# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::server::exceptionchecker(
    $xmldumpsprivatedir = lookup('profile::dumps::xmldumpsprivatedir'),
    $ensure = lookup('profile::dumps::generation::server::exceptionchecker'),
) {
    class {'::dumps::generation::server::exceptionchecker':
        dumpsbasedir => $xmldumpsprivatedir,
        user         => 'dumpsgen',
        ensure       => $ensure,
    }
}
