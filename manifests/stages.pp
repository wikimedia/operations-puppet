stage { "first": before => Stage[main] }
stage { "last": require => Stage[main] }

class {
	"base::apt::update": stage => first;
	"base::instance-finish": stage => last;
}
