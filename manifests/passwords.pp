# This file is deliberately kept empty. Do NOT put it in git.
# The real file is in /etc/puppet/manifests/passwords.pp

class passwords::certs { }
class passwords::civi { }
class passwords::etherpad { }
class passwords::ganglia { }
class passwords::ldap::initial_setup { }
class passwords::ldap::wmf_cluster { }
class passwords::ldap::wmf_corp_cluster { }
class passwords::ldap::wmf_test_cluster { }
class passwords::lucene { }
class passwords::misc::scripts { }
class passwords::nagios::monitor { }
class passwords::nagios::mysql { }
class passwords::nagios::snmp { }
class passwords::network { }
class passwords::openstack::glance { }
class passwords::openstack::nova { }
class passwords::puppet::database { }
class passwords::analytics { }
class passwords::bugzilla { }
class passwords::mysql::eventlogging { }
class passwords::mongodb::eventlogging { }
class passwords::racktables { }

class passwords::wikimetrics {
    $flask_secret_key     = 'SLIJSsliejsl ise lsiejsa3s$#$ 432 wsj ls8u(*OPS4s4w ls; lsis^%RSDFVCASDl5e;  el li'
    $google_client_secret = 'KgqnHVWfsP0uu4hR0juAjkOY'
    $google_client_id     = '133082872359@developer.gserviceaccount.com'
    $google_client_email  = '133082872359-jaud8u6qisr4uvob6hs614clm9tt7pmv.apps.googleusercontent.com'

    # Wikimetrics Database Creds
    $db_user_wikimetrics = 'wikimetrics'
    $db_pass_wikimetrics = 'jGKuwks*&^k86I87jk*'
    $db_host_wikimetrics = 'localhost'
    $db_name_wikimetrics = 'wikimetrics'
    # Mediawiki Database Creds
    $db_user_mediawiki = 'u2543'
    $db_pass_mediawiki = 'tohbahrutiezooko'
}