# this class sets up the Apache site config and SSL certs
# for a Wikimedia Bugzilla installation
# it expects {'webserver::php5': ssl => true; } on the node
class bugzilla::apache ($svc_name, $attach_svc_name, $docroot){

    include ::apache::mod::headers
    include ::apache::mod::expires
    include ::apache::mod::env
    include ::apache::mod::rewrite

    apache::site { 'bugzilla.wikimedia.org':
        content  => template("bugzilla/apache/bugzilla.wikimedia.org.erb"),
        priority => 10,
    }

}
