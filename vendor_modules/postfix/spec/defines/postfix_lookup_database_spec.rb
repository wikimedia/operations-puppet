require 'spec_helper'

describe 'postfix::lookup::database' do
  let(:title) do
    '/etc/postfix/test'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'with a hashed database' do
        let(:params) do
          {
            type:    'dbm',
            content: "postmaster\tpostmaster@example.com\n",
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('postmap dbm:/etc/postfix/test').with_unless("[ -f /etc/postfix/test.pag ] && [ $(stat -c '%Y' /etc/postfix/test.pag) -gt $(stat -c '%Y' /etc/postfix/test) ] && [ -f /etc/postfix/test.dir ] && [ $(stat -c '%Y' /etc/postfix/test.dir) -gt $(stat -c '%Y' /etc/postfix/test) ]") } # rubocop:disable LineLength
        it { is_expected.to contain_file('/etc/postfix/test') }
        it { is_expected.to contain_file('/etc/postfix/test.pag') }
        it { is_expected.to contain_file('/etc/postfix/test.dir') }
        it { is_expected.to contain_postfix__lookup__database('/etc/postfix/test') }
      end

      context 'with a flat database' do
        let(:params) do
          {
            type:    'texthash',
            content: "postmaster\tpostmaster@example.com\n",
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/postfix/test').that_notifies('Class[postfix::service]') }
        it { is_expected.to contain_postfix__lookup__database('/etc/postfix/test') }
      end
    end
  end
end
