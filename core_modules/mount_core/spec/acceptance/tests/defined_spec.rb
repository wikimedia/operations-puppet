require 'spec_helper_acceptance'

require 'mount_utils'

RSpec.context 'when managing mounts' do
  agents.each do |agent|
    context "on #{agent}" do
      include_context('mount context', agent)

      it 'defines a mount entry' do
        step 'creates a mount'
        args = ['ensure=defined',
                "fstype=#{fs_type}",
                "device='/tmp/#{name}'"]
        on(agent, puppet_resource('mount', "/#{name}", args))

        step 'verify entry in filesystem table'
        on(agent, "cat #{fs_file}")  do |result|
          fail_test "didn't find the mount #{name}" unless result.stdout.include?(name)
        end
      end

      it 'defines a mount entry with whitespace' do
        step 'creates a mount'
        args = ['ensure=defined',
                "fstype=#{fs_type}",
                "device='/tmp/#{name_w_whitespace}'"]
        on(agent, puppet_resource('mount', "'/#{name_w_whitespace}'", args))

        step 'verify entry in filesystem table'
        on(agent, "cat #{fs_file}") do |result|
          munged_name = name_w_whitespace.gsub(' ', '\\\040')
          fail_test "didn't find the mount #{name_w_whitespace}" unless result.stdout.include?(munged_name)
        end
      end
    end
  end
end
