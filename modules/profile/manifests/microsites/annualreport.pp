# https://annual.wikimedia.org/
# microsite for the WMF annual report
# http://wikimediafoundation.org/wiki/Annual_Report
class profile::microsites::annualreport {

    system::role { 'role::microsites::annualreport': description => 'WMF Annual report server - annual.wikimedia.org' }

    include ::annualreport

    include ::base::firewall

    ferm::service { 'annualreport_http':
        proto => 'tcp',
        port  => '80',
    }

}

