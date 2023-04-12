require 'spec_helper_acceptance'

require 'mount_utils'

RSpec.context 'when managing mounts' do
  agents.each do |agent|
    context "on #{agent}" do
      include_context('mount context', agent)

      it 'finds an existing filesystem table entry' do
        step '(setup) add entry to filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name)

        step 'verify mount with puppet'
        on(agent, puppet_resource('mount', "/#{name}")) do |result|
          fail_test "didn't find the mount #{name}" unless %r{'/#{name}':\s+ensure\s+=>\s+'unmounted'}.match?(result.stdout)
        end
      end

      it 'finds an existing filesystem table entry containing whitespace' do
        step '(setup) add entry to filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name_w_whitespace)

        step 'verify mount with puppet'
        on(agent, puppet_resource('mount', "'/#{name_w_whitespace}'")) do |result|
          fail_test "didn't find the mount #{name_w_whitespace}" unless %r{'/#{name_w_whitespace}':\s+ensure\s+=>\s+'unmounted'}.match?(result.stdout)
        end
      end

      # There is a discrepancy between how `puppet resource` and `puppet apply` handle this case.
      # With this patch, using a resource title with a trailing slash in `puppet apply` will match a mount resource without a trailing slash.
      # However, `puppet resource mount` with a trailing slash will not match.
      # Therefore, this test cheats by performing the munging that occurs during a manifest application
      it 'finds an existing filesystem table entry with trailing slash' do
        munged_name = name_w_slash.gsub(%r{^(.+?)/*$}, '\1')
        step '(setup) add entry to filesystem table'
        MountUtils.add_entry_to_filesystem_table(agent, name_w_slash)

        step 'verify mount with puppet'
        on(agent, puppet_resource('mount', "/#{munged_name}")) do |result|
          fail_test "didn't find the mount #{name_w_slash}" unless %r{'/#{munged_name}':\s+ensure\s+=>\s+'unmounted'}.match?(result.stdout)
        end
      end
    end
  end
end
