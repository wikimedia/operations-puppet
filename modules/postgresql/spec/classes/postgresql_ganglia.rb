require 'spec_helper'

describe 'postgresql::ganglia', :type => :class do
    let(:params) do {
        :ensure           => 'present',
        }
    end

    context 'ensure present' do
        it { should contain_file('/usr/lib/ganglia/python_modules/postgresql.py').with_ensure('present') }
        it { should contain_file('/etc/ganglia/conf.d/postgresql.pyconf').with_ensure('present') }
    end
end

describe 'postgresql::slave', :type => :class do
    let(:params) do {
        :ensure           => 'absent',
        }
    end

    context 'ensure absent' do
        it { should contain_file('/usr/lib/ganglia/python_modules/postgresql.py').with_ensure('absent') }
        it { should contain_file('/etc/ganglia/conf.d/postgresql.pyconf').with_ensure('absent') }
    end
end
