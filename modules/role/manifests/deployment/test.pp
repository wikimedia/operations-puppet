# === Class role::deployment::test
# Test trebuchet by installing a simple test repo
class role::deployment::test {
    package { 'test/testrepo':
        provider => 'trebuchet',
    }
}
