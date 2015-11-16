# Copyright: 2015 Wikimedia Foundation, Inc.
#
# Fact: initsystem
#
# Purpose: Determine the init system that has been used to boot the system
#
# Resolution:
#
#   While it supports a number of different OSes, it has only been tested with
#   Linux. Especially useful to tell systemd/upstart/sysvinit apart.

Facter.add('initsystem') do
  confine :kernel => %w{Linux FreeBSD OpenBSD SunOS Darwin GNU/kFreeBSD}

  setcode do

    if FileTest.exists?('/run/systemd/system')
      # also see sd_booted(3)
      result = 'systemd'
    elsif FileTest.exists?('/sbin/initctl')
      result = 'upstart'
    elsif FileTest.exists?('/libexec/rc/version')
      result = 'openrc'
    elsif ['Linux', 'GNU/kFreeBSD'].include? Facter.value(:kernel)
      # generic fallback
      result = 'sysvinit'
    elsif ['FreeBSD', 'OpenBSD', 'NetBSD'].include? Facter.value(:kernel)
      result = 'bsd'
    elsif Facter.value(:kernel) == 'SunOS'
      result = 'smf'
    elsif Facter.value(:kernel) == 'Darwin'
      result = 'launchd'
    else
      result = 'unknown'
    end

    result
  end
end
