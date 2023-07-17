# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::server::jobswatcher(
    $xmldumpspublicdir  = lookup('profile::dumps::xmldumpspublicdir'),
    $xmldumpsprivatedir = lookup('profile::dumps::xmldumpsprivatedir'),
    $ensure = lookup('profile::dumps::generation::server::jobswatcher'),
) {
    class {'::dumps::generation::server::jobswatcher':
        dumpsbasedir => $xmldumpspublicdir,
        locksbasedir => $xmldumpsprivatedir,
        user         => 'dumpsgen',
        ensure       => $ensure,
    }
}
