# setup Apache site and SSL certs for WMF Bugzilla
# requires: {'webserver::php5': ssl => true; } on node

class bugzilla::apache ($svc_name, $attach_svc_name, $docroot){

    # separate cert and ServerName for attachments for security
    install_certificate{ $svc_name: }
    install_certificate{ $attach_svc_name: }

    # this includes them both, 80 and 443
    apache_site { $svc_name: name => $svc_name }

    file {
        "/etc/apache2/sites-available/${svc_name}":
            ensure   => present,
            content  => template("bugzilla/apache/${svc_name}.erb"),
            mode     => '0444',
            owner    => 'root',
            group    => 'www-data';
    }
}

