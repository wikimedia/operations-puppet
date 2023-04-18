# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

Puppet::Functions.create_function(:'ssh::ssh_sign_host_certificate') do
  dispatch :ssh_sign_host_certificate do
    param 'String[1]', :pubkey
    param 'Array[Stdlib::Host]', :names
  end

  def ssh_sign_host_certificate(pubkey, names)
    key_id = File.read('/etc/ssh/ca-key-id.txt')

    Dir.mktmpdir('puppet-sshhostkey') do |tmp_path|
      pubkey_file = File.join(tmp_path, 'key.pub')
      cert_file = File.join(tmp_path, 'key-cert.pub')

      File.write(pubkey_file, pubkey)

      Puppet::Util::Execution.execute([
        '/usr/bin/ssh-keygen',
        '-s', '/etc/ssh/ca',
        '-I', key_id,
        '-h',  # sign host keys
        '-n', names.join(','),
        '-V', '+6w',
        pubkey_file
      ])

      File.read(cert_file)
    end
  end
end
