# -*- coding: utf-8 -*-
#
# Copyright © 2014 eNovance
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import contextlib
import errno
import functools
import logging
import socket

from oslo_utils import encodeutils
from pymemcache import client as pymemcache_client
import six

import tooz
from tooz import _retry
from tooz import coordination
from tooz import locking
from tooz import utils


LOG = logging.getLogger(__name__)


@contextlib.contextmanager
def _failure_translator():
    """Translates common pymemcache exceptions into tooz exceptions.

    https://github.com/pinterest/pymemcache/blob/d995/pymemcache/client.py#L202
    """
    try:
        yield
    except pymemcache_client.MemcacheUnexpectedCloseError as e:
        utils.raise_with_cause(coordination.ToozConnectionError,
                               encodeutils.exception_to_unicode(e),
                               cause=e)
    except (socket.timeout, socket.error,
            socket.gaierror, socket.herror) as e:
        # TODO(harlowja): get upstream pymemcache to produce a better
        # exception for these, using socket (vs. a memcache specific
        # error) seems sorta not right and/or the best approach...
        msg = encodeutils.exception_to_unicode(e)
        if e.errno is not None:
            msg += " (with errno %s [%s])" % (errno.errorcode[e.errno],
                                              e.errno)
        utils.raise_with_cause(coordination.ToozConnectionError,
                               msg, cause=e)
    except pymemcache_client.MemcacheError as e:
        utils.raise_with_cause(tooz.ToozError,
                               encodeutils.exception_to_unicode(e),
                               cause=e)


def _translate_failures(func):

    @six.wraps(func)
    def wrapper(*args, **kwargs):
        with _failure_translator():
            return func(*args, **kwargs)

    return wrapper


class MemcachedLock(locking.Lock):
    _LOCK_PREFIX = b'__TOOZ_LOCK_'

    def __init__(self, coord, name, timeout):
        super(MemcachedLock, self).__init__(self._LOCK_PREFIX + name)
        self.coord = coord
        self.timeout = timeout

    def is_still_owner(self):
        if not self.acquired:
            return False
        else:
            owner = self.get_owner()
            if owner is None:
                return False
            return owner == self.coord._member_id

    def acquire(self, blocking=True, shared=False):
        if shared:
            raise tooz.NotImplemented

        @_retry.retry(stop_max_delay=blocking)
        @_translate_failures
        def _acquire():
            if self.coord.client.add(
                    self.name,
                    self.coord._member_id,
                    expire=self.timeout,
                    noreply=False):
                self.coord._acquired_locks.append(self)
                return True
            if blocking is False:
                return False
            raise _retry.TryAgain

        return _acquire()

    @_translate_failures
    def break_(self):
        return bool(self.coord.client.delete(self.name, noreply=False))

    @_translate_failures
    def release(self):
        if not self.acquired:
            return False
        # NOTE(harlowja): this has the potential to delete others locks
        # especially if this key expired before the delete/release call is
        # triggered.
        #
        # For example:
        #
        # 1. App #1 with coordinator 'A' acquires lock "b"
        # 2. App #1 heartbeats every 10 seconds, expiry for lock let's
        #    say is 11 seconds.
        # 3. App #2 with coordinator also named 'A' blocks trying to get
        #    lock "b" (let's say it retries attempts every 0.5 seconds)
        # 4. App #1 is running behind a little bit, tries to heartbeat but
        #    key has expired (log message is written); at this point app #1
        #    doesn't own the lock anymore but it doesn't know that.
        # 5. App #2 now retries and adds the key, and now it believes it
        #    has the lock.
        # 6. App #1 (still believing it has the lock) calls release, and
        #    deletes app #2 lock, app #2 now doesn't own the lock anymore
        #    but it doesn't know that and now app #(X + 1) can get it.
        # 7. App #2 calls release (repeat #6 as many times as desired)
        #
        # Sadly I don't think memcache has the primitives to actually make
        # this work, redis does because it has lua which can check a session
        # id and then do the delete and bail out if the session id is not
        # as expected but memcache doesn't seem to have any equivalent
        # capability.
        if self not in self.coord._acquired_locks:
            return False
        # Do a ghetto test to see what the value is... (see above note),
        # and how this really can't be done safely with memcache due to
        # it being done in the client side (non-atomic).
        value = self.coord.client.get(self.name)
        if value != self.coord._member_id:
            return False
        else:
            was_deleted = self.coord.client.delete(self.name, noreply=False)
            if was_deleted:
                self.coord._acquired_locks.remove(self)
            return was_deleted

    @_translate_failures
    def heartbeat(self):
        """Keep the lock alive."""
        if self.acquired:
            poked = self.coord.client.touch(self.name,
                                            expire=self.timeout,
                                            noreply=False)
            if poked:
                return True
            LOG.warning("Unable to heartbeat by updating key '%s' with "
                        "extended expiry of %s seconds", self.name,
                        self.timeout)
        return False

    @_translate_failures
    def get_owner(self):
        return self.coord.client.get(self.name)

    @property
    def acquired(self):
        return self in self.coord._acquired_locks


