# sets up the WMF annual report site - https://annual.wikimedia.org/
# T599 - https://15.wikipedia.org (aka. annual report 2015)
class annualreport {

    include ::apache
    include ::apache::mod::headers

    apache::site { 'annual.wikimedia.org':
        source => 'puppet:///modules/annualreport/annual.wikimedia.org',
    }

    apache::site { '15.wikipedia.org':
        source => 'puppet:///modules/annualreport/15.wikipedia.org',
    }

    git::clone { 'wikimedia/annualreport':
        ensure    => 'latest',
        directory => '/srv/org/wikimedia/annualreport',
        branch    => 'master',
    }
}
