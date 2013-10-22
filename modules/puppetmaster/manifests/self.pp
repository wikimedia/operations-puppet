#
# Below are classes used to configure self hosted puppet
# on labs instances. role::puppet::self (in puppet.pp)
# is the recommended class to use.  Please use it to
# include these classes.
#

# == Class puppetmaster::self
# Wrapper class for puppet::self::master
# with server => localhost.  This is
# maintained for backwards compatibility.
# Please use role::puppet::self
# in roles/puppet.pp instead.
#
class puppetmaster::self {
	class { 'puppet::self::master':
		server => 'localhost',
	}
}
