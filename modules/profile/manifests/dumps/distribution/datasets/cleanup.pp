# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::cleanup(
    Boolean $isreplica = lookup('profile::dumps::distribution::datasets::cleanup::isreplica'),
    Stdlib::Unixpath $miscdumpsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $dumpstempdir = lookup('profile::dumps::distribution::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
