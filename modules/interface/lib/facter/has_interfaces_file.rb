# SPDX-License-Identifier: Apache-2.0
Facter.add(:has_interfaces_file) do
  confine :kernel => :linux
  setcode do
    File.exist?('/etc/network/interfaces')
  end
end
