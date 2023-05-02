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

      # The OpenSSH certificate format interprets a valid_before time of 2^64-1
      # (max for unsigned long) to mean "forever", but Puppet's max integer
      # value is 9,223,372,036,854,775,807. Ensure valid_before_seconds is
      # equal or less than Puppet's max value. Otherwise puppetserver's JRuby
      # throws an error when accessing the facts hash:
      #    https://github.com/net-ssh/net-ssh/pull/746
      #    https://www.puppet.com/docs/puppet/7/lang_data_number.html#lang_data_number_integer_type
      valid_before_seconds = [ssh_data.valid_before.to_i, 9_223_372_036_854_775_807].min
      hash[file_path] = {
        principals: ssh_data.valid_principals,
        lifetime_remaining_seconds: valid_before_seconds - Time.now.to_i,
      }
    end

    hash
  end
end
