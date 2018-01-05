# sets up the WMF annual report site
# https://annual.wikimedia.org/
# http://wikimediafoundation.org/wiki/Annual_Report
# T599 - https://15.wikipedia.org (aka. annual report 2015)
class profile::microsites::annualreport {

    httpd::site { 'annual.wikimedia.org':
        source => 'puppet:///modules/profile/annualreport/annual.wikimedia.org',
    }

    httpd::site { '15.wikipedia.org':
        source => 'puppet:///modules/profile/annualreport/15.wikipedia.org',
    }

    git::clone { 'wikimedia/annualreport':
        ensure    => 'latest',
        directory => '/srv/org/wikimedia/annualreport',
        branch    => 'master',
    }
}

