# installs required packages for a planet-venus server
class planet_httpd::packages {

    if os_version('debian == jessie') {
        # the main package
        # prefer to update this manually
        package { 'planet-venus':
            ensure => 'present',
        }

        # XSLT 1.0 command line processor
        package { 'xsltproc':
            ensure => 'present',
        }
    }

    # planet-venus does not exist anymore in stretch
    # rawdog is another RSS aggregator using Python and Feedparser
    # to produce a "planet"-like static site
    if os_version('debian >= stretch') {
        # 'RSS Aggregator Without Delusions Of Grandeur'
        package { 'rawdog':
            ensure => 'present',
        }

        # PyTidyLib 0.2.1 or later (optional but strongly recommended)
        # python-libxml2 is needed for the xml archive plugin we will use
        # for rawdog.
        package { ['python-tidylib', 'python-libxml2']:
            ensure => 'present',
        }
    }
}
