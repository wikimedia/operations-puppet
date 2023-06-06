require 'spec_helper_acceptance'

RSpec.context 'Mailalias: should create an email alias' do
  name = "pl#{rand(999_999).to_i}"

  before(:all) do
    non_windows_agents.each do |agent|
      on(agent, 'cp /etc/aliases /tmp/aliases', acceptable_exit_codes: [0, 1])
    end
  end

  after(:all) do
    non_windows_agents.each do |agent|
      on(agent, 'mv /tmp/aliases /etc/aliases', acceptable_exit_codes: [0, 1])
    end
  end

  non_windows_agents.each do |agent|
    it 'creates a mailalias resource' do
      # create a mailalias with puppet
      args = ['ensure=present',
              'recipient="foo,bar,baz"']
      on(agent, puppet_resource('mailalias', name, args))

      # verify the alias exists
      on(agent, 'cat /etc/aliases') do |res|
        assert_match(%r{#{name}:.*foo,bar,baz}, res.stdout, 'mailalias not in aliases file')
      end
    end
  end
end
