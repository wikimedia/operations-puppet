# installs required packages for a planet server
class planet::packages {

    # rawdog is a RSS aggregator using Python and Feedparser
    # to produce a "planet"-like static site
    # 'RSS Aggregator Without Delusions Of Grandeur'
    package { 'rawdog':
        ensure => present,
    }

    # PyTidyLib 0.2.1 or later (optional but strongly recommended)
    # python-libxml2 is needed for the xml archive plugin we will use
    # for rawdog.
    ensure_packages(['python3-tidylib','python3-libxml2'])
}
