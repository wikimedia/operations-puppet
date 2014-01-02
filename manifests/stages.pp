stage { 'first': before => Stage[main] }
stage { 'last': require => Stage[main] }

class {
    'apt::update': stage => first;
}
