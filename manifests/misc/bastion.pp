# misc/bastion.pp

# bastion hosts
# Uses role::bastion::* instead.

class misc::bastionhost {

	include role::bastion::production

}
