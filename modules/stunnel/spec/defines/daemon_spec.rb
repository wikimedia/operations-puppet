require_relative '../../../../rake_modules/spec_helper'

describe 'stunnel::daemon' do
  let(:title) { 'foobar' }
  let(:facts) { {} }
  let(:params) do
    {
      accept_port: 1337,
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # let (:pre_condition) { "class {'::foobar' }" }
  # it { pp catalogue.resources }

  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/stunnel/daemons/foobar.conf').with(
            ensure: 'present'
          ).with_content(
            /
            client\s=\sno\n
            verifyChain\s=\sno\n
            verifyPeer\s=\sno\n
            sslVersion\s=\sTLSv1.3\n
            debug\s=\s5\n\n
            \[foobar\]\n
            accept\s=\slocalhost:1337\n
            /x
          )
        end
      end
      describe 'Additional parameters Defaults' do
        context 'exec' do
          before { params.merge!(exec: '/bin/foobar42') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/stunnel/daemons/foobar.conf').with(
              ensure: 'present'
            ).with_content(
              %r{
              client\s=\sno\n
              verifyChain\s=\sno\n
              verifyPeer\s=\sno\n
              sslVersion\s=\sTLSv1.3\n
              debug\s=\s5\n\n
              \[foobar\]\n
              accept\s=\slocalhost:1337\n
              exec\s=\s/bin/foobar42\n
              }x
            )
          end
        end
        context 'xecargs' do
          before { params.merge!(exec: '/bin/foo', exec_args: ['foobar', '42']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/stunnel/daemons/foobar.conf').with(
              ensure: 'present'
            ).with_content(
              %r{
              client\s=\sno\n
              verifyChain\s=\sno\n
              verifyPeer\s=\sno\n
              sslVersion\s=\sTLSv1.3\n
              debug\s=\s5\n\n
              \[foobar\]\n
              accept\s=\slocalhost:1337\n
              exec\s=\s/bin/foo\n
              execargs\s=\sfoobar\s42\n
              }x
            )
          end
        end
        context 'connect port' do
          before { params.merge!(connect_port: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/stunnel/daemons/foobar.conf').with(
              ensure: 'present'
            ).with_content(
              /
              client\s=\sno\n
              verifyChain\s=\sno\n
              verifyPeer\s=\sno\n
              sslVersion\s=\sTLSv1.3\n
              debug\s=\s5\n\n
              \[foobar\]\n
              accept\s=\slocalhost:1337\n
              connect\s=\s42\n
              /x
            )
          end
        end
        context 'connect host and port' do
          before { params.merge!(connect_host: 'vpn.example.org', connect_port: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/stunnel/daemons/foobar.conf').with(
              ensure: 'present'
            ).with_content(
              /
              client\s=\sno\n
              verifyChain\s=\sno\n
              verifyPeer\s=\sno\n
              sslVersion\s=\sTLSv1.3\n
              debug\s=\s5\n\n
              \[foobar\]\n
              accept\s=\slocalhost:1337\n
              connect\s=\svpn.example.org:42\n
              /x
            )
          end
        end
      end
    end
  end
end
