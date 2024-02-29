# SPDX-License-Identifier: Apache-2.0
# @summary module to install and configure tomcat
class tomcat10 (
    Stdlib::Host           $hostname                 = 'localhost',
    String[1]              $user                     = 'tomcat',
    String[1]              $group                    = 'tomcat',
    String                 $app_base                 = 'webapps',
    Boolean                $unpack_wars              = true,
    Boolean                $auto_deploy              = true,
    Stdlib::Port           $connector_port           = 8080,
    Integer                $connector_timeout        = 20000,
    Stdlib::Unixpath       $config_basedir           = '/etc/tomcat10',
    String[1]              $logs_dir                 = 'logs',
    String[1]              $log_pattern              = 'combined',
    Boolean                $default_servlet_debug    = false,
    Boolean                $default_servlet_listings = false,
    Boolean                $remote_ip_logging        = true,
    Hash[String[1], String[1]] $java_opts            = {'java.awt.headless'         => 'true',
                                                        'log4j2.formatMsgNoLookups' => 'true'},
){
    ensure_packages(['tomcat10'])
    $_java_opts  = $java_opts.reduce('') |$memo, $value| { "-D${value[0]}=${value[1]} ${memo}" }.strip

    file{
        default:
            ensure => file,
            owner  => 'root',
            mode   => '0640',
            group  => $group,
            notify => Service['tomcat10'];
        $config_basedir:
            ensure => directory;
        "${config_basedir}/server.xml":
            content => template('tomcat10/server.xml.erb');
        "${config_basedir}/context.xml":
            content => template('tomcat10/context.xml.erb');
        "${config_basedir}/web.xml":
            content => template('tomcat10/web.xml.erb');
        '/etc/default/tomcat10':
            mode    => '0644',
            group   => 'root',
            content => "JAVA_OPTS=\"${_java_opts}\"\n";
    }
    service{'tomcat10':
        ensure => 'running',
        enable => true,
    }
}
