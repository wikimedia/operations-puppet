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

  # Creates placeholders for slave-scripts. This need to be moved out to a
  # better place under contint module.
  class jenkins {

    file {
      '/var/lib/jenkins/.gitconfig':
        ensure  => present,
        mode    => '0444',
        owner   => 'jenkins',
        group   => 'jenkins',
        source  => 'puppet:///files/misc/jenkins/gitconfig',
        require => User['jenkins'];
    }

    # FIXME needs to be migrated somewhere else
    # Maybe contint::slave-scripts
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

}
