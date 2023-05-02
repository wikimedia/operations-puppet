require 'spec_helper_acceptance'

RSpec.context 'when querying all hosts from a host file' do
  agents.each do |agent|
    context "on #{agent}" do
      let(:backup) { agent.tmpfile('host-query') }
      let(:content) do
        <<END
127.0.0.1 test1 test1.local
127.0.0.2 test2 test2.local
127.0.0.3 test3 test3.local
127.0.0.4 test4 test4.local
END
      end

      before(:each) do
        on(agent, "cp /etc/hosts #{backup}")
        on agent, 'cat > /etc/hosts', stdin: content
      end

      after(:each) do
        on agent, "cat #{backup} > /etc/hosts && rm -f #{backup}"
      end

      it 'returns 4 host records' do
        on(agent, puppet_resource('host')) do |result|
          found = result.stdout.scan(%r{host \{ '([^']+)'}).flatten.sort
          fail_test "the list of returned hosts was wrong: #{found.join(', ')}" unless
            found == ['test1', 'test2', 'test3', 'test4']

          count = result.stdout.scan(%r{ensure\s+=>\s+'present'}).length
          fail_test "found #{count} records, wanted 4" unless count == 4
        end
      end
    end
  end
end
