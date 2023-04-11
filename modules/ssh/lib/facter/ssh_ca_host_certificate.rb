# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'time'

Facter.add(:ssh_ca_host_certificate) do
  confine do
    !Dir.glob('/etc/ssh/*-cert.pub').empty? && Facter::Core::Execution.which('ssh-keygen') && Gem::Specification.find_all_by_name('net-ssh').any?
  end

  setcode do
    hash = {}

    require 'net/ssh'

    Dir.glob('/etc/ssh/*-cert.pub').each do |file_path|
      ssh_data = Net::SSH::KeyFactory.load_public_key(file_path)

      hash[file_path] = {
        principals: ssh_data.valid_principals,
        lifetime_remaining_seconds: ssh_data.valid_before.to_i - Time.now.to_i,
      }
    end

    hash
  end
end
