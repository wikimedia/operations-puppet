# == Class: profile::piwik::instance
#
# piwik is an open-source analytics platform.
# It powers <https://piwik.wikimedia.org>.
#
# Q: Why is there no piwik module?
# A: The only sanctioned way of configuring Piwik is via the web
#    installer. It is possible to provision a config.ini.php via Puppet,
#    but then you can't get to the web installer, so you are left with
#    no way to initialize the database, short of doing a bulk MySQL
#    import of a dump of an already-initialized Piwik database.
#
#    See #1586: Headless install / command line piwik remote install
#    <https://github.com/piwik/piwik/issues/1586>.
#    Closed with "We have implemented this plugin for Piwik PRO, please
#    get in touch if you are interested."
#
# Q: So where are the credentials?
# A: In pwstore.
#
# Q: Where did the package come from?
# A: http://debian.piwik.org/, imported to jessie-wikimedia.
#
class profile::piwik::instance {
    require_package('piwik')

    # Fix explained in the following github issue:
    # https://github.com/piwik/piwik/issues/6398#issuecomment-91093146
    file_line { 'piwik_bulk_requests_use_transaction':
        line   => 'bulk_requests_use_transaction = 0',
        match  => '^;?bulk_requests_use_transaction\s*\=',
        path   => '/etc/piwik/config.ini.php',
    }
}