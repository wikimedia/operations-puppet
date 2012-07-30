# misc/bastion.pp

# bastion hosts
# The misc::bastionhost class is deprecated, uses role::bastion::production
# or one of the other role::bastion::* instead.

class misc::bastionhost {

	include role::bastion::production

}
