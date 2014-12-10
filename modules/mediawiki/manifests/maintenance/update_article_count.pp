
class mediawiki::maintenance::update_article_count( $ensure = present ) {
    cron { 'update_article_count':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-article-count /usr/local/bin/update-article-count > /var/log/mediawiki/updateArticleCount.log 2>&1',
        user     => $::mediawiki::users::web,
        monthday => 29,
        hour     => 5,
        minute   => 0,
    }

    file { '/usr/local/bin/update-article-count':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/update-article-count',
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0755',
    }
}

