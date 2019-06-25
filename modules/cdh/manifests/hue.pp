# == Class cdh::hue
#
# Installs hue, sets up the hue.ini file
# and ensures that hue server is running.
# This requires that cdh::hadoop is included.
#
# If cdh::hive and/or cdh::oozie are included
# on this node, hue will be configured to interface
# with hive and oozie.
#
# == Parameters
# $http_host               - IP for webservice to bind.
# $http_port               - Port for webservice to bind.
# $secret_key              - Secret key used for session hashing.
# $app_blacklist           - Array of application names that Hue should not load.
#                            Default: hbase, impala, search, spark, rdbms, zookeeper
#
# $hive_server_host        - FQDN of host running hive-server2
#
# $oozie_url               - URL for Oozie API.  If cdh::oozie is included,
#                            this will be inferred.  Else this will be disabled.
# $oozie_security_enabled  - Default: false.
#
# $proxy_whitelist         - Comma-separated regular expressions,
#                            which match 'host:port' of requested proxy target.
#                            Default: (localhost|127\.0\.0\.1):(50030|50070|50060|50075|8088|8042|19888|11001)
# $proxy_blacklist         - Comma-separated regular expressions,
#                            which match any prefix of 'host:port/path' of requested
#                            proxy target.  Default: undef
#
# $smtp_host               - SMTP host for email notifications.
#                            Default: undef, SMTP will not be configured.
# $smtp_port               - SMTP port.                             Default: 25
# $smtp_from_email         - Sender email address of notifications. Default: undef
# $smtp_username           - Username for SMTP authentication.      Default: undef
# $smtp_password           - Password for SMTP authentication.      Default: undef
#
# $httpfs_enabled          - If true, Hue will be configured to interact with HDFS via
#                            HttpFS rather than the default WebHDFS.  You must
#                            manually configure HttpFS on your namenode.
# $webhdfs_enabled         - If true, Hue will be configured to interact with HDFS
#                            using WebHDFS.
#
# $ssl_private_key         - Path to SSL private key.  Default: /etc/hue/hue.key
# $ssl_certificate         - Path to SSL certificate.  Default: /etc/hue/hue.cert
#                            If ssl_private_key and ssl_certificate are set to the defaults,
#                            a self-signed certificate will be generated automatically for you.
# $secure_proxy_ssl_header - Django support for HTTPS termination at the load-balancer
#                            level with SECURE_PROXY_SSL_HEADER.
#                            See: https://github.com/cloudera/hue/pull/68
#                            Default: false
# $use_(yarn|hdfs|mapred)_ssl_config - Use the SSL/TLS ports for the Yarn/HDFS/MapRed config
#                                      in hue.ini
# $ssl_cacerts             - Path to the .pem certificate related to the trusted TLS CA.
#
# === Database parameters:
# The default DB is Sqlite, but it is possible to configure a external database.
# Database schema/username/tables creation is not handled by puppet but it is
# expected to be there before proceeding.
# INFO: http://www.cloudera.com/documentation/enterprise/5-5-x/topics/cdh_ig_hue_database.html
#
# $database_username       - Database username.  Default: undef
# $database_password       - Database password.  Default: undef
# $database_host           - Database hostname.  Default: undef
# $database_port           - Database port.      Default: undef
# $database_engine         - Database type.      Default: sqlite3
# $database_name           - Database name.      Default: /var/lib/hue/desktop.db
#
# === LDAP parameters:
# See hue.ini comments for documentation.  By default these are undefined.
#
# $ldap_url
# $ldap_cert
# $ldap_nt_domain
# $ldap_bind_dn
# $ldap_base_dn
# $ldap_bind_password
# $ldap_username_pattern
# $ldap_user_filter
# $ldap_user_name_attr
# $ldap_group_filter
# $ldap_group_name_attr
# $ldap_group_member_attr
# $ldap_create_users_on_login - Default: true
#
class cdh::hue(
    $http_host                  = '0.0.0.0',
    $http_port                  = 8888,
    $secret_key                 = undef,
    $app_blacklist              = ['hbase', 'impala', 'search', 'spark', 'rdbms', 'zookeeper'],

    $hive_server_host           = undef,

    $proxy_whitelist            = undef,
    $proxy_blacklist            = undef,

    $smtp_host                  = 'localhost',
    $smtp_port                  = 25,
    $smtp_user                  = undef,
    $smtp_password              = undef,
    $smtp_from_email            = undef,

    $ssl_cacerts                = undef,
    $ssl_private_key            = '/etc/ssl/private/hue.key',
    $ssl_certificate            = '/etc/ssl/certs/hue.cert',
    $secure_proxy_ssl_header    = false,

    $use_yarn_ssl_config        = false,
    $use_hdfs_ssl_config        = false,
    $use_mapred_ssl_config      = false,

    $ldap_url                   = undef,
    $ldap_cert                  = undef,
    $ldap_nt_domain             = undef,
    $ldap_bind_dn               = undef,
    $ldap_base_dn               = undef,
    $ldap_bind_password         = undef,
    $ldap_username_pattern      = undef,
    $ldap_user_filter           = undef,
    $ldap_user_name_attr        = undef,
    $ldap_group_filter          = undef,
    $ldap_group_name_attr       = undef,
    $ldap_group_member_attr     = undef,
    $ldap_create_users_on_login = true,

    $hue_ini_template           = 'cdh/hue/hue.ini.erb',
    $hue_log4j_template         = 'cdh/hue/log4j.properties.erb',
    $hue_log_conf_template      = 'cdh/hue/log.conf.erb',

    $database_host              = undef,
    $database_port              = undef,
    $database_user              = undef,
    $database_password          = undef,
    $database_name              = '/var/lib/hue/desktop.db',
    $database_engine            = 'sqlite3',

    $kerberos_keytab            = undef,
    $kerbersos_principal        = undef,
    $kerberos_kinit_path        = undef,

    $oozie_security_enabled     = false,

) {
    Class['cdh::hadoop'] -> Class['cdh::hue']

    # Set Hue Oozie defaults to those already
    # set in the cdh::oozie class.
    if (defined(Class['cdh::oozie'])) {
        $oozie_url              = $cdh::oozie::url
        $oozie_proxy_regex      = "${cdh::oozie::oozie_host}:(11000|11443)"
    }
    # Otherwise disable Oozie interface for Hue.
    else {
        $oozie_url              = undef
        $oozie_proxy_regex      = ''

    }

    $namenode_hosts = $cdh::hadoop::namenode_hosts
    $yarn_rm_http_protocol = $use_yarn_ssl_config ? {
        true    => 'https',
        default => 'http',
    }
    $yarn_rm_port = $use_yarn_ssl_config ? {
        true    => '8090',
        default => '8088',
    }
    $yarn_nm_port = $use_yarn_ssl_config ? {
        true    => '8044',
        default => '8042',
    }
    $hdfs_nn_http_protocol = $use_hdfs_ssl_config ? {
        true    => 'https',
        default => 'http',
    }
    $hdfs_nn_port = $use_hdfs_ssl_config ? {
        true    => '50470',
        default => '50070',
    }
    $hdfs_dn_port = $use_hdfs_ssl_config ? {
        true    => '50475',
        default => '50075',
    }
    $mapred_history_http_protocol = $use_mapred_ssl_config ? {
        true    => 'https',
        default => 'http',
    }
    $mapred_history_port = $use_mapred_ssl_config ? {
        true    => '19890',
        default => '19888',
    }
    if $proxy_whitelist {
        $proxy_whitelist_final = $proxy_whitelist
    } else {
        $proxy_whitelist_final = [
            # namenode + resourcemanager + history server host and ports
            inline_template("(<%= @namenode_hosts.join('|') %>):(<%= @yarn_rm_port %>|<%= @hdfs_nn_port %>|<%= @mapred_history_port %>)"),
            # Oozie Web UI.
            $oozie_proxy_regex,
            # No way to determine DataNode or NodeManager hostname defaults.
            # If you want to restrict this, make sure you override $proxy_whitelist parameter.
            ".+:(${hdfs_dn_port}| ${yarn_nm_port})",
        ]
    }

    # If httpfs is enabled, the default httpfs port
    # will be used, instead of the webhdfs port.
    $httpfs_enabled = $cdh::hadoop::httpfs_enabled
    $webhdfs_enabled = $cdh::hadoop::webhdfs_enabled

    package { 'hue':
        ensure => 'installed'
    }

    $config_directory = "/etc/hue/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hue'],
    }
    cdh::alternative { 'hue-conf':
        link => '/etc/hue/conf',
        path => $config_directory,
    }

    # Managing the hue user here so we can add
    # it to the hive group if hive-site.xml is
    # not world readable.
    user { 'hue':
        gid        => 'hue',
        comment    => 'Hue daemon',
        home       => '/usr/lib/hue',
        shell      => '/bin/false',
        managehome => false,
        system     => true,
        require    => Package['hue'],
    }
    # hive-site.xml might not be world readable.
    if defined(Class['cdh::hive']) {
        # Below, if hive is enabled, the hue
        # user will be added to the hive group.
        # It isn't added here because Puppet only
        # allows group addtions to a User once,
        # and we might also have to add the ssl-cert group.
        $hive_enabled = true

        # make sure cdh::hive is applied before cdh::hue.
        Class['cdh::hive']  -> Class['cdh::hue']
    }

    # If SSL file paths are given, configure Hue to use SSL.
    if ($ssl_private_key and $ssl_certificate) {
        # Below, if ssl is enabled, the hue
        # user will be added to the ssl-cert group.
        # It isn't added here because Puppet only
        # allows group addtions to a User once,
        # and we might also have to add the hive group.
        # Adding the ssl-cert group allows hue to read
        # files in /etc/ssl/private.
        $ssl_enabled = true
        if (!defined(Package['openssl'])) {
            package { 'openssl':
                ensure => 'installed',
                before => User['hue'],
            }
        }
        if (!defined(Package['ssl-cert'])) {
            package { 'ssl-cert':
                ensure => 'installed',
                before => User['hue'],
            }
        }
        if (!defined(Package['python-openssl'])) {
            package { 'python-openssl':
                ensure => 'installed',
            }
        }

        # If the SSL settings are left at the defaults,
        # then generate a default self-signed certificate.
        if (($ssl_private_key == '/etc/ssl/private/hue.key') and
            ($ssl_certificate == '/etc/ssl/certs/hue.cert')) {

            exec { 'generate_hue_ssl_private_key':
                command => "/usr/bin/openssl genrsa 2048 > ${ssl_private_key}",
                creates => $ssl_private_key,
                require => [Package['openssl'], User['hue']],
                notify  => Service['hue'],
                before  => File[$ssl_private_key],
            }
            exec { 'generate_hue_ssl_certificate':
                command => "/usr/bin/openssl req -new -x509 -nodes -sha1 -subj '/C=US/ST=Denial/L=Nonya/O=Dis/CN=www.example.com' -key ${ssl_private_key} -out ${ssl_certificate}",
                creates => $ssl_certificate,
                require => Exec['generate_hue_ssl_private_key'],
                notify  => Service['hue'],
                before  => File[$ssl_certificate],
            }
        }

        # Ensure SSL files have proper permissions.
        file { $ssl_private_key:
            mode   => '0440',
            owner  => 'root',
            group  => 'hue',
            before => Service['hue'],
        }
        file { $ssl_certificate:
            mode   => '0444',
            owner  => 'root',
            group  => 'hue',
            before => Service['hue'],
        }
    }

    # Stupid Puppet hack:  Need to select all
    # of the groups we are going to add the
    # hue user to before we actually do it.

    # add hue to the proper groups based on hive
    # and ssl usage.
    if ($hive_enabled and $ssl_enabled) {
        $hue_groups = ['hive', 'ssl-cert']
    }
    elsif ($hive_enabled) {
        $hue_groups = ['hive']
    }
    elsif($ssl_enabled) {
        $hue_groups = ['ssl-cert']
    }

    if ($hue_groups) {
        # Add the hue user to the hive group.
        User['hue'] { groups +> $hue_groups }
    }

    $namenode_host = $::cdh::hadoop::primary_namenode_host
    file { "${config_directory}/hue.ini":
        content => template($hue_ini_template),
        require => Package['hue'],
    }
    file { "${config_directory}/log4j.properties":
        content => template($hue_log4j_template),
        require => Package['hue'],
    }
    file { "${config_directory}/log.conf":
        content => template($hue_log_conf_template),
        require => Package['hue'],
    }

    service { 'hue':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        subscribe  => File["${config_directory}/hue.ini"],
        require    => [Package['hue'], User['hue']],
    }
}
