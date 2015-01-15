# https://annual.wikimedia.org/
# microsite for the WMF annual report
# http://wikimediafoundation.org/wiki/Annual_Report
class role::annualreport {

    system::role { 'role::annualreport': description => 'annual.wikimedia.org' }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    include ::annualreport

}

