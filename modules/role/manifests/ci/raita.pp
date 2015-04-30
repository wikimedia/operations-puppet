# Raita dashboard for displaying and taking action on Cucumber test results
# logged to Elasticsearch via MW-Selenium's custom logger.
#
class role::ci::raita {
    ensure_packages(['nodejs', 'npm'])

    include ::elasticsearch
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    $dir = '/srv/raita'
    $docroot = '/srv/raita/docroot'
    $index_url = 'http://127.0.0.1:9200/raita'

    system::role { 'role::ci::raita':
        description => 'Dashboard for Cucumber test results',
    }

    git::clone { 'integration/raita':
        ensure    => 'latest',
        directory => $dir,
        owner     => 'root',
        group     => 'www-data',
        mode      => '0755',
    }

    exec { 'raita import elasticsearch mappings':
        command => "/usr/bin/nodejs scripts/mappings.js import ${index_url}",
        unless  => "/usr/bin/nodejs scripts/mappings.js check ${index_url}",
        cwd     => $dir,
        require => [Class['elasticsearch'], Git::Clone['integration/raita']],
    }

    apache::site { 'raita.wmflabs.org':
        content => template('contint/apache/raita.wmflabs.org.erb'),
        require => Git::Clone['integration/raita'],
    }
}
