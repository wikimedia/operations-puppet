# vim: ts=2 sw=2 expandtab
class wikimedia::contint {

  include androidsdk
  include iptables
  include jdk
  include jenkins
  include packages
  include webserver
}
