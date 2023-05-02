require 'spec_helper_acceptance'

RSpec.context 'when modifying host files' do
  agents.each do |agent|
    context "on #{agent}" do
      let(:target) { agent.tmpfile('host-modify') }

      after(:each) do
        on(agent, "test #{target} && rm -f #{target}")
      end

      it 'modifies a host address' do
        on agent, "printf '127.0.0.9 test alias\n' > #{target}"
        on(agent, puppet_resource('host', 'test', "target=#{target}",
                                  'ensure=present', 'ip=127.0.0.10', 'host_aliases=alias'))

        on(agent, "cat #{target}") do |result|
          fail_test 'the address was not updated' unless
            %r{^127\.0\.0\.10[[:space:]]+test[[:space:]]+alias[[:space:]]*$}.match?(result.stdout)
        end
      end

      it 'modifies a host alias' do
        on agent, "printf '127.0.0.8 test alias\n' > #{target}"
        on(agent, puppet_resource('host', 'test', "target=#{target}",
                                  'ensure=present', 'ip=127.0.0.8', 'host_aliases=banzai'))

        on(agent, "cat #{target}") do |result|
          fail_test 'the alias was not updated' unless
            %r{^127\.0\.0\.8[[:space:]]+test[[:space:]]+banzai[[:space:]]*$}.match?(result.stdout)
        end
      end
    end
  end
end
