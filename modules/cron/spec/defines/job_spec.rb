require 'spec_helper'

describe 'cron::job' do
  let( :title )  { 'mysql_backup' }
  let( :params ) {{
    :minute      => '45',
    :hour        => '7',
    :date        => '12',
    :month       => '7',
    :weekday     => '*',
    :environment => [ 'MAILTO="root"', 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    :user        => 'root',
    :command     => 'mysqldump -u root test_db >some_file',
  }}

  it do
    cron_timestamp = ""
    [ :minute, :hour, :date, :month, :weekday ].each do |k|
      cron_timestamp << "#{params[k]} "
    end
    cron_timestamp.strip!

    should contain_file( "job_#{title}" ).with(
      'ensure'  => 'file',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0640',
      'path'    => "/etc/cron.d/#{title}"
    ).with_content(
      /\n#{params[:environment].join('\n')}\n/
    ).with_content(
      /\n#{cron_timestamp}\s+/
    ).with_content(
      /\s+#{params[:user]}\s+/
    ).with_content(
      /\s+#{params[:command]}\n/
    )
  end
end

