# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::cleanup(
    Stdlib::Unixpath $miscdumpsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
) {
    class {'::dumps::web::cleanup':
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        user         => 'dumpsgen',
    }
}
