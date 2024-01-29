# SPDX-License-Identifier: Apache-2.0
# this class is for snapshot hosts that run fillin page content of dumps
# meaning wikidatawiki for page-meta-history dumps dumps during the full run
class profile::dumps::generation::worker::dumper_fillin_wd(
    $maxjobs = lookup('profile::dumps::generation::worker::dumper::maxjobs'),
    $parts_startend = lookup('profile::dumps::generation::worker::dumper::parts_startend'),
) {
    class { 'snapshot::dumps::dump_fillin_wd':
        user           => 'dumpsgen',
        maxjobs        => $maxjobs,
        parts_startend => $parts_startend,
    }
}
