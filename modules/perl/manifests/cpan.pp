# Class: perl::cpan
#
# This class configures cpan.
#
class perl::cpan inherits perl {

  if $perl::cpan_package != '' and ! defined(Package[$perl::cpan_package]) {
    package { $perl::cpan_package:
      ensure  => $perl::manage_cpan_package,
      noop    => $perl::noops,
    }
  }

  exec{ 'configure_cpan':
    command => "cpan <<EOF
yes
yes
no
no
${perl::cpan_mirror}

yes
quit
EOF",
    creates => '/root/.cpan/CPAN/MyConfig.pm',
    require => [ Package[$perl::cpan_package] ],
    user    => root,
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    timeout => 600,
  }

}
