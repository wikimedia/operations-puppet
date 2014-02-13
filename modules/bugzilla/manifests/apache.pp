# this class sets up the Apache site config and SSL certs
# for a Wikimedia Bugzilla installation
# it expects {'webserver::php5': ssl => true; } on the node
class bugzilla::apache ($svc_name, $attach_svc_name, $docroot){

    # separate cert and ServerName for attachments for security
    install_certificate{ $svc_name: }
    install_certificate{ $attach_svc_name: }

    # this includes them both, 80 and 443
    apache_site { "000-${svc_name}": name => "000-${svc_name}" }

    file {
        "/etc/apache2/sites-available/000-${svc_name}":
            ensure   => present,
            content  => template("bugzilla/apache/${svc_name}.erb"),
            mode     => '0444',
            owner    => 'root',
            group    => 'www-data';
    }
}

