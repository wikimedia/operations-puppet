# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

Facter.add(:nrpe_checks) do
  confine do
    File.directory?('/etc/nagios/nrpe.d/')
  end

  setcode do
    Dir.glob('/etc/nagios/nrpe.d/*.cfg').map { |file| file.split('/').last.gsub('.cfg', '') }
  end
end
