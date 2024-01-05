# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::mediamoderation {
    # push periodically-computed metrics into statsd (T353703)
    profile::mediawiki::periodic_job { 'mediamoderation-updateMetrics':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/all.dblist extensions/MediaModeration/maintenance/updateMetrics.php --verbose',
        interval => '*-*-* 04:32:00',
    }
}
