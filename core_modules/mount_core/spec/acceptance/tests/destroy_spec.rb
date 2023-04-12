require 'spec_helper_acceptance'

require 'mount_utils'

RSpec.context 'when managing mounts' do
  agents.each do |agent|
    context "on #{agent}" do
      include_context('mount context', agent)

      it 'deletes an entry in filesystem table and unmounts it' do
        step 'create mount point'
        on(agent, "mkdir /#{name}", acceptable_exit_codes: [0, 1])

        step 'create new filesystem to be mounted'
        MountUtils.create_filesystem(agent, name)

        step 'add entry to the filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name)

        step 'mount entry'
        on(agent, "mount /#{name}")

        step 'verify entry exists in filesystem table'
        on(agent, "cat #{fs_file}") do |result|
          fail_test "did not find mount #{name}" unless result.stdout.include?(name)
        end

        step 'destroy a mount with puppet (absent)'
        on(agent, puppet_resource('mount', "/#{name}", 'ensure=absent'))

        step 'verify entry removed from filesystem table'
        on(agent, "cat #{fs_file}") do |result|
          fail_test "found the mount #{name}" if result.stdout.include?(name)
        end

        step 'verify entry is not mounted'
        on(agent, 'mount') do |result|
          fail_test "found the mount #{name} mounted" if result.stdout.include?(name)
        end
      end

      it 'deletes an entry with whitespace in filesystem table and unmounts it' do
        step 'create mount point'
        on(agent, "mkdir '/#{name_w_whitespace}'", acceptable_exit_codes: [0, 1])

        step 'create new filesystem to be mounted'
        MountUtils.create_filesystem(agent, name_w_whitespace)

        step 'add entry to the filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name_w_whitespace)

        step 'mount entry'
        on(agent, "mount '/#{name_w_whitespace}'")

        step 'verify entry exists in filesystem table'
        on(agent, "cat #{fs_file}") do |result|
          munged_name = name_w_whitespace.gsub(' ', '\\\040')
          fail_test "did not find mount '#{name_w_whitespace}'" unless result.stdout.include?(munged_name)
        end

        step 'destroy a mount with puppet (absent)'
        on(agent, puppet_resource('mount', "'/#{name_w_whitespace}'", 'ensure=absent'))

        step 'verify entry removed from filesystem table'
        on(agent, "cat #{fs_file}") do |result|
          munged_name = name_w_whitespace.gsub(' ', '\\\040')
          fail_test "found the mount '#{name_w_whitespace}'" if result.stdout.include?(munged_name)
        end

        step 'verify entry is not mounted'
        on(agent, 'mount') do |result|
          fail_test "found the mount '#{name_w_whitespace}' mounted" if result.stdout.include?(name_w_whitespace)
        end
      end
    end
  end
end
