# SPDX-License-Identifier: Apache-2.0
# this should be left behind by cloud-init. If it's not found,
#  we're not on cloud-vps or cloud-init didn't do its job.
require 'facter'

Facter.add('openstack_project_id') do
  setcode do
    filename = "/etc/openstack/project_id"
    if File.exist?(filename)
      id = File.read(filename).chomp
    end
    id
  end
end
