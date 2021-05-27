concat { '/tmp/file':
  format => 'yaml', # See REFERENCE.md for more formats
}

concat::fragment { '1':
  target  => '/tmp/file',
  content => '{"one": "foo"}',
}

concat::fragment { '2':
  target  => '/tmp/file',
  content => '{"two": "bar"}',
}
