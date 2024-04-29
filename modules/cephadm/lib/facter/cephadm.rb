# SPDX-License-Identifier: Apache-2.0
Facter.add(:cephadm) do
  setcode do
    {
      ssh: {
        key: File.read('/root/.ssh/id_cephadm.pub').chomp
      }
    }
  end
end
