# vim: ts=2 sw=2 expandtab
class wikimedia::contint::androidsdk {
  # Class installing prerequisites to the Android SDK
  # The SDK itself need to be installed manually for now.
  #
  # Help link: http://developer.android.com/sdk/installing.html

  # We really want Sun/Oracle JDK
  require wikimedia::contint::jdk
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
