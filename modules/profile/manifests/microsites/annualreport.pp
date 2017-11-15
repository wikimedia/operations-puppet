# sets up the WMF annual report site
# https://annual.wikimedia.org/
# http://wikimediafoundation.org/wiki/Annual_Report
# T599 - https://15.wikipedia.org (aka. annual report 2015)
class profile::microsites::annualreport {

    include ::apache
    include ::apache::mod::headers

    ferm::service { 'annualreport_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    apache::site { 'annual.wikimedia.org':
        source => 'puppet:///modules/profile/annualreport/annual.wikimedia.org',
    }

    apache::site { '15.wikipedia.org':
        source => 'puppet:///modules/profile/annualreport/15.wikipedia.org',
    }

    git::clone { 'wikimedia/annualreport':
        ensure    => 'latest',
        directory => '/srv/org/wikimedia/annualreport',
        branch    => 'master',
    }
}

