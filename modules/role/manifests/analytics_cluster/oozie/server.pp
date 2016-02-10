# == Class role::analytics_cluster::oozie::server
# Installs Oozie server
# Make sure you set hiera variables for cdh::oozie::server appropriately,
# especially if you are hosting
class role::analytics_cluster::oozie::server {
    system::role { 'role::analytics_cluster::oozie::server':
        description => 'Oozie Server',
    }
    require role::analytics_cluster::oozie::client

    # cdh::oozie::server will ensure that its MySQL DB is
    # properly initialized.  For puppet to do this,
    # it needs a mysql client.
    require_package('mysql-client')

    class { 'cdh::oozie::server':
        smtp_host       => $::mail_smarthost[0],
        smtp_from_email => "oozie@${::fqdn}",
        # This is not currently working.  Disabling
        # this allows any user to manage any Oozie
        # job.  Since access to our cluster is limited,
        # this isn't a big deal.  But, we should still
        # figure out why this isn't working and
        # turn it back on.
        # I was not able to kill any oozie jobs
        # with this on, even though the
        # oozie.service.ProxyUserService.proxyuser.*
        # settings look like they are properly configured.
        authorization_service_authorization_enabled => false,
    }

    ferm::service{ 'oozie_server':
        proto  => 'tcp',
        port   => '11000',
        srange => '$INTERNAL',
    }
}
