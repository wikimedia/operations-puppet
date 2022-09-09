# SPDX-License-Identifier: Apache-2.0
# /dev/./urandom is needed due to a java won't fix bug
# https://bugs.java.com/bugdatabase/view_bug.do?bug_id=6202721 
type Java::Egd_source = Enum['/dev/random', '/dev/urandom', '/dev/./urandom']
