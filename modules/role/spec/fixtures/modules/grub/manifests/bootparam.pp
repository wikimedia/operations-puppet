# rspec would fail with:
# error during compilation: not supported on systems running an old augeas
#
# Would be resolved by bumping augeas in Gemfile
define grub::bootparam(
  $ensure=present,
  $key=$title,
  $value=undef,
  $glob=true,
) {
}
