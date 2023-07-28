# SPDX-License-Identifier: MIT
# Partly imported from https://voxpupuli.org/

require 'facter'

python = {
  'version' => nil,
  'python-is' => nil
}

def get_python_version(executable)
  if Facter::Util::Resolution.which(executable) # rubocop:disable Style/GuardClause
    results = Facter::Util::Resolution.exec("#{executable} -V 2>&1").match(/^.*(\d+\.\d+\.\d+\+?)$/)
    results[1] if results
  end
end

Facter.add('python3') do
  confine do
    Facter::Util::Resolution.which('python3')
  end
  setcode do
    default_version = get_python_version 'python'
    if default_version.nil? || default_version[0] == '2'
      python['version'] = get_python_version 'python3'

      # Set python-is to 2 or nil.
      if default_version.nil?
        python['python-is'] = nil
      else
        python['python-is'] = '2'
      end
    else
      python['version'] = default_version
      python['python-is'] = python['version'][0]
    end
    python
  end
end

if $PROGRAM_NAME == __FILE__
  require 'json'
  puts JSON.dump({ :'python_version' => Facter.value('python3') })
end
