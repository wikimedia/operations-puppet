require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::sysuser' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'dummy'}

      context 'when using defaults' do
        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("u\tdummy\t-\t-\t-\t-\n")
        end
      end
      context 'users' do
        context "id uid" do
          let(:params) { {id: 999} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t999\t-\t-\t-\n")
          end
        end
        context "description" do
          let(:params) { {description: 'foo bar'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t\"foo bar\"\t-\t-\n")
          end
        end
        context "homedir" do
          let(:params) { {home_dir: '/home/foobar'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t-\t/home/foobar\t-\n")
          end
        end
        context "shell" do
          let(:params) { {shell: '/bin/sh'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t-\t-\t/bin/sh\n")
          end
        end
      end
      context 'groups' do
        let(:params) { {usertype: 'group'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("g\tdummy\t-\t-\t-\t-\n")
        end
      end
      context 'modify' do
        let(:params) { {usertype: 'modify'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("m\tdummy\t-\t-\t-\t-\n")
        end
      end
      context 'range' do
        let(:params) { {usertype: 'range'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("r\tdummy\t-\t-\t-\t-\n")
        end
      end
    end
  end
end
