# == Fact: hhvm_extension_version
#
# Resolves to the current HHVM extension path.
#
Facter.add('hhvm_extension_path') do
    setcode { Dir['/usr/lib/hphp/extensions/[0-9]*'].sort.last }
end
