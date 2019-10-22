require 'spec_helper'

describe 'bacula::client::job', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :fileset      => 'root',
        :jobdefaults  => 'testdefaults',
        }
    }
    let(:facts) do
      {
        'lsbdistrelease' => '10.1',
        'lsbdistid' => 'Debian'
      }
    end
end