class MemcachedDriver(coordination.CoordinationDriverCachedRunWatchers,
                      coordination.CoordinationDriverWithExecutor):
    """A `memcached`_ based driver.

    This driver users `memcached`_ concepts to provide the coordination driver
    semantics and required API(s). It **is** fully functional and implements
    all of the coordination driver API(s). It stores data into memcache
    using expiries and `msgpack`_ encoded values.

    General recommendations/usage considerations:

    - Memcache (without different backend technology) is a **cache** enough
      said.

    .. _memcached: http://memcached.org/
    .. _msgpack: http://msgpack.org/
    """

    CHARACTERISTICS = (
        coordination.Characteristics.DISTRIBUTED_ACROSS_THREADS,
        coordination.Characteristics.DISTRIBUTED_ACROSS_PROCESSES,
        coordination.Characteristics.DISTRIBUTED_ACROSS_HOSTS,
        coordination.Characteristics.CAUSAL,
    )
    """
    Tuple of :py:class:`~tooz.coordination.Characteristics` introspectable
    enum member(s) that can be used to interogate how this driver works.
    """

    #: Key prefix attached to groups (used in name-spacing keys)
    GROUP_PREFIX = b'_TOOZ_GROUP_'

    #: Key prefix attached to leaders of groups (used in name-spacing keys)
    GROUP_LEADER_PREFIX = b'_TOOZ_GROUP_LEADER_'

    #: Key prefix attached to members of groups (used in name-spacing keys)
    MEMBER_PREFIX = b'_TOOZ_MEMBER_'

    #: Key where all groups 'known' are stored.
    GROUP_LIST_KEY = b'_TOOZ_GROUP_LIST'

    #: Default socket/lock/member/leader timeout used when none is provided.
    DEFAULT_TIMEOUT = 30

    #: String used to keep a key/member alive (until it next expires).
    STILL_ALIVE = b"It's alive!"

    def __init__(self, member_id, parsed_url, options):
        super(MemcachedDriver, self).__init__(member_id, parsed_url, options)
        self.host = (parsed_url.hostname or "localhost",
                     parsed_url.port or 11211)
        default_timeout = self._options.get('timeout', self.DEFAULT_TIMEOUT)
        self.timeout = int(default_timeout)
        self.membership_timeout = int(self._options.get(
            'membership_timeout', default_timeout))
        self.lock_timeout = int(self._options.get(
            'lock_timeout', default_timeout))
        self.leader_timeout = int(self._options.get(
            'leader_timeout', default_timeout))
        max_pool_size = self._options.get('max_pool_size', None)
        if max_pool_size is not None:
            self.max_pool_size = int(max_pool_size)
        else:
            self.max_pool_size = None
        self._acquired_locks = []

    @staticmethod
    def _msgpack_serializer(key, value):
        if isinstance(value, six.binary_type):
            return value, 1
        return utils.dumps(value), 2

    @staticmethod
    def _msgpack_deserializer(key, value, flags):
        if flags == 1:
            return value
        if flags == 2:
            return utils.loads(value)
        raise coordination.SerializationError("Unknown serialization"
                                              " format '%s'" % flags)

    @_translate_failures
    def _start(self):
        super(MemcachedDriver, self)._start()
        self.client = pymemcache_client.PooledClient(
            self.host,
            serializer=self._msgpack_serializer,
            deserializer=self._msgpack_deserializer,
            timeout=self.timeout,
            connect_timeout=self.timeout,
            max_pool_size=self.max_pool_size)
        # Run heartbeat here because pymemcache use a lazy connection
        # method and only connect once you do an operation.
        self.heartbeat()

    @_translate_failures
    def _stop(self):
        super(MemcachedDriver, self)._stop()
        for lock in list(self._acquired_locks):
            lock.release()
        self.client.delete(self._encode_member_id(self._member_id))
        self.client.close()

    def _encode_group_id(self, group_id):
        return self.GROUP_PREFIX + group_id

    def _encode_member_id(self, member_id):
        return self.MEMBER_PREFIX + member_id

    def _encode_group_leader(self, group_id):
        return self.GROUP_LEADER_PREFIX + group_id

    @_retry.retry()
    def _add_group_to_group_list(self, group_id):
        """Add group to the group list.

        :param group_id: The group id
        """
        group_list, cas = self.client.gets(self.GROUP_LIST_KEY)
        if cas:
            group_list = set(group_list)
            group_list.add(group_id)
            if not self.client.cas(self.GROUP_LIST_KEY,
                                   list(group_list), cas):
                # Someone updated the group list before us, try again!
                raise _retry.TryAgain
        else:
            if not self.client.add(self.GROUP_LIST_KEY,
                                   [group_id], noreply=False):
                # Someone updated the group list before us, try again!
                raise _retry.TryAgain

    @_retry.retry()
    def _remove_from_group_list(self, group_id):
        """Remove group from the group list.

        :param group_id: The group id
        """
        group_list, cas = self.client.gets(self.GROUP_LIST_KEY)
        group_list = set(group_list)
        group_list.remove(group_id)
        if not self.client.cas(self.GROUP_LIST_KEY,
                               list(group_list), cas):
            # Someone updated the group list before us, try again!
            raise _retry.TryAgain

    def create_group(self, group_id):
        encoded_group = self._encode_group_id(group_id)

        @_translate_failures
        def _create_group():
            if not self.client.add(encoded_group, {}, noreply=False):
                raise coordination.GroupAlreadyExist(group_id)
            self._add_group_to_group_list(group_id)

        return MemcachedFutureResult(self._executor.submit(_create_group))

    def get_groups(self):

        @_translate_failures
        def _get_groups():
            return self.client.get(self.GROUP_LIST_KEY) or []

        return MemcachedFutureResult(self._executor.submit(_get_groups))

    def join_group(self, group_id, capabilities=b""):
        encoded_group = self._encode_group_id(group_id)

        @_retry.retry()
        @_translate_failures
        def _join_group():
            group_members, cas = self.client.gets(encoded_group)
            if group_members is None:
                raise coordination.GroupNotCreated(group_id)
            if self._member_id in group_members:
                raise coordination.MemberAlreadyExist(group_id,
                                                      self._member_id)
            group_members[self._member_id] = {
                b"capabilities": capabilities,
            }
            if not self.client.cas(encoded_group, group_members, cas):
                # It changed, let's try again
                raise _retry.TryAgain
            self._joined_groups.add(group_id)

        return MemcachedFutureResult(self._executor.submit(_join_group))

    def leave_group(self, group_id):
        encoded_group = self._encode_group_id(group_id)

        @_retry.retry()
        @_translate_failures
        def _leave_group():
            group_members, cas = self.client.gets(encoded_group)
            if group_members is None:
                raise coordination.GroupNotCreated(group_id)
            if self._member_id not in group_members:
                raise coordination.MemberNotJoined(group_id, self._member_id)
            del group_members[self._member_id]
            if not self.client.cas(encoded_group, group_members, cas):
                # It changed, let's try again
                raise _retry.TryAgain
            self._joined_groups.discard(group_id)

        return MemcachedFutureResult(self._executor.submit(_leave_group))

    def _destroy_group(self, group_id):
        self.client.delete(self._encode_group_id(group_id))

    def delete_group(self, group_id):
        encoded_group = self._encode_group_id(group_id)

        @_retry.retry()
        @_translate_failures
        def _delete_group():
            group_members, cas = self.client.gets(encoded_group)
            if group_members is None:
                raise coordination.GroupNotCreated(group_id)
            if group_members != {}:
                raise coordination.GroupNotEmpty(group_id)
            # Delete is not atomic, so we first set the group to
            # using CAS, and then we delete it, to avoid race conditions.
            if not self.client.cas(encoded_group, None, cas):
                raise _retry.TryAgain
            self.client.delete(encoded_group)
            self._remove_from_group_list(group_id)

        return MemcachedFutureResult(self._executor.submit(_delete_group))

    @_retry.retry()
    @_translate_failures
    def _get_members(self, group_id):
        encoded_group = self._encode_group_id(group_id)
        group_members, cas = self.client.gets(encoded_group)
        if group_members is None:
            raise coordination.GroupNotCreated(group_id)
        actual_group_members = {}
        for m, v in six.iteritems(group_members):
            # Never kick self from the group, we know we're alive
            if (m == self._member_id or
               self.client.get(self._encode_member_id(m))):
                actual_group_members[m] = v
        if group_members != actual_group_members:
            # There are some dead members, update the group
            if not self.client.cas(encoded_group, actual_group_members, cas):
                # It changed, let's try again
                raise _retry.TryAgain
        return actual_group_members

    def get_members(self, group_id):

        def _get_members():
            return set(self._get_members(group_id).keys())

        return MemcachedFutureResult(self._executor.submit(_get_members))

    def get_member_capabilities(self, group_id, member_id):

        def _get_member_capabilities():
            group_members = self._get_members(group_id)
            if member_id not in group_members:
                raise coordination.MemberNotJoined(group_id, member_id)
            return group_members[member_id][b'capabilities']

        return MemcachedFutureResult(
            self._executor.submit(_get_member_capabilities))

    def update_capabilities(self, group_id, capabilities):
        encoded_group = self._encode_group_id(group_id)

        @_retry.retry()
        @_translate_failures
        def _update_capabilities():
            group_members, cas = self.client.gets(encoded_group)
            if group_members is None:
                raise coordination.GroupNotCreated(group_id)
            if self._member_id not in group_members:
                raise coordination.MemberNotJoined(group_id, self._member_id)
            group_members[self._member_id][b'capabilities'] = capabilities
            if not self.client.cas(encoded_group, group_members, cas):
                # It changed, try again
                raise _retry.TryAgain

        return MemcachedFutureResult(
            self._executor.submit(_update_capabilities))

    def get_leader(self, group_id):

        def _get_leader():
            return self._get_leader_lock(group_id).get_owner()

        return MemcachedFutureResult(self._executor.submit(_get_leader))

    @_translate_failures
    def heartbeat(self):
        self.client.set(self._encode_member_id(self._member_id),
                        self.STILL_ALIVE,
                        expire=self.membership_timeout)
        # Reset the acquired locks
        for lock in self._acquired_locks:
            lock.heartbeat()
        return min(self.membership_timeout,
                   self.leader_timeout,
                   self.lock_timeout)

    def get_lock(self, name):
        return MemcachedLock(self, name, self.lock_timeout)

    def _get_leader_lock(self, group_id):
        return MemcachedLock(self, self._encode_group_leader(group_id),
                             self.leader_timeout)

    @_translate_failures
    def run_elect_coordinator(self):
        for group_id, hooks in six.iteritems(self._hooks_elected_leader):
            # Try to grab the lock, if that fails, that means someone has it
            # already.
            leader_lock = self._get_leader_lock(group_id)
            if leader_lock.acquire(blocking=False):
                # We got the lock
                hooks.run(coordination.LeaderElected(
                    group_id,
                    self._member_id))

    def run_watchers(self, timeout=None):
        result = super(MemcachedDriver, self).run_watchers(timeout=timeout)
        self.run_elect_coordinator()
        return result


MemcachedFutureResult = functools.partial(
    coordination.CoordinatorResult,
    failure_translator=_failure_translator)
