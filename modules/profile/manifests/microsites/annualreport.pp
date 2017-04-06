# https://annual.wikimedia.org/
# microsite for the WMF annual report
# http://wikimediafoundation.org/wiki/Annual_Report
class profile::microsites::annualreport {

    include ::annualreport

    include ::base::firewall

    ferm::service { 'annualreport_http':
        proto => 'tcp',
        port  => '80',
    }

}

