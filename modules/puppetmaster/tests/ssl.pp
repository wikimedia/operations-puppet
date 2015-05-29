class { 'puppetmaster::ssl':
    server_name => 'puppet',
    ca => 'false',
}
