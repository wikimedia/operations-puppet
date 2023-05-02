require 'spec_helper_acceptance'

RSpec.context 'when managing host files' do
  agents.each do |agent|
    context "on #{agent}" do
      let(:target) { agent.tmpfile('host-destroy') }

      after(:each) do
        on(agent, "test #{target} && rm -f #{target}")
      end

      it 'deletes a host record' do
        line = '127.0.0.7 test1'

        on agent, "printf '#{line}\n' > #{target}"
        on(agent, puppet_resource('host', 'test1', "target=#{target}",
                                  'ensure=absent', 'ip=127.0.0.7'))
        on(agent, "cat #{target}") do |result|
          fail_test 'the content was still present' if result.stdout.include? line
        end
      end

      it 'does not purge valid host records if file contains malformed content' do
        on(agent, "printf '127.0.0.2 existing alias\n' > #{target}")
        on(agent, "printf '==\n' >> #{target}")

        on(agent, puppet_resource('host', 'test', "target=#{target}",
                                  'ensure=present', 'ip=127.0.0.3', 'host_aliases=foo'))

        on(agent, "cat #{target}") do |result|
          fail_test 'existing host data was deleted' unless result.stdout.include? 'existing'
        end
      end
    end
  end
end
