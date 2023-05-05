# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ci::gitcache' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      it { is_expected.to compile }
      it "creates repositories parent directory" do
          is_expected.to contain_file('/srv/git/mediawiki').with_ensure('directory')
          is_expected.to contain_file('/srv/git/operations').with_ensure('directory')
      end
      it "clones bare repositories" do
          is_expected.to contain_git__clone('mediawiki/core')
              .with_directory('/srv/git/mediawiki/core.git')
              .with_bare(true)
          is_expected.to contain_git__clone('operations/puppet')
              .with_directory('/srv/git/operations/puppet.git')
              .with_bare(true)
      end
    end
  end
end
