# SPDX-License-Identifier: Apache-2.0
# @summary module to install and configure tomcat
class tomcat (
    Stdlib::Host           $hostname                 = 'localhost',
    String[1]              $user                     = 'tomcat',
    String[1]              $group                    = 'tomcat',
    String                 $app_base                 = 'webapps',
    Boolean                $unpack_wars              = true,
    Boolean                $auto_deploy              = true,
    Stdlib::Port           $connector_port           = 8080,
    Integer                $connector_timeout        = 20000,
    Stdlib::Unixpath       $config_basedir           = '/etc/tomcat9',
    Boolean                $versionlogger_listener   = true,
    Boolean                $security_listener        = false,
    Boolean                $apr_listener             = false,
    Boolean                $apr_sslengine            = false,
    Stdlib::Port::User     $apr_port                 = 8443,
    Boolean                $userdatabase_realm       = false,
    String[1]              $userdatabase_file        = 'tomcat-users.xml',
    String[1]              $logs_dir                 = 'logs',
    String[1]              $log_pattern              = 'combined',
    Integer[1]             $default_session_timeout  = 30,
    Boolean                $default_servlet_debug    = false,
    Boolean                $default_servlet_listings = false,
    Boolean                $default_servlet_readonly = true,
    Array[String[1]]       $default_servlet_mappings = ['/'],
    Boolean                $jsp_servlet_fork         = false,
    Boolean                $jsp_servlet_xpoweredby   = false,
    Array[String[1]]       $jsp_servlet_mappings     = ['*.jsp', '*.jspx'],
    Array[String[1]]       $welcome_files            = ['index.html', 'index.htm', 'index.jsp'],
    Stdlib::Host           $shutdown_address         = 'localhost',
    String                 $shutdown_string          = 'SHUTDOWN',
    Stdlib::Unixpath       $public_key_path          = '/etc/tomcat9/ssl/cert.pem',
    Stdlib::Unixpath       $private_key_path         = '/etc/tomcat9/ssl/server.key',
    Hash[String[1], String[1]] $java_opts            = {'java.awt.headless'         => 'true',
                                                        'log4j2.formatMsgNoLookups' => 'true'},
    Array[String[1]]           $watched_resources    = ['WEB-INF/web.xml',
                                                        'WEB-INF/tomcat-web.xml',
    # lint:ignore:single_quote_string_with_variables
                                                        '${catalina.base}/conf/web.xml'],
    # lint:endignore
    Optional[Stdlib::Port]     $shutdown_port           = undef,
){
    ensure_packages(['tomcat9'])
    if $apr_listener {
      ensure_packages(['libtcnative-1'])
    }
    $_java_opts  = $java_opts.reduce('') |$memo, $value| { "-D${value[0]}=${value[1]} ${memo}" }.strip

    file{
        default:
            ensure => file,
            owner  => 'root',
            mode   => '0640',
            group  => $group,
            notify => Service['tomcat9'];
        $config_basedir:
            ensure => directory;
        "${config_basedir}/server.xml":
            content => template('tomcat/server.xml.erb');
        "${config_basedir}/context.xml":
            content => template('tomcat/context.xml.erb');
        "${config_basedir}/web.xml":
            content => template('tomcat/web.xml.erb');
        '/etc/default/tomcat9':
            mode    => '0644',
            group   => 'root',
            content => "JAVA_OPTS=\"${_java_opts}\"\n";
    }
    service{'tomcat9':
        ensure => 'running',
        enable => true,
    }
}
