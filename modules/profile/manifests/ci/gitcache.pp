# SPDX-License-Identifier: Apache-2.0
class profile::ci::gitcache {
    file { '/srv/git':
        ensure => directory,
    }

    $repos = [
        'operations/puppet',
        'mediawiki/core',
        'mediawiki/vendor',
        'mediawiki/extensions/AbuseFilter',
        'mediawiki/extensions/Cite',
        'mediawiki/extensions/cldr',
        'mediawiki/extensions/Echo',
        'mediawiki/extensions/EventLogging',
        'mediawiki/extensions/MobileFrontend',
        'mediawiki/extensions/Scribunto',
        'mediawiki/extensions/TemplateData',
        'mediawiki/extensions/Translate',
        'mediawiki/extensions/VisualEditor',
        'mediawiki/extensions/Wikibase',
        'mediawiki/skins/MinervaNeue',
        'mediawiki/skins/Vector',
    ]

    $repos.each |$repo| {
        $repo_dir = "/srv/git/${repo}.git"
        ensure_resource('file', $repo_dir.dirname, { 'ensure' => 'directory' })
        ensure_resource('git::clone', $repo, {
            'directory' => $repo_dir,
            'bare' => true,
            }
        )
    }

    systemd::timer::job { 'operations-puppet':
        ensure      => absent,
        description => 'Regular jobs to update gitcache for operations/puppet',
        user        => 'root',
        command     => '/usr/bin/git -C /srv/git/operations/puppet.git fetch origin --prune +refs/heads/*:refs/heads/*',
        require     => Git::Clone['operations/puppet'],
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:00:00'},
    }

    $minute = fqdn_rand(60)

    systemd::timer::job { 'ci-gitcache-refresh':
        ensure      => present,
        description => 'Regular job to update the CI git cache',
        user        => 'root',
        command     => '/usr/bin/find /srv/git -type d -name \'*.git\' -exec git -C {} fetch origin --prune \'+refs/heads/*:refs/heads/*\' \;',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* 3:${minute}:00"},
    }

    systemd::timer::job { 'mediawiki-core':
        ensure      => absent,
        description => 'Regular jobs to update gitcache for mediawiki/core',
        user        => 'root',
        command     => '/usr/bin/git -C /srv/git/mediawiki/core.git fetch origin --prune +refs/heads/*:refs/heads/*',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:00:00'},
        require     => Git::Clone['mediawiki/core'],
    }
}
