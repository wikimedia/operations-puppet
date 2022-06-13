#!/usr/bin/env python
# SPDX-License-Identifier: Apache-2.0
# -*- encoding: utf-8 -*-
from backy2.logging import logger
from backy2.meta_backends import MetaBackend as _MetaBackend
from collections import namedtuple
from sqlalchemy import Column, String, Integer, BigInteger, ForeignKey
from sqlalchemy import func, distinct, desc
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, query
from sqlalchemy.sql import text
from sqlalchemy.types import DateTime, Date
import binascii
import csv
import datetime
import os
import sqlalchemy
import sys
import time
import uuid


METADATA_VERSION = '2.12'

DELETE_CANDIDATE_MAYBE = 0
DELETE_CANDIDATE_SURE = 1
DELETE_CANDIDATE_DELETED = 2


Base = declarative_base()

class Stats(Base):
    __tablename__ = 'stats'
    date = Column("date", DateTime , default=func.now(), nullable=False)
    id = Column(Integer, primary_key=True)
    version_uid = Column(String(36), index=True)
    version_name = Column(String, nullable=False)
    version_size_bytes = Column(BigInteger, nullable=False)
    version_size_blocks = Column(BigInteger, nullable=False)
    bytes_read = Column(BigInteger, nullable=False)
    blocks_read = Column(BigInteger, nullable=False)
    bytes_written = Column(BigInteger, nullable=False)
    blocks_written = Column(BigInteger, nullable=False)
    bytes_found_dedup = Column(BigInteger, nullable=False)
    blocks_found_dedup = Column(BigInteger, nullable=False)
    bytes_sparse = Column(BigInteger, nullable=False)
    blocks_sparse = Column(BigInteger, nullable=False)
    duration_seconds = Column(BigInteger, nullable=False)


class Version(Base):
    __tablename__ = 'versions'
    uid = Column(String(36), primary_key=True)
    date = Column("date", DateTime, default=func.now(), nullable=False)
    expire = Column(DateTime, nullable=True)
    name = Column(String, nullable=False, default='')
    snapshot_name = Column(String, nullable=False, server_default='', default='')
    size = Column(BigInteger, nullable=False)
    size_bytes = Column(BigInteger, nullable=False)
    valid = Column(Integer, nullable=False)
    protected = Column(Integer, nullable=False)
    tags = sqlalchemy.orm.relationship(
            "Tag",
            backref="version",
            cascade="all, delete, delete-orphan",  # i.e. delete when version is deleted
            )


    def __repr__(self):
       return "<Version(uid='%s', name='%s', snapshot_name='%s', date='%s')>" % (
                            self.uid, self.name, self.snapshot_name, self.date)


class Tag(Base):
    __tablename__ = 'tags'
    version_uid = Column(String(36), ForeignKey('versions.uid'), primary_key=True, nullable=False)
    name = Column(String, nullable=False, primary_key=True)

    def __repr__(self):
       return "<Tag(version_uid='%s', name='%s')>" % (
                            self.version_uid, self.name)


DereferencedBlock = namedtuple('Block', ['uid', 'version_uid', 'id', 'date', 'checksum', 'size', 'valid', 'enc_envkey', 'enc_version', 'enc_nonce'])
class Block(Base):
    __tablename__ = 'blocks'
    uid = Column(String(32), nullable=True, index=True)
    version_uid = Column(String(36), ForeignKey('versions.uid'), primary_key=True, nullable=False)
    id = Column(Integer, primary_key=True, nullable=False)
    date = Column("date", DateTime , default=func.now(), nullable=False)
    checksum = Column(String(128), index=True, nullable=True)
    size = Column(BigInteger, nullable=True)
    valid = Column(Integer, nullable=False)
    enc_version = Column(Integer, nullable=False, default=0)
    enc_envkey = Column(String(80), nullable=True)
    enc_nonce = Column(String(32), nullable=True)  # This is doubled here (it's also in blob[:16] for fast rekeying.
    # hashsum of master key?


    def deref(self):
        """ Dereference this to a namedtuple so that we can pass it around
        without any thread inconsistencies
        """
        return DereferencedBlock(
            uid=self.uid,
            version_uid=self.version_uid,
            id=self.id,
            date=self.date,
            checksum=self.checksum,
            size=self.size,
            valid=self.valid,
            enc_version=self.enc_version,
            enc_envkey=self.enc_envkey,
            enc_nonce=self.enc_nonce,
        )


    def __repr__(self):
       return "<Block(id='%s', uid='%s', version_uid='%s')>" % (
                            self.id, self.uid, self.version_uid)


