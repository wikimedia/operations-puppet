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
        it { is_expected.not_to contain_user('dummy') }
        it { is_expected.not_to contain_group('dummy') }
      end
      context 'users' do
        context "id uid" do
          let(:params) { {id: 999} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t999\t-\t-\t-\n")
          end
          it { is_expected.to contain_user('dummy').with_uid(999) }
        end
        context "id uid:gid" do
          let(:params) { {id: '999:999'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t999:999\t-\t-\t-\n")
          end
          it { is_expected.to contain_user('dummy').with_uid(999).with_gid(999) }
          it { is_expected.to contain_group('dummy').with_gid(999) }
        end
        context "id uid:groupname" do
          let(:params) { {id: '999:foobar'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t999:foobar\t-\t-\t-\n")
          end
          it { is_expected.to contain_user('dummy').with_uid(999).with_gid('foobar') }
          it { is_expected.not_to contain_group('dummy') }
        end
        context "id /some/path" do
          let(:params) { {id: '/some/path'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t/some/path\t-\t-\t-\n")
          end
          it { is_expected.not_to contain_user('dummy') }
          it { is_expected.not_to contain_group('dummy') }
        end
        context "id String" do
          let(:params) { {id: 'groupname'} }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid-gid" do
          let(:params) { {id: '999-999'} }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "description" do
          let(:params) { {description: 'foo bar'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t\"foo bar\"\t-\t-\n")
          end
          it { is_expected.not_to contain_user('dummy') }
          it { is_expected.not_to contain_group('dummy') }
        end
        context "homedir" do
          let(:params) { {home_dir: '/home/foobar'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t-\t/home/foobar\t-\n")
          end
          it { is_expected.to contain_user('dummy').with_home('/home/foobar') }
          it { is_expected.not_to contain_group('dummy') }
        end
        context "shell" do
          let(:params) { {shell: '/bin/sh'} }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("u\tdummy\t-\t-\t-\t/bin/sh\n")
          end
          it { is_expected.to contain_user('dummy').with_shell('/bin/sh') }
          it { is_expected.not_to contain_group('dummy') }
        end
      end
      context 'groups' do
        let(:params) { {usertype: 'group'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("g\tdummy\t-\t-\t-\t-\n")
        end
        it { is_expected.not_to contain_group('dummy') }
        context "id gid" do
          let(:params) { super().merge(id: 999) }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("g\tdummy\t999\t-\t-\t-\n")
          end
          it { is_expected.to contain_group('dummy').with_gid(999) }
        end
        context "id uid:gid" do
          let(:params) { super().merge(id: "999:999") }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid:groupname" do
          let(:params) { super().merge(id: '999:foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id /some/path" do
          let(:params) { super().merge(id: '/some/path') }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("g\tdummy\t/some/path\t-\t-\t-\n")
          end
          it { is_expected.not_to contain_group('dummy') }
        end
        context "id String" do
          let(:params) { super().merge(id: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid-gid" do
          let(:params) { super().merge(id: '500-999') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "description" do
          let(:params) { super().merge(description: 'foo bar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "homedir" do
          let(:params) { super().merge(home_dir: '/home/foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "shell" do
          let(:params) { super().merge(shell: '/bin/sh') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
      context 'modify' do
        let(:params) { {usertype: 'modify'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("m\tdummy\t-\t-\t-\t-\n")
        end
        it { is_expected.not_to contain_group('dummy') }
        context "id gid" do
          let(:params) { super().merge(id: 999) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid:gid" do
          let(:params) { super().merge(id: "999:999") }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid:groupname" do
          let(:params) { super().merge(id: '999:foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id /some/path" do
          let(:params) { super().merge(id: '/some/path') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id String" do
          let(:params) { super().merge(id: 'foobar') }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("m\tdummy\tfoobar\t-\t-\t-\n")
          end
          it { is_expected.not_to contain_group('dummy') }
        end
        context "id uid-gid" do
          let(:params) { super().merge(id: '500-999') }

          # this is a valud group name we cant fail here
          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("m\tdummy\t500-999\t-\t-\t-\n")
          end
          it { is_expected.not_to contain_group('dummy') }
        end
        context "description" do
          let(:params) { super().merge(description: 'foo bar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "homedir" do
          let(:params) { super().merge(home_dir: '/home/foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "shell" do
          let(:params) { super().merge(shell: '/bin/sh') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
      context 'range' do
        let(:params) { {usertype: 'range'} }

        it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
          .with_ensure('file')
          .with_content("r\tdummy\t-\t-\t-\t-\n")
        end
        it { is_expected.not_to contain_group('dummy') }
        context "id gid" do
          let(:params) { super().merge(id: 999) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid:gid" do
          let(:params) { super().merge(id: "999:999") }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid:groupname" do
          let(:params) { super().merge(id: '999:foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id /some/path" do
          let(:params) { super().merge(id: '/some/path') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id String" do
          let(:params) { super().merge(id: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "id uid-gid" do
          let(:params) { super().merge(id: '500-999') }

          it do is_expected.to contain_file('/etc/sysusers.d/dummy.conf')
            .with_content("r\tdummy\t500-999\t-\t-\t-\n")
          end
          it { is_expected.not_to contain_group('dummy') }
        end
        context "description" do
          let(:params) { super().merge(description: 'foo bar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "homedir" do
          let(:params) { super().merge(home_dir: '/home/foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
        context "shell" do
          let(:params) { super().merge(shell: '/bin/sh') }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
