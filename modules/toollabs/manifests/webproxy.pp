# Class: toollabs::webproxy
#
# This role sets up a web proxy in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webproxy {
  include toollabs,
    toollabs::infrastructure

  #TODO: apache config
  #TODO: sshd config
}

