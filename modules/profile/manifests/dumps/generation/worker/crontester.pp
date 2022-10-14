# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::worker::crontester(
    $php = lookup('profile::dumps::generation_worker_cron_php'),
) {
    class { '::snapshot::systemdjobs':
        miscdumpsuser => 'dumpsgen',
        group         => 'www-data',
        filesonly     => true,
        php           => $php,
    }
}
