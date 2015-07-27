# vim:sw=4 ts=4 sts=4 et:
@monitoring::group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions Logstash and ElasticSearch.
#
class role::logstash {
    include standard
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check
    include ::logstash

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }

    # TODO: setup repo for this
    #package { 'logstash/plugins':
    #    provider => 'trebuchet',
    #}

    logstash::plugin { 'logstash-filter-prune':
        ensure  => 'present',
        gem     => '/srv/deployment/logstash/plugins/logstash-filter-prune-0.1.5.gem',
        #require => Package['logstash/plugins'],
    }

    ## Inputs (10)

    logstash::input::udp2log { 'mediawiki':
        port => 8324,
    }

    logstash::input::syslog { 'syslog':
        port => 10514,
    }

    logstash::input::gelf { 'gelf':
        port => 12201,
    }

    ## Global pre-processing (15)

    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    ## Input specific processing (20)

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///files/logstash/filter-syslog.conf',
        priority => 20,
    }

    logstash::conf { 'filter_udp2log':
        source   => 'puppet:///files/logstash/filter-udp2log.conf',
        priority => 20,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///files/logstash/filter-gelf.conf',
        priority => 20,
    }

    ## Application specific processing (50)

    logstash::conf { 'filter_mediawiki':
        source   => 'puppet:///files/logstash/filter-mediawiki.conf',
        priority => 50,
    }

    ## Global post-processing (70)

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///files/logstash/filter-add-normalized-message.conf',
        priority => 70,
    }

    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/elasticsearch-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        guard_condition => '"es" in [tags]',
        manage_indices  => true,
        priority        => 90,
        template        => '/etc/logstash/elasticsearch-template.json',
        require         => File['/etc/logstash/elasticsearch-template.json'],
    }
}

# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include standard
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }
}

# == Class: role::logstash::puppetreports
#
# Set up a TCP listener to listen for puppet failure reports.
class role::logstash::puppetreports {
    require ::role::logstash

    if $::realm != 'labs' {
        # Constrain to only labs, security issues in prod have not been worked out yet
        fail('role::logstash::puppetreports may only be deployed to Labs.')
    }

    logstash::input::tcp { 'tcp_json':
        port  => 5229,
        codec => 'json_lines',
    }

    logstash::conf { 'filter_puppet':
        source   => 'puppet:///files/logstash/filter-puppet.conf',
        priority => 50,
    }
}


# == Class: role::logstash::apifeatureusage
#
# Builds on role::logstash to insert sanitized data for
# Extension:ApiFeatureUsage into Elasticsearch.
#
class role::logstash::apifeatureusage {
    include ::role::logstash

    # FIXME: make this a param and use hiera to vary by realm
    $host            = $::realm ? {
        'production' => '10.2.2.30', # search.svc.eqiad.wmnet
        'labs'       => 'deployment-elastic05', # Pick one at random
    }

    # Template for Elasticsearch index creation
    file { '/etc/logstash/apifeatureusage-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/apifeatureusage-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///files/logstash/filter-apifeatureusage.conf',
        priority => 55,
    }

    # Output destined for separate Elasticsearch cluster from Logstash cluster
    logstash::output::elasticsearch { 'apifeatureusage':
        host            => $host,
        guard_condition => '[type] == "api-feature-usage-sanitized"',
        manage_indices  => true,
        priority        => 95,
        template        => '/etc/logstash/apifeatureusage-template.json',
        require         => File['/etc/logstash/apifeatureusage-template.json'],
    }
}

# == Class: role::logstash::stashbot
#
# Configure logstash to record IRC channel messages
#
# == Parameters:
# [*irc_user*]
#   IRC username
#
# [*irc_pass*]
#   IRC password
#
# [*irc_nick*]
#   IRC nick
#
# [*irc_real*]
#   IRC real name
#
# [*channels*]
#   List of channels to join and log
#
class role::logstash::stashbot (
    $irc_user = 'stashbot',
    $irc_pass = undef,
    $irc_nick = 'stashbot',
    $irc_real = 'Wikimedia Tool Labs IRC bot',
    $channels = [],
) {
    include standard
    include ::logstash

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }

    logstash::input::irc { 'freenode':
        user     => $irc_user,
        password => $irc_pass,
        nick     => $irc_nick,
        real     => $irc_real,
        channels => $channels,
    }

    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    logstash::conf { 'filter_stashbot':
        source   => 'puppet:///files/logstash/filter-stashbot.conf',
        priority => 20,
    }

    logstash::conf { 'filter_stashbot_sal':
        source   => 'puppet:///files/logstash/filter-stashbot-sal.conf',
        priority => 50,
    }

    logstash::conf { 'filter_stashbot_bash':
        source   => 'puppet:///files/logstash/filter-stashbot-bash.conf',
        priority => 50,
    }

    file { '/etc/logstash/stashbot-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        index           => "stashbot-%{+YYYY.MM}",
        guard_condition => '"es" in [tags]',
        priority        => 90,
        template        => '/etc/logstash/stashbot-template.json',
        require         => File['/etc/logstash/stashbot-template.json'],
    }

    # Special indexing for SAL messages
    file { '/etc/logstash/stashbot-sal-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-sal-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'sal':
        host            => $host,
        index           => 'sal',
        guard_condition => '[type] == "sal"',
        priority        => 95,
        template        => '/etc/logstash/stashbot-sal-template.json',
        require         => File['/etc/logstash/stashbot-sal-template.json'],
    }

    # Special indexing for bash messages
    file { '/etc/logstash/stashbot-bash-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-bash-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'bash':
        host            => $host,
        index           => 'bash',
        guard_condition => '[type] == "bash"',
        priority        => 95,
        template        => '/etc/logstash/stashbot-bash-template.json',
        require         => File['/etc/logstash/stashbot-bash-template.json'],
    }
}

