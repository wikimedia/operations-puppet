# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'backup::offsite', :type => :define do
    let(:title) { 'something' }

    context 'with ensure_packages => latest' do
        let(:params) { { :ensure_packages => 'latest' } }

        it { is_expected.to compile.and_raise_error(/got 'latest'/) }
    end

    context 'with ensure_packages => present' do
        let(:params) { { :ensure_packages => 'present' } }

        it { is_expected.to contain_package('rclone').with_ensure('installed') }
    end

    context 'with ensure_packages => absent' do
        let(:params) { { :ensure_packages => 'absent' } }

        it { is_expected.to contain_package('rclone').with_ensure('absent') }
    end
end
