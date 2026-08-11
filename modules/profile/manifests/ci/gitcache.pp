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
        'mediawiki/extensions/AntiSpoof',
        'mediawiki/extensions/Babel',
        'mediawiki/extensions/BetaFeatures',
        'mediawiki/extensions/CampaignEvents',
        'mediawiki/extensions/CheckUser',
        'mediawiki/extensions/CirrusSearch',
        'mediawiki/extensions/Cite',
        'mediawiki/extensions/CiteThisPage',
        'mediawiki/extensions/cldr',
        'mediawiki/extensions/CodeEditor',
        'mediawiki/extensions/CommunityConfiguration',
        'mediawiki/extensions/CommunityConfigurationExample',
        'mediawiki/extensions/ConfirmEdit',
        'mediawiki/extensions/ContentTranslation',
        'mediawiki/extensions/Disambiguator',
        'mediawiki/extensions/Echo',
        'mediawiki/extensions/Elastica',
        'mediawiki/extensions/EventBus',
        'mediawiki/extensions/EventLogging',
        'mediawiki/extensions/EventStreamConfig',
        'mediawiki/extensions/FileImporter',
        'mediawiki/extensions/Gadgets',
        'mediawiki/extensions/GeoData',
        'mediawiki/extensions/GlobalCssJs',
        'mediawiki/extensions/GlobalPreferences',
        'mediawiki/extensions/GrowthExperiments',
        'mediawiki/extensions/GuidedTour',
        'mediawiki/extensions/ImageMap',
        'mediawiki/extensions/InputBox',
        'mediawiki/extensions/Interwiki',
        'mediawiki/extensions/IPInfo',
        'mediawiki/extensions/JsonConfig',
        'mediawiki/extensions/Kartographer',
        'mediawiki/extensions/Math',
        'mediawiki/extensions/MediaModeration',
        'mediawiki/extensions/MobileApp',
        'mediawiki/extensions/MobileFrontend',
        'mediawiki/extensions/NavigationTiming',
        'mediawiki/extensions/PageImages',
        'mediawiki/extensions/PageTriage',
        'mediawiki/extensions/PageViewInfo',
        'mediawiki/extensions/ParserFunctions',
        'mediawiki/extensions/PdfHandler',
        'mediawiki/extensions/Poem',
        'mediawiki/extensions/ProofreadPage',
        'mediawiki/extensions/ReadingLists',
        'mediawiki/extensions/SandboxLink',
        'mediawiki/extensions/Scribunto',
        'mediawiki/extensions/SiteMatrix',
        'mediawiki/extensions/SpamBlacklist',
        'mediawiki/extensions/TemplateData',
        'mediawiki/extensions/Thanks',
        'mediawiki/extensions/TimedMediaHandler',
        'mediawiki/extensions/Translate',
        'mediawiki/extensions/UniversalLanguageSelector',
        'mediawiki/extensions/VisualEditor',
        'mediawiki/extensions/Wikibase',
        'mediawiki/extensions/WikibaseCirrusSearch',
        'mediawiki/extensions/WikibaseMediaInfo',
        'mediawiki/extensions/WikiEditor',
        'mediawiki/extensions/WikiLove',
        'mediawiki/extensions/WikimediaCampaignEvents',
        'mediawiki/extensions/WikimediaMessages', # Takes 13s to resolve deltas
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
