require 'spec_helper'

describe 'postgresql::postgis', :type => :class do
    let(:params) do {
        :pgversion => '9.1',
        :ensure => 'present',
        }
    end

    context 'ensure present' do
        it { should contain_package('postgresql-9.1-postgis').with_ensure('present') }
    end
end

describe 'postgresql::postgis', :type => :class do
    let(:params) do {
        :pgversion => '9.1',
        :ensure => 'absent',
        }
    end

    context 'ensure absent' do
        it { should contain_package('postgresql-9.1-postgis').with_ensure('absent') }
    end
end
