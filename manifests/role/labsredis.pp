# See https://gerrit.wikimedia.org/r/#/c/54970/ and https://projects.puppetlabs.com/issues/2053
# before renaming.
class role::labs-redis {
	class { "::redis":
		dir => "/var/lib/redis/",
	}
}
