require 'spec_helper_acceptance'

RSpec.context 'ssh_authorized_key: Create' do
  test_name 'should create an entry for an SSH authorized key'

  let(:auth_keys) { '~/.ssh/authorized_keys' }
  let(:name) { "pl#{rand(999_999).to_i}" }
  let(:custom_key_directory) { "/etc/ssh_authorized_keys_#{name}" }
  let(:custom_key) { "#{custom_key_directory}/authorized_keys_#{name}" }

  before(:each) do
    posix_agents.each do |agent|
      on(agent, "cp -a #{auth_keys} /tmp/auth_keys", acceptable_exit_codes: [0, 1])
      on(agent, "rm -f #{auth_keys}")
    end
  end

  after(:each) do
    posix_agents.each do |agent|
      # (teardown) restore the #{auth_keys} file
      on(agent, "mv /tmp/auth_keys #{auth_keys}", acceptable_exit_codes: [0, 1])
    end
  end

  posix_agents.each do |agent|
    it "#{agent} should create an entry for an SSH authorized key" do
      args = ['ensure=present',
              'user=$LOGNAME',
              "type='rsa'",
              "key='mykey'"]
      on(agent, puppet_resource('ssh_authorized_key', name.to_s, args))

      on(agent, "cat #{auth_keys}") do |_res|
        fail_test "didn't find the ssh_authorized_key for #{name}" unless stdout.include? name.to_s
      end
    end

    it "#{agent} should create an entry for an SSH authorized key in a custom location" do
      on(agent, "mkdir #{custom_key_directory}")
      args = ['ensure=present',
              'user=$LOGNAME',
              "type='rsa'",
              "key='mykey'",
              "target='#{custom_key}'"]
      on(agent, puppet_resource('ssh_authorized_key', name.to_s, args))

      on(agent, "cat #{custom_key}") do |_res|
        fail_test "didn't find the ssh_authorized_key for #{name}" unless stdout.include? name.to_s
      end
      on(agent, "rm -rf #{custom_key_directory}")
    end

    it "#{agent} should fail if target user doesn't have permissions for symlinked path" do
      # create a dummy user
      on(agent, puppet_resource('user', 'testuser', 'ensure=present', 'managehome=true'))

      on(agent, "mkdir #{custom_key_directory}")

      # as the user, symlink an owned directory to something inside /root
      on(agent, puppet_resource('file', '/home/testuser/tmp', ['ensure=/etc', 'owner=testuser']))
      args = ['ensure=present',
              'user=testuser',
              "type='rsa'",
              "key='mykey'",
              'drop_privileges=false',
              "target=/home/testuser/tmp/ssh_authorized_keys_#{name}/authorized_keys_#{name}"]
      on(agent, puppet_resource('ssh_authorized_key', name.to_s, args)) do |_res|
        fail_test unless %r{the target path is not trusted}.match?(stderr)
      end
      on(agent, "rm -rf #{custom_key_directory}")

      # purge the user
      on(agent, puppet_resource('user', 'testuser', 'ensure=absent'))
    end

    it "#{agent} should not create directories for SSH authorized key in a custom location" do
      args = ['ensure=present',
              'user=$LOGNAME',
              "type='rsa'",
              "key='mykey'",
              'drop_privileges=false',
              "target='#{custom_key}'"]
      on(agent, puppet_resource('ssh_authorized_key', name.to_s, args), acceptable_exit_codes: [0, 1]) do |_res|
        fail_test unless %r{the target path is not trusted}.match?(stderr)
      end
    end
  end
end
