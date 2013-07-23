# vim: set ts=2 sw=2 et :
# continuous integration (CI)

class misc::contint::android::sdk {
  # Class installing prerequisites to the Android SDK
  # The SDK itself need to be installed manually for now.
  #
  # Help link: http://developer.android.com/sdk/installing.html

  include generic::packages::ant18

  # 32bit libs needed by Android SDK
  # ..but NOT just all of ia32-libs ..
  package { [
    'libstdc++6:i386',
    'libgcc1:i386',
    'zlib1g:i386',
    'libncurses5:i386',
    'libsdl1.2debian:i386',
    'libswt-gtk-3.5-java'
    ]: ensure => installed;
  }
}

# CI test server as per RT #1204
class misc::contint::test {

  system_role { 'misc::contint::test': description => 'continuous integration test server' }

  class jenkins {

    # Load the Jenkins module
    include ::jenkins

    # We need a basic site to publish nightly builds in
    include contint::website

    include contint::proxy_jenkins

    include jenkins::user
    file {
      '/var/lib/jenkins/.gitconfig':
        ensure  => present,
        mode    => '0444',
        owner   => 'jenkins',
        group   => 'jenkins',
        source  => 'puppet:///files/misc/jenkins/gitconfig',
        require => User['jenkins'];
    }

    file {
      '/var/lib/jenkins/.git':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        group  => 'jenkins';
      '/var/lib/jenkins/bin':
        ensure => directory,
        owner  => 'jenkins',
        group  => 'wikidev',
        mode   => '0775';
    }

  }

  # prevent users from accessing port 8080 directly (but still allow from localhost and own net)

  class iptables-purges {

    require 'iptables::tables'

    iptables_purge_service{  'deny_all_http-alt': service => 'http-alt' }
  }

  class iptables-accepts {

    require 'misc::contint::test::iptables-purges'

    iptables_add_service{ 'lo_all': interface => 'lo', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'localhost_all': source => '127.0.0.1', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_all': source => '10.0.0.0/8', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_all': source => '208.80.152.0/22', service => 'all', jump => 'ACCEPT' }
  }

  class iptables-drops {

    require 'misc::contint::test::iptables-accepts'

    iptables_add_service{ 'deny_all_http-alt': service => 'http-alt', jump => 'DROP' }
  }

  class iptables {

    require 'misc::contint::test::iptables-drops'

    iptables_add_exec{ $hostname: service => 'http-alt' }
  }

  require 'misc::contint::test::iptables'
}
