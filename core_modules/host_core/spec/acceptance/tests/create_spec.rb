require 'spec_helper_acceptance'

RSpec.context 'when creating host files' do
  agents.each do |agent|
    context "on #{agent}" do
      let(:target) { agent.tmpfile('host-create') }

      after(:each) do
        on(agent, "test #{target} && rm -f #{target}")
      end

      it 'creates a host record' do
        on(agent, puppet_resource('host', 'test', 'ensure=present',
                                  'ip=127.0.0.1', "target=#{target}"))
        on(agent, "cat #{target}") do |result|
          fail_test 'record was not present' unless %r{^127\.0\.0\.1[[:space:]]+test}.match?(result.stdout)
        end
      end

      it 'creates host aliases' do
        on(agent, puppet_resource('host', 'test', 'ensure=present',
                                  'ip=127.0.0.7', "target=#{target}", 'host_aliases=alias'))

        on(agent, "cat #{target}") do |result|
          fail_test 'alias was missing' unless
            %r{^127\.0\.0\.7[[:space:]]+test[[:space:]]alias}.match?(result.stdout)
        end
      end

      it "doesn't create the entry if it already exists" do
        on agent, "printf '127.0.0.2 test alias\n' > #{target}"

        step 'tell puppet to ensure the host exists'
        on(agent, puppet_resource('host', 'test', "target=#{target}",
                                  'ensure=present', 'ip=127.0.0.2', 'host_aliases=alias')) do |result|
          fail_test 'darn, we created the host record' if
            result.stdout.include? '/Host[test1]/ensure: created'
        end
      end

      it 'requires an ipaddress' do
        skip_test if agent['locale'] == 'ja'

        on(agent, puppet_resource('host', 'test', "target=#{target}",
                                  'host_aliases=alias')) do |result|
          fail_test "puppet didn't complain about the missing attribute" unless
            result.stderr.include? 'ip is a required attribute for hosts'
        end

        on(agent, "cat #{target}") do |result|
          fail_test 'the host was apparently added to the file' if result.stdout.include? 'test'
        end
      end
    end
  end
end