def inttime():
    return int(time.time())


class DeletedBlock(Base):
    __tablename__ = 'deleted_blocks'
    id = Column(BigInteger().with_variant(Integer, "sqlite"), primary_key=True)
    uid = Column(String(32), nullable=True, index=True)
    size = Column(BigInteger, nullable=True)
    delete_candidate = Column(Integer, nullable=False)
    # we need a date in order to find only delete candidates that are older than 1 hour.
    time = Column(BigInteger, default=inttime, nullable=False)

    def __repr__(self):
       return "<DeletedBlock(id='%s', uid='%s')>" % (
                            self.id, self.uid)


class MetaBackend(_MetaBackend):
    """ Stores meta data in an sql database """

    FLUSH_EVERY_N_BLOCKS = 1000

    def __init__(self, config):
        _MetaBackend.__init__(self)
        # engine = sqlalchemy.create_engine(config.get('engine'), echo=True)
        self.engine = sqlalchemy.create_engine(config.get('engine'))


    def open(self):
        try:
            self.migrate_db(self.engine)
        #except sqlalchemy.exc.OperationalError:
        except Exception as e:
            logger.error('Invalid database ({}). Please run initdb first.'.format(self.engine.url))
            logger.error(e)
            sys.exit(1)  # TODO: Return something (or raise)
            #raise RuntimeError('Invalid database')

        Session = sessionmaker(bind=self.engine)
        self.session = Session()
        self._flush_block_counter = 0
        return self


    def migrate_db(self, engine):
        # migrate the db to the lastest version
        from alembic.config import Config
        from alembic import command
        alembic_cfg = Config(os.path.join(os.path.dirname(os.path.realpath(__file__)), "sql_migrations", "alembic.ini"))
        with self.engine.begin() as connection:
            alembic_cfg.attributes['connection'] = connection
            #command.upgrade(alembic_cfg, "head", sql=True)
            command.upgrade(alembic_cfg, "head")


    def initdb(self):
        # this will create all tables. It will NOT delete any tables or data.
        # Instead, it will raise when something can't be created.
        # TODO: explicitly check if the database is empty
        Base.metadata.create_all(self.engine, checkfirst=False)  # checkfirst False will raise when it finds an existing table

        from alembic.config import Config
        from alembic import command
        alembic_cfg = Config(os.path.join(os.path.dirname(os.path.realpath(__file__)), "sql_migrations", "alembic.ini"))
        with self.engine.begin() as connection:
            alembic_cfg.attributes['connection'] = connection
            # mark the version table, "stamping" it with the most recent rev:
            command.stamp(alembic_cfg, "head")


    def _uid(self):
        return str(uuid.uuid1())


    def _commit(self):
        self.session.commit()


    def set_version(self, version_name, snapshot_name, size, size_bytes, valid, protected=0):
        uid = self._uid()
        version = Version(
            uid=uid,
            date=datetime.datetime.utcnow(),  # as func.now creates timezone stamps...
            name=version_name,
            snapshot_name=snapshot_name,
            size=size,
            size_bytes=size_bytes,
            valid=valid,
            protected=protected,
            )
        self.session.add(version)
        self.session.commit()
        return uid


    def copy_version(self, from_version_uid, version_name, snapshot_name=''):
        """ Copy version to a new uid and name, snapshot_name"""
        old_version = self.get_version(from_version_uid)
        new_version_uid = self.set_version(version_name, snapshot_name, old_version.size, old_version.size_bytes, old_version.valid)
        old_blocks = self.get_blocks_by_version(from_version_uid)
        logger.info('Copying version...')
        for i, block in enumerate(old_blocks.yield_per(1000)):
            self.set_block(
                    i,
                    new_version_uid,
                    block.uid,
                    block.checksum,
                    block.size,
                    block.valid,
                    _commit=False,
                    )
        self._commit()
        logger.info('Done copying version...')
        return new_version_uid


    def du(self, version_uid):
        virtual_space = 0
        real_space = 0
        dedup_own = 0
        dedup_others = 0
        nodedup = 0
        null_space = 0
        backy_space = 0
        space_freed = 0

        # find null blocks
        blocks = self.session.query(Block).filter_by(version_uid=version_uid, uid=None).all()
        for block in blocks:
            virtual_space += block.size
            null_space += block.size

        # find real blocks
        statement = text("""
            select a.uid, a.size, count(a.uid) own_shared,
                (select count(*) cnt from blocks where uid=a.uid) shared
            from blocks a
                where a.version_uid=:version_uid
                and a.uid is not NULL
            group by a.uid, a.size
            """)

        # Alternative, probably more compatible but not really faster.
        #statement = text("""
        #    select
        #        a.uid, a.size, sum(case when a.version_uid=b.version_uid then 1 else 0 end) own_shared,
        #        count(b.*) shared
        #    from blocks a
        #    left join blocks b on a.uid=b.uid
        #        where a.version_uid=:version_uid
        #    group by a.uid, a.size
        #    """)
        result = self.session.execute(statement, params={'version_uid': version_uid})
        for row in result:
            # calculations are based on part of real.
            real_space += row.size * row.own_shared

            _block_count_in_own_version = row.own_shared
            _block_count_in_all_versions = row.shared
            _block_count_in_other_versions = _block_count_in_all_versions - _block_count_in_own_version

            # if the block is in other versions, only account it as dedup_others.
            # It doesn't matter how often it is used in other versions.
            if _block_count_in_other_versions:
                dedup_others += row.size * _block_count_in_own_version
            elif _block_count_in_own_version > 1:
                dedup_own += row.size * (_block_count_in_own_version - 1)  # 1 is real, the others are dedup'd
            else:
                nodedup += row.size

            backy_space += row.size / _block_count_in_all_versions  # partial size

            if _block_count_in_other_versions == 0:  # only in this version
                space_freed += row.size

        ret = {
            'real_space': real_space,
            'null_space': null_space,
            'dedup_own': dedup_own,
            'dedup_others': dedup_others,
            'nodedup': nodedup,
            'backy_space': round(backy_space),
            'space_freed': space_freed,
        }

        return ret


    def set_stats(self, version_uid, version_name, version_size_bytes,
            version_size_blocks, bytes_read, blocks_read, bytes_written,
            blocks_written, bytes_found_dedup, blocks_found_dedup,
            bytes_sparse, blocks_sparse, duration_seconds):
        stats = Stats(
            version_uid=version_uid,
            version_name=version_name,
            version_size_bytes=version_size_bytes,
            version_size_blocks=version_size_blocks,
            bytes_read=bytes_read,
            blocks_read=blocks_read,
            bytes_written=bytes_written,
            blocks_written=blocks_written,
            bytes_found_dedup=bytes_found_dedup,
            blocks_found_dedup=blocks_found_dedup,
            bytes_sparse=bytes_sparse,
            blocks_sparse=blocks_sparse,
            duration_seconds=duration_seconds,
            )
        self.session.add(stats)
        self.session.commit()


    def get_stats(self, version_uid=None, limit=None):
        """ gets the <limit> newest entries """
        if version_uid:
            if limit is not None and limit < 1:
                return []
            stats = self.session.query(Stats).filter_by(version_uid=version_uid).all()
            if stats is None:
                raise KeyError('Statistics for version {} not found.'.format(version_uid))
            return stats
        else:
            if limit == 0:
                return []
            _stats = self.session.query(Stats).order_by(desc(Stats.date))
            if limit:
                _stats = _stats.limit(limit)
            return reversed(_stats.all())


    def set_version_invalid(self, uid):
        version = self.get_version(uid)
        version.valid = 0
        self.session.commit()
        logger.info('Marked version invalid (UID {})'.format(
            uid,
            ))


    def set_version_valid(self, uid):
        version = self.get_version(uid)
        version.valid = 1
        self.session.commit()
        logger.debug('Marked version valid (UID {})'.format(
            uid,
            ))


    def get_version(self, uid):
        version = self.session.query(Version).filter_by(uid=uid).first()
        if version is None:
            raise KeyError('Version {} not found.'.format(uid))
        return version


    def protect_version(self, uid):
        version = self.get_version(uid)
        version.protected = 1
        self.session.commit()
        logger.debug('Marked version protected (UID {})'.format(
            uid,
            ))


    def unprotect_version(self, uid):
        version = self.get_version(uid)
        version.protected = 0
        self.session.commit()
        logger.debug('Marked version unprotected (UID {})'.format(
            uid,
            ))


    def get_versions(self):
        """ Return versions, must be sorted by date ascending"""
        return self.session.query(Version).order_by(Version.name, Version.date).all()


    def add_tag(self, version_uid, name):
        """ Add a tag to a version_uid, do nothing if the tag already exists.
        """
        version = self.get_version(version_uid)
        existing_tags = [t.name for t in version.tags]
        if name not in existing_tags:
            tag = Tag(
                version_uid=version_uid,
                name=name,
                )
            self.session.add(tag)


    def remove_tag(self, version_uid, name):
        self.session.query(Tag).filter_by(version_uid=version_uid, name=name).delete()
        self.session.commit()


    def expire_version(self, version_uid, expire):
        version = self.get_version(version_uid)
        version.expire = expire
        self.session.commit()
        logger.debug('Set expire for version (UID {})'.format(
            version_uid,
            ))


    def set_block(self, id, version_uid, block_uid, checksum, size, valid, enc_envkey=b'', enc_version=0, enc_nonce=None, _commit=True):
        """ insert a block
        """
        valid = 1 if valid else 0
        if enc_envkey:
            enc_envkey = binascii.hexlify(enc_envkey).decode('ascii')
        if enc_nonce:
            enc_nonce = binascii.hexlify(enc_nonce).decode('ascii')
        block = Block(
            id=id,
            version_uid=version_uid,
            date=datetime.datetime.utcnow(),  # as func.now creates timezone stamps...
            uid=block_uid,
            checksum=checksum,
            size=size,
            valid=valid,
            enc_envkey=enc_envkey,
            enc_version=enc_version,
            enc_nonce=enc_nonce,
            )
        self.session.add(block)
        self._flush_block_counter += 1
        if self._flush_block_counter % self.FLUSH_EVERY_N_BLOCKS == 0:
            t1 = time.time()
            self.session.flush()  # saves some ram
            t2 = time.time()
            logger.debug('Flushed meta backend in {:.2f}s'.format(t2-t1))
        if _commit:
            self.session.commit()
        return block


    def set_block_enc_envkey(self, block, enc_envkey):
        block.enc_envkey = binascii.hexlify(enc_envkey).decode('ascii')
        self.session.add(block)
        self._flush_block_counter += 1

        if self._flush_block_counter % self.FLUSH_EVERY_N_BLOCKS == 0:
            t1 = time.time()
            self.session.flush()  # saves some ram
            t2 = time.time()
            logger.debug('Flushed meta backend in {:.2f}s'.format(t2-t1))
        return block


    def set_blocks_invalid(self, uid, checksum):
        _affected_version_uids = self.session.query(distinct(Block.version_uid)).filter_by(uid=uid, checksum=checksum).all()
        affected_version_uids = [v[0] for v in _affected_version_uids]
        self.session.query(Block).filter_by(uid=uid, checksum=checksum).update({'valid': 0}, synchronize_session='fetch')
        self.session.commit()
        logger.info('Marked block invalid (UID {}, Checksum {}. Affected versions: {}'.format(
            uid,
            checksum,
            ', '.join(affected_version_uids)
            ))
        for version_uid in affected_version_uids:
            self.set_version_invalid(version_uid)
        return affected_version_uids


    def get_block(self, uid):
        return self.session.query(Block).filter_by(uid=uid).first()


    def get_block_by_checksum(self, checksum, preferred_encryption_version):
        # there's this sql: order by field=value, field in order to get the specific value on top.
        # Too bad, sqlalchemy does not support this (yes, I tried sqlalchemy.func.field). So we have
        # to do this in python. Not too bad as there shouldn't be too many encryption versioned
        # blocks of the same checksum.
        # Here we prefer the block with preferred_encryption_version and next the highest encryption
        # version number available, then decending.
        results = sorted(self.session.query(Block).filter_by(checksum=checksum, valid=1).all(), key=lambda b: 100000 if b.enc_version==preferred_encryption_version else b.enc_version, reverse=True)
        if not results:
            return None
        else:
            return results[0]


    def get_blocks_by_version(self, version_uid):
        return self.session.query(Block).filter_by(version_uid=version_uid).order_by(Block.id)


    def get_blocks_by_version_deref(self, version_uid):
        """ use blocks but don't hold them in the session, because
        that makes the commit on the session slow"""
        statement = text("""
            select uid, id, date, checksum, size, valid, enc_version, enc_envkey, enc_nonce
            from blocks
                where version_uid=:version_uid
            """)
        result = self.session.execute(statement, params={'version_uid': version_uid})
        for block in result:
            yield DereferencedBlock(
                uid=block.uid,
                version_uid=version_uid,
                id=block.id,
                date=block.date,
                checksum=block.checksum,
                size=block.size,
                valid=block.valid,
                enc_version=block.enc_version,
                enc_envkey=block.enc_envkey,
                enc_nonce=block.enc_nonce,
            )


    def get_blocks(self):
        return self.session.query(Block).order_by(Block.id)


    def get_block_ids_by_version(self, version_uid):
        _b = self.session.query(Block.id).filter_by(version_uid=version_uid).order_by(Block.id)
        return [v[0] for v in _b.values('id')]


    def rm_version(self, version_uid):
        affected_blocks = self.session.query(Block).filter_by(version_uid=version_uid)
        num_blocks = affected_blocks.count()
        for affected_block in affected_blocks:
            if affected_block.uid:  # uid == None means sparse
                deleted_block = DeletedBlock(
                    uid=affected_block.uid,
                    size=affected_block.size,
                    delete_candidate=DELETE_CANDIDATE_MAYBE,  # TODO: obsolete
                )
                self.session.add(deleted_block)
        affected_blocks.delete()
        # TODO: This is a sqlalchemy stupidity. cascade only works if the version
        # is deleted via session.delete() which first loads all objects into
        # memory. A session.query().filter().delete does not work with cascade.
        # Please see http://stackoverflow.com/questions/5033547/sqlalchemy-cascade-delete/12801654#12801654
        # for reference.
        self.session.query(Tag).filter_by(version_uid=version_uid).delete()
        self.session.query(Version).filter_by(uid=version_uid).delete()
        self.session.commit()
        return num_blocks


    def cleanup_delete_candidates(self, dt=3600):
        # Delete false positives:
        logger.info("Deleting false positives...")
        self.session.query(DeletedBlock.uid).filter(DeletedBlock.uid.in_(self.session.query(Block.uid).distinct(Block.uid).filter(Block.uid.isnot(None)).subquery())).filter(DeletedBlock.time < (inttime() - dt)).delete(synchronize_session=False)
        logger.info("Deleting false positives: done. Now deleting blocks.")
        self.session.commit()


    def get_delete_candidates(self, dt=3600):
        delete_candidates_query = self.session.query(distinct(DeletedBlock.uid)).join(Block, Block.uid == DeletedBlock.uid, isouter=True).filter(Block.uid == None).filter(DeletedBlock.time < (inttime() - dt))
        delete_candidates = [b[0] for b in delete_candidates_query.all()]
        return delete_candidates


    def del_delete_candidates(self, uids):
        self.session.query(DeletedBlock).filter(DeletedBlock.uid.in_(uids)).delete(synchronize_session=False)
        self.session.commit()


    def get_all_block_uids(self, prefix=None):
        if prefix:
            rows = self.session.query(distinct(Block.uid)).filter(Block.uid.like('{}%'.format(prefix))).all()
        else:
            rows = self.session.query(distinct(Block.uid)).all()
        return [b[0] for b in rows]


    def export(self, version_uid, f):
        blocks = self.get_blocks_by_version(version_uid)
        _csv = csv.writer(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        _csv.writerow(['backy2 Version {} metadata dump'.format(METADATA_VERSION)])
        version = self.get_version(version_uid)
        _csv.writerow([
            version.uid,
            version.date.strftime('%Y-%m-%d %H:%M:%S'),
            version.name,
            version.snapshot_name,
            version.size,
            version.size_bytes,
            version.valid,
            version.protected,
            version.expire.strftime('%Y-%m-%d') if version.expire else '',
            ])
        for block in blocks.yield_per(1000):
            _csv.writerow([
                block.uid,
                block.version_uid,
                block.id,
                block.date.strftime('%Y-%m-%d %H:%M:%S'),
                block.checksum,
                block.size,
                block.valid,
                block.enc_version,
                block.enc_envkey,
                block.enc_nonce,
                ])
        return _csv


    def import_(self, f):
        _csv = csv.reader(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        signature = next(_csv)
        if signature[0] == 'backy2 Version 2.1 metadata dump':
            self.import_2_1(_csv)
        elif signature[0] == 'backy2 Version 2.2 metadata dump':
            self.import_2_2(_csv)
        elif signature[0] == 'backy2 Version 2.10 metadata dump':
            self.import_2_10(_csv)
        elif signature[0] == 'backy2 Version 2.12 metadata dump':
            self.import_2_12(_csv)
        else:
            raise ValueError('Wrong import format.')


    def import_2_1(self, _csv):
        version_uid, version_date, version_name, version_size, version_size_bytes, version_valid = next(_csv)
        try:
            self.get_version(version_uid)
        except KeyError:
            pass  # does not exist
        else:
            raise KeyError('Version {} already exists and cannot be imported.'.format(version_uid))
        version = Version(
            uid=version_uid,
            date=datetime.datetime.strptime(version_date, '%Y-%m-%d %H:%M:%S'),
            name=version_name,
            snapshot_name='',
            size=version_size,
            size_bytes=version_size_bytes,
            valid=version_valid,
            protected=0,
            )
        self.session.add(version)
        for uid, version_uid, id, date, checksum, size, valid in _csv:
            if uid == '':
                uid = None
            block = Block(
                uid=uid,
                version_uid=version_uid,
                id=id,
                date=datetime.datetime.strptime(date, '%Y-%m-%d %H:%M:%S'),
                checksum=checksum,
                size=size,
                valid=valid,
            )
            self.session.add(block)
        self.session.commit()


    def import_2_2(self, _csv):
        version_uid, version_date, version_name, version_snapshot_name, version_size, version_size_bytes, version_valid, version_protected = next(_csv)
        try:
            self.get_version(version_uid)
        except KeyError:
            pass  # does not exist
        else:
            raise KeyError('Version {} already exists and cannot be imported.'.format(version_uid))
        version = Version(
            uid=version_uid,
            date=datetime.datetime.strptime(version_date, '%Y-%m-%d %H:%M:%S'),
            name=version_name,
            snapshot_name=version_snapshot_name,
            size=version_size,
            size_bytes=version_size_bytes,
            valid=version_valid,
            protected=version_protected,
            )
        self.session.add(version)
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        # SQLAlchemy Bug
        # https://stackoverflow.com/questions/10154343/is-sqlalchemy-saves-order-in-adding-objects-to-session
        #
        # """
        # Within the same class, the order is indeed determined by the order
        # that add was called. However, you may see different orderings in the
        # INSERTs between different classes. If you add object a of type A and
        # later add object b of type B, but a turns out to have a foreign key
        # to b, you'll see an INSERT for b before the INSERT for a.
        # """
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.session.commit()
        # and because of this bug we must also try/except here instead of
        # simply leaving this to the database's transaction handling.
        try:
            for uid, version_uid, id, date, checksum, size, valid in _csv:
                if uid == '':
                    uid = None
                block = Block(
                    uid=uid,
                    version_uid=version_uid,
                    id=id,
                    date=datetime.datetime.strptime(date, '%Y-%m-%d %H:%M:%S'),
                    checksum=checksum,
                    size=size,
                    valid=valid,
                )
                self.session.add(block)
        except:  # see above
            self.rm_version(version_uid)
        finally:
            self.session.commit()


    def import_2_10(self, _csv):
        version_uid, version_date, version_name, version_snapshot_name, version_size, version_size_bytes, version_valid, version_protected, version_expire = next(_csv)
        try:
            self.get_version(version_uid)
        except KeyError:
            pass  # does not exist
        else:
            raise KeyError('Version {} already exists and cannot be imported.'.format(version_uid))
        version = Version(
            uid=version_uid,
            date=datetime.datetime.strptime(version_date, '%Y-%m-%d %H:%M:%S'),
            name=version_name,
            snapshot_name=version_snapshot_name,
            size=version_size,
            size_bytes=version_size_bytes,
            valid=version_valid,
            protected=version_protected,
            expire=datetime.datetime.strptime(version_expire, '%Y-%m-%d').date() if version_expire else None,
            )
        self.session.add(version)
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        # SQLAlchemy Bug
        # https://stackoverflow.com/questions/10154343/is-sqlalchemy-saves-order-in-adding-objects-to-session
        #
        # """
        # Within the same class, the order is indeed determined by the order
        # that add was called. However, you may see different orderings in the
        # INSERTs between different classes. If you add object a of type A and
        # later add object b of type B, but a turns out to have a foreign key
        # to b, you'll see an INSERT for b before the INSERT for a.
        # """
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.session.commit()
        # and because of this bug we must also try/except here instead of
        # simply leaving this to the database's transaction handling.
        try:
            for uid, version_uid, id, date, checksum, size, valid in _csv:
                if uid == '':
                    uid = None
                block = Block(
                    uid=uid,
                    version_uid=version_uid,
                    id=id,
                    date=datetime.datetime.strptime(date, '%Y-%m-%d %H:%M:%S'),
                    checksum=checksum,
                    size=size,
                    valid=valid,
                )
                self.session.add(block)
        except:  # see above
            self.rm_version(version_uid)
        finally:
            self.session.commit()


    def import_2_12(self, _csv):
        version_uid, version_date, version_name, version_snapshot_name, version_size, version_size_bytes, version_valid, version_protected, version_expire = next(_csv)
        try:
            self.get_version(version_uid)
        except KeyError:
            pass  # does not exist
        else:
            raise KeyError('Version {} already exists and cannot be imported.'.format(version_uid))
        version = Version(
            uid=version_uid,
            date=datetime.datetime.strptime(version_date, '%Y-%m-%d %H:%M:%S'),
            name=version_name,
            snapshot_name=version_snapshot_name,
            size=version_size,
            size_bytes=version_size_bytes,
            valid=version_valid,
            protected=version_protected,
            expire=datetime.datetime.strptime(version_expire, '%Y-%m-%d').date() if version_expire else None,
            )
        self.session.add(version)
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        # SQLAlchemy Bug
        # https://stackoverflow.com/questions/10154343/is-sqlalchemy-saves-order-in-adding-objects-to-session
        #
        # """
        # Within the same class, the order is indeed determined by the order
        # that add was called. However, you may see different orderings in the
        # INSERTs between different classes. If you add object a of type A and
        # later add object b of type B, but a turns out to have a foreign key
        # to b, you'll see an INSERT for b before the INSERT for a.
        # """
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.session.commit()
        # and because of this bug we must also try/except here instead of
        # simply leaving this to the database's transaction handling.
        try:
            for uid, version_uid, id, date, checksum, size, valid, enc_version, enc_envkey, enc_nonce in _csv:
                if uid == '':
                    uid = None
                block = Block(
                    uid=uid,
                    version_uid=version_uid,
                    id=id,
                    date=datetime.datetime.strptime(date, '%Y-%m-%d %H:%M:%S'),
                    checksum=checksum,
                    size=size,
                    valid=valid,
                    enc_version=enc_version,
                    enc_envkey=enc_envkey,
                    enc_nonce=enc_nonce if enc_nonce != '\\x' else None,  # csv None is \x
                )
                self.session.add(block)
        except:  # see above
            self.rm_version(version_uid)
        finally:
            self.session.commit()


    def close(self):
        self.session.commit()
        self.session.close()


