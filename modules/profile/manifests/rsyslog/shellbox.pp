# Rsyslog filters for shellbox
class profile::rsyslog::shellbox () {
  rsyslog::conf { 'shellbox':
    ensure   => 'present',
    source   => 'puppet:///modules/profile/rsyslog/shellbox.rsyslog.conf',
    priority => 20
  }
}
