# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9', '10'],
    }
  ]
}

describe 'adduser' do
  let(:node) { 'foobar.example.com' }
  let(:params) do
    {
      # default_shell: "/bin/bash",
      # default_home: "/home",
      # use_group_homes: false,
      # use_letter_homes: false,
      # skel_dir: "/etc/skel",
      # first_system_uid: "100",
      # last_system_uid: "499",
      # first_system_gid: "100",
      # last_system_gid: "499",
      # first_uid: "1000",
      # last_uid: "59999",
      # first_gid: "1000",
      # last_gid: "59999",
      # use_usergroups: true,
      # users_gid: "100",
      # dir_mode: "0755",
      # home_setgid: false,
      # quota_user: "",
      # skel_ignore_regex: "dpkg-(old|new|dist|save)",
      # extra_groups: [],
      # name_regex: :undef,
    }
  end

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/adduser.conf').with(
            ensure: 'file',
            mode: '0644'
          ).with_content(
            %r{^DSHELL=/bin/bash$}
          ).with_content(
            %r{^DHOME=/home$}
          ).with_content(
            /^GROUPHOMES=no$/
          ).with_content(
            /^LETTERHOMES=no$/
          ).with_content(
            %r{^SKEL=/etc/skel$}
          ).with_content(
            /^FIRST_SYSTEM_UID=100$/
          ).with_content(
            /^LAST_SYSTEM_UID=499$/
          ).with_content(
            /^FIRST_SYSTEM_GID=100$/
          ).with_content(
            /^LAST_SYSTEM_GID=499$/
          ).with_content(
            /^FIRST_UID=1000$/
          ).with_content(
            /^LAST_UID=59999$/
          ).with_content(
            /^FIRST_GID=1000$/
          ).with_content(
            /^LAST_GID=59999$/
          ).with_content(
            /^USERGROUPS=yes$/
          ).with_content(
            /^USERS_GID=100$/
          ).with_content(
            /^DIR_MODE=0755$/
          ).with_content(
            /^SETGID_HOME=no$/
          ).with_content(
            /^QUOTAUSER=""$/
          ).with_content(
            /^SKEL_IGNORE_REGEX="dpkg-\(old\|new\|dist\|save\)"$/
          ).without_content(
            /EXTRA_GROUPS|ADD_EXTRA_GROUPS|NAME_REGEX/
          )
        end
      end
      describe 'Change Defaults' do
        context 'default_shell' do
          before(:each) { params.merge!(default_shell: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              %r{DSHELL=/foo/bar}
            )
          end
        end
        context 'default_home' do
          before(:each) { params.merge!(default_home: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              %r{DHOME=/foo/bar}
            )
          end
        end
        context 'use_group_homes' do
          before(:each) { params.merge!(use_group_homes: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /GROUPHOMES=yes/
            )
          end
        end
        context 'use_letter_homes' do
          before(:each) { params.merge!(use_letter_homes: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /LETTERHOMES=yes/
            )
          end
        end
        context 'skel_dir' do
          before(:each) { params.merge!(skel_dir: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              %r{SKEL=/foo/bar}
            )
          end
        end
        context 'first_system_uid' do
          before(:each) { params.merge!(first_system_uid: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /FIRST_SYSTEM_UID=42/
            )
          end
        end
        context 'last_system_uid' do
          before(:each) { params.merge!(last_system_uid: 142) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /LAST_SYSTEM_UID=142/
            )
          end
        end
        context 'first_system_gid' do
          before(:each) { params.merge!(first_system_gid: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /FIRST_SYSTEM_GID=42/
            )
          end
        end
        context 'last_system_gid' do
          before(:each) { params.merge!(last_system_gid: 142) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /LAST_SYSTEM_GID=142/
            )
          end
        end
        context 'first_uid' do
          before(:each) { params.merge!(first_uid: 1042) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /FIRST_UID=1042/
            )
          end
        end
        context 'last_uid' do
          before(:each) { params.merge!(last_uid: 1042) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /LAST_UID=1042/
            )
          end
        end
        context 'first_gid' do
          before(:each) { params.merge!(first_gid: 1042) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /FIRST_GID=1042/
            )
          end
        end
        context 'last_gid' do
          before(:each) { params.merge!(last_gid: 1042) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /LAST_GID=1042/
            )
          end
        end
        context 'use_usergroups' do
          before(:each) { params.merge!(use_usergroups: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /USERGROUPS=no/
            )
          end
        end
        context 'users_gid' do
          before(:each) { params.merge!(users_gid: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /USERS_GID=42/
            )
          end
        end
        context 'dir_mode' do
          before(:each) { params.merge!(dir_mode: '0444') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /DIR_MODE=0444/
            )
          end
        end
        context 'home_setgid' do
          before(:each) { params.merge!(home_setgid: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /SETGID_HOME=yes/
            )
          end
        end
        context 'quota_user' do
          before(:each) { params.merge!(quota_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /QUOTAUSER="foobar"/
            )
          end
        end
        context 'skel_ignore_regex' do
          before(:each) { params.merge!(skel_ignore_regex: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /SKEL_IGNORE_REGEX="foobar"/
            )
          end
        end
        context 'extra_groups' do
          before(:each) { params.merge!(extra_groups: ['foobar']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /EXTRA_GROUPS="foobar"/
            ).with_content(
              /ADD_EXTRA_GROUPS=1/
            )
          end
        end
        context 'name_regex' do
          before(:each) { params.merge!(name_regex: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/adduser.conf').with_content(
              /NAME_REGEX="foobar"/
            )
          end
        end
      end
      describe 'Error handeling' do
        context 'first_system_uid larger then last_system_uid' do
          before(:each) { params.merge!(first_system_uid: 500) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /first_system_uid.*must be smaller then \$last_system_uid/
            )
          end
        end
        context 'first_system_gid to larger then last_system_gid' do
          before(:each) { params.merge!(first_system_gid: 500) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /first_system_gid.*must be smaller then \$last_system_gid/
            )
          end
        end
        context 'first_uid larger then last_uid' do
          before(:each) { params.merge!(first_uid: 600_00) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /first_uid.*must be smaller then \$last_uid/
            )
          end
        end
        context 'first_gid to larger then last_gid' do
          before(:each) { params.merge!(first_gid: 600_00) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /first_gid.*must be smaller then \$last_gid/
            )
          end
        end
        context 'first_uid smaller then last_system_uid' do
          before(:each) { params.merge!(first_uid: 498) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /last_system_uid.*must be smaller then \$first_uid/
            )
          end
        end
        context 'first_gid smaller then last_system_gid' do
          before(:each) { params.merge!(first_gid: 498) }
          it do
            is_expected.to raise_error(
              Puppet::Error, /last_system_gid.*must be smaller then \$first_gid/
            )
          end
        end
      end
    end
  end
end
