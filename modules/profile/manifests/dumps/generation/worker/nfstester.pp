# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::worker::nfstester(
    $php = lookup('profile::dumps::generation_worker_cron_php'),
) {
    class { '::snapshot::dumps::nfstester':
        user    => 'dumpsgen',
        group   => 'www-data',
        homedir => '/var/lib/dumpsgen',
    }
}
