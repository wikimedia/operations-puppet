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
        'mediawiki/extensions/GrowthExperiments',
        'mediawiki/extensions/MobileFrontend',
        'mediawiki/extensions/Scribunto',
        'mediawiki/extensions/TemplateData',
        'mediawiki/extensions/Translate',
        'mediawiki/extensions/UniversalLanguageSelector',
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

    $minute = fqdn_rand(60)

    systemd::timer::job { 'ci-gitcache-refresh':
        ensure      => present,
        description => 'Regular job to update the CI git cache',
        user        => 'root',
        command     => '/usr/bin/find /srv/git -type d -name \'*.git\' -exec git -C {} fetch origin --prune --prune-tags --force \'+refs/heads/*:refs/heads/*\' \'+refs/tags/*:refs/tags/*\' \;',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* 3:${minute}:00"},
    }
}
