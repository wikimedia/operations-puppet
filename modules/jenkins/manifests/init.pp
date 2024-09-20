# == Class jenkins
#
# Set up a basic Jenkins controller instance for CI.
#
# == Parameters:
#
# [*prefix*]
# Prefix for web access to use with Apache proxying. Must be the full path with
# a leading slash. Example: /ci
#
# [*log_group*]
# Unix group for the log files under /var/log/jenkins. Default: 'wikidev'
#
# [*http_port*]
# HTTP port for the web service. Default: 8080
#
# [*max_open_files*]
# Maximum number of file descriptors. Passed to systemd LimitNOFILE.
# Default: 8192.
#
# [*service_ensure*]
# Passed to Puppet Service['jenkins']
# Allowed values: (Boolean) true, false (Strings) running, stopped
# Default: stopped
#
# [*service_enable*]
# Passed to Puppet Service['jenkins']
# Allowed values: (Boolean) true, false (Strings) mask, manual
# Default: mask
#
# [*umask*]
# Control permission bits of files created by Jenkins. Passed to systemd.
# Default: '0002'
#
# [*builds_dir*]
# Change location of build records. This option was formerly set in the
# jenkins ui, now must be set via system properties
# Default: ${ITEM_ROOTDIR}/builds
#
# [*workspaces_dir*]
# Change location of built-in node workspaces. This option was formerly set in
# the Jenkins UI, now must be set via system properties
# Default: ${ITEM_ROOTDIR}/workspace
#
# [*java_home*]
# Path to JAVA_HOME. Can be used to start the Jenkins server with a different
# Java version.
# Default: /usr/lib/jvm/java-8-openjdk-amd64/jre
#
#
# [*use_scap3_deployment*]
# Transitory flag to choose between the old Jenkins installation method and
# Scap3
#
class jenkins(
    String $prefix,
    String $log_group = 'wikidev',
    Stdlib::Port $http_port = 8080,
    Integer $max_open_files = 8192,
    Variant[Enum['mask', 'manual'], Boolean] $service_enable = 'mask',
    Variant[Enum['running', 'stopped'], Boolean] $service_ensure = 'stopped',
    Boolean $service_monitor = true,
    Stdlib::Filemode $umask = '0002',
    String $builds_dir = "\${ITEM_ROOTDIR}/builds",
    String $workspaces_dir = "\${ITEM_ROOTDIR}/workspace",
    Stdlib::Unixpath $java_home = '/usr/lib/jvm/java-8-openjdk-amd64/jre',
    Boolean $use_scap3_deployment = false
)
{
    user { 'jenkins':
        uid        => 924,
        home       => '/var/lib/jenkins',
        shell      => '/bin/bash',  # admins need to be able to login
        gid        => 'jenkins',
        system     => true,
        managehome => false,
        require    => Group['jenkins'],
    }

    group { 'jenkins':
        ensure    => present,
        gid       => 924,
        name      => 'jenkins',
        system    => true,
        allowdupe => false,
    }

    $java_path = "${java_home}/bin/java"

    file { '/var/lib/jenkins/.daemonrc':
        ensure  => 'absent',
    }

    file { '/etc/jenkins':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'jenkins',
        mode   => '0755',
    }


    apt::repository { 'jenkins-thirdparty-ci':
      uri        => 'http://apt.wikimedia.org/wikimedia',
      dist       => "${::lsbdistcodename}-wikimedia",
      components => 'thirdparty/ci',
    }

    if ! $use_scap3_deployment {
        package { 'jenkins':
            ensure  => present,
            require => Apt::Repository['jenkins-thirdparty-ci'],
        }
        file { '/etc/jenkins/logging.properties':
          content => template('jenkins/logging.properties.erb'),
          owner   => 'jenkins',
          group   => 'jenkins',
          mode    => '0755',
        }
    }

    systemd::syslog { 'jenkins':
        base_dir     => '/var/log',
        owner        => 'jenkins',
        group        => $log_group,
        readable_by  => 'group',
        log_filename => 'jenkins.log',
    }

    if $use_scap3_deployment {
        $deploy_dir = 'releng/jenkins-deploy'

        file { '/etc/systemd/system/jenkins.service.d/override.conf':
          ensure => 'link',
          target => "/srv/deployment/${deploy_dir}/conf/jenkins.service.d/override.conf",
          owner  => 'root',
          group  => 'root',
        }

        scap::target { $deploy_dir:
          deploy_user  => 'deploy-jenkins',
          service_name => 'jenkins',
          sudo_rules   => [
              # Options to the JVM and Jenkins daemon are passed using a systemd override in the deployment repositor
              # which requires a reload when changed
              'ALL=(root) NOPASSWD: /usr/bin/systemctl daemon-reload',
              'ALL=(root) NOPASSWD: /usr/bin/apt-get install -y jenkins',
              # To allow the installation process to run any required jars in the deployment repository
              "ALL=(jenkins) NOPASSWD: /usr/bin/java -Dhttps.proxyHost=url-downloader.wikimedia.org -Dhttps.proxyPort=8080 -jar /srv/deployment/${deploy_dir}/*",
          ]
        }

        file { '/var/log/jenkins/access.log':
          ensure  => present,
          replace => false,
          owner   => 'jenkins',
          group   => $log_group,
          mode    => '0640',
          before  => Package[$deploy_dir],
        }

        file { '/etc/default/jenkins':
          ensure  => absent,
          require => Package[$deploy_dir],
        }
    } else {
        $jenkins_access_log_arg = '--accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/jenkins/access.log'
        file { '/var/log/jenkins/access.log':
          ensure  => present,
          replace => false,
          owner   => 'jenkins',
          group   => $log_group,
          mode    => '0640',
          before  => Service['jenkins'],
        }

        $builds_dir_for_systemd = regsubst( $builds_dir, '\$', '$$', 'G' )
        $workspaces_dir_for_systemd = regsubst( $workspaces_dir, '\$', '$$', 'G' )

        $java_args = join([
            # Allow graphs etc. to work even when an X server is present
            '-Djava.awt.headless=true',
            # Make Git plugin verbose which dramatically helps debugging
            '-Dhudson.plugins.git.GitSCM.verbose=true',
            # Prevents Jenkins 1.651.2+ from stripping parameters injected by the
            # Gearman plugin.
            #
            # References:
            #   https://phabricator.wikimedia.org/T133737
            #   https://jenkins.io/blog/2016/05/11/security-update/
            #   https://wiki.jenkins-ci.org/display/SECURITY/Jenkins+Security+Advisory+2016-05-11
            '-Dhudson.model.ParametersAction.keepUndefinedParameters=true',
            '-Djava.util.logging.config.file=/etc/jenkins/logging.properties',
            # Disable auto discovery T178608
            '-Dhudson.udp=-1',
            '-Dhudson.DNSMultiCast.disabled=true',
            "-Djenkins.model.Jenkins.buildsDir=${builds_dir_for_systemd}",
            "-Djenkins.model.Jenkins.workspacesDir=${workspaces_dir_for_systemd}",
            # T245658 Allow inline CSS and playing MP4 videos of test results.
            # To accomodate with systemd on Jessie, the whole argument has to be
            # double quoted to prevent word splitting.
            "\"-Dhudson.model.DirectoryBrowserSupport.CSP=sandbox; default-src 'none'; img-src 'self'; style-src 'self' 'unsafe-inline'; media-src 'self'\""
        ], ' ')

        systemd::service { 'jenkins':
          ensure            => 'present',
          content           => init_template('jenkins', 'systemd_override'),
          override          => true,
          # Note Jenkins migrate.sh scrip skips whenever there is an override at:
          # /etc/systemd/system/jenkins.service.d/override.conf
          override_filename => 'override.conf',
          service_params    => {
              enable => $service_enable,
              ensure => $service_ensure,
          },
          require           => [
              Systemd::Syslog['jenkins'],
              File['/etc/default/jenkins'],
          ],
        }

        file { '/etc/default/jenkins':
          ensure  => absent,
          require => Package['jenkins'],
        }
    }

    if $service_monitor {
        nrpe::monitor_service { 'jenkins':
            description   => 'jenkins_service_running',
            contact_group => 'contint',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '.*/bin/java .*-jar /usr/share/java/jenkins.war'",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Jenkins',
        }
    }

    file { '/srv/jenkins':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/var/lib/jenkins':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }
    # Top level jobs folder
    file { '/var/lib/jenkins/jobs':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }
    # SECURITY-829 / CVE-2019-1003051
    # Plugin stores credentials unencrypted.
    file { '/var/lib/jenkins/hudson.plugins.ircbot.IrcPublisher.xml':
        ensure => present,
        mode   => '0660',
        owner  => 'jenkins',
        group  => 'adm',
    }

    file { '/var/lib/jenkins/logs':
        ensure => directory,
        mode   => '0700',
        owner  => 'jenkins',
        group  => 'adm',
    }
    file { '/var/lib/jenkins/secrets':
        ensure => directory,
        mode   => '0700',
        owner  => 'jenkins',
        group  => 'adm',
    }
}
