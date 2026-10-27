# installs required packages for a planet server
class planet::packages (
    String $user_agent = 'Wikimedia-Planet/1.0 (https://planet.wikimedia.org/; noc@wikimedia.org) rawdog',
) {

    # rawdog is a RSS aggregator using Python and Feedparser
    # to produce a "planet"-like static site
    # 'RSS Aggregator Without Delusions Of Grandeur'
    package { 'rawdog':
        ensure => present,
    }

    # The User-Agent is hardcoded in the package, no config option (T442071)
    file_line { 'planet_user_agent':
        path    => '/usr/lib/python3/dist-packages/rawdog/rawdog.py',
        match   => '^HTTP_AGENT = ',
        line    => "HTTP_AGENT = \"${user_agent}\"",
        require => Package['rawdog'],
    }

    # PyTidyLib 0.2.1 or later (optional but strongly recommended)
    # python-libxml2 is needed for the xml archive plugin we will use
    # for rawdog.
    stdlib::ensure_packages(['python3-tidylib','python3-libxml2'])
}
