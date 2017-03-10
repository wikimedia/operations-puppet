# a webserver for misc. static sites
class role::webserver_misc_static {

    include ::standard

    include profile::microsites::annualreport    # https://annual.wikimedia.org
    include profile::microsites::endowment       # https://endowment.wikimedia.org
    include profile::microsites::releases        # https://releases.wikimedia.org
    include profile::microsites::static_bugzilla # https://static-bugzilla.wikimedia.org
    include profile::microsites::transparency    # https://transparency.wikimedia.org

}
