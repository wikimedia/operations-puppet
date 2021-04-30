require_relative '../../../../rake_modules/spec_helper'

describe 'rsync::server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let :fragment_file do
        "/etc/rsync.d/header"
      end

      describe 'when using default params' do
        it {
          should_not contain_class('xinetd')
          should_not contain_xinetd__service('rsync').with({ 'bind' => '0.0.0.0' })
          should contain_service('rsync')
          should_not contain_file('/etc/rsync-motd')
          should contain_file(fragment_file).with_content(/^use chroot\s*=\s*yes$/)
          should contain_file(fragment_file).with_content(/^address\s*=\s*0.0.0.0$/)
        }
      end

      describe 'when overriding use_chroot' do
        let :params do
          { :use_chroot => 'no' }
        end

        it {
          should contain_file(fragment_file).with_content(/^use chroot\s*=\s*no$/)
        }
      end

      describe 'when overriding address' do
        let :params do
          { :address => '10.0.0.42' }
        end

        it {
          should contain_file(fragment_file).with_content(/^address\s*=\s*10.0.0.42$/)
        }
      end

      describe 'when passing configuration' do
        let :params do
          {
            :rsyncd_conf => {
              'forward lookup' => 'no',
              'use chroot' => 'yes',
            }
          }
        end

        it {
          should contain_file(fragment_file)
            .with_content(/^use chroot = yes$/)
            .with_content(/^forward lookup = no$/)
        }
      end
    end
  end
end
