# this class sets up the Apache site config and SSL certs
# for a Wikimedia Bugzilla installation
# it expects {'webserver::php5': ssl => true; } on the node
class bugzilla::apache ($svc_name, $attach_svc_name, $docroot, $cipher_suite){

    include ::apache::mod::headers
    include ::apache::mod::expires
    include ::apache::mod::env

    # separate cert and ServerName for attachments for security
    install_certificate{ $svc_name: }
    install_certificate{ $attach_svc_name: }

    # this includes them both, 80 and 443

    file {
        "/etc/apache2/sites-enabled/000-${svc_name}":
            ensure   => present,
            content  => template("bugzilla/apache/${svc_name}.erb"),
            mode     => '0444',
            owner    => 'root',
            group    => 'www-data';
    }
}

