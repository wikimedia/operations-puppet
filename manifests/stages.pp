stage { "first": before => Stage[main] }
stage { "last": require => Stage[main] }

class {
	"apt::update": stage => first;
	"base::instance-finish": stage => last;
	"ldap::client::instance-finish": stage => last;
}
