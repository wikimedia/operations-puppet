# Lot of manifests do not explicitly require ::base and we mock it anyway
require_package('git')
require_package('openssh-server')

# FIXME
class role::statsite {
}

class privateexim::aliases::private {
}
