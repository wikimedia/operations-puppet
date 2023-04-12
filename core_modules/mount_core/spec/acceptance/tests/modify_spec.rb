require 'spec_helper_acceptance'

require 'mount_utils'

RSpec.context 'when managing mounts' do
  agents.each do |agent|
    context "on #{agent}" do
      include_context('mount context', agent)

      it 'modifies an entry in the filesystem table' do
        step '(setup) create mount point'
        on(agent, "mkdir /#{name}", acceptable_exit_codes: [0, 1])

        step '(setup) create new filesystem to be mounted'
        MountUtils.create_filesystem(agent, name)

        step '(setup) add entry to the filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name)

        step '(setup) mount entry'
        on(agent, "mount /#{name}")

        step 'modify a mount with puppet (defined)'
        args = ['ensure=defined',
                'fstype=bogus']
        on(agent, puppet_resource('mount', "/#{name}", args))

        step 'verify entry is updated in filesystem table'
        on(agent, "cat #{fs_file}") do |res|
          fail_test "attributes not updated for the mount #{name}" unless res.stdout.include? 'bogus'
        end
      end

      it 'modifies an entry with whitespace in the filesystem table' do
        step '(setup) create mount point'
        on(agent, "mkdir '/#{name_w_whitespace}'", acceptable_exit_codes: [0, 1])

        step '(setup) create new filesystem to be mounted'
        MountUtils.create_filesystem(agent, name_w_whitespace)

        step '(setup) add entry to the filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name_w_whitespace)

        step '(setup) mount entry'
        on(agent, "mount '/#{name_w_whitespace}'")

        step 'modify a mount with puppet (defined)'
        args = ['ensure=defined',
                'fstype=bogus']
        on(agent, puppet_resource('mount', "'/#{name_w_whitespace}'", args))

        step 'verify entry is updated in filesystem table'
        on(agent, "cat #{fs_file}") do |res|
          fail_test "attributes not updated for the mount '#{name_w_whitespace}'" unless res.stdout.include? 'bogus'
        end
      end
    end
  end
end
