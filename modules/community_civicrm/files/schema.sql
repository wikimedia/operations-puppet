-- SPDX-License-Identifier: AGPL-3.0-only
-- MariaDB dump 10.19  Distrib 10.5.19-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: drupal
-- ------------------------------------------------------
-- Server version	10.5.19-MariaDB-0+deb11u2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `drupal`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `drupal` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `drupal`;

--
-- Table structure for table `block_content`
--

DROP TABLE IF EXISTS `block_content`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `revision_id` int(10) unsigned DEFAULT NULL,
  `type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `block_content_field__uuid__value` (`uuid`),
  UNIQUE KEY `block_content__revision_id` (`revision_id`),
  KEY `block_content_field__type__target_id` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for block_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_content__body`
--

DROP TABLE IF EXISTS `block_content__body`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content__body` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `body_value` longtext NOT NULL,
  `body_summary` longtext DEFAULT NULL,
  `body_format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `body_format` (`body_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for block_content field body.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_content_field_data`
--

DROP TABLE IF EXISTS `block_content_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content_field_data` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `info` varchar(255) DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `reusable` tinyint(4) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`,`langcode`),
  KEY `block_content__id__default_langcode__langcode` (`id`,`default_langcode`,`langcode`),
  KEY `block_content__revision_id` (`revision_id`),
  KEY `block_content_field__type__target_id` (`type`),
  KEY `block_content__status_type` (`status`,`type`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for block_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_content_field_revision`
--

DROP TABLE IF EXISTS `block_content_field_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content_field_revision` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `info` varchar(255) DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`,`langcode`),
  KEY `block_content__id__default_langcode__langcode` (`id`,`default_langcode`,`langcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision data table for block_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_content_revision`
--

DROP TABLE IF EXISTS `block_content_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content_revision` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `revision_user` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `revision_created` int(11) DEFAULT NULL,
  `revision_log` longtext DEFAULT NULL,
  `revision_default` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`),
  KEY `block_content__id` (`id`),
  KEY `block_content_field__revision_user__target_id` (`revision_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision table for block_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_content_revision__body`
--

DROP TABLE IF EXISTS `block_content_revision__body`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `block_content_revision__body` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `body_value` longtext NOT NULL,
  `body_summary` longtext DEFAULT NULL,
  `body_format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `body_format` (`body_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for block_content field body.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_bootstrap`
--

DROP TABLE IF EXISTS `cache_bootstrap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_bootstrap` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_config`
--

DROP TABLE IF EXISTS `cache_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_config` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_container`
--

DROP TABLE IF EXISTS `cache_container`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_container` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_data`
--

DROP TABLE IF EXISTS `cache_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_data` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_default`
--

DROP TABLE IF EXISTS `cache_default`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_default` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_discovery`
--

DROP TABLE IF EXISTS `cache_discovery`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_discovery` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_dynamic_page_cache`
--

DROP TABLE IF EXISTS `cache_dynamic_page_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_dynamic_page_cache` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_entity`
--

DROP TABLE IF EXISTS `cache_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_entity` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_menu`
--

DROP TABLE IF EXISTS `cache_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_menu` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_page`
--

DROP TABLE IF EXISTS `cache_page`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_page` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_render`
--

DROP TABLE IF EXISTS `cache_render`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_render` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_toolbar`
--

DROP TABLE IF EXISTS `cache_toolbar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_toolbar` (
  `cid` varchar(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique cache ID.',
  `data` longblob DEFAULT NULL COMMENT 'A collection of data to cache.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'A Unix timestamp indicating when the cache entry should expire, or -1 for never.',
  `created` decimal(14,3) NOT NULL DEFAULT 0.000 COMMENT 'A timestamp with millisecond precision indicating when the cache entry was created.',
  `serialized` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag to indicate whether content is serialized (1) or not (0).',
  `tags` longtext DEFAULT NULL COMMENT 'Space-separated list of cache tags for this entry.',
  `checksum` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The tag invalidation checksum when this entry was saved.',
  PRIMARY KEY (`cid`),
  KEY `expire` (`expire`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Storage for the cache API.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cachetags`
--

DROP TABLE IF EXISTS `cachetags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cachetags` (
  `tag` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Namespace-prefixed tag string.',
  `invalidations` int(11) NOT NULL DEFAULT 0 COMMENT 'Number incremented when the tag is invalidated.',
  PRIMARY KEY (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Cache table for tracking cache tag invalidations.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_acl`
--

DROP TABLE IF EXISTS `civicrm_acl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_acl` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'ACL Name.',
  `deny` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this ACL entry Allow  (0) or Deny (1) ?',
  `entity_table` varchar(64) NOT NULL COMMENT 'Table of the object possessing this ACL entry (Contact, Group, or ACL Group)',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'ID of the object possessing this ACL',
  `operation` varchar(8) NOT NULL COMMENT 'What operation does this ACL entry control?',
  `object_table` varchar(64) DEFAULT NULL COMMENT 'The table of the object controlled by this ACL entry',
  `object_id` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the object controlled by this ACL entry',
  `acl_table` varchar(64) DEFAULT NULL COMMENT 'If this is a grant/revoke entry, what table are we granting?',
  `acl_id` int(10) unsigned DEFAULT NULL COMMENT 'ID of the ACL or ACL group being granted/revoked',
  `is_active` tinyint(4) DEFAULT NULL COMMENT 'Is this property active?',
  `priority` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_acl_id` (`acl_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_acl_cache`
--

DROP TABLE IF EXISTS `civicrm_acl_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_acl_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign Key to Contact',
  `acl_id` int(10) unsigned NOT NULL COMMENT 'Foreign Key to ACL',
  `modified_date` timestamp NULL DEFAULT NULL COMMENT 'When was this cache entry last modified',
  PRIMARY KEY (`id`),
  KEY `index_contact_id` (`contact_id`),
  KEY `index_acl_id` (`acl_id`),
  KEY `index_modified_date` (`modified_date`),
  CONSTRAINT `FK_civicrm_acl_cache_acl_id` FOREIGN KEY (`acl_id`) REFERENCES `civicrm_acl` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_acl_contact_cache`
--

DROP TABLE IF EXISTS `civicrm_acl_contact_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_acl_contact_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `user_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact (could be null for anon user)',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_contact',
  `operation` varchar(8) NOT NULL COMMENT 'What operation does this user have permission on?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_user_contact_operation` (`user_id`,`contact_id`,`operation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_acl_entity_role`
--

DROP TABLE IF EXISTS `civicrm_acl_entity_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_acl_entity_role` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `acl_role_id` int(10) unsigned NOT NULL COMMENT 'Foreign Key to ACL Role (which is an option value pair and hence an implicit FK)',
  `entity_table` varchar(64) NOT NULL COMMENT 'Table of the object joined to the ACL Role (Contact or Group)',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'ID of the group/contact object being joined',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  PRIMARY KEY (`id`),
  KEY `index_role` (`acl_role_id`),
  KEY `index_entity` (`entity_table`,`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_action_log`
--

DROP TABLE IF EXISTS `civicrm_action_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_action_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to id of the entity that the action was performed on. Pseudo - FK.',
  `entity_table` varchar(255) DEFAULT NULL COMMENT 'name of the entity table for the above id, e.g. civicrm_activity, civicrm_participant',
  `action_schedule_id` int(10) unsigned NOT NULL COMMENT 'FK to the action schedule that this action originated from.',
  `action_date_time` datetime DEFAULT NULL COMMENT 'date time that the action was performed on.',
  `is_error` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Was there any error sending the reminder?',
  `message` text DEFAULT NULL COMMENT 'Description / text in case there was an error encountered.',
  `repetition_number` int(10) unsigned DEFAULT NULL COMMENT 'Keeps track of the sequence number of this repetition.',
  `reference_date` datetime DEFAULT NULL COMMENT 'Stores the date from the entity which triggered this reminder action (e.g. membership.end_date for most membership renewal reminders)',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_action_log_contact_id` (`contact_id`),
  KEY `FK_civicrm_action_log_action_schedule_id` (`action_schedule_id`),
  CONSTRAINT `FK_civicrm_action_log_action_schedule_id` FOREIGN KEY (`action_schedule_id`) REFERENCES `civicrm_action_schedule` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_action_log_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_action_schedule`
--

DROP TABLE IF EXISTS `civicrm_action_schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_action_schedule` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT 'Name of the action(reminder)',
  `title` varchar(64) DEFAULT NULL COMMENT 'Title of the action(reminder)',
  `recipient` varchar(64) DEFAULT NULL COMMENT 'Recipient',
  `limit_to` tinyint(4) DEFAULT NULL COMMENT 'Is this the recipient criteria limited to OR in addition to?',
  `entity_value` varchar(255) DEFAULT NULL COMMENT 'Entity value',
  `entity_status` varchar(64) DEFAULT NULL COMMENT 'Entity status',
  `start_action_offset` int(10) unsigned DEFAULT 0 COMMENT 'Reminder Interval.',
  `start_action_unit` varchar(8) DEFAULT NULL COMMENT 'Time units for reminder.',
  `start_action_condition` varchar(64) DEFAULT NULL COMMENT 'Reminder Action',
  `start_action_date` varchar(64) DEFAULT NULL COMMENT 'Entity date',
  `is_repeat` tinyint(4) NOT NULL DEFAULT 0,
  `repetition_frequency_unit` varchar(8) DEFAULT NULL COMMENT 'Time units for repetition of reminder.',
  `repetition_frequency_interval` int(10) unsigned DEFAULT 0 COMMENT 'Time interval for repeating the reminder.',
  `end_frequency_unit` varchar(8) DEFAULT NULL COMMENT 'Time units till repetition of reminder.',
  `end_frequency_interval` int(10) unsigned DEFAULT 0 COMMENT 'Time interval till repeating the reminder.',
  `end_action` varchar(32) DEFAULT NULL COMMENT 'Reminder Action till repeating the reminder.',
  `end_date` varchar(64) DEFAULT NULL COMMENT 'Entity end date',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this option active?',
  `recipient_manual` varchar(128) DEFAULT NULL COMMENT 'Contact IDs to which reminder should be sent.',
  `recipient_listing` varchar(128) DEFAULT NULL COMMENT 'listing based on recipient field.',
  `body_text` longtext DEFAULT NULL COMMENT 'Body of the mailing in text format.',
  `body_html` longtext DEFAULT NULL COMMENT 'Body of the mailing in html format.',
  `sms_body_text` longtext DEFAULT NULL COMMENT 'Content of the SMS text.',
  `subject` varchar(128) DEFAULT NULL COMMENT 'Subject of mailing',
  `record_activity` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Record Activity for this reminder?',
  `mapping_id` varchar(64) DEFAULT NULL COMMENT 'Name/ID of the mapping to use on this table',
  `group_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Group',
  `msg_template_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the message template.',
  `sms_template_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the message template.',
  `absolute_date` date DEFAULT NULL COMMENT 'Date on which the reminder be sent.',
  `from_name` varchar(255) DEFAULT NULL COMMENT 'Name in "from" field',
  `from_email` varchar(255) DEFAULT NULL COMMENT 'Email address in "from" field',
  `mode` varchar(128) DEFAULT 'Email' COMMENT 'Send the message as email or sms or both.',
  `sms_provider_id` int(10) unsigned DEFAULT NULL,
  `used_for` varchar(64) DEFAULT NULL COMMENT 'Used for repeating entity',
  `filter_contact_language` varchar(128) DEFAULT NULL COMMENT 'Used for multilingual installation',
  `communication_language` varchar(8) DEFAULT NULL COMMENT 'Used for multilingual installation',
  `created_date` timestamp NULL DEFAULT current_timestamp() COMMENT 'When was the scheduled reminder created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When the reminder was created or modified.',
  `effective_start_date` timestamp NULL DEFAULT NULL COMMENT 'Earliest date to consider start events from.',
  `effective_end_date` timestamp NULL DEFAULT NULL COMMENT 'Latest date to consider end events from.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_action_schedule_group_id` (`group_id`),
  KEY `FK_civicrm_action_schedule_msg_template_id` (`msg_template_id`),
  KEY `FK_civicrm_action_schedule_sms_template_id` (`sms_template_id`),
  KEY `FK_civicrm_action_schedule_sms_provider_id` (`sms_provider_id`),
  CONSTRAINT `FK_civicrm_action_schedule_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_action_schedule_msg_template_id` FOREIGN KEY (`msg_template_id`) REFERENCES `civicrm_msg_template` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_action_schedule_sms_provider_id` FOREIGN KEY (`sms_provider_id`) REFERENCES `civicrm_sms_provider` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_action_schedule_sms_template_id` FOREIGN KEY (`sms_template_id`) REFERENCES `civicrm_msg_template` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_activity`
--

DROP TABLE IF EXISTS `civicrm_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_activity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique  Other Activity ID',
  `source_record_id` int(10) unsigned DEFAULT NULL COMMENT 'Artificial FK to original transaction (e.g. contribution) IF it is not an Activity. Entity table is discovered by filtering by the appropriate activity_type_id.',
  `activity_type_id` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'FK to civicrm_option_value.id, that has to be valid, registered activity type.',
  `subject` varchar(255) DEFAULT NULL COMMENT 'The subject/purpose/short description of the activity.',
  `activity_date_time` datetime DEFAULT current_timestamp() COMMENT 'Date and time this activity is scheduled to occur. Formerly named scheduled_date_time.',
  `duration` int(10) unsigned DEFAULT NULL COMMENT 'Planned or actual duration of activity expressed in minutes. Conglomerate of former duration_hours and duration_minutes.',
  `location` varchar(255) DEFAULT NULL COMMENT 'Location of the activity (optional, open text).',
  `phone_id` int(10) unsigned DEFAULT NULL COMMENT 'Phone ID of the number called (optional - used if an existing phone number is selected).',
  `phone_number` varchar(64) DEFAULT NULL COMMENT 'Phone number in case the number does not exist in the civicrm_phone table.',
  `details` longtext DEFAULT NULL COMMENT 'Details about the activity (agenda, notes, etc).',
  `status_id` int(10) unsigned DEFAULT NULL COMMENT 'ID of the status this activity is currently in. Foreign key to civicrm_option_value.',
  `priority_id` int(10) unsigned DEFAULT NULL COMMENT 'ID of the priority given to this activity. Foreign key to civicrm_option_value.',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent meeting ID (if this is a follow-up item).',
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `medium_id` int(10) unsigned DEFAULT NULL COMMENT 'Activity Medium, Implicit FK to civicrm_option_value where option_group = encounter_medium.',
  `is_auto` tinyint(4) NOT NULL DEFAULT 0,
  `relationship_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Relationship ID',
  `is_current_revision` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Unused deprecated column.',
  `original_id` int(10) unsigned DEFAULT NULL COMMENT 'Unused deprecated column.',
  `result` varchar(255) DEFAULT NULL COMMENT 'Currently being used to store result id for survey activity, FK to option value.',
  `is_deleted` tinyint(4) NOT NULL DEFAULT 0,
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this activity has been triggered.',
  `engagement_level` int(10) unsigned DEFAULT NULL COMMENT 'Assign a specific level of engagement to this activity. Used for tracking constituents in ladder of engagement.',
  `weight` int(11) DEFAULT NULL,
  `is_star` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Activity marked as favorite.',
  `created_date` timestamp NULL DEFAULT current_timestamp() COMMENT 'When was the activity was created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When was the activity (or closely related entity) was created or modified or deleted.',
  PRIMARY KEY (`id`),
  KEY `UI_source_record_id` (`source_record_id`),
  KEY `UI_activity_type_id` (`activity_type_id`),
  KEY `index_activity_date_time` (`activity_date_time`),
  KEY `index_status_id` (`status_id`),
  KEY `index_is_current_revision` (`is_current_revision`),
  KEY `index_is_deleted` (`is_deleted`),
  KEY `FK_civicrm_activity_phone_id` (`phone_id`),
  KEY `FK_civicrm_activity_parent_id` (`parent_id`),
  KEY `FK_civicrm_activity_relationship_id` (`relationship_id`),
  KEY `FK_civicrm_activity_original_id` (`original_id`),
  KEY `FK_civicrm_activity_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_activity_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_activity_original_id` FOREIGN KEY (`original_id`) REFERENCES `civicrm_activity` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_activity_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_activity` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_activity_phone_id` FOREIGN KEY (`phone_id`) REFERENCES `civicrm_phone` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_activity_relationship_id` FOREIGN KEY (`relationship_id`) REFERENCES `civicrm_relationship` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=643 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_activity_before_insert before insert ON civicrm_activity FOR EACH ROW BEGIN  
SET NEW.created_date = CURRENT_TIMESTAMP;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_activity_before_update before update ON civicrm_activity FOR EACH ROW BEGIN  UPDATE civicrm_case SET modified_date = CURRENT_TIMESTAMP WHERE id IN (SELECT ca.case_id FROM civicrm_case_activity ca WHERE ca.activity_id = OLD.id); END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_activity_before_delete before delete ON civicrm_activity FOR EACH ROW BEGIN  UPDATE civicrm_case SET modified_date = CURRENT_TIMESTAMP WHERE id IN (SELECT ca.case_id FROM civicrm_case_activity ca WHERE ca.activity_id = OLD.id); END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_activity_contact`
--

DROP TABLE IF EXISTS `civicrm_activity_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_activity_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Activity contact id',
  `activity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the activity for this record.',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the contact for this record.',
  `record_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Determines the contact''s role in the activity (source, target, or assignee).',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_activity_contact` (`contact_id`,`activity_id`,`record_type_id`),
  KEY `index_record_type` (`activity_id`,`record_type_id`),
  CONSTRAINT `FK_civicrm_activity_contact_activity_id` FOREIGN KEY (`activity_id`) REFERENCES `civicrm_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_activity_contact_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=938 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_address`
--

DROP TABLE IF EXISTS `civicrm_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_address` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Address ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Location does this address belong to.',
  `is_primary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the primary address.',
  `is_billing` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the billing address.',
  `street_address` varchar(96) DEFAULT NULL COMMENT 'Concatenation of all routable street address components (prefix, street number, street name, suffix, unit\n      number OR P.O. Box). Apps should be able to determine physical location with this data (for mapping, mail\n      delivery, etc.).',
  `street_number` int(11) DEFAULT NULL COMMENT 'Numeric portion of address number on the street, e.g. For 112A Main St, the street_number = 112.',
  `street_number_suffix` varchar(8) DEFAULT NULL COMMENT 'Non-numeric portion of address number on the street, e.g. For 112A Main St, the street_number_suffix = A',
  `street_number_predirectional` varchar(8) DEFAULT NULL COMMENT 'Directional prefix, e.g. SE Main St, SE is the prefix.',
  `street_name` varchar(64) DEFAULT NULL COMMENT 'Actual street name, excluding St, Dr, Rd, Ave, e.g. For 112 Main St, the street_name = Main.',
  `street_type` varchar(8) DEFAULT NULL COMMENT 'St, Rd, Dr, etc.',
  `street_number_postdirectional` varchar(8) DEFAULT NULL COMMENT 'Directional prefix, e.g. Main St S, S is the suffix.',
  `street_unit` varchar(16) DEFAULT NULL COMMENT 'Secondary unit designator, e.g. Apt 3 or Unit # 14, or Bldg 1200',
  `supplemental_address_1` varchar(96) DEFAULT NULL COMMENT 'Supplemental Address Information, Line 1',
  `supplemental_address_2` varchar(96) DEFAULT NULL COMMENT 'Supplemental Address Information, Line 2',
  `supplemental_address_3` varchar(96) DEFAULT NULL COMMENT 'Supplemental Address Information, Line 3',
  `city` varchar(64) DEFAULT NULL COMMENT 'City, Town or Village Name.',
  `county_id` int(10) unsigned DEFAULT NULL COMMENT 'Which County does this address belong to.',
  `state_province_id` int(10) unsigned DEFAULT NULL COMMENT 'Which State_Province does this address belong to.',
  `postal_code_suffix` varchar(12) DEFAULT NULL COMMENT 'Store the suffix, like the +4 part in the USPS system.',
  `postal_code` varchar(64) DEFAULT NULL COMMENT 'Store both US (zip5) AND international postal codes. App is responsible for country/region appropriate validation.',
  `usps_adc` varchar(32) DEFAULT NULL COMMENT 'USPS Bulk mailing code.',
  `country_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Country does this address belong to.',
  `geo_code_1` double DEFAULT NULL COMMENT 'Latitude',
  `geo_code_2` double DEFAULT NULL COMMENT 'Longitude',
  `manual_geo_code` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a manually entered geo code',
  `timezone` varchar(8) DEFAULT NULL COMMENT 'Timezone expressed as a UTC offset - e.g. United States CST would be written as "UTC-6".',
  `name` varchar(255) DEFAULT NULL,
  `master_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Address ID',
  PRIMARY KEY (`id`),
  KEY `index_location_type` (`location_type_id`),
  KEY `index_is_primary` (`is_primary`),
  KEY `index_is_billing` (`is_billing`),
  KEY `index_street_name` (`street_name`),
  KEY `index_city` (`city`),
  KEY `index_geo_code_1_geo_code_2` (`geo_code_1`,`geo_code_2`),
  KEY `FK_civicrm_address_contact_id` (`contact_id`),
  KEY `FK_civicrm_address_county_id` (`county_id`),
  KEY `FK_civicrm_address_state_province_id` (`state_province_id`),
  KEY `FK_civicrm_address_country_id` (`country_id`),
  KEY `FK_civicrm_address_master_id` (`master_id`),
  CONSTRAINT `FK_civicrm_address_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_address_country_id` FOREIGN KEY (`country_id`) REFERENCES `civicrm_country` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_address_county_id` FOREIGN KEY (`county_id`) REFERENCES `civicrm_county` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_address_master_id` FOREIGN KEY (`master_id`) REFERENCES `civicrm_address` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_address_state_province_id` FOREIGN KEY (`state_province_id`) REFERENCES `civicrm_state_province` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=187 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_address_after_insert after insert ON civicrm_address FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_address_after_update after update ON civicrm_address FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_address_after_delete after delete ON civicrm_address FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_address_format`
--

DROP TABLE IF EXISTS `civicrm_address_format`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_address_format` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Address Format ID',
  `format` text DEFAULT NULL COMMENT 'The format of an address',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_batch`
--

DROP TABLE IF EXISTS `civicrm_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_batch` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Address ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Variable name/programmatic handle for this batch.',
  `title` varchar(255) DEFAULT NULL COMMENT 'Friendly Name.',
  `description` text DEFAULT NULL COMMENT 'Description of this batch set.',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `created_date` datetime DEFAULT NULL COMMENT 'When was this item created',
  `modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `modified_date` datetime DEFAULT NULL COMMENT 'When was this item modified',
  `saved_search_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Saved Search ID',
  `status_id` int(10) unsigned NOT NULL COMMENT 'fk to Batch Status options in civicrm_option_values',
  `type_id` int(10) unsigned DEFAULT NULL COMMENT 'fk to Batch Type options in civicrm_option_values',
  `mode_id` int(10) unsigned DEFAULT NULL COMMENT 'fk to Batch mode options in civicrm_option_values',
  `total` decimal(20,2) DEFAULT NULL COMMENT 'Total amount for this batch.',
  `item_count` int(10) unsigned DEFAULT NULL COMMENT 'Number of items in a batch.',
  `payment_instrument_id` int(10) unsigned DEFAULT NULL COMMENT 'fk to Payment Instrument options in civicrm_option_values',
  `exported_date` datetime DEFAULT NULL,
  `data` longtext DEFAULT NULL COMMENT 'cache entered data',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_batch_created_id` (`created_id`),
  KEY `FK_civicrm_batch_modified_id` (`modified_id`),
  KEY `FK_civicrm_batch_saved_search_id` (`saved_search_id`),
  CONSTRAINT `FK_civicrm_batch_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_batch_modified_id` FOREIGN KEY (`modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_batch_saved_search_id` FOREIGN KEY (`saved_search_id`) REFERENCES `civicrm_saved_search` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_cache`
--

DROP TABLE IF EXISTS `civicrm_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `group_name` varchar(32) NOT NULL COMMENT 'group name for cache element, useful in cleaning cache elements',
  `path` varchar(255) DEFAULT NULL COMMENT 'Unique path name for cache element',
  `data` longtext DEFAULT NULL COMMENT 'data associated with this path',
  `component_id` int(10) unsigned DEFAULT NULL COMMENT 'Component that this menu item belongs to',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When was the cache item created',
  `expired_date` timestamp NULL DEFAULT NULL COMMENT 'When should the cache item expire',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_group_name_path` (`group_name`,`path`),
  KEY `index_expired_date` (`expired_date`),
  KEY `FK_civicrm_cache_component_id` (`component_id`),
  CONSTRAINT `FK_civicrm_cache_component_id` FOREIGN KEY (`component_id`) REFERENCES `civicrm_component` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_campaign`
--

DROP TABLE IF EXISTS `civicrm_campaign`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_campaign` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Campaign ID.',
  `name` varchar(255) NOT NULL COMMENT 'Name of the Campaign.',
  `title` varchar(255) DEFAULT NULL COMMENT 'Title of the Campaign.',
  `description` text DEFAULT NULL COMMENT 'Full description of Campaign.',
  `start_date` datetime DEFAULT NULL COMMENT 'Date and time that Campaign starts.',
  `end_date` datetime DEFAULT NULL COMMENT 'Date and time that Campaign ends.',
  `campaign_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Campaign Type ID.Implicit FK to civicrm_option_value where option_group = campaign_type',
  `status_id` int(10) unsigned DEFAULT NULL COMMENT 'Campaign status ID.Implicit FK to civicrm_option_value where option_group = campaign_status',
  `external_identifier` varchar(32) DEFAULT NULL COMMENT 'Unique trusted external ID (generally from a legacy app/datasource). Particularly useful for deduping operations.',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional parent id for this Campaign.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this Campaign enabled or disabled/cancelled?',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this Campaign.',
  `created_date` datetime DEFAULT current_timestamp() COMMENT 'Date and time that Campaign was created.',
  `last_modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who recently edited this Campaign.',
  `last_modified_date` datetime DEFAULT NULL COMMENT 'Date and time that Campaign was edited last time.',
  `goal_general` text DEFAULT NULL COMMENT 'General goals for Campaign.',
  `goal_revenue` decimal(20,2) DEFAULT NULL COMMENT 'The target revenue for this campaign.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  UNIQUE KEY `UI_external_identifier` (`external_identifier`),
  KEY `index_campaign_type_id` (`campaign_type_id`),
  KEY `index_status_id` (`status_id`),
  KEY `FK_civicrm_campaign_parent_id` (`parent_id`),
  KEY `FK_civicrm_campaign_created_id` (`created_id`),
  KEY `FK_civicrm_campaign_last_modified_id` (`last_modified_id`),
  CONSTRAINT `FK_civicrm_campaign_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_campaign_last_modified_id` FOREIGN KEY (`last_modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_campaign_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_campaign_group`
--

DROP TABLE IF EXISTS `civicrm_campaign_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_campaign_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Campaign Group id.',
  `campaign_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the activity Campaign.',
  `group_type` varchar(8) DEFAULT NULL COMMENT 'Type of Group.',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'Name of table where item being referenced is stored.',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'Entity id of referenced table.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_campaign_group_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_campaign_group_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_case`
--

DROP TABLE IF EXISTS `civicrm_case`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_case` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Case ID',
  `case_type_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_case_type.id',
  `subject` varchar(128) DEFAULT NULL COMMENT 'Short name of the case.',
  `start_date` date DEFAULT NULL COMMENT 'Date on which given case starts.',
  `end_date` date DEFAULT NULL COMMENT 'Date on which given case ends.',
  `details` text DEFAULT NULL COMMENT 'Details populated from Open Case. Only used in the CiviCase extension.',
  `status_id` int(10) unsigned NOT NULL COMMENT 'ID of case status.',
  `is_deleted` tinyint(4) NOT NULL DEFAULT 0,
  `created_date` timestamp NULL DEFAULT NULL COMMENT 'When was the case was created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When was the case (or closely related entity) was created or modified or deleted.',
  PRIMARY KEY (`id`),
  KEY `index_case_type_id` (`case_type_id`),
  KEY `index_is_deleted` (`is_deleted`),
  CONSTRAINT `FK_civicrm_case_case_type_id` FOREIGN KEY (`case_type_id`) REFERENCES `civicrm_case_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_case_before_insert before insert ON civicrm_case FOR EACH ROW BEGIN  
SET NEW.created_date = CURRENT_TIMESTAMP;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_case_activity`
--

DROP TABLE IF EXISTS `civicrm_case_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_case_activity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique case-activity association id',
  `case_id` int(10) unsigned NOT NULL COMMENT 'Case ID of case-activity association.',
  `activity_id` int(10) unsigned NOT NULL COMMENT 'Activity ID of case-activity association.',
  PRIMARY KEY (`id`),
  KEY `UI_case_activity_id` (`case_id`,`activity_id`),
  KEY `FK_civicrm_case_activity_activity_id` (`activity_id`),
  CONSTRAINT `FK_civicrm_case_activity_activity_id` FOREIGN KEY (`activity_id`) REFERENCES `civicrm_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_case_activity_case_id` FOREIGN KEY (`case_id`) REFERENCES `civicrm_case` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_case_activity_after_insert after insert ON civicrm_case_activity FOR EACH ROW BEGIN  UPDATE civicrm_case SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.case_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_case_contact`
--

DROP TABLE IF EXISTS `civicrm_case_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_case_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique case-contact association id',
  `case_id` int(10) unsigned NOT NULL COMMENT 'Case ID of case-contact association.',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Contact ID of contact record given case belongs to.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_case_contact_id` (`case_id`,`contact_id`),
  KEY `FK_civicrm_case_contact_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_case_contact_case_id` FOREIGN KEY (`case_id`) REFERENCES `civicrm_case` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_case_contact_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_case_type`
--

DROP TABLE IF EXISTS `civicrm_case_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_case_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Autoincremented type id',
  `name` varchar(64) NOT NULL COMMENT 'Machine name for Case Type',
  `title` varchar(64) NOT NULL COMMENT 'Natural language name for Case Type',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of the Case Type',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this case type enabled?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this case type a predefined system type?',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Ordering of the case types',
  `definition` blob DEFAULT NULL COMMENT 'xml definition of case type',
  PRIMARY KEY (`id`),
  UNIQUE KEY `case_type_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_component`
--

DROP TABLE IF EXISTS `civicrm_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_component` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Component ID',
  `name` varchar(64) NOT NULL COMMENT 'Name of the component.',
  `namespace` varchar(128) DEFAULT NULL COMMENT 'Path to components main directory in a form of a class namespace.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contact`
--

DROP TABLE IF EXISTS `civicrm_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Contact ID',
  `contact_type` varchar(64) DEFAULT NULL COMMENT 'Type of Contact.',
  `external_identifier` varchar(64) DEFAULT NULL COMMENT 'Unique trusted external ID (generally from a legacy app/datasource). Particularly useful for deduping operations.',
  `display_name` varchar(128) DEFAULT NULL COMMENT 'Formatted name representing preferred format for display/print/other output.',
  `organization_name` varchar(128) DEFAULT NULL COMMENT 'Organization Name.',
  `contact_sub_type` varchar(255) DEFAULT NULL COMMENT 'May be used to over-ride contact view and edit templates.',
  `first_name` varchar(64) DEFAULT NULL COMMENT 'First Name.',
  `middle_name` varchar(64) DEFAULT NULL COMMENT 'Middle Name.',
  `last_name` varchar(64) DEFAULT NULL COMMENT 'Last Name.',
  `do_not_email` tinyint(4) NOT NULL DEFAULT 0,
  `do_not_phone` tinyint(4) NOT NULL DEFAULT 0,
  `do_not_mail` tinyint(4) NOT NULL DEFAULT 0,
  `do_not_sms` tinyint(4) NOT NULL DEFAULT 0,
  `do_not_trade` tinyint(4) NOT NULL DEFAULT 0,
  `is_opt_out` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Has the contact opted out from receiving all bulk email from the organization or site domain?',
  `legal_identifier` varchar(32) DEFAULT NULL COMMENT 'May be used for SSN, EIN/TIN, Household ID (census) or other applicable unique legal/government ID.',
  `sort_name` varchar(128) DEFAULT NULL COMMENT 'Name used for sorting different contact types',
  `nick_name` varchar(128) DEFAULT NULL COMMENT 'Nickname.',
  `legal_name` varchar(128) DEFAULT NULL COMMENT 'Legal Name.',
  `image_URL` text DEFAULT NULL COMMENT 'optional URL for preferred image (photo, logo, etc.) to display for this contact.',
  `preferred_communication_method` varchar(255) DEFAULT NULL COMMENT 'What is the preferred mode of communication.',
  `preferred_language` varchar(5) DEFAULT NULL COMMENT 'Which language is preferred for communication. FK to languages in civicrm_option_value.',
  `hash` varchar(32) DEFAULT NULL COMMENT 'Key for validating requests related to this contact.',
  `api_key` varchar(32) DEFAULT NULL COMMENT 'API Key for validating requests related to this contact.',
  `source` varchar(255) DEFAULT NULL COMMENT 'where contact come from, e.g. import, donate module insert...',
  `prefix_id` int(10) unsigned DEFAULT NULL COMMENT 'Prefix or Title for name (Ms, Mr...). FK to prefix ID',
  `suffix_id` int(10) unsigned DEFAULT NULL COMMENT 'Suffix for name (Jr, Sr...). FK to suffix ID',
  `formal_title` varchar(64) DEFAULT NULL COMMENT 'Formal (academic or similar) title in front of name. (Prof., Dr. etc.)',
  `communication_style_id` int(10) unsigned DEFAULT NULL COMMENT 'Communication style (e.g. formal vs. familiar) to use with this contact. FK to communication styles in civicrm_option_value.',
  `email_greeting_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.id, that has to be valid registered Email Greeting.',
  `email_greeting_custom` varchar(128) DEFAULT NULL COMMENT 'Custom Email Greeting.',
  `email_greeting_display` varchar(255) DEFAULT NULL COMMENT 'Cache Email Greeting.',
  `postal_greeting_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.id, that has to be valid registered Postal Greeting.',
  `postal_greeting_custom` varchar(128) DEFAULT NULL COMMENT 'Custom Postal greeting.',
  `postal_greeting_display` varchar(255) DEFAULT NULL COMMENT 'Cache Postal greeting.',
  `addressee_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.id, that has to be valid registered Addressee.',
  `addressee_custom` varchar(128) DEFAULT NULL COMMENT 'Custom Addressee.',
  `addressee_display` varchar(255) DEFAULT NULL COMMENT 'Cache Addressee.',
  `job_title` varchar(255) DEFAULT NULL COMMENT 'Job Title',
  `gender_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to gender ID',
  `birth_date` date DEFAULT NULL COMMENT 'Date of birth',
  `is_deceased` tinyint(4) NOT NULL DEFAULT 0,
  `deceased_date` date DEFAULT NULL COMMENT 'Date of deceased',
  `household_name` varchar(128) DEFAULT NULL COMMENT 'Household Name.',
  `primary_contact_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional FK to Primary Contact for this household.',
  `sic_code` varchar(8) DEFAULT NULL COMMENT 'Standard Industry Classification Code.',
  `user_unique_id` varchar(255) DEFAULT NULL COMMENT 'the OpenID (or OpenID-style http://username.domain/) unique identifier for this contact mainly used for logging in to CiviCRM',
  `employer_id` int(10) unsigned DEFAULT NULL COMMENT 'OPTIONAL FK to civicrm_contact record.',
  `is_deleted` tinyint(4) NOT NULL DEFAULT 0,
  `created_date` timestamp NULL DEFAULT NULL COMMENT 'When was the contact was created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When was the contact (or closely related entity) was created or modified or deleted.',
  `preferred_mail_format` varchar(8) DEFAULT 'Both' COMMENT 'Deprecated setting for text vs html mailings',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_external_identifier` (`external_identifier`),
  KEY `index_contact_type` (`contact_type`),
  KEY `index_organization_name` (`organization_name`),
  KEY `index_contact_sub_type` (`contact_sub_type`),
  KEY `index_first_name` (`first_name`),
  KEY `index_last_name` (`last_name`),
  KEY `index_sort_name` (`sort_name`),
  KEY `index_preferred_communication_method` (`preferred_communication_method`),
  KEY `index_hash` (`hash`),
  KEY `index_api_key` (`api_key`),
  KEY `UI_prefix` (`prefix_id`),
  KEY `UI_suffix` (`suffix_id`),
  KEY `index_communication_style_id` (`communication_style_id`),
  KEY `UI_gender` (`gender_id`),
  KEY `index_is_deceased` (`is_deceased`),
  KEY `index_household_name` (`household_name`),
  KEY `index_is_deleted_sort_name` (`is_deleted`,`sort_name`,`id`),
  KEY `index_created_date` (`created_date`),
  KEY `index_modified_date` (`modified_date`),
  KEY `FK_civicrm_contact_primary_contact_id` (`primary_contact_id`),
  KEY `FK_civicrm_contact_employer_id` (`employer_id`),
  CONSTRAINT `FK_civicrm_contact_employer_id` FOREIGN KEY (`employer_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contact_primary_contact_id` FOREIGN KEY (`primary_contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_contact_before_insert before insert ON civicrm_contact FOR EACH ROW BEGIN  
SET NEW.created_date = CURRENT_TIMESTAMP;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_contact_type`
--

DROP TABLE IF EXISTS `civicrm_contact_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contact_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contact Type ID',
  `name` varchar(64) NOT NULL COMMENT 'Internal name of Contact Type (or Subtype).',
  `label` varchar(64) DEFAULT NULL COMMENT 'localized Name of Contact Type.',
  `description` text DEFAULT NULL COMMENT 'localized Optional verbose description of the type.',
  `image_URL` varchar(255) DEFAULT NULL COMMENT 'URL of image if any.',
  `icon` varchar(255) DEFAULT NULL COMMENT 'crm-i icon class representing this contact type',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional FK to parent contact type.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this entry active?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this contact type a predefined system type',
  PRIMARY KEY (`id`),
  UNIQUE KEY `contact_type` (`name`),
  KEY `FK_civicrm_contact_type_parent_id` (`parent_id`),
  CONSTRAINT `FK_civicrm_contact_type_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_contact_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution`
--

DROP TABLE IF EXISTS `civicrm_contribution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contribution ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type for (total_amount - non_deductible_amount).',
  `contribution_page_id` int(10) unsigned DEFAULT NULL COMMENT 'The Contribution Page which triggered this contribution',
  `payment_instrument_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Payment Instrument',
  `receive_date` datetime DEFAULT NULL,
  `non_deductible_amount` decimal(20,2) DEFAULT 0.00 COMMENT 'Portion of total amount which is NOT tax deductible. Equal to total_amount for non-deductible financial types.',
  `total_amount` decimal(20,2) NOT NULL COMMENT 'Total amount of this contribution. Use market value for non-monetary gifts.',
  `fee_amount` decimal(20,2) DEFAULT NULL COMMENT 'actual processor fee if known - may be 0.',
  `net_amount` decimal(20,2) DEFAULT NULL COMMENT 'actual funds transfer amount. total less fees. if processor does not report actual fee during transaction, this is set to total_amount.',
  `trxn_id` varchar(255) DEFAULT NULL COMMENT 'unique transaction id. may be processor id, bank id + trans id, or account number + check number... depending on payment_method',
  `invoice_id` varchar(255) DEFAULT NULL COMMENT 'unique invoice id, system generated or passed in',
  `invoice_number` varchar(255) DEFAULT NULL COMMENT 'Human readable invoice number',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `cancel_date` datetime DEFAULT NULL COMMENT 'when was gift cancelled',
  `cancel_reason` text DEFAULT NULL,
  `receipt_date` datetime DEFAULT NULL COMMENT 'when (if) receipt was sent. populated automatically for online donations w/ automatic receipting',
  `thankyou_date` datetime DEFAULT NULL COMMENT 'when (if) was donor thanked',
  `source` varchar(255) DEFAULT NULL COMMENT 'Origin of this Contribution.',
  `amount_level` text DEFAULT NULL,
  `contribution_recur_id` int(10) unsigned DEFAULT NULL COMMENT 'Conditional foreign key to civicrm_contribution_recur id. Each contribution made in connection with a recurring contribution carries a foreign key to the recurring contribution record. This assumes we can track these processor initiated events.',
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `is_pay_later` tinyint(4) NOT NULL DEFAULT 0,
  `contribution_status_id` int(10) unsigned DEFAULT 1,
  `address_id` int(10) unsigned DEFAULT NULL COMMENT 'Conditional foreign key to civicrm_address.id. We insert an address record for each contribution when we have associated billing name and address data.',
  `check_number` varchar(255) DEFAULT NULL,
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this contribution has been triggered.',
  `creditnote_id` varchar(255) DEFAULT NULL COMMENT 'unique credit note id, system generated or passed in',
  `tax_amount` decimal(20,2) DEFAULT NULL COMMENT 'Total tax amount of this contribution.',
  `revenue_recognition_date` datetime DEFAULT NULL COMMENT 'Stores the date when revenue should be recognized.',
  `is_template` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Shows this is a template for recurring contributions.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contrib_trxn_id` (`trxn_id`),
  UNIQUE KEY `UI_contrib_invoice_id` (`invoice_id`),
  KEY `UI_contrib_payment_instrument_id` (`payment_instrument_id`),
  KEY `index_total_amount_receive_date` (`total_amount`,`receive_date`),
  KEY `index_source` (`source`),
  KEY `index_contribution_status` (`contribution_status_id`),
  KEY `received_date` (`receive_date`),
  KEY `check_number` (`check_number`),
  KEY `index_creditnote_id` (`creditnote_id`),
  KEY `FK_civicrm_contribution_contact_id` (`contact_id`),
  KEY `FK_civicrm_contribution_financial_type_id` (`financial_type_id`),
  KEY `FK_civicrm_contribution_contribution_page_id` (`contribution_page_id`),
  KEY `FK_civicrm_contribution_contribution_recur_id` (`contribution_recur_id`),
  KEY `FK_civicrm_contribution_address_id` (`address_id`),
  KEY `FK_civicrm_contribution_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_contribution_address_id` FOREIGN KEY (`address_id`) REFERENCES `civicrm_address` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_contribution_contribution_page_id` FOREIGN KEY (`contribution_page_id`) REFERENCES `civicrm_contribution_page` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_contribution_recur_id` FOREIGN KEY (`contribution_recur_id`) REFERENCES `civicrm_contribution_recur` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=113 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution_page`
--

DROP TABLE IF EXISTS `civicrm_contribution_page`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution_page` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contribution ID',
  `title` varchar(255) NOT NULL COMMENT 'Contribution Page title. For top of page display',
  `frontend_title` varchar(255) NOT NULL COMMENT 'Contribution Page Public title',
  `name` varchar(255) NOT NULL COMMENT 'Unique name for identifying contribution page',
  `intro_text` text DEFAULT NULL COMMENT 'Text and html allowed. Displayed below title.',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'default financial type assigned to contributions submitted via this page, e.g. Contribution, Campaign Contribution',
  `payment_processor` varchar(128) DEFAULT NULL COMMENT 'Payment Processors configured for this contribution Page',
  `is_credit_card_only` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - processing logic must reject transaction at confirmation stage if pay method != credit card',
  `is_monetary` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'if true - allows real-time monetary transactions otherwise non-monetary transactions',
  `is_recur` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - allows recurring contributions, valid only for PayPal_Standard',
  `is_confirm_enabled` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'if false, the confirm page in contribution pages gets skipped',
  `recur_frequency_unit` varchar(128) DEFAULT NULL COMMENT 'Supported recurring frequency units.',
  `is_recur_interval` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - supports recurring intervals',
  `is_recur_installments` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - asks user for recurring installments',
  `adjust_recur_start_date` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - user is able to adjust payment start date',
  `is_pay_later` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - allows the user to send payment directly to the org later',
  `pay_later_text` text DEFAULT NULL COMMENT 'The text displayed to the user in the main form',
  `pay_later_receipt` text DEFAULT NULL COMMENT 'The receipt sent to the user instead of the normal receipt text',
  `is_partial_payment` tinyint(4) DEFAULT 0 COMMENT 'is partial payment enabled for this online contribution page',
  `initial_amount_label` varchar(255) DEFAULT NULL COMMENT 'Initial amount label for partial payment',
  `initial_amount_help_text` text DEFAULT NULL COMMENT 'Initial amount help text for partial payment',
  `min_initial_amount` decimal(20,2) DEFAULT NULL COMMENT 'Minimum initial amount for partial payment',
  `is_allow_other_amount` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true, page will include an input text field where user can enter their own amount',
  `default_amount_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.',
  `min_amount` decimal(20,2) DEFAULT NULL COMMENT 'if other amounts allowed, user can configure minimum allowed.',
  `max_amount` decimal(20,2) DEFAULT NULL COMMENT 'if other amounts allowed, user can configure maximum allowed.',
  `goal_amount` decimal(20,2) DEFAULT NULL COMMENT 'The target goal for this page, allows people to build a goal meter',
  `thankyou_title` varchar(255) DEFAULT NULL COMMENT 'Title for Thank-you page (header title tag, and display at the top of the page).',
  `thankyou_text` text DEFAULT NULL COMMENT 'text and html allowed. displayed above result on success page',
  `thankyou_footer` text DEFAULT NULL COMMENT 'Text and html allowed. displayed at the bottom of the success page. Common usage is to include link(s) to other pages such as tell-a-friend, etc.',
  `is_email_receipt` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true, receipt is automatically emailed to contact on success',
  `receipt_from_name` varchar(255) DEFAULT NULL COMMENT 'FROM email name used for receipts generated by contributions to this contribution page.',
  `receipt_from_email` varchar(255) DEFAULT NULL COMMENT 'FROM email address used for receipts generated by contributions to this contribution page.',
  `cc_receipt` varchar(255) DEFAULT NULL COMMENT 'comma-separated list of email addresses to cc each time a receipt is sent',
  `bcc_receipt` varchar(255) DEFAULT NULL COMMENT 'comma-separated list of email addresses to bcc each time a receipt is sent',
  `receipt_text` text DEFAULT NULL COMMENT 'text to include above standard receipt info on receipt email. emails are text-only, so do not allow html for now',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this page active?',
  `footer_text` text DEFAULT NULL COMMENT 'Text and html allowed. Displayed at the bottom of the first page of the contribution wizard.',
  `amount_block_is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  `start_date` datetime DEFAULT NULL COMMENT 'Date and time that this page starts.',
  `end_date` datetime DEFAULT NULL COMMENT 'Date and time that this page ends. May be NULL if no defined end date/time',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this contribution page',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time that contribution page was created.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which we are collecting contributions with this page.',
  `is_share` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Can people share the contribution page through social media?',
  `is_billing_required` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - billing block is required for online contribution page',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_contribution_page_financial_type_id` (`financial_type_id`),
  KEY `FK_civicrm_contribution_page_created_id` (`created_id`),
  KEY `FK_civicrm_contribution_page_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_contribution_page_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_page_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_page_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution_product`
--

DROP TABLE IF EXISTS `civicrm_contribution_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution_product` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `contribution_id` int(10) unsigned NOT NULL,
  `product_option` varchar(255) DEFAULT NULL COMMENT 'Option value selected if applicable - e.g. color, size etc.',
  `quantity` int(11) DEFAULT NULL,
  `fulfilled_date` date DEFAULT NULL COMMENT 'Optional. Can be used to record the date this product was fulfilled or shipped.',
  `start_date` date DEFAULT NULL COMMENT 'Actual start date for a time-delimited premium (subscription, service or membership)',
  `end_date` date DEFAULT NULL COMMENT 'Actual end date for a time-delimited premium (subscription, service or membership)',
  `comment` text DEFAULT NULL,
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type(for membership price sets only).',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_contribution_product_product_id` (`product_id`),
  KEY `FK_civicrm_contribution_product_contribution_id` (`contribution_id`),
  KEY `FK_civicrm_contribution_product_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_contribution_product_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_contribution_product_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_product_product_id` FOREIGN KEY (`product_id`) REFERENCES `civicrm_product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution_recur`
--

DROP TABLE IF EXISTS `civicrm_contribution_recur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution_recur` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contribution Recur ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to civicrm_contact.id.',
  `amount` decimal(20,2) NOT NULL COMMENT 'Amount to be collected (including any sales tax) by payment processor each recurrence.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `frequency_unit` varchar(8) DEFAULT 'month' COMMENT 'Time units for recurrence of payment.',
  `frequency_interval` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Number of time units for recurrence of payment.',
  `installments` int(10) unsigned DEFAULT NULL COMMENT 'Total number of payments to be made. Set this to 0 if this is an open-ended commitment i.e. no set end date.',
  `start_date` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'The date the first scheduled recurring contribution occurs.',
  `create_date` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'When this recurring contribution record was created.',
  `modified_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last updated date for this record. mostly the last time a payment was received',
  `cancel_date` datetime DEFAULT NULL COMMENT 'Date this recurring contribution was cancelled by contributor- if we can get access to it',
  `cancel_reason` text DEFAULT NULL COMMENT 'Free text field for a reason for cancelling',
  `end_date` datetime DEFAULT NULL COMMENT 'Date this recurring contribution finished successfully',
  `processor_id` varchar(255) DEFAULT NULL COMMENT 'Possibly needed to store a unique identifier for this recurring payment order - if this is available from the processor??',
  `payment_token_id` int(10) unsigned DEFAULT NULL COMMENT 'Optionally used to store a link to a payment token used for this recurring contribution.',
  `trxn_id` varchar(255) DEFAULT NULL COMMENT 'unique transaction id (deprecated - use processor_id)',
  `invoice_id` varchar(255) DEFAULT NULL COMMENT 'unique invoice id, system generated or passed in',
  `contribution_status_id` int(10) unsigned DEFAULT 2,
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `cycle_day` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Day in the period when the payment should be charged e.g. 1st of month, 15th etc.',
  `next_sched_contribution_date` datetime DEFAULT NULL COMMENT 'Next scheduled date',
  `failure_count` int(10) unsigned DEFAULT 0 COMMENT 'Number of failed charge attempts since last success. Business rule could be set to deactivate on more than x failures.',
  `failure_retry_date` datetime DEFAULT NULL COMMENT 'Date to retry failed attempt',
  `auto_renew` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Some systems allow contributor to set a number of installments - but then auto-renew the subscription or commitment if they do not cancel.',
  `payment_processor_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to civicrm_payment_processor.id',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type',
  `payment_instrument_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Payment Instrument',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this contribution has been triggered.',
  `is_email_receipt` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'if true, receipt is automatically emailed to contact on each successful payment',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contrib_trxn_id` (`trxn_id`),
  UNIQUE KEY `UI_contrib_invoice_id` (`invoice_id`),
  KEY `index_contribution_status` (`contribution_status_id`),
  KEY `UI_contribution_recur_payment_instrument_id` (`payment_instrument_id`),
  KEY `FK_civicrm_contribution_recur_contact_id` (`contact_id`),
  KEY `FK_civicrm_contribution_recur_payment_token_id` (`payment_token_id`),
  KEY `FK_civicrm_contribution_recur_payment_processor_id` (`payment_processor_id`),
  KEY `FK_civicrm_contribution_recur_financial_type_id` (`financial_type_id`),
  KEY `FK_civicrm_contribution_recur_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_contribution_recur_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_recur_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_contribution_recur_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_recur_payment_processor_id` FOREIGN KEY (`payment_processor_id`) REFERENCES `civicrm_payment_processor` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_contribution_recur_payment_token_id` FOREIGN KEY (`payment_token_id`) REFERENCES `civicrm_payment_token` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution_soft`
--

DROP TABLE IF EXISTS `civicrm_contribution_soft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution_soft` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Soft Credit ID',
  `contribution_id` int(10) unsigned NOT NULL COMMENT 'FK to contribution table.',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `amount` decimal(20,2) NOT NULL COMMENT 'Amount of this soft credit.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `pcp_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_pcp.id',
  `pcp_display_in_roll` tinyint(4) NOT NULL DEFAULT 0,
  `pcp_roll_nickname` varchar(255) DEFAULT NULL,
  `pcp_personal_note` varchar(255) DEFAULT NULL,
  `soft_credit_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Soft Credit Type ID.Implicit FK to civicrm_option_value where option_group = soft_credit_type.',
  PRIMARY KEY (`id`),
  KEY `index_id` (`pcp_id`),
  KEY `FK_civicrm_contribution_soft_contribution_id` (`contribution_id`),
  KEY `FK_civicrm_contribution_soft_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_contribution_soft_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_contribution_soft_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_contribution_soft_pcp_id` FOREIGN KEY (`pcp_id`) REFERENCES `civicrm_pcp` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_contribution_widget`
--

DROP TABLE IF EXISTS `civicrm_contribution_widget`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_contribution_widget` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contribution ID',
  `contribution_page_id` int(10) unsigned DEFAULT NULL COMMENT 'The Contribution Page which triggered this contribution',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  `title` varchar(255) DEFAULT NULL COMMENT 'Widget title.',
  `url_logo` varchar(255) DEFAULT NULL COMMENT 'URL to Widget logo',
  `button_title` varchar(255) DEFAULT NULL COMMENT 'Button title.',
  `about` text DEFAULT NULL COMMENT 'About description.',
  `url_homepage` varchar(255) DEFAULT NULL COMMENT 'URL to Homepage.',
  `color_title` varchar(10) DEFAULT NULL,
  `color_button` varchar(10) DEFAULT NULL,
  `color_bar` varchar(10) DEFAULT NULL,
  `color_main_text` varchar(10) DEFAULT NULL,
  `color_main` varchar(10) DEFAULT NULL,
  `color_main_bg` varchar(10) DEFAULT NULL,
  `color_bg` varchar(10) DEFAULT NULL,
  `color_about_link` varchar(10) DEFAULT NULL,
  `color_homepage_link` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_contribution_widget_contribution_page_id` (`contribution_page_id`),
  CONSTRAINT `FK_civicrm_contribution_widget_contribution_page_id` FOREIGN KEY (`contribution_page_id`) REFERENCES `civicrm_contribution_page` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_country`
--

DROP TABLE IF EXISTS `civicrm_country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_country` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Country ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Country Name',
  `iso_code` char(2) DEFAULT NULL COMMENT 'ISO Code',
  `country_code` varchar(4) DEFAULT NULL COMMENT 'National prefix to be used when dialing TO this country.',
  `address_format_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to civicrm_address_format.id.',
  `idd_prefix` varchar(4) DEFAULT NULL COMMENT 'International direct dialing prefix from within the country TO another country',
  `ndd_prefix` varchar(4) DEFAULT NULL COMMENT 'Access prefix to call within a country to a different area',
  `region_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to civicrm_worldregion.id.',
  `is_province_abbreviated` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should state/province be displayed as abbreviation for contacts from this country?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this Country active?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name_iso_code` (`name`,`iso_code`),
  KEY `FK_civicrm_country_address_format_id` (`address_format_id`),
  KEY `FK_civicrm_country_region_id` (`region_id`),
  CONSTRAINT `FK_civicrm_country_address_format_id` FOREIGN KEY (`address_format_id`) REFERENCES `civicrm_address_format` (`id`),
  CONSTRAINT `FK_civicrm_country_region_id` FOREIGN KEY (`region_id`) REFERENCES `civicrm_worldregion` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1254 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_county`
--

DROP TABLE IF EXISTS `civicrm_county`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_county` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'County ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Name of County',
  `abbreviation` varchar(4) DEFAULT NULL COMMENT '2-4 Character Abbreviation of County',
  `state_province_id` int(10) unsigned NOT NULL COMMENT 'ID of State/Province that County belongs',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this County active?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name_state_id` (`name`,`state_province_id`),
  KEY `FK_civicrm_county_state_province_id` (`state_province_id`),
  CONSTRAINT `FK_civicrm_county_state_province_id` FOREIGN KEY (`state_province_id`) REFERENCES `civicrm_state_province` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_currency`
--

DROP TABLE IF EXISTS `civicrm_currency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_currency` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Currency ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Currency Name',
  `symbol` varchar(8) DEFAULT NULL COMMENT 'Currency Symbol',
  `numeric_code` varchar(3) DEFAULT NULL COMMENT 'Numeric currency code',
  `full_name` varchar(64) DEFAULT NULL COMMENT 'Full currency name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=186 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_custom_field`
--

DROP TABLE IF EXISTS `civicrm_custom_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_custom_field` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Custom Field ID',
  `custom_group_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_custom_group.',
  `name` varchar(64) DEFAULT NULL COMMENT 'Variable name/programmatic handle for this field.',
  `label` varchar(255) NOT NULL COMMENT 'Text for form field label (also friendly name for administering this custom property).',
  `data_type` varchar(16) NOT NULL COMMENT 'Controls location of data storage in extended_data table.',
  `html_type` varchar(32) NOT NULL COMMENT 'HTML types plus several built-in extended types.',
  `default_value` varchar(255) DEFAULT NULL COMMENT 'Use form_options.is_default for field_types which use options.',
  `is_required` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is a value required for this property.',
  `is_searchable` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this property searchable.',
  `is_search_range` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this property range searchable.',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Controls field display order within an extended property group.',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before this field.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after this field.',
  `attributes` varchar(255) DEFAULT NULL COMMENT 'Store collection of type-appropriate attributes, e.g. textarea  needs rows/cols attributes',
  `is_active` tinyint(4) DEFAULT 1 COMMENT 'Is this property active?',
  `is_view` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this property set by PHP Code? A code field is viewable but not editable',
  `options_per_line` int(10) unsigned DEFAULT NULL COMMENT 'number of options per line for checkbox and radio',
  `text_length` int(10) unsigned DEFAULT NULL COMMENT 'field length if alphanumeric',
  `start_date_years` int(11) DEFAULT NULL COMMENT 'Date may be up to start_date_years years prior to the current date.',
  `end_date_years` int(11) DEFAULT NULL COMMENT 'Date may be up to end_date_years years after the current date.',
  `date_format` varchar(64) DEFAULT NULL COMMENT 'date format for custom date',
  `time_format` int(10) unsigned DEFAULT NULL COMMENT 'time format for custom date',
  `note_columns` int(10) unsigned DEFAULT NULL COMMENT 'Number of columns in Note Field',
  `note_rows` int(10) unsigned DEFAULT NULL COMMENT 'Number of rows in Note Field',
  `column_name` varchar(255) DEFAULT NULL COMMENT 'Name of the column that holds the values for this field.',
  `option_group_id` int(10) unsigned DEFAULT NULL COMMENT 'For elements with options, the option group id that is used',
  `serialize` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Serialization method - a non-zero value indicates a multi-valued field.',
  `filter` varchar(255) DEFAULT NULL COMMENT 'Stores Contact Get API params contact reference custom fields. May be used for other filters in the future.',
  `in_selector` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should the multi-record custom field values be displayed in tab table listing',
  `fk_entity` varchar(255) DEFAULT NULL COMMENT 'Name of entity being referenced.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_label_custom_group_id` (`label`,`custom_group_id`),
  UNIQUE KEY `UI_name_custom_group_id` (`name`,`custom_group_id`),
  KEY `FK_civicrm_custom_field_custom_group_id` (`custom_group_id`),
  KEY `FK_civicrm_custom_field_option_group_id` (`option_group_id`),
  CONSTRAINT `FK_civicrm_custom_field_custom_group_id` FOREIGN KEY (`custom_group_id`) REFERENCES `civicrm_custom_group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_custom_field_option_group_id` FOREIGN KEY (`option_group_id`) REFERENCES `civicrm_option_group` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_custom_group`
--

DROP TABLE IF EXISTS `civicrm_custom_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_custom_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Custom Group ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Variable name/programmatic handle for this group.',
  `title` varchar(64) NOT NULL COMMENT 'Friendly Name.',
  `extends` varchar(255) DEFAULT 'Contact' COMMENT 'Type of object this group extends (can add other options later e.g. contact_address, etc.).',
  `extends_entity_column_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.id (for option group custom_data_type.)',
  `extends_entity_column_value` varchar(255) DEFAULT NULL COMMENT 'linking custom group for dynamic object',
  `style` varchar(15) DEFAULT NULL COMMENT 'Visual relationship between this form and its parent.',
  `collapse_display` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Will this group be in collapsed or expanded mode on initial display ?',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before fields in form.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after fields in form.',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Controls display order when multiple extended property groups are setup for the same class.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  `table_name` varchar(255) DEFAULT NULL COMMENT 'Name of the table that holds the values for this group.',
  `is_multiple` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Does this group hold multiple values?',
  `min_multiple` int(10) unsigned DEFAULT NULL COMMENT 'minimum number of multiple records (typically 0?)',
  `max_multiple` int(10) unsigned DEFAULT NULL COMMENT 'maximum number of multiple records, if 0 - no max',
  `collapse_adv_display` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Will this group be in collapsed or expanded mode on advanced search display ?',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this custom group',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time this custom group was created.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a reserved Custom Group?',
  `is_public` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property public?',
  `icon` varchar(255) DEFAULT NULL COMMENT 'crm-i icon class',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_title_extends` (`title`,`extends`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_custom_group_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_custom_group_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_cxn`
--

DROP TABLE IF EXISTS `civicrm_cxn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_cxn` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Connection ID',
  `app_guid` varchar(128) DEFAULT NULL COMMENT 'Application GUID',
  `app_meta` text DEFAULT NULL COMMENT 'Application Metadata (JSON)',
  `cxn_guid` varchar(128) DEFAULT NULL COMMENT 'Connection GUID',
  `secret` text DEFAULT NULL COMMENT 'Shared secret',
  `perm` text DEFAULT NULL COMMENT 'Permissions approved for the service (JSON)',
  `options` text DEFAULT NULL COMMENT 'Options for the service (JSON)',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is connection currently enabled?',
  `created_date` timestamp NULL DEFAULT NULL COMMENT 'When was the connection was created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When the connection was created or modified.',
  `fetched_date` timestamp NULL DEFAULT NULL COMMENT 'The last time the application metadata was fetched.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_appid` (`app_guid`),
  UNIQUE KEY `UI_keypair_cxnid` (`cxn_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_dashboard`
--

DROP TABLE IF EXISTS `civicrm_dashboard`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_dashboard` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Domain for dashboard',
  `name` varchar(64) DEFAULT NULL COMMENT 'Internal name of dashlet.',
  `label` varchar(255) DEFAULT NULL COMMENT 'dashlet title',
  `url` varchar(255) DEFAULT NULL COMMENT 'url in case of external dashlet',
  `permission` varchar(255) DEFAULT NULL COMMENT 'Permission for the dashlet',
  `permission_operator` varchar(3) DEFAULT NULL COMMENT 'Permission Operator',
  `fullscreen_url` varchar(255) DEFAULT NULL COMMENT 'fullscreen url for dashlet',
  `is_active` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this dashlet active?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this dashlet reserved?',
  `cache_minutes` int(10) unsigned NOT NULL DEFAULT 60 COMMENT 'Number of minutes to cache dashlet content in browser localStorage.',
  `directive` varchar(255) DEFAULT NULL COMMENT 'Element name of angular directive to invoke (lowercase hyphenated format)',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_dashboard_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_dashboard_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_dashboard_contact`
--

DROP TABLE IF EXISTS `civicrm_dashboard_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_dashboard_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dashboard_id` int(10) unsigned NOT NULL COMMENT 'Dashboard ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Contact ID',
  `column_no` int(11) DEFAULT 0 COMMENT 'column no for this widget',
  `is_active` tinyint(4) DEFAULT 0 COMMENT 'Is this widget active?',
  `weight` int(11) DEFAULT 0 COMMENT 'Ordering of the widgets.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_dashboard_id_contact_id` (`dashboard_id`,`contact_id`),
  KEY `FK_civicrm_dashboard_contact_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_dashboard_contact_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_dashboard_contact_dashboard_id` FOREIGN KEY (`dashboard_id`) REFERENCES `civicrm_dashboard` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_dedupe_exception`
--

DROP TABLE IF EXISTS `civicrm_dedupe_exception`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_dedupe_exception` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique dedupe exception id',
  `contact_id1` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `contact_id2` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contact_id1_contact_id2` (`contact_id1`,`contact_id2`),
  KEY `FK_civicrm_dedupe_exception_contact_id2` (`contact_id2`),
  CONSTRAINT `FK_civicrm_dedupe_exception_contact_id1` FOREIGN KEY (`contact_id1`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_dedupe_exception_contact_id2` FOREIGN KEY (`contact_id2`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_dedupe_rule`
--

DROP TABLE IF EXISTS `civicrm_dedupe_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_dedupe_rule` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique dedupe rule id',
  `dedupe_rule_group_id` int(10) unsigned NOT NULL COMMENT 'The id of the rule group this rule belongs to',
  `rule_table` varchar(64) NOT NULL COMMENT 'The name of the table this rule is about',
  `rule_field` varchar(64) NOT NULL COMMENT 'The name of the field of the table referenced in rule_table',
  `rule_length` int(10) unsigned DEFAULT NULL COMMENT 'The length of the matching substring',
  `rule_weight` int(11) NOT NULL COMMENT 'The weight of the rule',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_dedupe_rule_dedupe_rule_group_id` (`dedupe_rule_group_id`),
  CONSTRAINT `FK_civicrm_dedupe_rule_dedupe_rule_group_id` FOREIGN KEY (`dedupe_rule_group_id`) REFERENCES `civicrm_dedupe_rule_group` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_dedupe_rule_group`
--

DROP TABLE IF EXISTS `civicrm_dedupe_rule_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_dedupe_rule_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique dedupe rule group id',
  `contact_type` varchar(12) DEFAULT NULL COMMENT 'The type of contacts this group applies to',
  `threshold` int(11) NOT NULL COMMENT 'The weight threshold the sum of the rule weights has to cross to consider two contacts the same',
  `used` varchar(12) NOT NULL COMMENT 'Whether the rule should be used for cases where usage is Unsupervised, Supervised OR General(programatically)',
  `name` varchar(255) DEFAULT NULL COMMENT 'Unique name of rule group',
  `title` varchar(255) DEFAULT NULL COMMENT 'Label of the rule group',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a reserved rule - a rule group that has been optimized and cannot be changed by the admin',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_discount`
--

DROP TABLE IF EXISTS `civicrm_discount`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_discount` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to discount, e.g. civicrm_event',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `price_set_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_price_set',
  `start_date` date DEFAULT NULL COMMENT 'Date when discount starts.',
  `end_date` date DEFAULT NULL COMMENT 'Date when discount ends.',
  PRIMARY KEY (`id`),
  KEY `index_entity` (`entity_table`,`entity_id`),
  KEY `index_entity_option_id` (`entity_table`,`entity_id`,`price_set_id`),
  KEY `FK_civicrm_discount_price_set_id` (`price_set_id`),
  CONSTRAINT `FK_civicrm_discount_price_set_id` FOREIGN KEY (`price_set_id`) REFERENCES `civicrm_price_set` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_domain`
--

DROP TABLE IF EXISTS `civicrm_domain`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_domain` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Domain ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Name of Domain / Organization',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of Domain.',
  `version` varchar(32) DEFAULT NULL COMMENT 'The civicrm version this instance is running',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID. This is specifically not an FK to avoid circular constraints',
  `locales` text DEFAULT NULL COMMENT 'list of locales supported by the current db state (NULL for single-lang install)',
  `locale_custom_strings` text DEFAULT NULL COMMENT 'Locale specific string overrides',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_domain_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_domain_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_email`
--

DROP TABLE IF EXISTS `civicrm_email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_email` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Email ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Location does this email belong to.',
  `email` varchar(254) DEFAULT NULL COMMENT 'Email address',
  `is_primary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the primary email address',
  `is_billing` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the billing?',
  `on_hold` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Implicit FK to civicrm_option_value where option_group = email_on_hold.',
  `is_bulkmail` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this address for bulk mail ?',
  `hold_date` datetime DEFAULT NULL COMMENT 'When the address went on bounce hold',
  `reset_date` datetime DEFAULT NULL COMMENT 'When the address bounce status was last reset',
  `signature_text` text DEFAULT NULL COMMENT 'Text formatted signature for the email.',
  `signature_html` text DEFAULT NULL COMMENT 'HTML formatted signature for the email.',
  PRIMARY KEY (`id`),
  KEY `index_location_type` (`location_type_id`),
  KEY `UI_email` (`email`),
  KEY `index_is_primary` (`is_primary`),
  KEY `index_is_billing` (`is_billing`),
  KEY `FK_civicrm_email_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_email_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=201 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_email_after_insert after insert ON civicrm_email FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_email_after_update after update ON civicrm_email FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_email_after_delete after delete ON civicrm_email FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_entity_batch`
--

DROP TABLE IF EXISTS `civicrm_entity_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_entity_batch` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to file, e.g. civicrm_contact',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `batch_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_batch',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_batch_entity` (`batch_id`,`entity_id`,`entity_table`),
  KEY `index_entity` (`entity_table`,`entity_id`),
  CONSTRAINT `FK_civicrm_entity_batch_batch_id` FOREIGN KEY (`batch_id`) REFERENCES `civicrm_batch` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_entity_file`
--

DROP TABLE IF EXISTS `civicrm_entity_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_entity_file` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to file, e.g. civicrm_contact',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `file_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_file',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_entity_id_entity_table_file_id` (`entity_id`,`entity_table`,`file_id`),
  KEY `FK_civicrm_entity_file_file_id` (`file_id`),
  CONSTRAINT `FK_civicrm_entity_file_file_id` FOREIGN KEY (`file_id`) REFERENCES `civicrm_file` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_entity_financial_account`
--

DROP TABLE IF EXISTS `civicrm_entity_financial_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_entity_financial_account` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Links to an entity_table like civicrm_financial_type',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Links to an id in the entity_table, such as vid in civicrm_financial_type',
  `account_relationship` int(10) unsigned NOT NULL COMMENT 'FK to a new civicrm_option_value (account_relationship)',
  `financial_account_id` int(10) unsigned NOT NULL COMMENT 'FK to the financial_account_id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_entity_id_entity_table_account_relationship` (`entity_id`,`entity_table`,`account_relationship`),
  KEY `FK_civicrm_entity_financial_account_financial_account_id` (`financial_account_id`),
  CONSTRAINT `FK_civicrm_entity_financial_account_financial_account_id` FOREIGN KEY (`financial_account_id`) REFERENCES `civicrm_financial_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_entity_financial_trxn`
--

DROP TABLE IF EXISTS `civicrm_entity_financial_trxn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_entity_financial_trxn` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'May contain civicrm_financial_item, civicrm_contribution, civicrm_financial_trxn, civicrm_grant, etc',
  `entity_id` int(10) unsigned NOT NULL,
  `financial_trxn_id` int(10) unsigned DEFAULT NULL,
  `amount` decimal(20,2) NOT NULL COMMENT 'allocated amount of transaction to this entity',
  PRIMARY KEY (`id`),
  KEY `UI_entity_financial_trxn_entity_table` (`entity_table`),
  KEY `UI_entity_financial_trxn_entity_id` (`entity_id`),
  KEY `FK_civicrm_entity_financial_trxn_financial_trxn_id` (`financial_trxn_id`),
  CONSTRAINT `FK_civicrm_entity_financial_trxn_financial_trxn_id` FOREIGN KEY (`financial_trxn_id`) REFERENCES `civicrm_financial_trxn` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=223 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_entity_tag`
--

DROP TABLE IF EXISTS `civicrm_entity_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_entity_tag` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to file, e.g. civicrm_contact',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `tag_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_tag',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_entity_id_entity_table_tag_id` (`entity_id`,`entity_table`,`tag_id`),
  KEY `FK_civicrm_entity_tag_tag_id` (`tag_id`),
  CONSTRAINT `FK_civicrm_entity_tag_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `civicrm_tag` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_event`
--

DROP TABLE IF EXISTS `civicrm_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_event` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Event',
  `title` varchar(255) DEFAULT NULL COMMENT 'Event Title (e.g. Fall Fundraiser Dinner)',
  `summary` text DEFAULT NULL COMMENT 'Brief summary of event. Text and html allowed. Displayed on Event Registration form and can be used on other CMS pages which need an event summary.',
  `description` text DEFAULT NULL COMMENT 'Full description of event. Text and html allowed. Displayed on built-in Event Information screens.',
  `event_type_id` int(10) unsigned DEFAULT 0 COMMENT 'Event Type ID.Implicit FK to civicrm_option_value where option_group = event_type.',
  `participant_listing_id` int(10) unsigned DEFAULT NULL COMMENT 'Should we expose the participant list? Implicit FK to civicrm_option_value where option_group = participant_listing.',
  `is_public` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Public events will be included in the iCal feeds. Access to private event information may be limited using ACLs.',
  `start_date` datetime DEFAULT NULL COMMENT 'Date and time that event starts.',
  `end_date` datetime DEFAULT NULL COMMENT 'Date and time that event ends. May be NULL if no defined end date/time',
  `is_online_registration` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'If true, include registration link on Event Info page.',
  `registration_link_text` varchar(255) DEFAULT NULL COMMENT 'Text for link to Event Registration form which is displayed on Event Information screen when is_online_registration is true.',
  `registration_start_date` datetime DEFAULT NULL COMMENT 'Date and time that online registration starts.',
  `registration_end_date` datetime DEFAULT NULL COMMENT 'Date and time that online registration ends.',
  `max_participants` int(10) unsigned DEFAULT NULL COMMENT 'Maximum number of registered participants to allow. After max is reached, a custom Event Full message is displayed. If NULL, allow unlimited number of participants.',
  `event_full_text` text DEFAULT NULL COMMENT 'Message to display on Event Information page and INSTEAD OF Event Registration form if maximum participants are signed up. Can include email address/info about getting on a waiting list, etc. Text and html allowed.',
  `is_monetary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'If true, one or more fee amounts must be set and a Payment Processor must be configured for Online Event Registration.',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Financial type assigned to paid event registrations for this event. Required if is_monetary is true.',
  `payment_processor` varchar(128) DEFAULT NULL COMMENT 'Payment Processors configured for this Event (if is_monetary is true)',
  `is_map` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Include a map block on the Event Information page when geocode info is available and a mapping provider has been specified?',
  `is_active` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this Event enabled or disabled/cancelled?',
  `fee_label` varchar(255) DEFAULT NULL,
  `is_show_location` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'If true, show event location.',
  `loc_block_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Location Block ID',
  `default_role_id` int(10) unsigned DEFAULT 1 COMMENT 'Participant role ID. Implicit FK to civicrm_option_value where option_group = participant_role.',
  `intro_text` text DEFAULT NULL COMMENT 'Introductory message for Event Registration page. Text and html allowed. Displayed at the top of Event Registration form.',
  `footer_text` text DEFAULT NULL COMMENT 'Footer message for Event Registration page. Text and html allowed. Displayed at the bottom of Event Registration form.',
  `confirm_title` varchar(255) DEFAULT NULL COMMENT 'Title for Confirmation page.',
  `confirm_text` text DEFAULT NULL COMMENT 'Introductory message for Event Registration page. Text and html allowed. Displayed at the top of Event Registration form.',
  `confirm_footer_text` text DEFAULT NULL COMMENT 'Footer message for Event Registration page. Text and html allowed. Displayed at the bottom of Event Registration form.',
  `is_email_confirm` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'If true, confirmation is automatically emailed to contact on successful registration.',
  `confirm_email_text` text DEFAULT NULL COMMENT 'text to include above standard event info on confirmation email. emails are text-only, so do not allow html for now',
  `confirm_from_name` varchar(255) DEFAULT NULL COMMENT 'FROM email name used for confirmation emails.',
  `confirm_from_email` varchar(255) DEFAULT NULL COMMENT 'FROM email address used for confirmation emails.',
  `cc_confirm` varchar(255) DEFAULT NULL COMMENT 'comma-separated list of email addresses to cc each time a confirmation is sent',
  `bcc_confirm` varchar(255) DEFAULT NULL COMMENT 'comma-separated list of email addresses to bcc each time a confirmation is sent',
  `default_fee_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.',
  `default_discount_fee_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_option_value.',
  `thankyou_title` varchar(255) DEFAULT NULL COMMENT 'Title for ThankYou page.',
  `thankyou_text` text DEFAULT NULL COMMENT 'ThankYou Text.',
  `thankyou_footer_text` text DEFAULT NULL COMMENT 'Footer message.',
  `is_pay_later` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - allows the user to send payment directly to the org later',
  `pay_later_text` text DEFAULT NULL COMMENT 'The text displayed to the user in the main form',
  `pay_later_receipt` text DEFAULT NULL COMMENT 'The receipt sent to the user instead of the normal receipt text',
  `is_partial_payment` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'is partial payment enabled for this event',
  `initial_amount_label` varchar(255) DEFAULT NULL COMMENT 'Initial amount label for partial payment',
  `initial_amount_help_text` text DEFAULT NULL COMMENT 'Initial amount help text for partial payment',
  `min_initial_amount` decimal(20,2) DEFAULT NULL COMMENT 'Minimum initial amount for partial payment',
  `is_multiple_registrations` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - allows the user to register multiple participants for event',
  `max_additional_participants` int(10) unsigned DEFAULT 0 COMMENT 'Maximum number of additional participants that can be registered on a single booking',
  `allow_same_participant_emails` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true - allows the user to register multiple registrations from same email address.',
  `has_waitlist` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Whether the event has waitlist support.',
  `requires_approval` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Whether participants require approval before they can finish registering.',
  `expiration_time` int(10) unsigned DEFAULT NULL COMMENT 'Expire pending but unconfirmed registrations after this many hours.',
  `allow_selfcancelxfer` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Allow self service cancellation or transfer for event?',
  `selfcancelxfer_time` int(11) DEFAULT 0 COMMENT 'Number of hours prior to event start date to allow self-service cancellation or transfer.',
  `waitlist_text` text DEFAULT NULL COMMENT 'Text to display when the event is full, but participants can signup for a waitlist.',
  `approval_req_text` text DEFAULT NULL COMMENT 'Text to display when the approval is required to complete registration for an event.',
  `is_template` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'whether the event has template',
  `template_title` varchar(255) DEFAULT NULL COMMENT 'Event Template Title',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this event',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time that event was created.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this event has been created.',
  `is_share` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Can people share the event through social media?',
  `is_confirm_enabled` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'If false, the event booking confirmation screen gets skipped',
  `parent_event_id` int(10) unsigned DEFAULT NULL COMMENT 'Implicit FK to civicrm_event: parent event',
  `slot_label_id` int(10) unsigned DEFAULT NULL COMMENT 'Subevent slot label. Implicit FK to civicrm_option_value where option_group = conference_slot.',
  `dedupe_rule_group_id` int(10) unsigned DEFAULT NULL COMMENT 'Rule to use when matching registrations for this event',
  `is_billing_required` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'if true than billing block is required this event',
  PRIMARY KEY (`id`),
  KEY `index_event_type_id` (`event_type_id`),
  KEY `index_participant_listing_id` (`participant_listing_id`),
  KEY `index_parent_event_id` (`parent_event_id`),
  KEY `FK_civicrm_event_loc_block_id` (`loc_block_id`),
  KEY `FK_civicrm_event_created_id` (`created_id`),
  KEY `FK_civicrm_event_campaign_id` (`campaign_id`),
  KEY `FK_civicrm_event_dedupe_rule_group_id` (`dedupe_rule_group_id`),
  CONSTRAINT `FK_civicrm_event_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_event_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_event_dedupe_rule_group_id` FOREIGN KEY (`dedupe_rule_group_id`) REFERENCES `civicrm_dedupe_rule_group` (`id`),
  CONSTRAINT `FK_civicrm_event_loc_block_id` FOREIGN KEY (`loc_block_id`) REFERENCES `civicrm_loc_block` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_event_carts`
--

DROP TABLE IF EXISTS `civicrm_event_carts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_event_carts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Cart ID',
  `user_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact who created this cart',
  `completed` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_event_carts_user_id` (`user_id`),
  CONSTRAINT `FK_civicrm_event_carts_user_id` FOREIGN KEY (`user_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_events_in_carts`
--

DROP TABLE IF EXISTS `civicrm_events_in_carts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_events_in_carts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Event In Cart ID',
  `event_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Event ID',
  `event_cart_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Event Cart ID',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_events_in_carts_event_id` (`event_id`),
  KEY `FK_civicrm_events_in_carts_event_cart_id` (`event_cart_id`),
  CONSTRAINT `FK_civicrm_events_in_carts_event_cart_id` FOREIGN KEY (`event_cart_id`) REFERENCES `civicrm_event_carts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_events_in_carts_event_id` FOREIGN KEY (`event_id`) REFERENCES `civicrm_event` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_extension`
--

DROP TABLE IF EXISTS `civicrm_extension`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_extension` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Local Extension ID',
  `type` varchar(8) NOT NULL,
  `full_name` varchar(255) NOT NULL COMMENT 'Fully qualified extension name',
  `name` varchar(255) DEFAULT NULL COMMENT 'Short name',
  `label` varchar(255) DEFAULT NULL COMMENT 'Short, printable name',
  `file` varchar(255) DEFAULT NULL COMMENT 'Primary PHP file',
  `schema_version` varchar(63) DEFAULT NULL COMMENT 'Revision code of the database schema; the format is module-defined',
  `is_active` tinyint(4) DEFAULT 1 COMMENT 'Is this extension active?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_extension_full_name` (`full_name`),
  KEY `UI_extension_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_file`
--

DROP TABLE IF EXISTS `civicrm_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_file` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique ID',
  `file_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Type of file (e.g. Transcript, Income Tax Return, etc). FK to civicrm_option_value.',
  `mime_type` varchar(255) DEFAULT NULL COMMENT 'mime type of the document',
  `uri` varchar(255) DEFAULT NULL COMMENT 'uri of the file on disk',
  `document` mediumblob DEFAULT NULL COMMENT 'contents of the document',
  `description` varchar(255) DEFAULT NULL COMMENT 'Additional descriptive text regarding this attachment (optional).',
  `upload_date` datetime DEFAULT NULL COMMENT 'Date and time that this attachment was uploaded or written to server.',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who uploaded this file',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_file_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_file_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_financial_account`
--

DROP TABLE IF EXISTS `civicrm_financial_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_financial_account` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `name` varchar(255) NOT NULL COMMENT 'Financial Account Name.',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID that is responsible for the funds in this account',
  `financial_account_type_id` int(10) unsigned NOT NULL DEFAULT 3 COMMENT 'pseudo FK into civicrm_option_value.',
  `accounting_code` varchar(64) DEFAULT NULL COMMENT 'Optional value for mapping monies owed and received to accounting system codes.',
  `account_type_code` varchar(64) DEFAULT NULL COMMENT 'Optional value for mapping account types to accounting system account categories (QuickBooks Account Type Codes for example).',
  `description` varchar(255) DEFAULT NULL COMMENT 'Financial Type Description.',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent ID in account hierarchy',
  `is_header_account` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a header account which does not allow transactions to be posted against it directly, but only to its sub-accounts?',
  `is_deductible` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this account tax-deductible?',
  `is_tax` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this account for taxes?',
  `tax_rate` decimal(10,8) DEFAULT NULL COMMENT 'The percentage of the total_amount that is due for this tax.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a predefined system object?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this account the default one (or default tax one) for its financial_account_type?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_financial_account_contact_id` (`contact_id`),
  KEY `FK_civicrm_financial_account_parent_id` (`parent_id`),
  CONSTRAINT `FK_civicrm_financial_account_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_financial_account_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_financial_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_financial_item`
--

DROP TABLE IF EXISTS `civicrm_financial_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_financial_item` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date and time the item was created',
  `transaction_date` datetime NOT NULL COMMENT 'Date and time of the source transaction',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID of contact the item is from',
  `description` varchar(255) DEFAULT NULL COMMENT 'Human readable description of this item, to ease display without lookup of source item.',
  `amount` decimal(20,2) NOT NULL DEFAULT 0.00 COMMENT 'Total amount of this item',
  `currency` varchar(3) DEFAULT NULL COMMENT 'Currency for the amount',
  `financial_account_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_financial_account',
  `status_id` int(10) unsigned DEFAULT NULL COMMENT 'Payment status: test, paid, part_paid, unpaid (if empty assume unpaid)',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'May contain civicrm_line_item, civicrm_financial_trxn etc',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'The specific source item that is responsible for the creation of this financial_item',
  PRIMARY KEY (`id`),
  KEY `IX_created_date` (`created_date`),
  KEY `IX_transaction_date` (`transaction_date`),
  KEY `index_entity_id_entity_table` (`entity_id`,`entity_table`),
  KEY `FK_civicrm_financial_item_contact_id` (`contact_id`),
  KEY `FK_civicrm_financial_item_financial_account_id` (`financial_account_id`),
  CONSTRAINT `FK_civicrm_financial_item_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_financial_item_financial_account_id` FOREIGN KEY (`financial_account_id`) REFERENCES `civicrm_financial_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_financial_trxn`
--

DROP TABLE IF EXISTS `civicrm_financial_trxn`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_financial_trxn` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `from_financial_account_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to financial_account table.',
  `to_financial_account_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to financial_financial_account table.',
  `trxn_date` datetime DEFAULT NULL COMMENT 'date transaction occurred',
  `total_amount` decimal(20,2) NOT NULL COMMENT 'amount of transaction',
  `fee_amount` decimal(20,2) DEFAULT NULL COMMENT 'actual processor fee if known - may be 0.',
  `net_amount` decimal(20,2) DEFAULT NULL COMMENT 'actual funds transfer amount. total less fees. if processor does not report actual fee during transaction, this is set to total_amount.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `is_payment` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this entry either a payment or a reversal of a payment?',
  `trxn_id` varchar(255) DEFAULT NULL COMMENT 'Transaction id supplied by external processor. This may not be unique.',
  `trxn_result_code` varchar(255) DEFAULT NULL COMMENT 'processor result code',
  `status_id` int(10) unsigned DEFAULT NULL COMMENT 'pseudo FK to civicrm_option_value of contribution_status_id option_group',
  `payment_processor_id` int(10) unsigned DEFAULT NULL COMMENT 'Payment Processor for this financial transaction',
  `payment_instrument_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to payment_instrument option group values',
  `card_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to accept_creditcard option group values',
  `check_number` varchar(255) DEFAULT NULL COMMENT 'Check number',
  `pan_truncation` varchar(4) DEFAULT NULL COMMENT 'Last 4 digits of credit card',
  `order_reference` varchar(255) DEFAULT NULL COMMENT 'Payment Processor external order reference',
  PRIMARY KEY (`id`),
  KEY `UI_ftrxn_trxn_id` (`trxn_id`),
  KEY `UI_ftrxn_payment_instrument_id` (`payment_instrument_id`),
  KEY `UI_ftrxn_check_number` (`check_number`),
  KEY `FK_civicrm_financial_trxn_from_financial_account_id` (`from_financial_account_id`),
  KEY `FK_civicrm_financial_trxn_to_financial_account_id` (`to_financial_account_id`),
  KEY `FK_civicrm_financial_trxn_payment_processor_id` (`payment_processor_id`),
  CONSTRAINT `FK_civicrm_financial_trxn_from_financial_account_id` FOREIGN KEY (`from_financial_account_id`) REFERENCES `civicrm_financial_account` (`id`),
  CONSTRAINT `FK_civicrm_financial_trxn_payment_processor_id` FOREIGN KEY (`payment_processor_id`) REFERENCES `civicrm_payment_processor` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_financial_trxn_to_financial_account_id` FOREIGN KEY (`to_financial_account_id`) REFERENCES `civicrm_financial_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_financial_type`
--

DROP TABLE IF EXISTS `civicrm_financial_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_financial_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID of original financial_type so you can search this table by the financial_type.id and then select the relevant version based on the timestamp',
  `name` varchar(64) NOT NULL COMMENT 'Financial Type Name.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Financial Type Description.',
  `is_deductible` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this financial type tax-deductible? If true, contributions of this type may be fully OR partially deductible - non-deductible amount is stored in the Contribution record.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a predefined system object?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_group`
--

DROP TABLE IF EXISTS `civicrm_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Group ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Internal name of Group.',
  `title` varchar(255) DEFAULT NULL COMMENT 'Name of Group.',
  `description` text DEFAULT NULL COMMENT 'Optional verbose description of the group.',
  `source` varchar(64) DEFAULT NULL COMMENT 'Module or process which created this group.',
  `saved_search_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to saved search table.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this group active?',
  `visibility` varchar(24) DEFAULT 'User and User Admin Only' COMMENT 'In what context(s) is this field visible.',
  `where_clause` text DEFAULT NULL COMMENT 'the sql where clause if a saved search acl',
  `select_tables` text DEFAULT NULL COMMENT 'the tables to be included in a select data',
  `where_tables` text DEFAULT NULL COMMENT 'the tables to be included in the count statement',
  `group_type` varchar(128) DEFAULT NULL COMMENT 'FK to group type',
  `cache_date` timestamp NULL DEFAULT NULL COMMENT 'Date when we created the cache for a smart group',
  `refresh_date` timestamp NULL DEFAULT NULL COMMENT 'Unused deprecated column.',
  `parents` text DEFAULT NULL COMMENT 'List of parent groups',
  `children` text DEFAULT NULL COMMENT 'List of child groups (calculated)',
  `is_hidden` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this group hidden?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0,
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `frontend_title` varchar(255) DEFAULT NULL COMMENT 'Alternative public title for this Group.',
  `frontend_description` text DEFAULT NULL COMMENT 'Alternative public description of the group.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_title` (`title`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `UI_cache_date` (`cache_date`),
  KEY `index_group_type` (`group_type`),
  KEY `FK_civicrm_group_saved_search_id` (`saved_search_id`),
  KEY `FK_civicrm_group_created_id` (`created_id`),
  KEY `FK_civicrm_group_modified_id` (`modified_id`),
  CONSTRAINT `FK_civicrm_group_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_group_modified_id` FOREIGN KEY (`modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_group_saved_search_id` FOREIGN KEY (`saved_search_id`) REFERENCES `civicrm_saved_search` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_group_contact`
--

DROP TABLE IF EXISTS `civicrm_group_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_group_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `group_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_group',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_contact',
  `status` varchar(8) DEFAULT NULL COMMENT 'status of contact relative to membership in group',
  `location_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional location to associate with this membership',
  `email_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional email to associate with this membership',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contact_group` (`contact_id`,`group_id`),
  KEY `FK_civicrm_group_contact_group_id` (`group_id`),
  KEY `FK_civicrm_group_contact_location_id` (`location_id`),
  KEY `FK_civicrm_group_contact_email_id` (`email_id`),
  CONSTRAINT `FK_civicrm_group_contact_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_group_contact_email_id` FOREIGN KEY (`email_id`) REFERENCES `civicrm_email` (`id`),
  CONSTRAINT `FK_civicrm_group_contact_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_group_contact_location_id` FOREIGN KEY (`location_id`) REFERENCES `civicrm_loc_block` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_group_contact_cache`
--

DROP TABLE IF EXISTS `civicrm_group_contact_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_group_contact_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `group_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_group',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_contact',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contact_group` (`contact_id`,`group_id`),
  KEY `FK_civicrm_group_contact_cache_group_id` (`group_id`),
  CONSTRAINT `FK_civicrm_group_contact_cache_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_group_contact_cache_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_group_nesting`
--

DROP TABLE IF EXISTS `civicrm_group_nesting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_group_nesting` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Relationship ID',
  `child_group_id` int(10) unsigned NOT NULL COMMENT 'ID of the child group',
  `parent_group_id` int(10) unsigned NOT NULL COMMENT 'ID of the parent group',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_group_nesting_child_group_id` (`child_group_id`),
  KEY `FK_civicrm_group_nesting_parent_group_id` (`parent_group_id`),
  CONSTRAINT `FK_civicrm_group_nesting_child_group_id` FOREIGN KEY (`child_group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_group_nesting_parent_group_id` FOREIGN KEY (`parent_group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_group_organization`
--

DROP TABLE IF EXISTS `civicrm_group_organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_group_organization` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Relationship ID',
  `group_id` int(10) unsigned NOT NULL COMMENT 'ID of the group',
  `organization_id` int(10) unsigned NOT NULL COMMENT 'ID of the Organization Contact',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_group_organization` (`group_id`,`organization_id`),
  KEY `FK_civicrm_group_organization_organization_id` (`organization_id`),
  CONSTRAINT `FK_civicrm_group_organization_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_group_organization_organization_id` FOREIGN KEY (`organization_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_im`
--

DROP TABLE IF EXISTS `civicrm_im`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_im` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique IM ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Location does this email belong to.',
  `name` varchar(64) DEFAULT NULL COMMENT 'IM screen name',
  `provider_id` int(10) unsigned DEFAULT NULL COMMENT 'Which IM Provider does this screen name belong to.',
  `is_primary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the primary IM for this contact and location.',
  `is_billing` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the billing?',
  PRIMARY KEY (`id`),
  KEY `index_location_type` (`location_type_id`),
  KEY `UI_provider_id` (`provider_id`),
  KEY `index_is_primary` (`is_primary`),
  KEY `index_is_billing` (`is_billing`),
  KEY `FK_civicrm_im_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_im_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_im_after_insert after insert ON civicrm_im FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_im_after_update after update ON civicrm_im FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_im_after_delete after delete ON civicrm_im FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_install_canary`
--

DROP TABLE IF EXISTS `civicrm_install_canary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_install_canary` (
  `id` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_job`
--

DROP TABLE IF EXISTS `civicrm_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_job` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Job ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this scheduled job for',
  `run_frequency` varchar(8) DEFAULT 'Daily' COMMENT 'Scheduled job run frequency.',
  `last_run` timestamp NULL DEFAULT NULL COMMENT 'When was this cron entry last run',
  `scheduled_run_date` timestamp NULL DEFAULT NULL COMMENT 'When is this cron entry scheduled to run',
  `name` varchar(255) DEFAULT NULL COMMENT 'Title of the job',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of the job',
  `api_entity` varchar(255) DEFAULT NULL COMMENT 'Entity of the job api call',
  `api_action` varchar(255) DEFAULT NULL COMMENT 'Action of the job api call',
  `parameters` text DEFAULT NULL COMMENT 'List of parameters to the command.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this job active?',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_job_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_job_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_job_log`
--

DROP TABLE IF EXISTS `civicrm_job_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_job_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Job log entry ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this scheduled job for',
  `run_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Log entry date',
  `job_id` int(10) unsigned DEFAULT NULL COMMENT 'Pointer to job id',
  `name` varchar(255) DEFAULT NULL COMMENT 'Title of the job',
  `command` varchar(255) DEFAULT NULL COMMENT 'Full path to file containing job script',
  `description` varchar(255) DEFAULT NULL COMMENT 'Title line of log entry',
  `data` longtext DEFAULT NULL COMMENT 'Potential extended data for specific job run (e.g. tracebacks).',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_job_log_domain_id` (`domain_id`),
  KEY `FK_civicrm_job_log_job_id` (`job_id`),
  CONSTRAINT `FK_civicrm_job_log_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_job_log_job_id` FOREIGN KEY (`job_id`) REFERENCES `civicrm_job` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_line_item`
--

DROP TABLE IF EXISTS `civicrm_line_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_line_item` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Line Item',
  `entity_table` varchar(64) NOT NULL COMMENT 'May contain civicrm_contribution, civicrm_participant or civicrm_membership',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'entry in table',
  `contribution_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contribution',
  `price_field_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_price_field',
  `label` varchar(255) DEFAULT NULL COMMENT 'descriptive label for item - from price_field_value.label',
  `qty` decimal(20,2) NOT NULL COMMENT 'How many items ordered',
  `unit_price` decimal(20,2) NOT NULL COMMENT 'price of each item',
  `line_total` decimal(20,2) NOT NULL COMMENT 'qty * unit_price',
  `participant_count` int(10) unsigned DEFAULT NULL COMMENT 'Participant count for field',
  `price_field_value_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_price_field_value',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type.',
  `non_deductible_amount` decimal(20,2) NOT NULL DEFAULT 0.00 COMMENT 'Portion of total amount which is NOT tax deductible.',
  `tax_amount` decimal(20,2) DEFAULT NULL COMMENT 'tax of each item',
  `membership_num_terms` int(10) unsigned DEFAULT NULL COMMENT 'Number of terms for this membership (only supported in Order->Payment flow). If the field is NULL it means unknown and it will be assumed to be 1 during payment.create if entity_table is civicrm_membership',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_line_item_value` (`entity_id`,`entity_table`,`contribution_id`,`price_field_value_id`,`price_field_id`),
  KEY `FK_civicrm_line_item_contribution_id` (`contribution_id`),
  KEY `FK_civicrm_line_item_price_field_id` (`price_field_id`),
  KEY `FK_civicrm_line_item_price_field_value_id` (`price_field_value_id`),
  KEY `FK_civicrm_line_item_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_line_item_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_line_item_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_line_item_price_field_id` FOREIGN KEY (`price_field_id`) REFERENCES `civicrm_price_field` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_line_item_price_field_value_id` FOREIGN KEY (`price_field_value_id`) REFERENCES `civicrm_price_field_value` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=113 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_loc_block`
--

DROP TABLE IF EXISTS `civicrm_loc_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_loc_block` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique ID',
  `address_id` int(10) unsigned DEFAULT NULL,
  `email_id` int(10) unsigned DEFAULT NULL,
  `phone_id` int(10) unsigned DEFAULT NULL,
  `im_id` int(10) unsigned DEFAULT NULL,
  `address_2_id` int(10) unsigned DEFAULT NULL,
  `email_2_id` int(10) unsigned DEFAULT NULL,
  `phone_2_id` int(10) unsigned DEFAULT NULL,
  `im_2_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_loc_block_address_id` (`address_id`),
  KEY `FK_civicrm_loc_block_email_id` (`email_id`),
  KEY `FK_civicrm_loc_block_phone_id` (`phone_id`),
  KEY `FK_civicrm_loc_block_im_id` (`im_id`),
  KEY `FK_civicrm_loc_block_address_2_id` (`address_2_id`),
  KEY `FK_civicrm_loc_block_email_2_id` (`email_2_id`),
  KEY `FK_civicrm_loc_block_phone_2_id` (`phone_2_id`),
  KEY `FK_civicrm_loc_block_im_2_id` (`im_2_id`),
  CONSTRAINT `FK_civicrm_loc_block_address_2_id` FOREIGN KEY (`address_2_id`) REFERENCES `civicrm_address` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_address_id` FOREIGN KEY (`address_id`) REFERENCES `civicrm_address` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_email_2_id` FOREIGN KEY (`email_2_id`) REFERENCES `civicrm_email` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_email_id` FOREIGN KEY (`email_id`) REFERENCES `civicrm_email` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_im_2_id` FOREIGN KEY (`im_2_id`) REFERENCES `civicrm_im` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_im_id` FOREIGN KEY (`im_id`) REFERENCES `civicrm_im` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_phone_2_id` FOREIGN KEY (`phone_2_id`) REFERENCES `civicrm_phone` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_loc_block_phone_id` FOREIGN KEY (`phone_id`) REFERENCES `civicrm_phone` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_location_type`
--

DROP TABLE IF EXISTS `civicrm_location_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_location_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Location Type ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Location Type Name.',
  `display_name` varchar(64) DEFAULT NULL COMMENT 'Location Type Display Name.',
  `vcard_name` varchar(64) DEFAULT NULL COMMENT 'vCard Location Type Name.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Location Type Description.',
  `is_reserved` tinyint(4) DEFAULT NULL COMMENT 'Is this location type a predefined system location?',
  `is_active` tinyint(4) DEFAULT NULL COMMENT 'Is this property active?',
  `is_default` tinyint(4) DEFAULT NULL COMMENT 'Is this location type the default?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_log`
--

DROP TABLE IF EXISTS `civicrm_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Log ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Name of table where item being referenced is stored.',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the referenced item.',
  `data` text DEFAULT NULL COMMENT 'Updates does to this object if any.',
  `modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID of person under whose credentials this data modification was made.',
  `modified_date` datetime DEFAULT NULL COMMENT 'When was the referenced entity created or modified or deleted.',
  PRIMARY KEY (`id`),
  KEY `index_entity` (`entity_table`,`entity_id`),
  KEY `FK_civicrm_log_modified_id` (`modified_id`),
  CONSTRAINT `FK_civicrm_log_modified_id` FOREIGN KEY (`modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mail_settings`
--

DROP TABLE IF EXISTS `civicrm_mail_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mail_settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'primary key',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this match entry for',
  `name` varchar(255) DEFAULT NULL COMMENT 'name of this group of settings',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'whether this is the default set of settings for this domain',
  `domain` varchar(255) DEFAULT NULL COMMENT 'email address domain (the part after @)',
  `localpart` varchar(255) DEFAULT NULL COMMENT 'optional local part (like civimail+ for addresses like civimail+s.1.2@example.com)',
  `return_path` varchar(255) DEFAULT NULL COMMENT 'contents of the Return-Path header',
  `protocol` varchar(255) DEFAULT NULL COMMENT 'name of the protocol to use for polling (like IMAP, POP3 or Maildir)',
  `server` varchar(255) DEFAULT NULL COMMENT 'server to use when polling',
  `port` int(10) unsigned DEFAULT NULL COMMENT 'port to use when polling',
  `username` varchar(255) DEFAULT NULL COMMENT 'username to use when polling',
  `password` varchar(255) DEFAULT NULL COMMENT 'password to use when polling',
  `is_ssl` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'whether to use SSL or not',
  `source` varchar(255) DEFAULT NULL COMMENT 'folder to poll from when using IMAP, path to poll from when using Maildir, etc.',
  `activity_status` varchar(255) DEFAULT NULL COMMENT 'Name of status to use when creating email to activity.',
  `is_non_case_email_skipped` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Enabling this option will have CiviCRM skip any emails that do not have the Case ID or Case Hash so that the system will only process emails that can be placed on case records. Any emails that are not processed will be moved to the ignored folder.',
  `is_contact_creation_disabled_if_no_match` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mail_settings_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_mail_settings_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing`
--

DROP TABLE IF EXISTS `civicrm_mailing`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'Which site is this mailing for',
  `header_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the header component.',
  `footer_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the footer component.',
  `reply_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the auto-responder component.',
  `unsubscribe_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the unsubscribe component.',
  `resubscribe_id` int(10) unsigned DEFAULT NULL,
  `optout_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the opt-out component.',
  `name` varchar(128) DEFAULT NULL COMMENT 'Mailing Name.',
  `mailing_type` varchar(32) DEFAULT NULL COMMENT 'differentiate between standalone mailings, A/B tests, and A/B final-winner',
  `from_name` varchar(128) DEFAULT NULL COMMENT 'From Header of mailing',
  `from_email` varchar(128) DEFAULT NULL COMMENT 'From Email of mailing',
  `replyto_email` varchar(128) DEFAULT NULL COMMENT 'Reply-To Email of mailing',
  `template_type` varchar(64) NOT NULL DEFAULT 'traditional' COMMENT 'The language/processing system used for email templates.',
  `template_options` longtext DEFAULT NULL COMMENT 'Advanced options used by the email templating system. (JSON encoded)',
  `subject` varchar(128) DEFAULT NULL COMMENT 'Subject of mailing',
  `body_text` longtext DEFAULT NULL COMMENT 'Body of the mailing in text format.',
  `body_html` longtext DEFAULT NULL COMMENT 'Body of the mailing in html format.',
  `url_tracking` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we track URL click-throughs for this mailing?',
  `forward_replies` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we forward replies back to the author?',
  `auto_responder` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we enable the auto-responder?',
  `open_tracking` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we track when recipients open/read this mailing?',
  `is_completed` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Has at least one job associated with this mailing finished?',
  `msg_template_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to the message template.',
  `override_verp` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Overwrite the VERP address in Reply-To',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID who first created this mailing',
  `created_date` timestamp NULL DEFAULT current_timestamp() COMMENT 'Date and time this mailing was created.',
  `modified_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When the mailing (or closely related entity) was created or modified or deleted.',
  `scheduled_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID who scheduled this mailing',
  `scheduled_date` timestamp NULL DEFAULT NULL COMMENT 'Date and time this mailing was scheduled.',
  `approver_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID who approved this mailing',
  `approval_date` timestamp NULL DEFAULT NULL COMMENT 'Date and time this mailing was approved.',
  `approval_status_id` int(10) unsigned DEFAULT NULL COMMENT 'The status of this mailing. Values: none, approved, rejected',
  `approval_note` longtext DEFAULT NULL COMMENT 'Note behind the decision.',
  `is_archived` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this mailing archived?',
  `visibility` varchar(40) DEFAULT 'Public Pages' COMMENT 'In what context(s) is the mailing contents visible (online viewing)',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this mailing has been initiated.',
  `dedupe_email` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Remove duplicate emails?',
  `sms_provider_id` int(10) unsigned DEFAULT NULL,
  `hash` varchar(16) DEFAULT NULL COMMENT 'Key for validating requests related to this mailing.',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'With email_selection_method, determines which email address to use',
  `email_selection_method` varchar(20) DEFAULT 'automatic' COMMENT 'With location_type_id, determine how to choose the email address to use.',
  `language` varchar(5) DEFAULT NULL COMMENT 'Language of the content of the mailing. Useful for tokens.',
  PRIMARY KEY (`id`),
  KEY `index_hash` (`hash`),
  KEY `FK_civicrm_mailing_domain_id` (`domain_id`),
  KEY `FK_civicrm_mailing_header_id` (`header_id`),
  KEY `FK_civicrm_mailing_footer_id` (`footer_id`),
  KEY `FK_civicrm_mailing_reply_id` (`reply_id`),
  KEY `FK_civicrm_mailing_unsubscribe_id` (`unsubscribe_id`),
  KEY `FK_civicrm_mailing_optout_id` (`optout_id`),
  KEY `FK_civicrm_mailing_msg_template_id` (`msg_template_id`),
  KEY `FK_civicrm_mailing_created_id` (`created_id`),
  KEY `FK_civicrm_mailing_scheduled_id` (`scheduled_id`),
  KEY `FK_civicrm_mailing_approver_id` (`approver_id`),
  KEY `FK_civicrm_mailing_campaign_id` (`campaign_id`),
  KEY `FK_civicrm_mailing_sms_provider_id` (`sms_provider_id`),
  KEY `FK_civicrm_mailing_location_type_id` (`location_type_id`),
  CONSTRAINT `FK_civicrm_mailing_approver_id` FOREIGN KEY (`approver_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_footer_id` FOREIGN KEY (`footer_id`) REFERENCES `civicrm_mailing_component` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_header_id` FOREIGN KEY (`header_id`) REFERENCES `civicrm_mailing_component` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_location_type_id` FOREIGN KEY (`location_type_id`) REFERENCES `civicrm_location_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_msg_template_id` FOREIGN KEY (`msg_template_id`) REFERENCES `civicrm_msg_template` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_optout_id` FOREIGN KEY (`optout_id`) REFERENCES `civicrm_mailing_component` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_reply_id` FOREIGN KEY (`reply_id`) REFERENCES `civicrm_mailing_component` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_scheduled_id` FOREIGN KEY (`scheduled_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_sms_provider_id` FOREIGN KEY (`sms_provider_id`) REFERENCES `civicrm_sms_provider` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_unsubscribe_id` FOREIGN KEY (`unsubscribe_id`) REFERENCES `civicrm_mailing_component` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_abtest`
--

DROP TABLE IF EXISTS `civicrm_mailing_abtest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_abtest` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) DEFAULT NULL COMMENT 'Name of the A/B test',
  `status` varchar(32) DEFAULT NULL COMMENT 'Status',
  `mailing_id_a` int(10) unsigned DEFAULT NULL COMMENT 'The first experimental mailing ("A" condition)',
  `mailing_id_b` int(10) unsigned DEFAULT NULL COMMENT 'The second experimental mailing ("B" condition)',
  `mailing_id_c` int(10) unsigned DEFAULT NULL COMMENT 'The final, general mailing (derived from A or B)',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which site is this mailing for',
  `testing_criteria` varchar(32) DEFAULT NULL,
  `winner_criteria` varchar(32) DEFAULT NULL,
  `specific_url` varchar(255) DEFAULT NULL COMMENT 'What specific url to track',
  `declare_winning_time` datetime DEFAULT NULL COMMENT 'In how much time to declare winner',
  `group_percentage` int(10) unsigned DEFAULT NULL,
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `created_date` timestamp NULL DEFAULT current_timestamp() COMMENT 'When was this item created',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_abtest_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_mailing_abtest_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_bounce_pattern`
--

DROP TABLE IF EXISTS `civicrm_mailing_bounce_pattern`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_bounce_pattern` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `bounce_type_id` int(10) unsigned NOT NULL COMMENT 'Type of bounce',
  `pattern` varchar(255) DEFAULT NULL COMMENT 'A regexp to match a message to a bounce type',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_bounce_pattern_bounce_type_id` (`bounce_type_id`),
  CONSTRAINT `FK_civicrm_mailing_bounce_pattern_bounce_type_id` FOREIGN KEY (`bounce_type_id`) REFERENCES `civicrm_mailing_bounce_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=166 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_bounce_type`
--

DROP TABLE IF EXISTS `civicrm_mailing_bounce_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_bounce_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Type of bounce',
  `description` varchar(2048) DEFAULT NULL COMMENT 'A description of this bounce type',
  `hold_threshold` int(10) unsigned NOT NULL COMMENT 'Number of bounces of this type required before the email address is put on bounce hold',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_component`
--

DROP TABLE IF EXISTS `civicrm_mailing_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_component` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT 'The name of this component',
  `component_type` varchar(12) DEFAULT NULL COMMENT 'Type of Component.',
  `subject` varchar(255) DEFAULT NULL,
  `body_html` text DEFAULT NULL COMMENT 'Body of the component in html format.',
  `body_text` text DEFAULT NULL COMMENT 'Body of the component in text format.',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the default component for this component_type?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this property active?',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_bounce`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_bounce`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_bounce` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `bounce_type_id` int(10) unsigned DEFAULT NULL COMMENT 'What type of bounce was it?',
  `bounce_reason` varchar(255) DEFAULT NULL COMMENT 'The reason the email bounced.',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this bounce event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_bounce_event_queue_id` (`event_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_bounce_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_confirm`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_confirm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_confirm` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_subscribe_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_mailing_event_subscribe',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this confirmation event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_confirm_event_subscribe_id` (`event_subscribe_id`),
  CONSTRAINT `FK_civicrm_mailing_event_confirm_event_subscribe_id` FOREIGN KEY (`event_subscribe_id`) REFERENCES `civicrm_mailing_event_subscribe` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_delivered`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_delivered`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_delivered` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this delivery event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_delivered_event_queue_id` (`event_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_delivered_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_forward`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_forward`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_forward` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `dest_queue_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to EventQueue for destination',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this forward event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_forward_event_queue_id` (`event_queue_id`),
  KEY `FK_civicrm_mailing_event_forward_dest_queue_id` (`dest_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_forward_dest_queue_id` FOREIGN KEY (`dest_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_event_forward_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_opened`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_opened`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_opened` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this open event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_opened_event_queue_id` (`event_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_opened_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_queue`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_queue` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_id` int(10) unsigned NOT NULL COMMENT 'Mailing Job',
  `email_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Email',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact',
  `hash` varchar(255) NOT NULL COMMENT 'Security hash',
  `phone_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Phone',
  PRIMARY KEY (`id`),
  KEY `index_hash` (`hash`),
  KEY `FK_civicrm_mailing_event_queue_job_id` (`job_id`),
  KEY `FK_civicrm_mailing_event_queue_email_id` (`email_id`),
  KEY `FK_civicrm_mailing_event_queue_contact_id` (`contact_id`),
  KEY `FK_civicrm_mailing_event_queue_phone_id` (`phone_id`),
  CONSTRAINT `FK_civicrm_mailing_event_queue_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_event_queue_email_id` FOREIGN KEY (`email_id`) REFERENCES `civicrm_email` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_event_queue_job_id` FOREIGN KEY (`job_id`) REFERENCES `civicrm_mailing_job` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_event_queue_phone_id` FOREIGN KEY (`phone_id`) REFERENCES `civicrm_phone` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_reply`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_reply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_reply` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this reply event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_reply_event_queue_id` (`event_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_reply_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_subscribe`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_subscribe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_subscribe` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `group_id` int(10) unsigned NOT NULL COMMENT 'FK to Group',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact',
  `hash` varchar(255) NOT NULL COMMENT 'Security hash',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this subscription event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_subscribe_group_id` (`group_id`),
  KEY `FK_civicrm_mailing_event_subscribe_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_mailing_event_subscribe_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_event_subscribe_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_trackable_url_open`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_trackable_url_open`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_trackable_url_open` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `trackable_url_id` int(10) unsigned NOT NULL COMMENT 'FK to TrackableURL',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this trackable URL open occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_trackable_url_open_event_queue_id` (`event_queue_id`),
  KEY `FK_civicrm_mailing_event_trackable_url_open_trackable_url_id` (`trackable_url_id`),
  CONSTRAINT `FK_civicrm_mailing_event_trackable_url_open_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_event_trackable_url_open_trackable_url_id` FOREIGN KEY (`trackable_url_id`) REFERENCES `civicrm_mailing_trackable_url` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_event_unsubscribe`
--

DROP TABLE IF EXISTS `civicrm_mailing_event_unsubscribe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_event_unsubscribe` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `event_queue_id` int(10) unsigned NOT NULL COMMENT 'FK to EventQueue',
  `org_unsubscribe` tinyint(4) NOT NULL COMMENT 'Unsubscribe at org- or group-level',
  `time_stamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When this delivery event occurred.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_event_unsubscribe_event_queue_id` (`event_queue_id`),
  CONSTRAINT `FK_civicrm_mailing_event_unsubscribe_event_queue_id` FOREIGN KEY (`event_queue_id`) REFERENCES `civicrm_mailing_event_queue` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_group`
--

DROP TABLE IF EXISTS `civicrm_mailing_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mailing_id` int(10) unsigned NOT NULL COMMENT 'The ID of a previous mailing to include/exclude recipients.',
  `group_type` varchar(8) DEFAULT NULL COMMENT 'Are the members of the group included or excluded?.',
  `entity_table` varchar(64) NOT NULL COMMENT 'Name of table where item being referenced is stored.',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the referenced item.',
  `search_id` int(11) DEFAULT NULL COMMENT 'The filtering search. custom search id or -1 for civicrm api search',
  `search_args` text DEFAULT NULL COMMENT 'The arguments to be sent to the search function',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_group_mailing_id` (`mailing_id`),
  CONSTRAINT `FK_civicrm_mailing_group_mailing_id` FOREIGN KEY (`mailing_id`) REFERENCES `civicrm_mailing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_job`
--

DROP TABLE IF EXISTS `civicrm_mailing_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_job` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mailing_id` int(10) unsigned NOT NULL COMMENT 'The ID of the mailing this Job will send.',
  `scheduled_date` timestamp NULL DEFAULT NULL COMMENT 'date on which this job was scheduled.',
  `start_date` timestamp NULL DEFAULT NULL COMMENT 'date on which this job was started.',
  `end_date` timestamp NULL DEFAULT NULL COMMENT 'date on which this job ended.',
  `status` varchar(12) DEFAULT NULL COMMENT 'The state of this job',
  `is_test` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this job for a test mail?',
  `job_type` varchar(255) DEFAULT NULL COMMENT 'Type of mailling job: null | child ',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent job id',
  `job_offset` int(11) DEFAULT 0 COMMENT 'Offset of the child job',
  `job_limit` int(11) DEFAULT 0 COMMENT 'Queue size limit for each child job',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_job_mailing_id` (`mailing_id`),
  KEY `FK_civicrm_mailing_job_parent_id` (`parent_id`),
  CONSTRAINT `FK_civicrm_mailing_job_mailing_id` FOREIGN KEY (`mailing_id`) REFERENCES `civicrm_mailing` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_job_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_mailing_job` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_recipients`
--

DROP TABLE IF EXISTS `civicrm_mailing_recipients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_recipients` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mailing_id` int(10) unsigned NOT NULL COMMENT 'The ID of the mailing this Job will send.',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact',
  `email_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Email',
  `phone_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Phone',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_recipients_mailing_id` (`mailing_id`),
  KEY `FK_civicrm_mailing_recipients_contact_id` (`contact_id`),
  KEY `FK_civicrm_mailing_recipients_email_id` (`email_id`),
  KEY `FK_civicrm_mailing_recipients_phone_id` (`phone_id`),
  CONSTRAINT `FK_civicrm_mailing_recipients_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_recipients_email_id` FOREIGN KEY (`email_id`) REFERENCES `civicrm_email` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_mailing_recipients_mailing_id` FOREIGN KEY (`mailing_id`) REFERENCES `civicrm_mailing` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mailing_recipients_phone_id` FOREIGN KEY (`phone_id`) REFERENCES `civicrm_phone` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_spool`
--

DROP TABLE IF EXISTS `civicrm_mailing_spool`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_spool` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_id` int(10) unsigned NOT NULL COMMENT 'The ID of the Job .',
  `recipient_email` text DEFAULT NULL COMMENT 'The email of the recipients this mail is to be sent.',
  `headers` text DEFAULT NULL COMMENT 'The header information of this mailing .',
  `body` text DEFAULT NULL COMMENT 'The body of this mailing.',
  `added_at` timestamp NULL DEFAULT NULL COMMENT 'date on which this job was added.',
  `removed_at` timestamp NULL DEFAULT NULL COMMENT 'date on which this job was removed.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_spool_job_id` (`job_id`),
  CONSTRAINT `FK_civicrm_mailing_spool_job_id` FOREIGN KEY (`job_id`) REFERENCES `civicrm_mailing_job` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mailing_trackable_url`
--

DROP TABLE IF EXISTS `civicrm_mailing_trackable_url`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mailing_trackable_url` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` text NOT NULL COMMENT 'The URL to be tracked.',
  `mailing_id` int(10) unsigned NOT NULL COMMENT 'FK to the mailing',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mailing_trackable_url_mailing_id` (`mailing_id`),
  CONSTRAINT `FK_civicrm_mailing_trackable_url_mailing_id` FOREIGN KEY (`mailing_id`) REFERENCES `civicrm_mailing` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_managed`
--

DROP TABLE IF EXISTS `civicrm_managed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_managed` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Surrogate Key',
  `module` varchar(127) NOT NULL COMMENT 'Name of the module which declared this object',
  `name` varchar(127) DEFAULT NULL COMMENT 'Symbolic name used by the module to identify the object',
  `entity_type` varchar(64) NOT NULL COMMENT 'API entity type',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the referenced item.',
  `cleanup` varchar(32) DEFAULT NULL COMMENT 'Policy on when to cleanup entity (always, never, unused)',
  `entity_modified_date` timestamp NULL DEFAULT NULL COMMENT 'When the managed entity was changed from its original settings.',
  PRIMARY KEY (`id`),
  KEY `UI_managed_module_name` (`module`,`name`),
  KEY `UI_managed_entity` (`entity_type`,`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mapping`
--

DROP TABLE IF EXISTS `civicrm_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mapping` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Mapping ID',
  `name` varchar(64) NOT NULL COMMENT 'Unique name of Mapping',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of Mapping.',
  `mapping_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Mapping Type',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_mapping_field`
--

DROP TABLE IF EXISTS `civicrm_mapping_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_mapping_field` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Mapping Field ID',
  `mapping_id` int(10) unsigned NOT NULL COMMENT 'Mapping to which this field belongs',
  `name` varchar(255) DEFAULT NULL COMMENT 'Mapping field key',
  `contact_type` varchar(64) DEFAULT NULL COMMENT 'Contact Type in mapping',
  `column_number` int(10) unsigned NOT NULL COMMENT 'Column number for mapping set',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Location type of this mapping, if required',
  `phone_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which type of phone does this number belongs.',
  `im_provider_id` int(10) unsigned DEFAULT NULL COMMENT 'Which type of IM Provider does this name belong.',
  `website_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which type of website does this site belong',
  `relationship_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Relationship type, if required',
  `relationship_direction` varchar(6) DEFAULT NULL,
  `grouping` int(10) unsigned DEFAULT 1 COMMENT 'Used to group mapping_field records into related sets (e.g. for criteria sets in search builder\n      mappings).',
  `operator` varchar(16) DEFAULT NULL COMMENT 'SQL WHERE operator for search-builder mapping fields (search criteria).',
  `value` varchar(255) DEFAULT NULL COMMENT 'SQL WHERE value for search-builder mapping fields.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_mapping_field_mapping_id` (`mapping_id`),
  KEY `FK_civicrm_mapping_field_location_type_id` (`location_type_id`),
  KEY `FK_civicrm_mapping_field_relationship_type_id` (`relationship_type_id`),
  CONSTRAINT `FK_civicrm_mapping_field_location_type_id` FOREIGN KEY (`location_type_id`) REFERENCES `civicrm_location_type` (`id`),
  CONSTRAINT `FK_civicrm_mapping_field_mapping_id` FOREIGN KEY (`mapping_id`) REFERENCES `civicrm_mapping` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_mapping_field_relationship_type_id` FOREIGN KEY (`relationship_type_id`) REFERENCES `civicrm_relationship_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership`
--

DROP TABLE IF EXISTS `civicrm_membership`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Membership ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `membership_type_id` int(10) unsigned NOT NULL COMMENT 'FK to Membership Type',
  `join_date` date DEFAULT NULL COMMENT 'Beginning of initial membership period (member since...).',
  `start_date` date DEFAULT NULL COMMENT 'Beginning of current uninterrupted membership period.',
  `end_date` date DEFAULT NULL COMMENT 'Current membership period expire date.',
  `source` varchar(128) DEFAULT NULL,
  `status_id` int(10) unsigned NOT NULL COMMENT 'FK to Membership Status',
  `is_override` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Admin users may set a manual status which overrides the calculated status. When this flag is true, automated status update scripts should NOT modify status for the record.',
  `status_override_end_date` date DEFAULT NULL COMMENT 'Then end date of membership status override if ''Override until selected date'' override type is selected.',
  `owner_membership_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional FK to Parent Membership.',
  `max_related` int(11) DEFAULT NULL COMMENT 'Maximum number of related memberships (membership_type override).',
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `is_pay_later` tinyint(4) NOT NULL DEFAULT 0,
  `contribution_recur_id` int(10) unsigned DEFAULT NULL COMMENT 'Conditional foreign key to civicrm_contribution_recur id. Each membership in connection with a recurring contribution carries a foreign key to the recurring contribution record. This assumes we can track these processor initiated events.',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this membership is attached.',
  PRIMARY KEY (`id`),
  KEY `index_owner_membership_id` (`owner_membership_id`),
  KEY `FK_civicrm_membership_contact_id` (`contact_id`),
  KEY `FK_civicrm_membership_membership_type_id` (`membership_type_id`),
  KEY `FK_civicrm_membership_status_id` (`status_id`),
  KEY `FK_civicrm_membership_contribution_recur_id` (`contribution_recur_id`),
  KEY `FK_civicrm_membership_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_membership_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_membership_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_membership_contribution_recur_id` FOREIGN KEY (`contribution_recur_id`) REFERENCES `civicrm_contribution_recur` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_membership_membership_type_id` FOREIGN KEY (`membership_type_id`) REFERENCES `civicrm_membership_type` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_membership_owner_membership_id` FOREIGN KEY (`owner_membership_id`) REFERENCES `civicrm_membership` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_membership_status_id` FOREIGN KEY (`status_id`) REFERENCES `civicrm_membership_status` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership_block`
--

DROP TABLE IF EXISTS `civicrm_membership_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership_block` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Membership ID',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'Name for Membership Status',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_contribution_page.id',
  `membership_types` varchar(1024) DEFAULT NULL COMMENT 'Membership types to be exposed by this block',
  `membership_type_default` int(10) unsigned DEFAULT NULL COMMENT 'Optional foreign key to membership_type',
  `display_min_fee` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Display minimum membership fee',
  `is_separate_payment` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Should membership transactions be processed separately',
  `new_title` varchar(255) DEFAULT NULL COMMENT 'Title to display at top of block',
  `new_text` text DEFAULT NULL COMMENT 'Text to display below title',
  `renewal_title` varchar(255) DEFAULT NULL COMMENT 'Title for renewal',
  `renewal_text` text DEFAULT NULL COMMENT 'Text to display for member renewal',
  `is_required` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is membership sign up optional',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this membership_block enabled',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_membership_block_entity_id` (`entity_id`),
  KEY `FK_civicrm_membership_block_membership_type_default` (`membership_type_default`),
  CONSTRAINT `FK_civicrm_membership_block_entity_id` FOREIGN KEY (`entity_id`) REFERENCES `civicrm_contribution_page` (`id`),
  CONSTRAINT `FK_civicrm_membership_block_membership_type_default` FOREIGN KEY (`membership_type_default`) REFERENCES `civicrm_membership_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership_log`
--

DROP TABLE IF EXISTS `civicrm_membership_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `membership_id` int(10) unsigned NOT NULL COMMENT 'FK to Membership table',
  `status_id` int(10) unsigned NOT NULL COMMENT 'New status assigned to membership by this action. FK to Membership Status',
  `start_date` date DEFAULT NULL COMMENT 'New membership period start date',
  `end_date` date DEFAULT NULL COMMENT 'New membership period expiration date.',
  `modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID of person under whose credentials this data modification was made.',
  `modified_date` date DEFAULT NULL COMMENT 'Date this membership modification action was logged.',
  `membership_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Membership Type.',
  `max_related` int(11) DEFAULT NULL COMMENT 'Maximum number of related memberships.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_membership_log_membership_id` (`membership_id`),
  KEY `FK_civicrm_membership_log_status_id` (`status_id`),
  KEY `FK_civicrm_membership_log_modified_id` (`modified_id`),
  KEY `FK_civicrm_membership_log_membership_type_id` (`membership_type_id`),
  CONSTRAINT `FK_civicrm_membership_log_membership_id` FOREIGN KEY (`membership_id`) REFERENCES `civicrm_membership` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_membership_log_membership_type_id` FOREIGN KEY (`membership_type_id`) REFERENCES `civicrm_membership_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_membership_log_modified_id` FOREIGN KEY (`modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_membership_log_status_id` FOREIGN KEY (`status_id`) REFERENCES `civicrm_membership_status` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership_payment`
--

DROP TABLE IF EXISTS `civicrm_membership_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership_payment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `membership_id` int(10) unsigned NOT NULL COMMENT 'FK to Membership table',
  `contribution_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contribution table.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contribution_membership` (`contribution_id`,`membership_id`),
  KEY `FK_civicrm_membership_payment_membership_id` (`membership_id`),
  CONSTRAINT `FK_civicrm_membership_payment_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_membership_payment_membership_id` FOREIGN KEY (`membership_id`) REFERENCES `civicrm_membership` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership_status`
--

DROP TABLE IF EXISTS `civicrm_membership_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership_status` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Membership ID',
  `name` varchar(128) NOT NULL COMMENT 'Name for Membership Status',
  `label` varchar(128) DEFAULT NULL COMMENT 'Label for Membership Status',
  `start_event` varchar(12) DEFAULT NULL COMMENT 'Event when this status starts.',
  `start_event_adjust_unit` varchar(8) DEFAULT NULL COMMENT 'Unit used for adjusting from start_event.',
  `start_event_adjust_interval` int(11) DEFAULT NULL COMMENT 'Status range begins this many units from start_event.',
  `end_event` varchar(12) DEFAULT NULL COMMENT 'Event after which this status ends.',
  `end_event_adjust_unit` varchar(8) DEFAULT NULL COMMENT 'Unit used for adjusting from the ending event.',
  `end_event_adjust_interval` int(11) DEFAULT NULL COMMENT 'Status range ends this many units from end_event.',
  `is_current_member` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Does this status aggregate to current members (e.g. New, Renewed, Grace might all be TRUE... while Unrenewed, Lapsed, Inactive would be FALSE).',
  `is_admin` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this status for admin/manual assignment only.',
  `weight` int(11) DEFAULT NULL,
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Assign this status to a membership record if no other status match is found.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this membership_status enabled.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this membership_status reserved.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_membership_type`
--

DROP TABLE IF EXISTS `civicrm_membership_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_membership_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Membership ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this match entry for',
  `name` varchar(128) NOT NULL COMMENT 'Name of Membership Type',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of Membership Type',
  `member_of_contact_id` int(10) unsigned NOT NULL COMMENT 'Owner organization for this membership type. FK to Contact ID',
  `financial_type_id` int(10) unsigned NOT NULL COMMENT 'If membership is paid by a contribution - what financial type should be used. FK to civicrm_financial_type.id',
  `minimum_fee` decimal(18,9) DEFAULT 0.000000000 COMMENT 'Minimum fee for this membership (0 for free/complimentary memberships).',
  `duration_unit` varchar(8) NOT NULL COMMENT 'Unit in which membership period is expressed.',
  `duration_interval` int(11) DEFAULT NULL COMMENT 'Number of duration units in membership period (e.g. 1 year, 12 months).',
  `period_type` varchar(8) NOT NULL COMMENT 'Rolling membership period starts on signup date. Fixed membership periods start on fixed_period_start_day.',
  `fixed_period_start_day` int(11) DEFAULT NULL COMMENT 'For fixed period memberships, month and day (mmdd) on which subscription/membership will start. Period start is back-dated unless after rollover day.',
  `fixed_period_rollover_day` int(11) DEFAULT NULL COMMENT 'For fixed period memberships, signups after this day (mmdd) rollover to next period.',
  `relationship_type_id` varchar(64) DEFAULT NULL COMMENT 'FK to Relationship Type ID',
  `relationship_direction` varchar(128) DEFAULT NULL,
  `max_related` int(11) DEFAULT NULL COMMENT 'Maximum number of related memberships.',
  `visibility` varchar(64) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `receipt_text_signup` varchar(255) DEFAULT NULL COMMENT 'Receipt Text for membership signup',
  `receipt_text_renewal` varchar(255) DEFAULT NULL COMMENT 'Receipt Text for membership renewal',
  `auto_renew` tinyint(4) DEFAULT 0 COMMENT '0 = No auto-renew option; 1 = Give option, but not required; 2 = Auto-renew required;',
  `is_active` tinyint(4) DEFAULT 1 COMMENT 'Is this membership_type enabled',
  PRIMARY KEY (`id`),
  KEY `index_relationship_type_id` (`relationship_type_id`),
  KEY `FK_civicrm_membership_type_domain_id` (`domain_id`),
  KEY `FK_civicrm_membership_type_member_of_contact_id` (`member_of_contact_id`),
  KEY `FK_civicrm_membership_type_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_membership_type_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_membership_type_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`),
  CONSTRAINT `FK_civicrm_membership_type_member_of_contact_id` FOREIGN KEY (`member_of_contact_id`) REFERENCES `civicrm_contact` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_menu`
--

DROP TABLE IF EXISTS `civicrm_menu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_menu` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this menu item for',
  `path` varchar(255) DEFAULT NULL COMMENT 'Path Name',
  `path_arguments` text DEFAULT NULL COMMENT 'Arguments to pass to the url',
  `title` varchar(255) DEFAULT NULL,
  `access_callback` varchar(255) DEFAULT NULL COMMENT 'Function to call to check access permissions',
  `access_arguments` text DEFAULT NULL COMMENT 'Arguments to pass to access callback',
  `page_callback` varchar(255) DEFAULT NULL COMMENT 'function to call for this url',
  `page_arguments` text DEFAULT NULL COMMENT 'Arguments to pass to page callback',
  `breadcrumb` text DEFAULT NULL COMMENT 'Breadcrumb for the path.',
  `return_url` varchar(255) DEFAULT NULL COMMENT 'Url where a page should redirected to, if next url not known.',
  `return_url_args` varchar(255) DEFAULT NULL COMMENT 'Arguments to pass to return_url',
  `component_id` int(10) unsigned DEFAULT NULL COMMENT 'Component that this menu item belongs to',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this menu item active?',
  `is_public` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this menu accessible to the public?',
  `is_exposed` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this menu exposed to the navigation system?',
  `is_ssl` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Should this menu be exposed via SSL if enabled?',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Ordering of the menu items in various blocks.',
  `type` int(11) NOT NULL DEFAULT 1 COMMENT 'Drupal menu type.',
  `page_type` int(11) NOT NULL DEFAULT 1 COMMENT 'CiviCRM menu type.',
  `skipBreadcrumb` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'skip this url being exposed to breadcrumb',
  `module_data` text DEFAULT NULL COMMENT 'All other menu metadata not stored in other fields',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_path_domain_id` (`path`,`domain_id`),
  KEY `FK_civicrm_menu_domain_id` (`domain_id`),
  KEY `FK_civicrm_menu_component_id` (`component_id`),
  CONSTRAINT `FK_civicrm_menu_component_id` FOREIGN KEY (`component_id`) REFERENCES `civicrm_component` (`id`),
  CONSTRAINT `FK_civicrm_menu_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=464 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_msg_template`
--

DROP TABLE IF EXISTS `civicrm_msg_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_msg_template` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Message Template ID',
  `msg_title` varchar(255) DEFAULT NULL COMMENT 'Descriptive title of message',
  `msg_subject` text DEFAULT NULL COMMENT 'Subject for email message.',
  `msg_text` longtext DEFAULT NULL COMMENT 'Text formatted message',
  `msg_html` longtext DEFAULT NULL COMMENT 'HTML formatted message',
  `is_active` tinyint(4) NOT NULL DEFAULT 1,
  `workflow_id` int(10) unsigned DEFAULT NULL COMMENT 'a pseudo-FK to civicrm_option_value',
  `workflow_name` varchar(255) DEFAULT NULL,
  `is_default` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'is this the default message template for the workflow referenced by workflow_id?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'is this the reserved message template which we ship for the workflow referenced by workflow_id?',
  `is_sms` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this message template used for sms?',
  `pdf_format_id` int(10) unsigned DEFAULT NULL COMMENT 'a pseudo-FK to civicrm_option_value containing PDF Page Format.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=68 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_navigation`
--

DROP TABLE IF EXISTS `civicrm_navigation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_navigation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this navigation item for',
  `label` varchar(255) DEFAULT NULL COMMENT 'Navigation Title',
  `name` varchar(255) DEFAULT NULL COMMENT 'Internal Name',
  `url` varchar(255) DEFAULT NULL COMMENT 'url in case of custom navigation link',
  `icon` varchar(255) DEFAULT NULL COMMENT 'CSS class name for an icon',
  `permission` varchar(255) DEFAULT NULL COMMENT 'Permission(s) needed to access menu item',
  `permission_operator` varchar(3) DEFAULT NULL COMMENT 'Operator to use if item has more than one permission',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent navigation item, used for grouping',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this navigation item active?',
  `has_separator` tinyint(4) DEFAULT 0 COMMENT 'Place a separator either before or after this menu item.',
  `weight` int(11) NOT NULL DEFAULT 0 COMMENT 'Ordering of the navigation items in various blocks.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_navigation_domain_id` (`domain_id`),
  KEY `FK_civicrm_navigation_parent_id` (`parent_id`),
  CONSTRAINT `FK_civicrm_navigation_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_navigation_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_navigation` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=253 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_note`
--

DROP TABLE IF EXISTS `civicrm_note`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_note` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Note ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Name of table where item being referenced is stored.',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the referenced item.',
  `note` text DEFAULT NULL COMMENT 'Note and/or Comment.',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID creator',
  `note_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date attached to the note',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When the note was created.',
  `modified_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When was this note last modified/edited',
  `subject` varchar(255) DEFAULT NULL COMMENT 'subject of note description',
  `privacy` varchar(255) DEFAULT NULL COMMENT 'Foreign Key to Note Privacy Level (which is an option value pair and hence an implicit FK)',
  PRIMARY KEY (`id`),
  KEY `index_entity` (`entity_table`,`entity_id`),
  KEY `FK_civicrm_note_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_note_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_openid`
--

DROP TABLE IF EXISTS `civicrm_openid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_openid` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique OpenID ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Location does this email belong to.',
  `openid` varchar(255) DEFAULT NULL COMMENT 'the OpenID (or OpenID-style http://username.domain/) unique identifier for this contact mainly used for logging in to CiviCRM',
  `allowed_to_login` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Whether or not this user is allowed to login',
  `is_primary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the primary email for this contact and location.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_openid` (`openid`),
  KEY `index_location_type` (`location_type_id`),
  KEY `FK_civicrm_openid_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_openid_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_option_group`
--

DROP TABLE IF EXISTS `civicrm_option_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_option_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Option Group ID',
  `name` varchar(64) NOT NULL COMMENT 'Option group name. Used as selection key by class properties which lookup options in civicrm_option_value.',
  `title` varchar(255) DEFAULT NULL COMMENT 'Option Group title.',
  `description` text DEFAULT NULL COMMENT 'Option group description.',
  `data_type` varchar(128) DEFAULT NULL COMMENT 'Type of data stored by this option group.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this a predefined system option group (i.e. it can not be deleted)?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this option group active?',
  `is_locked` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A lock to remove the ability to add new options via the UI.',
  `option_value_fields` varchar(128) DEFAULT 'name,label,description' COMMENT 'Which optional columns from the option_value table are in use by this group.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_option_value`
--

DROP TABLE IF EXISTS `civicrm_option_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_option_value` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Option ID',
  `option_group_id` int(10) unsigned NOT NULL COMMENT 'Group which this option belongs to.',
  `label` varchar(512) NOT NULL COMMENT 'Option string as displayed to users - e.g. the label in an HTML OPTION tag.',
  `value` varchar(512) NOT NULL COMMENT 'The actual value stored (as a foreign key) in the data record. Functions which need lookup option_value.title should use civicrm_option_value.option_group_id plus civicrm_option_value.value as the key.',
  `name` varchar(255) DEFAULT NULL COMMENT 'Stores a fixed (non-translated) name for this option value. Lookup functions should use the name as the key for the option value row.',
  `grouping` varchar(255) DEFAULT NULL COMMENT 'Use to sort and/or set display properties for sub-set(s) of options within an option group. EXAMPLE: Use for college_interest field, to differentiate partners from non-partners.',
  `filter` int(10) unsigned DEFAULT 0 COMMENT 'Bitwise logic can be used to create subsets of options within an option_group for different uses.',
  `is_default` tinyint(4) DEFAULT 0 COMMENT 'Is this the default option for the group?',
  `weight` int(10) unsigned NOT NULL COMMENT 'Controls display sort order.',
  `description` text DEFAULT NULL COMMENT 'Optional description.',
  `is_optgroup` tinyint(4) DEFAULT 0 COMMENT 'Is this row simply a display header? Expected usage is to render these as OPTGROUP tags within a SELECT field list of options?',
  `is_reserved` tinyint(4) DEFAULT 0 COMMENT 'Is this a predefined system object?',
  `is_active` tinyint(4) DEFAULT 1 COMMENT 'Is this option active?',
  `component_id` int(10) unsigned DEFAULT NULL COMMENT 'Component that this option value belongs/caters to.',
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Domain is this option value for',
  `visibility_id` int(10) unsigned DEFAULT NULL,
  `icon` varchar(255) DEFAULT NULL COMMENT 'crm-i icon class',
  `color` varchar(255) DEFAULT NULL COMMENT 'Hex color value e.g. #ffffff',
  PRIMARY KEY (`id`),
  KEY `index_option_group_id_value` (`value`(128),`option_group_id`),
  KEY `index_option_group_id_name` (`name`(128),`option_group_id`),
  KEY `FK_civicrm_option_value_option_group_id` (`option_group_id`),
  KEY `FK_civicrm_option_value_component_id` (`component_id`),
  KEY `FK_civicrm_option_value_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_option_value_component_id` FOREIGN KEY (`component_id`) REFERENCES `civicrm_component` (`id`),
  CONSTRAINT `FK_civicrm_option_value_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_option_value_option_group_id` FOREIGN KEY (`option_group_id`) REFERENCES `civicrm_option_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=893 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_participant`
--

DROP TABLE IF EXISTS `civicrm_participant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_participant` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Participant ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `event_id` int(10) unsigned NOT NULL COMMENT 'FK to Event ID',
  `status_id` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Participant status ID. FK to civicrm_participant_status_type. Default of 1 should map to status = Registered.',
  `role_id` varchar(128) DEFAULT NULL COMMENT 'Participant role ID. Implicit FK to civicrm_option_value where option_group = participant_role.',
  `register_date` datetime DEFAULT NULL COMMENT 'When did contact register for event?',
  `source` varchar(128) DEFAULT NULL COMMENT 'Source of this event registration.',
  `fee_level` text DEFAULT NULL COMMENT 'Populate with the label (text) associated with a fee level for paid events with multiple levels. Note that\n      we store the label value and not the key',
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `is_pay_later` tinyint(4) NOT NULL DEFAULT 0,
  `fee_amount` decimal(20,2) DEFAULT NULL COMMENT 'actual processor fee if known - may be 0.',
  `registered_by_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Participant ID',
  `discount_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Discount ID',
  `fee_currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value derived from config setting.',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this participant has been registered.',
  `discount_amount` int(10) unsigned DEFAULT NULL COMMENT 'Discount Amount',
  `cart_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_event_carts',
  `must_wait` int(11) DEFAULT NULL COMMENT 'On Waiting List',
  `transferred_to_contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'Contact responsible for registering this participant',
  PRIMARY KEY (`id`),
  KEY `index_status_id` (`status_id`),
  KEY `index_role_id` (`role_id`),
  KEY `FK_civicrm_participant_contact_id` (`contact_id`),
  KEY `FK_civicrm_participant_event_id` (`event_id`),
  KEY `FK_civicrm_participant_registered_by_id` (`registered_by_id`),
  KEY `FK_civicrm_participant_discount_id` (`discount_id`),
  KEY `FK_civicrm_participant_campaign_id` (`campaign_id`),
  KEY `FK_civicrm_participant_cart_id` (`cart_id`),
  KEY `FK_civicrm_participant_transferred_to_contact_id` (`transferred_to_contact_id`),
  KEY `FK_civicrm_participant_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_participant_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_participant_cart_id` FOREIGN KEY (`cart_id`) REFERENCES `civicrm_event_carts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_participant_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_participant_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_participant_discount_id` FOREIGN KEY (`discount_id`) REFERENCES `civicrm_discount` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_participant_event_id` FOREIGN KEY (`event_id`) REFERENCES `civicrm_event` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_participant_registered_by_id` FOREIGN KEY (`registered_by_id`) REFERENCES `civicrm_participant` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_participant_status_id` FOREIGN KEY (`status_id`) REFERENCES `civicrm_participant_status_type` (`id`),
  CONSTRAINT `FK_civicrm_participant_transferred_to_contact_id` FOREIGN KEY (`transferred_to_contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_participant_payment`
--

DROP TABLE IF EXISTS `civicrm_participant_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_participant_payment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Participant Payment ID',
  `participant_id` int(10) unsigned NOT NULL COMMENT 'Participant ID (FK)',
  `contribution_id` int(10) unsigned NOT NULL COMMENT 'FK to contribution table.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_contribution_participant` (`contribution_id`,`participant_id`),
  KEY `FK_civicrm_participant_payment_participant_id` (`participant_id`),
  CONSTRAINT `FK_civicrm_participant_payment_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_participant_payment_participant_id` FOREIGN KEY (`participant_id`) REFERENCES `civicrm_participant` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_participant_status_type`
--

DROP TABLE IF EXISTS `civicrm_participant_status_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_participant_status_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'unique participant status type id',
  `name` varchar(64) DEFAULT NULL COMMENT 'non-localized name of the status type',
  `label` varchar(255) DEFAULT NULL COMMENT 'localized label for display of this status type',
  `class` varchar(8) DEFAULT NULL COMMENT 'the general group of status type this one belongs to',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'whether this is a status type required by the system',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'whether this status type is active',
  `is_counted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'whether this status type is counted against event size limit',
  `weight` int(10) unsigned NOT NULL COMMENT 'controls sort order',
  `visibility_id` int(10) unsigned DEFAULT NULL COMMENT 'whether the status type is visible to the public, an implicit foreign key to option_value.value related to the `visibility` option_group',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_payment_processor`
--

DROP TABLE IF EXISTS `civicrm_payment_processor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_payment_processor` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Payment Processor ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this match entry for',
  `name` varchar(64) NOT NULL COMMENT 'Payment Processor Name.',
  `title` varchar(255) NOT NULL COMMENT 'Name of processor when shown to CiviCRM administrators.',
  `frontend_title` varchar(255) NOT NULL COMMENT 'Name of processor when shown to users making a payment.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Additional processor information shown to administrators.',
  `payment_processor_type_id` int(10) unsigned NOT NULL,
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this processor active?',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this processor the default?',
  `is_test` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this processor for a test site?',
  `user_name` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `signature` text DEFAULT NULL,
  `url_site` varchar(255) DEFAULT NULL,
  `url_api` varchar(255) DEFAULT NULL,
  `url_recur` varchar(255) DEFAULT NULL,
  `url_button` varchar(255) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `class_name` varchar(255) DEFAULT NULL,
  `billing_mode` int(10) unsigned NOT NULL COMMENT 'Billing Mode (deprecated)',
  `is_recur` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Can process recurring contributions',
  `payment_type` int(10) unsigned DEFAULT 1 COMMENT 'Payment Type: Credit or Debit (deprecated)',
  `payment_instrument_id` int(10) unsigned DEFAULT 1 COMMENT 'Payment Instrument ID',
  `accepted_credit_cards` text DEFAULT NULL COMMENT 'array of accepted credit card types',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name_test_domain_id` (`name`,`is_test`,`domain_id`),
  KEY `FK_civicrm_payment_processor_domain_id` (`domain_id`),
  KEY `FK_civicrm_payment_processor_payment_processor_type_id` (`payment_processor_type_id`),
  CONSTRAINT `FK_civicrm_payment_processor_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_payment_processor_payment_processor_type_id` FOREIGN KEY (`payment_processor_type_id`) REFERENCES `civicrm_payment_processor_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_payment_processor_type`
--

DROP TABLE IF EXISTS `civicrm_payment_processor_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_payment_processor_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Payment Processor Type ID',
  `name` varchar(64) NOT NULL COMMENT 'Payment Processor Type Name.',
  `title` varchar(127) NOT NULL COMMENT 'Payment Processor Type Title.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Payment Processor Description.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this processor active?',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this processor the default?',
  `user_name_label` varchar(255) DEFAULT NULL,
  `password_label` varchar(255) DEFAULT NULL,
  `signature_label` varchar(255) DEFAULT NULL,
  `subject_label` varchar(255) DEFAULT NULL,
  `class_name` varchar(255) NOT NULL,
  `url_site_default` varchar(255) DEFAULT NULL,
  `url_api_default` varchar(255) DEFAULT NULL,
  `url_recur_default` varchar(255) DEFAULT NULL,
  `url_button_default` varchar(255) DEFAULT NULL,
  `url_site_test_default` varchar(255) DEFAULT NULL,
  `url_api_test_default` varchar(255) DEFAULT NULL,
  `url_recur_test_default` varchar(255) DEFAULT NULL,
  `url_button_test_default` varchar(255) DEFAULT NULL,
  `billing_mode` int(10) unsigned NOT NULL COMMENT 'Billing Mode (deprecated)',
  `is_recur` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Can process recurring contributions',
  `payment_type` int(10) unsigned DEFAULT 1 COMMENT 'Payment Type: Credit or Debit (deprecated)',
  `payment_instrument_id` int(10) unsigned DEFAULT 1 COMMENT 'Payment Instrument ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_payment_token`
--

DROP TABLE IF EXISTS `civicrm_payment_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_payment_token` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Payment Token ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID for the owner of the token',
  `payment_processor_id` int(10) unsigned NOT NULL,
  `token` varchar(255) NOT NULL COMMENT 'Externally provided token string',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date created',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'Contact ID of token creator',
  `expiry_date` datetime DEFAULT NULL COMMENT 'Date this token expires',
  `email` varchar(255) DEFAULT NULL COMMENT 'Email at the time of token creation. Useful for fraud forensics',
  `billing_first_name` varchar(255) DEFAULT NULL COMMENT 'Billing first name at the time of token creation. Useful for fraud forensics',
  `billing_middle_name` varchar(255) DEFAULT NULL COMMENT 'Billing middle name at the time of token creation. Useful for fraud forensics',
  `billing_last_name` varchar(255) DEFAULT NULL COMMENT 'Billing last name at the time of token creation. Useful for fraud forensics',
  `masked_account_number` varchar(255) DEFAULT NULL COMMENT 'Holds the part of the card number or account details that may be retained or displayed',
  `ip_address` varchar(255) DEFAULT NULL COMMENT 'IP used when creating the token. Useful for fraud forensics',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_payment_token_contact_id` (`contact_id`),
  KEY `FK_civicrm_payment_token_payment_processor_id` (`payment_processor_id`),
  KEY `FK_civicrm_payment_token_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_payment_token_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_payment_token_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_payment_token_payment_processor_id` FOREIGN KEY (`payment_processor_id`) REFERENCES `civicrm_payment_processor` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_pcp`
--

DROP TABLE IF EXISTS `civicrm_pcp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_pcp` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Personal Campaign Page ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'FK to Contact ID',
  `status_id` int(10) unsigned NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `intro_text` text DEFAULT NULL,
  `page_text` text DEFAULT NULL,
  `donate_link_text` varchar(255) DEFAULT NULL,
  `page_id` int(10) unsigned NOT NULL COMMENT 'The Contribution or Event Page which triggered this pcp',
  `page_type` varchar(64) DEFAULT 'contribute' COMMENT 'The type of PCP this is: contribute or event',
  `pcp_block_id` int(10) unsigned NOT NULL COMMENT 'The pcp block that this pcp page was created from',
  `is_thermometer` int(10) unsigned DEFAULT 0,
  `is_honor_roll` int(10) unsigned DEFAULT 0,
  `goal_amount` decimal(20,2) DEFAULT NULL COMMENT 'Goal amount of this Personal Campaign Page.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is Personal Campaign Page enabled/active?',
  `is_notify` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Notify owner via email when someone donates to page?',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_pcp_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_pcp_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_pcp_block`
--

DROP TABLE IF EXISTS `civicrm_pcp_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_pcp_block` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'PCP block ID',
  `entity_table` varchar(64) DEFAULT NULL,
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_contribution_page.id OR civicrm_event.id',
  `target_entity_type` varchar(255) NOT NULL DEFAULT 'contribute' COMMENT 'The type of entity that this pcp targets',
  `target_entity_id` int(10) unsigned NOT NULL COMMENT 'The entity that this pcp targets',
  `supporter_profile_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_uf_group.id. Does Personal Campaign Page require manual activation by administrator? (is inactive by default after setup)?',
  `owner_notify_id` int(10) unsigned DEFAULT 0 COMMENT 'FK to civicrm_option_group with name = PCP owner notifications',
  `is_approval_needed` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Does Personal Campaign Page require manual activation by administrator? (is inactive by default after setup)?',
  `is_tellfriend_enabled` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Does Personal Campaign Page allow using tell a friend?',
  `tellfriend_limit` int(10) unsigned DEFAULT NULL COMMENT 'Maximum recipient fields allowed in tell a friend',
  `link_text` varchar(255) DEFAULT NULL COMMENT 'Link text for PCP.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is Personal Campaign Page Block enabled/active?',
  `notify_email` varchar(255) DEFAULT NULL COMMENT 'If set, notification is automatically emailed to this email-address on create/update Personal Campaign Page',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_pcp_block_supporter_profile_id` (`supporter_profile_id`),
  CONSTRAINT `FK_civicrm_pcp_block_supporter_profile_id` FOREIGN KEY (`supporter_profile_id`) REFERENCES `civicrm_uf_group` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_phone`
--

DROP TABLE IF EXISTS `civicrm_phone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_phone` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Phone ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Location does this phone belong to.',
  `is_primary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the primary phone for this contact and location.',
  `is_billing` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this the billing?',
  `mobile_provider_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Mobile Provider does this phone belong to.',
  `phone` varchar(32) DEFAULT NULL COMMENT 'Complete phone number.',
  `phone_ext` varchar(16) DEFAULT NULL COMMENT 'Optional extension for a phone number.',
  `phone_numeric` varchar(32) DEFAULT NULL COMMENT 'Phone number stripped of all whitespace, letters, and punctuation.',
  `phone_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which type of phone does this number belongs.',
  PRIMARY KEY (`id`),
  KEY `index_location_type` (`location_type_id`),
  KEY `index_is_primary` (`is_primary`),
  KEY `index_is_billing` (`is_billing`),
  KEY `UI_mobile_provider_id` (`mobile_provider_id`),
  KEY `index_phone_numeric` (`phone_numeric`),
  KEY `FK_civicrm_phone_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_phone_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=162 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_phone_before_insert before insert ON civicrm_phone FOR EACH ROW BEGIN  
SET NEW.phone_numeric = civicrm_strip_non_numeric(NEW.phone);
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_phone_after_insert after insert ON civicrm_phone FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_phone_before_update before update ON civicrm_phone FOR EACH ROW BEGIN  
SET NEW.phone_numeric = civicrm_strip_non_numeric(NEW.phone);
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_phone_after_update after update ON civicrm_phone FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_phone_after_delete after delete ON civicrm_phone FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_pledge`
--

DROP TABLE IF EXISTS `civicrm_pledge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_pledge` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Pledge ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to civicrm_contact.id .',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type',
  `contribution_page_id` int(10) unsigned DEFAULT NULL COMMENT 'The Contribution Page which triggered this contribution',
  `amount` decimal(20,2) NOT NULL COMMENT 'Total pledged amount.',
  `original_installment_amount` decimal(20,2) NOT NULL COMMENT 'Original amount for each of the installments.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `frequency_unit` varchar(8) NOT NULL DEFAULT 'month' COMMENT 'Time units for recurrence of pledge payments.',
  `frequency_interval` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Number of time units for recurrence of pledge payments.',
  `frequency_day` int(10) unsigned NOT NULL DEFAULT 3 COMMENT 'Day in the period when the pledge payment is due e.g. 1st of month, 15th etc. Use this to set the scheduled dates for pledge payments.',
  `installments` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Total number of payments to be made.',
  `start_date` datetime NOT NULL COMMENT 'The date the first scheduled pledge occurs.',
  `create_date` datetime NOT NULL COMMENT 'When this pledge record was created.',
  `acknowledge_date` datetime DEFAULT NULL COMMENT 'When a pledge acknowledgement message was sent to the contributor.',
  `modified_date` datetime DEFAULT NULL COMMENT 'Last updated date for this pledge record.',
  `cancel_date` datetime DEFAULT NULL COMMENT 'Date this pledge was cancelled by contributor.',
  `end_date` datetime DEFAULT NULL COMMENT 'Date this pledge finished successfully (total pledge payments equal to or greater than pledged amount).',
  `max_reminders` int(10) unsigned DEFAULT 1 COMMENT 'The maximum number of payment reminders to send for any given payment.',
  `initial_reminder_day` int(10) unsigned DEFAULT 5 COMMENT 'Send initial reminder this many days prior to the payment due date.',
  `additional_reminder_day` int(10) unsigned DEFAULT 5 COMMENT 'Send additional reminder this many days after last one sent, up to maximum number of reminders.',
  `status_id` int(10) unsigned NOT NULL COMMENT 'Implicit foreign key to civicrm_option_values in the pledge_status option group.',
  `is_test` tinyint(4) NOT NULL DEFAULT 0,
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'The campaign for which this pledge has been initiated.',
  PRIMARY KEY (`id`),
  KEY `index_status` (`status_id`),
  KEY `FK_civicrm_pledge_contact_id` (`contact_id`),
  KEY `FK_civicrm_pledge_financial_type_id` (`financial_type_id`),
  KEY `FK_civicrm_pledge_contribution_page_id` (`contribution_page_id`),
  KEY `FK_civicrm_pledge_campaign_id` (`campaign_id`),
  CONSTRAINT `FK_civicrm_pledge_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_pledge_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_pledge_contribution_page_id` FOREIGN KEY (`contribution_page_id`) REFERENCES `civicrm_contribution_page` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_pledge_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_pledge_block`
--

DROP TABLE IF EXISTS `civicrm_pledge_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_pledge_block` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Pledge ID',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to pledge, e.g. civicrm_contact',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `pledge_frequency_unit` varchar(128) DEFAULT NULL COMMENT 'Delimited list of supported frequency units',
  `is_pledge_interval` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is frequency interval exposed on the contribution form.',
  `max_reminders` int(10) unsigned DEFAULT 1 COMMENT 'The maximum number of payment reminders to send for any given payment.',
  `initial_reminder_day` int(10) unsigned DEFAULT 5 COMMENT 'Send initial reminder this many days prior to the payment due date.',
  `additional_reminder_day` int(10) unsigned DEFAULT 5 COMMENT 'Send additional reminder this many days after last one sent, up to maximum number of reminders.',
  `pledge_start_date` varchar(64) DEFAULT NULL COMMENT 'The date the first scheduled pledge occurs.',
  `is_pledge_start_date_visible` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'If true - recurring start date is shown.',
  `is_pledge_start_date_editable` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'If true - recurring start date is editable.',
  PRIMARY KEY (`id`),
  KEY `index_entity` (`entity_table`,`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_pledge_payment`
--

DROP TABLE IF EXISTS `civicrm_pledge_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_pledge_payment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pledge_id` int(10) unsigned NOT NULL COMMENT 'FK to Pledge table',
  `contribution_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contribution table.',
  `scheduled_amount` decimal(20,2) NOT NULL COMMENT 'Pledged amount for this payment (the actual contribution amount might be different).',
  `actual_amount` decimal(20,2) DEFAULT NULL COMMENT 'Actual amount that is paid as the Pledged installment amount.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `scheduled_date` datetime NOT NULL COMMENT 'The date the pledge payment is supposed to happen.',
  `reminder_date` datetime DEFAULT NULL COMMENT 'The date that the most recent payment reminder was sent.',
  `reminder_count` int(10) unsigned DEFAULT 0 COMMENT 'The number of payment reminders sent.',
  `status_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contribution_pledge` (`contribution_id`,`pledge_id`),
  KEY `index_status` (`status_id`),
  KEY `FK_civicrm_pledge_payment_pledge_id` (`pledge_id`),
  CONSTRAINT `FK_civicrm_pledge_payment_contribution_id` FOREIGN KEY (`contribution_id`) REFERENCES `civicrm_contribution` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_pledge_payment_pledge_id` FOREIGN KEY (`pledge_id`) REFERENCES `civicrm_pledge` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_preferences_date`
--

DROP TABLE IF EXISTS `civicrm_preferences_date`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_preferences_date` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL COMMENT 'The meta name for this date (fixed in code)',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of this date type.',
  `start` int(11) NOT NULL COMMENT 'The start offset relative to current year',
  `end` int(11) NOT NULL COMMENT 'The end offset relative to current year, can be negative',
  `date_format` varchar(64) DEFAULT NULL COMMENT 'The date type',
  `time_format` varchar(64) DEFAULT NULL COMMENT 'time format',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_premiums`
--

DROP TABLE IF EXISTS `civicrm_premiums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_premiums` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `entity_table` varchar(64) NOT NULL COMMENT 'Joins these premium settings to another object. Always civicrm_contribution_page for now.',
  `entity_id` int(10) unsigned NOT NULL,
  `premiums_active` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is the Premiums feature enabled for this page?',
  `premiums_intro_title` varchar(255) DEFAULT NULL COMMENT 'Title for Premiums section.',
  `premiums_intro_text` text DEFAULT NULL COMMENT 'Displayed in <div> at top of Premiums section of page. Text and HTML allowed.',
  `premiums_contact_email` varchar(100) DEFAULT NULL COMMENT 'This email address is included in receipts if it is populated and a premium has been selected.',
  `premiums_contact_phone` varchar(50) DEFAULT NULL COMMENT 'This phone number is included in receipts if it is populated and a premium has been selected.',
  `premiums_display_min_contribution` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Boolean. Should we automatically display minimum contribution amount text after the premium descriptions.',
  `premiums_nothankyou_label` varchar(255) DEFAULT NULL COMMENT 'Label displayed for No Thank-you option in premiums block (e.g. No thank you)',
  `premiums_nothankyou_position` int(10) unsigned DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_premiums_product`
--

DROP TABLE IF EXISTS `civicrm_premiums_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_premiums_product` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Contribution ID',
  `premiums_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to premiums settings record.',
  `product_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to each product object.',
  `weight` int(10) unsigned NOT NULL,
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_premiums_product_premiums_id` (`premiums_id`),
  KEY `FK_civicrm_premiums_product_product_id` (`product_id`),
  KEY `FK_civicrm_premiums_product_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_premiums_product_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_premiums_product_premiums_id` FOREIGN KEY (`premiums_id`) REFERENCES `civicrm_premiums` (`id`),
  CONSTRAINT `FK_civicrm_premiums_product_product_id` FOREIGN KEY (`product_id`) REFERENCES `civicrm_product` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_prevnext_cache`
--

DROP TABLE IF EXISTS `civicrm_prevnext_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_prevnext_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'physical tablename for entity being joined to discount, e.g. civicrm_event',
  `entity_id1` int(10) unsigned NOT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `entity_id2` int(10) unsigned DEFAULT NULL COMMENT 'FK to entity table specified in entity_table column.',
  `cachekey` varchar(255) DEFAULT NULL COMMENT 'Unique path name for cache element of the searched item',
  `data` longtext DEFAULT NULL COMMENT 'cached snapshot of the serialized data',
  `is_selected` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_all` (`cachekey`,`entity_id1`,`entity_id2`,`entity_table`,`is_selected`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_price_field`
--

DROP TABLE IF EXISTS `civicrm_price_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_price_field` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Price Field',
  `price_set_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_price_set',
  `name` varchar(255) NOT NULL COMMENT 'Variable name/programmatic handle for this field.',
  `label` varchar(255) NOT NULL COMMENT 'Text for form field label (also friendly name for administering this field).',
  `html_type` varchar(12) NOT NULL,
  `is_enter_qty` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Enter a quantity for this field?',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before this field.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after this field.',
  `weight` int(11) DEFAULT 1 COMMENT 'Order in which the fields should appear',
  `is_display_amounts` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Should the price be displayed next to the label for each option?',
  `options_per_line` int(10) unsigned DEFAULT 1 COMMENT 'number of options per line for checkbox and radio',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this price field active',
  `is_required` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this price field required (value must be > 1)',
  `active_on` datetime DEFAULT NULL COMMENT 'If non-zero, do not show this field before the date specified',
  `expire_on` datetime DEFAULT NULL COMMENT 'If non-zero, do not show this field after the date specified',
  `javascript` varchar(255) DEFAULT NULL COMMENT 'Optional scripting attributes for field',
  `visibility_id` int(10) unsigned DEFAULT 1 COMMENT 'Implicit FK to civicrm_option_group with name = ''visibility''',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`),
  KEY `FK_civicrm_price_field_price_set_id` (`price_set_id`),
  CONSTRAINT `FK_civicrm_price_field_price_set_id` FOREIGN KEY (`price_set_id`) REFERENCES `civicrm_price_set` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_price_field_value`
--

DROP TABLE IF EXISTS `civicrm_price_field_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_price_field_value` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Price Field Value',
  `price_field_id` int(10) unsigned NOT NULL COMMENT 'FK to civicrm_price_field',
  `name` varchar(255) DEFAULT NULL COMMENT 'Price field option name',
  `label` varchar(255) DEFAULT NULL COMMENT 'Price field option label',
  `description` text DEFAULT NULL COMMENT 'Price field option description.',
  `help_pre` text DEFAULT NULL COMMENT 'Price field option pre help text.',
  `help_post` text DEFAULT NULL COMMENT 'Price field option post field help.',
  `amount` decimal(18,9) NOT NULL COMMENT 'Price field option amount',
  `count` int(10) unsigned DEFAULT NULL COMMENT 'Number of participants per field option',
  `max_value` int(10) unsigned DEFAULT NULL COMMENT 'Max number of participants per field options',
  `weight` int(11) DEFAULT 1 COMMENT 'Order in which the field options should appear',
  `membership_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Membership Type',
  `membership_num_terms` int(10) unsigned DEFAULT NULL COMMENT 'Number of terms for this membership',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this default price field option',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this price field value active',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type.',
  `non_deductible_amount` decimal(20,2) NOT NULL DEFAULT 0.00 COMMENT 'Portion of total amount which is NOT tax deductible.',
  `visibility_id` int(10) unsigned DEFAULT 1 COMMENT 'Implicit FK to civicrm_option_group with name = ''visibility''',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_price_field_value_price_field_id` (`price_field_id`),
  KEY `FK_civicrm_price_field_value_membership_type_id` (`membership_type_id`),
  KEY `FK_civicrm_price_field_value_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_price_field_value_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_price_field_value_membership_type_id` FOREIGN KEY (`membership_type_id`) REFERENCES `civicrm_membership_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_price_field_value_price_field_id` FOREIGN KEY (`price_field_id`) REFERENCES `civicrm_price_field` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_price_set`
--

DROP TABLE IF EXISTS `civicrm_price_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_price_set` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Price Set',
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Domain is this price-set for',
  `name` varchar(255) NOT NULL COMMENT 'Variable name/programmatic handle for this set of price fields.',
  `title` varchar(255) NOT NULL COMMENT 'Displayed title for the Price Set.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this price set active',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before fields in form.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after fields in form.',
  `javascript` varchar(64) DEFAULT NULL COMMENT 'Optional Javascript script function(s) included on the form with this price_set. Can be used for conditional',
  `extends` varchar(255) NOT NULL COMMENT 'What components are using this price set?',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type(for membership price sets only).',
  `is_quick_config` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is set if edited on Contribution or Event Page rather than through Manage Price Sets',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a predefined system price set  (i.e. it can not be deleted, edited)?',
  `min_amount` decimal(20,2) DEFAULT 0.00 COMMENT 'Minimum Amount required for this set.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_price_set_domain_id` (`domain_id`),
  KEY `FK_civicrm_price_set_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_price_set_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_price_set_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_price_set_entity`
--

DROP TABLE IF EXISTS `civicrm_price_set_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_price_set_entity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Price Set Entity',
  `entity_table` varchar(64) NOT NULL COMMENT 'Table which uses this price set',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Item in table',
  `price_set_id` int(10) unsigned NOT NULL COMMENT 'price set being used',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_entity` (`entity_table`,`entity_id`),
  KEY `FK_civicrm_price_set_entity_price_set_id` (`price_set_id`),
  CONSTRAINT `FK_civicrm_price_set_entity_price_set_id` FOREIGN KEY (`price_set_id`) REFERENCES `civicrm_price_set` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_print_label`
--

DROP TABLE IF EXISTS `civicrm_print_label`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_print_label` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL COMMENT 'User title for this label layout',
  `name` varchar(255) DEFAULT NULL COMMENT 'variable name/programmatic handle for this field.',
  `description` text DEFAULT NULL COMMENT 'Description of this label layout',
  `label_format_name` varchar(255) DEFAULT NULL COMMENT 'This refers to name column of civicrm_option_value row in name_badge option group',
  `label_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Implicit FK to civicrm_option_value row in NEW label_type option group',
  `data` longtext DEFAULT NULL COMMENT 'contains json encode configurations options',
  `is_default` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this default?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this option active?',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this reserved label?',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this label layout',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_print_label_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_print_label_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_product`
--

DROP TABLE IF EXISTS `civicrm_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_product` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Required product/premium name',
  `description` text DEFAULT NULL COMMENT 'Optional description of the product/premium.',
  `sku` varchar(50) DEFAULT NULL COMMENT 'Optional product sku or code.',
  `options` text DEFAULT NULL COMMENT 'Store comma-delimited list of color, size, etc. options for the product.',
  `image` varchar(255) DEFAULT NULL COMMENT 'Full or relative URL to uploaded image - fullsize.',
  `thumbnail` varchar(255) DEFAULT NULL COMMENT 'Full or relative URL to image thumbnail.',
  `price` decimal(20,2) DEFAULT NULL COMMENT 'Sell price or market value for premiums. For tax-deductible contributions, this will be stored as non_deductible_amount in the contribution record.',
  `currency` varchar(3) DEFAULT NULL COMMENT '3 character string, value from config setting or input via user.',
  `financial_type_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Financial Type.',
  `min_contribution` decimal(20,2) DEFAULT NULL COMMENT 'Minimum contribution required to be eligible to select this premium.',
  `cost` decimal(20,2) DEFAULT NULL COMMENT 'Actual cost of this product. Useful to determine net return from sale or using this as an incentive.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Disabling premium removes it from the premiums_premium join table below.',
  `period_type` varchar(8) DEFAULT 'rolling' COMMENT 'Rolling means we set start/end based on current day, fixed means we set start/end for current year or month\n      (e.g. 1 year + fixed -> we would set start/end for 1/1/06 thru 12/31/06 for any premium chosen in 2006) ',
  `fixed_period_start_day` int(11) DEFAULT 101 COMMENT 'Month and day (MMDD) that fixed period type subscription or membership starts.',
  `duration_unit` varchar(8) DEFAULT 'year',
  `duration_interval` int(11) DEFAULT NULL COMMENT 'Number of units for total duration of subscription, service, membership (e.g. 12 Months).',
  `frequency_unit` varchar(8) DEFAULT 'month' COMMENT 'Frequency unit and interval allow option to store actual delivery frequency for a subscription or service.',
  `frequency_interval` int(11) DEFAULT NULL COMMENT 'Number of units for delivery frequency of subscription, service, membership (e.g. every 3 Months).',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_product_financial_type_id` (`financial_type_id`),
  CONSTRAINT `FK_civicrm_product_financial_type_id` FOREIGN KEY (`financial_type_id`) REFERENCES `civicrm_financial_type` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_queue`
--

DROP TABLE IF EXISTS `civicrm_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_queue` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL COMMENT 'Name of the queue',
  `type` varchar(64) NOT NULL COMMENT 'Type of the queue',
  `runner` varchar(64) DEFAULT NULL COMMENT 'Name of the task runner',
  `batch_limit` int(10) unsigned NOT NULL DEFAULT 1 COMMENT 'Maximum number of items in a batch.',
  `lease_time` int(10) unsigned NOT NULL DEFAULT 3600 COMMENT 'When claiming an item (or batch of items) for work, how long should the item(s) be reserved. (Seconds)',
  `retry_limit` int(11) NOT NULL DEFAULT 0 COMMENT 'Number of permitted retries. Set to zero (0) to disable.',
  `retry_interval` int(11) DEFAULT NULL COMMENT 'Number of seconds to wait before retrying a failed execution.',
  `status` varchar(16) DEFAULT 'active' COMMENT 'Execution status',
  `error` varchar(16) DEFAULT NULL COMMENT 'Fallback behavior for unhandled errors',
  `is_template` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a template configuration (for use by other/future queues)?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_queue_item`
--

DROP TABLE IF EXISTS `civicrm_queue_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_queue_item` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `queue_name` varchar(64) NOT NULL COMMENT 'Name of the queue which includes this item',
  `weight` int(11) NOT NULL,
  `submit_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'date on which this item was submitted to the queue',
  `release_time` timestamp NULL DEFAULT NULL COMMENT 'date on which this job becomes available; null if ASAP',
  `run_count` int(11) NOT NULL DEFAULT 0 COMMENT 'Number of times execution has been attempted.',
  `data` longtext DEFAULT NULL COMMENT 'Serialized queue data',
  PRIMARY KEY (`id`),
  KEY `index_queueids` (`queue_name`,`weight`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_recurring_entity`
--

DROP TABLE IF EXISTS `civicrm_recurring_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_recurring_entity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(10) unsigned NOT NULL COMMENT 'Recurring Entity Parent ID',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'Recurring Entity Child ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Physical tablename for entity, e.g. civicrm_event',
  `mode` tinyint(4) NOT NULL DEFAULT 1 COMMENT '1-this entity, 2-this and the following entities, 3-all the entities',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_relationship`
--

DROP TABLE IF EXISTS `civicrm_relationship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_relationship` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Relationship ID',
  `contact_id_a` int(10) unsigned NOT NULL COMMENT 'id of the first contact',
  `contact_id_b` int(10) unsigned NOT NULL COMMENT 'id of the second contact',
  `relationship_type_id` int(10) unsigned NOT NULL COMMENT 'Type of relationship',
  `start_date` date DEFAULT NULL COMMENT 'date when the relationship started',
  `end_date` date DEFAULT NULL COMMENT 'date when the relationship ended',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'is the relationship active ?',
  `description` varchar(255) DEFAULT NULL COMMENT 'Optional verbose description for the relationship.',
  `is_permission_a_b` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Permission that Contact A has to view/update Contact B',
  `is_permission_b_a` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Permission that Contact B has to view/update Contact A',
  `case_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_case',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Relationship created date.',
  `modified_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Relationship last modified.',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_relationship_contact_id_a` (`contact_id_a`),
  KEY `FK_civicrm_relationship_contact_id_b` (`contact_id_b`),
  KEY `FK_civicrm_relationship_relationship_type_id` (`relationship_type_id`),
  KEY `FK_civicrm_relationship_case_id` (`case_id`),
  CONSTRAINT `FK_civicrm_relationship_case_id` FOREIGN KEY (`case_id`) REFERENCES `civicrm_case` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_contact_id_a` FOREIGN KEY (`contact_id_a`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_contact_id_b` FOREIGN KEY (`contact_id_b`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_relationship_type_id` FOREIGN KEY (`relationship_type_id`) REFERENCES `civicrm_relationship_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=217 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_relationship_after_insert after insert ON civicrm_relationship FOR EACH ROW BEGIN  INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "a_b", rel.contact_id_a, reltype.name_a_b, rel.contact_id_b, reltype.name_b_a, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_a, near_relation = reltype.name_a_b, far_contact_id = rel.contact_id_b, far_relation = reltype.name_b_a, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;

INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "b_a", rel.contact_id_b, reltype.name_b_a, rel.contact_id_a, reltype.name_a_b, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_b, near_relation = reltype.name_b_a, far_contact_id = rel.contact_id_a, far_relation = reltype.name_a_b, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_relationship_after_update after update ON civicrm_relationship FOR EACH ROW BEGIN  INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "a_b", rel.contact_id_a, reltype.name_a_b, rel.contact_id_b, reltype.name_b_a, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_a, near_relation = reltype.name_a_b, far_contact_id = rel.contact_id_b, far_relation = reltype.name_b_a, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;

INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "b_a", rel.contact_id_b, reltype.name_b_a, rel.contact_id_a, reltype.name_a_b, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_b, near_relation = reltype.name_b_a, far_contact_id = rel.contact_id_a, far_relation = reltype.name_a_b, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_relationship_cache`
--

DROP TABLE IF EXISTS `civicrm_relationship_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_relationship_cache` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Relationship Cache ID',
  `relationship_id` int(10) unsigned NOT NULL COMMENT 'id of the relationship (FK to civicrm_relationship.id)',
  `relationship_type_id` int(10) unsigned NOT NULL COMMENT 'id of the relationship type',
  `orientation` char(3) NOT NULL COMMENT 'The cache record is a permutation of the original relationship record. The orientation indicates whether it is forward (a_b) or reverse (b_a) relationship.',
  `near_contact_id` int(10) unsigned NOT NULL COMMENT 'id of the first contact',
  `near_relation` varchar(64) DEFAULT NULL COMMENT 'name for relationship of near_contact to far_contact.',
  `far_contact_id` int(10) unsigned NOT NULL COMMENT 'id of the second contact',
  `far_relation` varchar(64) DEFAULT NULL COMMENT 'name for relationship of far_contact to near_contact.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'is the relationship active ?',
  `start_date` date DEFAULT NULL COMMENT 'date when the relationship started',
  `end_date` date DEFAULT NULL COMMENT 'date when the relationship ended',
  `case_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_case',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_relationship` (`relationship_id`,`orientation`),
  KEY `index_nearid_nearrelation` (`near_contact_id`,`near_relation`),
  KEY `index_nearid_farrelation` (`near_contact_id`,`far_relation`),
  KEY `index_near_relation` (`near_relation`),
  KEY `FK_civicrm_relationship_cache_relationship_type_id` (`relationship_type_id`),
  KEY `FK_civicrm_relationship_cache_far_contact_id` (`far_contact_id`),
  KEY `FK_civicrm_relationship_cache_case_id` (`case_id`),
  CONSTRAINT `FK_civicrm_relationship_cache_case_id` FOREIGN KEY (`case_id`) REFERENCES `civicrm_case` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_cache_far_contact_id` FOREIGN KEY (`far_contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_cache_near_contact_id` FOREIGN KEY (`near_contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_cache_relationship_id` FOREIGN KEY (`relationship_id`) REFERENCES `civicrm_relationship` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_relationship_cache_relationship_type_id` FOREIGN KEY (`relationship_type_id`) REFERENCES `civicrm_relationship_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=433 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_relationship_type`
--

DROP TABLE IF EXISTS `civicrm_relationship_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_relationship_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name_a_b` varchar(64) DEFAULT NULL COMMENT 'name for relationship of contact_a to contact_b.',
  `label_a_b` varchar(64) DEFAULT NULL COMMENT 'label for relationship of contact_a to contact_b.',
  `name_b_a` varchar(64) DEFAULT NULL COMMENT 'Optional name for relationship of contact_b to contact_a.',
  `label_b_a` varchar(64) DEFAULT NULL COMMENT 'Optional label for relationship of contact_b to contact_a.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Optional verbose description of the relationship type.',
  `contact_type_a` varchar(12) DEFAULT NULL COMMENT 'If defined, contact_a in a relationship of this type must be a specific contact_type.',
  `contact_type_b` varchar(12) DEFAULT NULL COMMENT 'If defined, contact_b in a relationship of this type must be a specific contact_type.',
  `contact_sub_type_a` varchar(64) DEFAULT NULL COMMENT 'If defined, contact_sub_type_a in a relationship of this type must be a specific contact_sub_type.',
  `contact_sub_type_b` varchar(64) DEFAULT NULL COMMENT 'If defined, contact_sub_type_b in a relationship of this type must be a specific contact_sub_type.',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this relationship type a predefined system type (can not be changed or de-activated)?',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this relationship type currently active (i.e. can be used when creating or editing relationships)?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name_a_b` (`name_a_b`),
  UNIQUE KEY `UI_name_b_a` (`name_b_a`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_relationship_type_after_update after update ON civicrm_relationship_type FOR EACH ROW BEGIN  
IF ((OLD.name_a_b != NEW.name_a_b COLLATE utf8mb4_bin) OR (OLD.name_b_a != NEW.name_b_a COLLATE utf8mb4_bin)) THEN
 INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "a_b", rel.contact_id_a, reltype.name_a_b, rel.contact_id_b, reltype.name_b_a, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.relationship_type_id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_a, near_relation = reltype.name_a_b, far_contact_id = rel.contact_id_b, far_relation = reltype.name_b_a, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;
 END IF;


IF ((OLD.name_a_b != NEW.name_a_b COLLATE utf8mb4_bin) OR (OLD.name_b_a != NEW.name_b_a COLLATE utf8mb4_bin)) THEN
 INSERT INTO civicrm_relationship_cache (relationship_id, relationship_type_id, orientation, near_contact_id, near_relation, far_contact_id, far_relation, start_date, end_date, is_active, case_id)
SELECT rel.id, rel.relationship_type_id, "b_a", rel.contact_id_b, reltype.name_b_a, rel.contact_id_a, reltype.name_a_b, rel.start_date, rel.end_date, rel.is_active, rel.case_id
FROM civicrm_relationship rel
INNER JOIN civicrm_relationship_type reltype ON rel.relationship_type_id = reltype.id
WHERE (rel.relationship_type_id = NEW.id)
 ON DUPLICATE KEY UPDATE relationship_type_id = rel.relationship_type_id, near_contact_id = rel.contact_id_b, near_relation = reltype.name_b_a, far_contact_id = rel.contact_id_a, far_relation = reltype.name_a_b, start_date = rel.start_date, end_date = rel.end_date, is_active = rel.is_active, case_id = rel.case_id
;
 END IF;
 END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_report_instance`
--

DROP TABLE IF EXISTS `civicrm_report_instance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_report_instance` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Report Instance ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this instance for',
  `title` varchar(255) DEFAULT NULL COMMENT 'Report Instance Title.',
  `report_id` varchar(512) NOT NULL COMMENT 'FK to civicrm_option_value for the report template',
  `name` varchar(255) DEFAULT NULL COMMENT 'when combined with report_id/template uniquely identifies the instance',
  `args` varchar(255) DEFAULT NULL COMMENT 'arguments that are passed in the url when invoking the instance',
  `description` varchar(255) DEFAULT NULL COMMENT 'Report Instance description.',
  `permission` varchar(255) DEFAULT NULL COMMENT 'permission required to be able to run this instance',
  `grouprole` varchar(1024) DEFAULT NULL COMMENT 'role required to be able to run this instance',
  `form_values` longtext DEFAULT NULL COMMENT 'Submitted form values for this report',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this entry active?',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `owner_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `email_subject` varchar(255) DEFAULT NULL COMMENT 'Subject of email',
  `email_to` text DEFAULT NULL COMMENT 'comma-separated list of email addresses to send the report to',
  `email_cc` text DEFAULT NULL COMMENT 'comma-separated list of email addresses to send the report to',
  `header` text DEFAULT NULL COMMENT 'comma-separated list of email addresses to send the report to',
  `footer` text DEFAULT NULL COMMENT 'comma-separated list of email addresses to send the report to',
  `navigation_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to navigation ID',
  `drilldown_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to instance ID drilldown to',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_report_instance_domain_id` (`domain_id`),
  KEY `FK_civicrm_report_instance_created_id` (`created_id`),
  KEY `FK_civicrm_report_instance_owner_id` (`owner_id`),
  KEY `FK_civicrm_report_instance_navigation_id` (`navigation_id`),
  KEY `FK_civicrm_report_instance_drilldown_id` (`drilldown_id`),
  CONSTRAINT `FK_civicrm_report_instance_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_report_instance_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`),
  CONSTRAINT `FK_civicrm_report_instance_drilldown_id` FOREIGN KEY (`drilldown_id`) REFERENCES `civicrm_report_instance` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_report_instance_navigation_id` FOREIGN KEY (`navigation_id`) REFERENCES `civicrm_navigation` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_report_instance_owner_id` FOREIGN KEY (`owner_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_saved_search`
--

DROP TABLE IF EXISTS `civicrm_saved_search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_saved_search` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Saved Search ID',
  `name` varchar(255) DEFAULT NULL COMMENT 'Unique name of saved search',
  `label` varchar(255) DEFAULT NULL COMMENT 'Administrative label for search',
  `form_values` text DEFAULT NULL COMMENT 'Submitted form values for this search',
  `mapping_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to civicrm_mapping used for saved search-builder searches.',
  `search_custom_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to civicrm_option value table used for saved custom searches.',
  `api_entity` varchar(255) DEFAULT NULL COMMENT 'Entity name for API based search',
  `api_params` text DEFAULT NULL COMMENT 'Parameters for API based search',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `expires_date` timestamp NULL DEFAULT NULL COMMENT 'Optional date after which the search is not needed',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When the search was created.',
  `modified_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'When the search was last modified.',
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_saved_search_mapping_id` (`mapping_id`),
  KEY `FK_civicrm_saved_search_created_id` (`created_id`),
  KEY `FK_civicrm_saved_search_modified_id` (`modified_id`),
  CONSTRAINT `FK_civicrm_saved_search_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_saved_search_mapping_id` FOREIGN KEY (`mapping_id`) REFERENCES `civicrm_mapping` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_saved_search_modified_id` FOREIGN KEY (`modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_search_display`
--

DROP TABLE IF EXISTS `civicrm_search_display`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_search_display` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique SearchDisplay ID',
  `name` varchar(255) NOT NULL COMMENT 'Unique name for identifying search display',
  `label` varchar(255) NOT NULL COMMENT 'Label for identifying search display to administrators',
  `saved_search_id` int(10) unsigned NOT NULL COMMENT 'FK to saved search table.',
  `type` varchar(128) NOT NULL COMMENT 'Type of display',
  `settings` text DEFAULT NULL COMMENT 'Configuration data for the search display',
  `acl_bypass` tinyint(4) DEFAULT 0 COMMENT 'Skip permission checks and ACLs when running this display.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_saved_search__id_name` (`saved_search_id`,`name`),
  CONSTRAINT `FK_civicrm_search_display_saved_search_id` FOREIGN KEY (`saved_search_id`) REFERENCES `civicrm_saved_search` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_search_segment`
--

DROP TABLE IF EXISTS `civicrm_search_segment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_search_segment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique SearchSegment ID',
  `name` varchar(255) NOT NULL COMMENT 'Unique name',
  `label` varchar(255) NOT NULL COMMENT 'Label for identifying search segment (will appear as name of calculated field)',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description will appear when selecting SearchSegment in the fields dropdown.',
  `entity_name` varchar(255) NOT NULL COMMENT 'Entity for which this set is used.',
  `items` text DEFAULT NULL COMMENT 'All items in set',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_setting`
--

DROP TABLE IF EXISTS `civicrm_setting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_setting` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL COMMENT 'Unique name for setting',
  `value` text DEFAULT NULL COMMENT 'data associated with this group / name combo',
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Domain does this setting belong to',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID if the setting is localized to a contact',
  `is_domain` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this setting per-domain or global?',
  `component_id` int(10) unsigned DEFAULT NULL COMMENT 'Component that this menu item belongs to',
  `created_date` datetime DEFAULT NULL COMMENT 'When was the setting created',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this setting',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_domain_contact_name` (`domain_id`,`contact_id`,`name`),
  KEY `FK_civicrm_setting_contact_id` (`contact_id`),
  KEY `FK_civicrm_setting_component_id` (`component_id`),
  KEY `FK_civicrm_setting_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_setting_component_id` FOREIGN KEY (`component_id`) REFERENCES `civicrm_component` (`id`),
  CONSTRAINT `FK_civicrm_setting_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_setting_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_setting_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_sms_provider`
--

DROP TABLE IF EXISTS `civicrm_sms_provider`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_sms_provider` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'SMS Provider ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Provider internal name points to option_value of option_group sms_provider_name',
  `title` varchar(64) DEFAULT NULL COMMENT 'Provider name visible to user',
  `username` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `api_type` int(10) unsigned NOT NULL COMMENT 'points to value in civicrm_option_value for group sms_api_type',
  `api_url` varchar(128) DEFAULT NULL,
  `api_params` text DEFAULT NULL COMMENT 'the api params in xml, http or smtp format',
  `is_default` tinyint(4) NOT NULL DEFAULT 0,
  `is_active` tinyint(4) NOT NULL DEFAULT 1,
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Domain is this sms provider for',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_sms_provider_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_sms_provider_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_state_province`
--

DROP TABLE IF EXISTS `civicrm_state_province`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_state_province` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'State/Province ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Name of State/Province',
  `abbreviation` varchar(4) DEFAULT NULL COMMENT '2-4 Character Abbreviation of State/Province',
  `country_id` int(10) unsigned NOT NULL COMMENT 'ID of Country that State/Province belong',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this StateProvince active?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name_country_id` (`name`,`country_id`),
  KEY `FK_civicrm_state_province_country_id` (`country_id`),
  CONSTRAINT `FK_civicrm_state_province_country_id` FOREIGN KEY (`country_id`) REFERENCES `civicrm_country` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10418 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_status_pref`
--

DROP TABLE IF EXISTS `civicrm_status_pref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_status_pref` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Status Preference ID',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this Status Preference for',
  `name` varchar(255) NOT NULL COMMENT 'Name of the status check this preference references.',
  `hush_until` date DEFAULT NULL COMMENT 'expires ignore_severity.  NULL never hushes.',
  `ignore_severity` int(10) unsigned DEFAULT 1 COMMENT 'Hush messages up to and including this severity.',
  `prefs` varchar(255) DEFAULT NULL COMMENT 'These settings are per-check, and can''t be compared across checks.',
  `check_info` varchar(255) DEFAULT NULL COMMENT 'These values are per-check, and can''t be compared across checks.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this status check active?',
  PRIMARY KEY (`id`),
  KEY `UI_status_pref_name` (`name`),
  KEY `FK_civicrm_status_pref_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_status_pref_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_subscription_history`
--

DROP TABLE IF EXISTS `civicrm_subscription_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_subscription_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Internal ID',
  `contact_id` int(10) unsigned NOT NULL COMMENT 'Contact ID',
  `group_id` int(10) unsigned DEFAULT NULL COMMENT 'Group ID',
  `date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date of the (un)subscription',
  `method` varchar(8) DEFAULT NULL COMMENT 'How the (un)subscription was triggered',
  `status` varchar(8) DEFAULT NULL COMMENT 'The state of the contact within the group',
  `tracking` varchar(255) DEFAULT NULL COMMENT 'IP address or other tracking info',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_subscription_history_contact_id` (`contact_id`),
  KEY `FK_civicrm_subscription_history_group_id` (`group_id`),
  CONSTRAINT `FK_civicrm_subscription_history_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_subscription_history_group_id` FOREIGN KEY (`group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_survey`
--

DROP TABLE IF EXISTS `civicrm_survey`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_survey` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Survey id.',
  `title` varchar(255) NOT NULL COMMENT 'Title of the Survey.',
  `campaign_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to the Campaign.',
  `activity_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Implicit FK to civicrm_option_value where option_group = activity_type',
  `recontact_interval` text DEFAULT NULL COMMENT 'Recontact intervals for each status.',
  `instructions` text DEFAULT NULL COMMENT 'Script instructions for volunteers to use for the survey.',
  `release_frequency` int(10) unsigned DEFAULT NULL COMMENT 'Number of days for recurrence of release.',
  `max_number_of_contacts` int(10) unsigned DEFAULT NULL COMMENT 'Maximum number of contacts to allow for survey.',
  `default_number_of_contacts` int(10) unsigned DEFAULT NULL COMMENT 'Default number of contacts to allow for survey.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this survey enabled or disabled/cancelled?',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this default survey?',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this Survey.',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time that Survey was created.',
  `last_modified_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who recently edited this Survey.',
  `last_modified_date` datetime DEFAULT NULL COMMENT 'Date and time that Survey was edited last time.',
  `result_id` int(10) unsigned DEFAULT NULL COMMENT 'Used to store option group id.',
  `bypass_confirm` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Bypass the email verification.',
  `thankyou_title` varchar(255) DEFAULT NULL COMMENT 'Title for Thank-you page (header title tag, and display at the top of the page).',
  `thankyou_text` text DEFAULT NULL COMMENT 'text and html allowed. displayed above result on success page',
  `is_share` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Can people share the petition through social media?',
  PRIMARY KEY (`id`),
  KEY `UI_activity_type_id` (`activity_type_id`),
  KEY `FK_civicrm_survey_campaign_id` (`campaign_id`),
  KEY `FK_civicrm_survey_created_id` (`created_id`),
  KEY `FK_civicrm_survey_last_modified_id` (`last_modified_id`),
  CONSTRAINT `FK_civicrm_survey_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `civicrm_campaign` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_survey_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_survey_last_modified_id` FOREIGN KEY (`last_modified_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_system_log`
--

DROP TABLE IF EXISTS `civicrm_system_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_system_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key ID',
  `message` varchar(128) NOT NULL COMMENT 'Standardized message',
  `context` longtext DEFAULT NULL COMMENT 'JSON encoded data',
  `level` varchar(9) DEFAULT 'info' COMMENT 'error level per PSR3',
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Timestamp of when event occurred.',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional Contact ID that created the log. Not an FK as we keep this regardless',
  `hostname` varchar(128) DEFAULT NULL COMMENT 'Optional Name of logging host',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_tag`
--

DROP TABLE IF EXISTS `civicrm_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_tag` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Tag ID',
  `name` varchar(64) NOT NULL COMMENT 'Name of Tag.',
  `description` varchar(255) DEFAULT NULL COMMENT 'Optional verbose description of the tag.',
  `parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional parent id for this tag.',
  `is_selectable` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this tag selectable / displayed',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0,
  `is_tagset` tinyint(4) NOT NULL DEFAULT 0,
  `used_for` varchar(64) DEFAULT NULL,
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this tag',
  `color` varchar(255) DEFAULT NULL COMMENT 'Hex color value e.g. #ffffff',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time that tag was created.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_tag_parent_id` (`parent_id`),
  KEY `FK_civicrm_tag_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_tag_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_tag_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `civicrm_tag` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_tell_friend`
--

DROP TABLE IF EXISTS `civicrm_tell_friend`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_tell_friend` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Friend ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Name of table where item being referenced is stored.',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to the referenced item.',
  `title` varchar(255) DEFAULT NULL,
  `intro` text DEFAULT NULL COMMENT 'Introductory message to contributor or participant displayed on the Tell a Friend form.',
  `suggested_message` text DEFAULT NULL COMMENT 'Suggested message to friends, provided as default on the Tell A Friend form.',
  `general_link` varchar(255) DEFAULT NULL COMMENT 'URL for general info about the organization - included in the email sent to friends.',
  `thankyou_title` varchar(255) DEFAULT NULL COMMENT 'Text for Tell a Friend thank you page header and HTML title.',
  `thankyou_text` text DEFAULT NULL COMMENT 'Thank you message displayed on success page.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_timezone`
--

DROP TABLE IF EXISTS `civicrm_timezone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_timezone` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Timezone ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Timezone full name',
  `abbreviation` char(3) DEFAULT NULL COMMENT 'ISO Code for timezone abbreviation',
  `gmt` varchar(64) DEFAULT NULL COMMENT 'GMT name of the timezone',
  `offset` int(11) DEFAULT NULL,
  `country_id` int(10) unsigned NOT NULL COMMENT 'Country ID',
  PRIMARY KEY (`id`),
  KEY `FK_civicrm_timezone_country_id` (`country_id`),
  CONSTRAINT `FK_civicrm_timezone_country_id` FOREIGN KEY (`country_id`) REFERENCES `civicrm_country` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_translation`
--

DROP TABLE IF EXISTS `civicrm_translation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_translation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique String ID',
  `entity_table` varchar(64) NOT NULL COMMENT 'Table where referenced item is stored',
  `entity_field` varchar(64) NOT NULL COMMENT 'Field where referenced item is stored',
  `entity_id` int(11) NOT NULL COMMENT 'ID of the relevant entity.',
  `language` varchar(5) NOT NULL COMMENT 'Relevant language',
  `status_id` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Specify whether the string is active, draft, etc',
  `string` longtext NOT NULL COMMENT 'Translated string',
  PRIMARY KEY (`id`),
  KEY `index_entity_lang` (`entity_id`,`entity_table`,`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_uf_field`
--

DROP TABLE IF EXISTS `civicrm_uf_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_uf_field` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `uf_group_id` int(10) unsigned NOT NULL COMMENT 'Which form does this field belong to.',
  `field_name` varchar(64) NOT NULL COMMENT 'Name for CiviCRM field which is being exposed for sharing.',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this field currently shareable? If false, hide the field for all sharing contexts.',
  `is_view` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'the field is view only and not editable in user forms.',
  `is_required` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this field required when included in a user or registration form?',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Controls field display order when user framework fields are displayed in registration and account editing forms.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after this field.',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before this field.',
  `visibility` varchar(32) DEFAULT 'User and User Admin Only' COMMENT 'In what context(s) is this field visible.',
  `in_selector` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this field included as a column in the selector table?',
  `is_searchable` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this field included search form of profile?',
  `location_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Location type of this mapping, if required',
  `phone_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Phone Type ID, if required',
  `website_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Website Type ID, if required',
  `label` varchar(255) NOT NULL COMMENT 'To save label for fields.',
  `field_type` varchar(255) DEFAULT NULL COMMENT 'This field saves field type (ie individual,household.. field etc).',
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this field reserved for use by some other CiviCRM functionality?',
  `is_multi_summary` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Include in multi-record listing?',
  PRIMARY KEY (`id`),
  KEY `IX_website_type_id` (`website_type_id`),
  KEY `FK_civicrm_uf_field_uf_group_id` (`uf_group_id`),
  KEY `FK_civicrm_uf_field_location_type_id` (`location_type_id`),
  CONSTRAINT `FK_civicrm_uf_field_location_type_id` FOREIGN KEY (`location_type_id`) REFERENCES `civicrm_location_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_uf_field_uf_group_id` FOREIGN KEY (`uf_group_id`) REFERENCES `civicrm_uf_group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_uf_group`
--

DROP TABLE IF EXISTS `civicrm_uf_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_uf_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this profile currently active? If false, hide all related fields for all sharing contexts.',
  `group_type` varchar(255) DEFAULT NULL COMMENT 'Comma separated list of the type(s) of profile fields.',
  `title` varchar(64) NOT NULL COMMENT 'Form title.',
  `frontend_title` varchar(64) DEFAULT NULL COMMENT 'Profile Form Public title',
  `description` text DEFAULT NULL COMMENT 'Optional verbose description of the profile.',
  `help_pre` text DEFAULT NULL COMMENT 'Description and/or help text to display before fields in form.',
  `help_post` text DEFAULT NULL COMMENT 'Description and/or help text to display after fields in form.',
  `limit_listings_group_id` int(10) unsigned DEFAULT NULL COMMENT 'Group id, foreign key from civicrm_group',
  `post_url` varchar(255) DEFAULT NULL COMMENT 'Redirect to URL on submit.',
  `add_to_group_id` int(10) unsigned DEFAULT NULL COMMENT 'foreign key to civicrm_group_id',
  `add_captcha` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should a CAPTCHA widget be included this Profile form.',
  `is_map` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Do we want to map results from this profile.',
  `is_edit_link` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should edit link display in profile selector',
  `is_uf_link` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we display a link to the website profile in profile selector',
  `is_update_dupe` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we update the contact record if we find a duplicate',
  `cancel_url` varchar(255) DEFAULT NULL COMMENT 'Redirect to URL when Cancel button clicked.',
  `is_cms_user` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we create a cms user for this profile ',
  `notify` text DEFAULT NULL,
  `is_reserved` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this group reserved for use by some other CiviCRM functionality?',
  `name` varchar(64) DEFAULT NULL COMMENT 'Name of the UF group for directly addressing it in the codebase',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to civicrm_contact, who created this UF group',
  `created_date` datetime DEFAULT NULL COMMENT 'Date and time this UF group was created.',
  `is_proximity_search` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Should we include proximity search feature in this profile search form?',
  `cancel_button_text` varchar(64) DEFAULT NULL COMMENT 'Custom Text to display on the Cancel button when used in create or edit mode',
  `submit_button_text` varchar(64) DEFAULT NULL COMMENT 'Custom Text to display on the submit button on profile edit/create screens',
  `add_cancel_button` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Should a Cancel button be included in this Profile form.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_uf_group_limit_listings_group_id` (`limit_listings_group_id`),
  KEY `FK_civicrm_uf_group_add_to_group_id` (`add_to_group_id`),
  KEY `FK_civicrm_uf_group_created_id` (`created_id`),
  CONSTRAINT `FK_civicrm_uf_group_add_to_group_id` FOREIGN KEY (`add_to_group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_uf_group_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_uf_group_limit_listings_group_id` FOREIGN KEY (`limit_listings_group_id`) REFERENCES `civicrm_group` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_uf_join`
--

DROP TABLE IF EXISTS `civicrm_uf_join`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_uf_join` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique table ID',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this join currently active?',
  `module` varchar(64) NOT NULL COMMENT 'Module which owns this uf_join instance, e.g. User Registration, CiviDonate, etc.',
  `entity_table` varchar(64) DEFAULT NULL COMMENT 'Name of table where item being referenced is stored. Modules which only need a single collection of uf_join instances may choose not to populate entity_table and entity_id.',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'Foreign key to the referenced item.',
  `weight` int(11) NOT NULL DEFAULT 1 COMMENT 'Controls display order when multiple user framework groups are setup for concurrent display.',
  `uf_group_id` int(10) unsigned NOT NULL COMMENT 'Which form does this field belong to.',
  `module_data` longtext DEFAULT NULL COMMENT 'Json serialized array of data used by the ufjoin.module',
  PRIMARY KEY (`id`),
  KEY `index_entity` (`entity_table`,`entity_id`),
  KEY `FK_civicrm_uf_join_uf_group_id` (`uf_group_id`),
  CONSTRAINT `FK_civicrm_uf_join_uf_group_id` FOREIGN KEY (`uf_group_id`) REFERENCES `civicrm_uf_group` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_uf_match`
--

DROP TABLE IF EXISTS `civicrm_uf_match`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_uf_match` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'System generated ID.',
  `domain_id` int(10) unsigned NOT NULL COMMENT 'Which Domain is this match entry for',
  `uf_id` int(10) unsigned NOT NULL COMMENT 'UF ID',
  `uf_name` varchar(128) DEFAULT NULL COMMENT 'UF Name',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `language` varchar(5) DEFAULT NULL COMMENT 'UI language preferred by the given user/contact',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_uf_name_domain_id` (`uf_name`,`domain_id`),
  UNIQUE KEY `UI_contact_domain_id` (`contact_id`,`domain_id`),
  KEY `I_civicrm_uf_match_uf_id` (`uf_id`),
  KEY `FK_civicrm_uf_match_domain_id` (`domain_id`),
  CONSTRAINT `FK_civicrm_uf_match_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_civicrm_uf_match_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_user_job`
--

DROP TABLE IF EXISTS `civicrm_user_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_user_job` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Job ID',
  `name` varchar(64) DEFAULT NULL COMMENT 'Unique name for job.',
  `created_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to contact table.',
  `created_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date and time this job was created.',
  `start_date` timestamp NULL DEFAULT NULL COMMENT 'Date and time this import job started.',
  `end_date` timestamp NULL DEFAULT NULL COMMENT 'Date and time this import job ended.',
  `expires_date` timestamp NULL DEFAULT NULL COMMENT 'Date and time to clean up after this import job (temp table deletion date).',
  `status_id` int(10) unsigned NOT NULL,
  `job_type` varchar(64) NOT NULL COMMENT 'Name of the job type, which will allow finding the correct class',
  `queue_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Queue',
  `metadata` text DEFAULT NULL COMMENT 'Data pertaining to job configuration',
  `is_template` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Is this a template configuration (for use by other/future jobs)?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_name` (`name`),
  KEY `FK_civicrm_user_job_created_id` (`created_id`),
  KEY `FK_civicrm_user_job_queue_id` (`queue_id`),
  CONSTRAINT `FK_civicrm_user_job_created_id` FOREIGN KEY (`created_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE SET NULL,
  CONSTRAINT `FK_civicrm_user_job_queue_id` FOREIGN KEY (`queue_id`) REFERENCES `civicrm_queue` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_value_constituent_information_1`
--

DROP TABLE IF EXISTS `civicrm_value_constituent_information_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_value_constituent_information_1` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` int(10) unsigned NOT NULL,
  `most_important_issue_1` varchar(255) DEFAULT NULL,
  `marital_status_2` varchar(255) DEFAULT NULL,
  `marriage_date_3` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_entity_id` (`entity_id`),
  KEY `INDEX_most_important_issue_1` (`most_important_issue_1`),
  KEY `INDEX_marital_status_2` (`marital_status_2`),
  KEY `INDEX_marriage_date_3` (`marriage_date_3`),
  CONSTRAINT `FK_civicrm_value_constituent_information_1_entity_id` FOREIGN KEY (`entity_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_value_constituent_information_1_after_insert after insert ON civicrm_value_constituent_information_1 FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.entity_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_value_constituent_information_1_after_update after update ON civicrm_value_constituent_information_1 FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.entity_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_value_constituent_information_1_after_delete after delete ON civicrm_value_constituent_information_1 FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.entity_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_value_donor_information_3`
--

DROP TABLE IF EXISTS `civicrm_value_donor_information_3`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_value_donor_information_3` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Default MySQL primary key',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Table that this extends',
  `known_areas_of_interest_5` text DEFAULT NULL,
  `how_long_have_you_been_a_donor_6` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_entity_id` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_value_food_preference_2`
--

DROP TABLE IF EXISTS `civicrm_value_food_preference_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_value_food_preference_2` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Default MySQL primary key',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'Table that this extends',
  `soup_selection_4` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_entity_id` (`entity_id`),
  CONSTRAINT `FK_civicrm_value_food_preference_2_entity_id` FOREIGN KEY (`entity_id`) REFERENCES `civicrm_participant` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_website`
--

DROP TABLE IF EXISTS `civicrm_website`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_website` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Unique Website ID',
  `contact_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Contact ID',
  `url` varchar(255) DEFAULT NULL COMMENT 'Website',
  `website_type_id` int(10) unsigned DEFAULT NULL COMMENT 'Which Website type does this website belong to.',
  PRIMARY KEY (`id`),
  KEY `UI_website_type_id` (`website_type_id`),
  KEY `FK_civicrm_website_contact_id` (`contact_id`),
  CONSTRAINT `FK_civicrm_website_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `civicrm_contact` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_website_after_insert after insert ON civicrm_website FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_website_after_update after update ON civicrm_website FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = NEW.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`civi_admin`@`localhost`*/ /*!50003 TRIGGER civicrm_website_after_delete after delete ON civicrm_website FOR EACH ROW BEGIN  UPDATE civicrm_contact SET modified_date = CURRENT_TIMESTAMP WHERE id = OLD.contact_id; END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `civicrm_word_replacement`
--

DROP TABLE IF EXISTS `civicrm_word_replacement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_word_replacement` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Word replacement ID',
  `find_word` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL COMMENT 'Word which need to be replaced',
  `replace_word` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL COMMENT 'Word which will replace the word in find',
  `is_active` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Is this entry active?',
  `match_type` varchar(16) DEFAULT 'wildcardMatch',
  `domain_id` int(10) unsigned DEFAULT NULL COMMENT 'FK to Domain ID. This is for Domain specific word replacement',
  PRIMARY KEY (`id`),
  UNIQUE KEY `UI_domain_find` (`domain_id`,`find_word`),
  CONSTRAINT `FK_civicrm_word_replacement_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `civicrm_domain` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `civicrm_worldregion`
--

DROP TABLE IF EXISTS `civicrm_worldregion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `civicrm_worldregion` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Country ID',
  `name` varchar(128) DEFAULT NULL COMMENT 'Region name to be associated with countries',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment` (
  `cid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `comment_type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`cid`),
  UNIQUE KEY `comment_field__uuid__value` (`uuid`),
  KEY `comment_field__comment_type__target_id` (`comment_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for comment entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment__comment_body`
--

DROP TABLE IF EXISTS `comment__comment_body`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment__comment_body` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to, which for an unversioned entity type is the same as the entity id',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `comment_body_value` longtext NOT NULL,
  `comment_body_format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `comment_body_format` (`comment_body_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for comment field comment_body.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment_entity_statistics`
--

DROP TABLE IF EXISTS `comment_entity_statistics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment_entity_statistics` (
  `entity_id` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The entity_id of the entity for which the statistics are compiled.',
  `entity_type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'node' COMMENT 'The entity_type of the entity to which this comment is a reply.',
  `field_name` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field_name of the field that was used to add this comment.',
  `cid` int(11) NOT NULL DEFAULT 0 COMMENT 'The "comment".cid of the last comment.',
  `last_comment_timestamp` int(11) NOT NULL DEFAULT 0 COMMENT 'The Unix timestamp of the last comment that was posted within this node, from "comment".changed.',
  `last_comment_name` varchar(60) DEFAULT NULL COMMENT 'The name of the latest author to post a comment on this node, from "comment".name.',
  `last_comment_uid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The user ID of the latest author to post a comment on this node, from "comment".uid.',
  `comment_count` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The total number of comments on this entity.',
  PRIMARY KEY (`entity_id`,`entity_type`,`field_name`),
  KEY `last_comment_timestamp` (`last_comment_timestamp`),
  KEY `comment_count` (`comment_count`),
  KEY `last_comment_uid` (`last_comment_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Maintains statistics of entity and comments posts to show …';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment_field_data`
--

DROP TABLE IF EXISTS `comment_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment_field_data` (
  `cid` int(10) unsigned NOT NULL,
  `comment_type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `uid` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  `pid` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `entity_id` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `subject` varchar(64) DEFAULT NULL,
  `name` varchar(60) DEFAULT NULL,
  `mail` varchar(254) DEFAULT NULL,
  `homepage` varchar(255) DEFAULT NULL,
  `hostname` varchar(128) DEFAULT NULL,
  `created` int(11) NOT NULL,
  `changed` int(11) DEFAULT NULL,
  `thread` varchar(255) NOT NULL,
  `entity_type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `field_name` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  PRIMARY KEY (`cid`,`langcode`),
  KEY `comment__id__default_langcode__langcode` (`cid`,`default_langcode`,`langcode`),
  KEY `comment_field__comment_type__target_id` (`comment_type`),
  KEY `comment_field__uid__target_id` (`uid`),
  KEY `comment_field__created` (`created`),
  KEY `comment__status_comment_type` (`status`,`comment_type`,`cid`),
  KEY `comment__status_pid` (`pid`,`status`),
  KEY `comment__num_new` (`entity_id`,`entity_type`,`comment_type`,`status`,`created`,`cid`,`thread`(191)),
  KEY `comment__entity_langcode` (`entity_id`,`entity_type`,`comment_type`,`default_langcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for comment entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config` (
  `collection` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Primary Key: Config object collection.',
  `name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Primary Key: Config object name.',
  `data` longblob DEFAULT NULL COMMENT 'A serialized configuration object data.',
  PRIMARY KEY (`collection`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for configuration data.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `file_managed`
--

DROP TABLE IF EXISTS `file_managed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `file_managed` (
  `fid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `filename` varchar(255) DEFAULT NULL,
  `uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `filemime` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `filesize` bigint(20) unsigned DEFAULT NULL,
  `status` tinyint(4) NOT NULL,
  `created` int(11) DEFAULT NULL,
  `changed` int(11) NOT NULL,
  PRIMARY KEY (`fid`),
  UNIQUE KEY `file_field__uuid__value` (`uuid`),
  KEY `file_field__uid__target_id` (`uid`),
  KEY `file_field__uri` (`uri`(191)),
  KEY `file_field__status` (`status`),
  KEY `file_field__changed` (`changed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for file entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `file_usage`
--

DROP TABLE IF EXISTS `file_usage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `file_usage` (
  `fid` int(10) unsigned NOT NULL COMMENT 'File ID.',
  `module` varchar(50) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The name of the module that is using the file.',
  `type` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The name of the object type in which the file is used.',
  `id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '0' COMMENT 'The primary key of the object using the file.',
  `count` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The number of times this file is used by this object.',
  PRIMARY KEY (`fid`,`type`,`id`,`module`),
  KEY `type_id` (`type`,`id`),
  KEY `fid_count` (`fid`,`count`),
  KEY `fid_module` (`fid`,`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Track where a file is used.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `history`
--

DROP TABLE IF EXISTS `history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `history` (
  `uid` int(11) NOT NULL DEFAULT 0 COMMENT 'The "users".uid that read the "node" nid.',
  `nid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "node".nid that was read.',
  `timestamp` int(11) NOT NULL DEFAULT 0 COMMENT 'The Unix timestamp at which the read occurred.',
  PRIMARY KEY (`uid`,`nid`),
  KEY `nid` (`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='A record of which "users" have read which "node"s.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `key_value`
--

DROP TABLE IF EXISTS `key_value`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `key_value` (
  `collection` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'A named collection of key and value pairs.',
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The key of the key-value pair. As KEY is a SQL reserved keyword, name was chosen instead.',
  `value` longblob NOT NULL COMMENT 'The value.',
  PRIMARY KEY (`collection`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Generic key-value storage table. See the state system for…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `key_value_expire`
--

DROP TABLE IF EXISTS `key_value_expire`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `key_value_expire` (
  `collection` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'A named collection of key and value pairs.',
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The key of the key/value pair.',
  `value` longblob NOT NULL COMMENT 'The value of the key/value pair.',
  `expire` int(11) NOT NULL DEFAULT 2147483647 COMMENT 'The time since Unix epoch in seconds when this item expires. Defaults to the maximum possible time.',
  PRIMARY KEY (`collection`,`name`),
  KEY `expire` (`expire`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Generic key/value storage table with an expiration.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_link_content`
--

DROP TABLE IF EXISTS `menu_link_content`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_link_content` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `revision_id` int(10) unsigned DEFAULT NULL,
  `bundle` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `menu_link_content_field__uuid__value` (`uuid`),
  UNIQUE KEY `menu_link_content__revision_id` (`revision_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for menu_link_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_link_content_data`
--

DROP TABLE IF EXISTS `menu_link_content_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_link_content_data` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `bundle` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `enabled` tinyint(4) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `menu_name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `link__uri` varchar(2048) DEFAULT NULL COMMENT 'The URI of the link.',
  `link__title` varchar(255) DEFAULT NULL COMMENT 'The link text.',
  `link__options` longblob DEFAULT NULL COMMENT 'Serialized array of options for the link.',
  `external` tinyint(4) DEFAULT NULL,
  `rediscover` tinyint(4) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `expanded` tinyint(4) DEFAULT NULL,
  `parent` varchar(255) DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`,`langcode`),
  KEY `menu_link_content__id__default_langcode__langcode` (`id`,`default_langcode`,`langcode`),
  KEY `menu_link_content__revision_id` (`revision_id`),
  KEY `menu_link_content_field__link__uri` (`link__uri`(30)),
  KEY `menu_link_content__enabled_bundle` (`enabled`,`bundle`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for menu_link_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_link_content_field_revision`
--

DROP TABLE IF EXISTS `menu_link_content_field_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_link_content_field_revision` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `enabled` tinyint(4) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `link__uri` varchar(2048) DEFAULT NULL COMMENT 'The URI of the link.',
  `link__title` varchar(255) DEFAULT NULL COMMENT 'The link text.',
  `link__options` longblob DEFAULT NULL COMMENT 'Serialized array of options for the link.',
  `external` tinyint(4) DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`,`langcode`),
  KEY `menu_link_content__id__default_langcode__langcode` (`id`,`default_langcode`,`langcode`),
  KEY `menu_link_content_field__link__uri` (`link__uri`(30))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision data table for menu_link_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_link_content_revision`
--

DROP TABLE IF EXISTS `menu_link_content_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_link_content_revision` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `revision_user` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `revision_created` int(11) DEFAULT NULL,
  `revision_log_message` longtext DEFAULT NULL,
  `revision_default` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`),
  KEY `menu_link_content__id` (`id`),
  KEY `menu_link_content__ef029a1897` (`revision_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision table for menu_link_content entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `menu_tree`
--

DROP TABLE IF EXISTS `menu_tree`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_tree` (
  `menu_name` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The menu name. All links with the same menu name (such as ''tools'') are part of the same menu.',
  `mlid` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'The menu link ID (mlid) is the integer primary key.',
  `id` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'Unique machine name: the plugin ID.',
  `parent` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The plugin ID for the parent of this link.',
  `route_name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL COMMENT 'The machine name of a defined Symfony Route this menu link represents.',
  `route_param_key` varchar(255) DEFAULT NULL COMMENT 'An encoded string of route parameters for loading by route.',
  `route_parameters` longblob DEFAULT NULL COMMENT 'Serialized array of route parameters of this menu link.',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT 'The external path this link points to (when not using a route).',
  `title` longblob DEFAULT NULL COMMENT 'The serialized title for the link. May be a TranslatableMarkup.',
  `description` longblob DEFAULT NULL COMMENT 'The serialized description of this link - used for admin pages and title attribute. May be a TranslatableMarkup.',
  `class` text DEFAULT NULL COMMENT 'The class for this link plugin.',
  `options` longblob DEFAULT NULL COMMENT 'A serialized array of URL options, such as a query string or HTML attributes.',
  `provider` varchar(50) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'system' COMMENT 'The name of the module that generated this link.',
  `enabled` smallint(6) NOT NULL DEFAULT 1 COMMENT 'A flag for whether the link should be rendered in menus. (0 = a disabled menu link that may be shown on admin screens, 1 = a normal, visible link)',
  `discovered` smallint(6) NOT NULL DEFAULT 0 COMMENT 'A flag for whether the link was discovered, so can be purged on rebuild',
  `expanded` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Flag for whether this link should be rendered as expanded in menus - expanded links always have their child links displayed, instead of only when the link is in the active trail (1 = expanded, 0 = not expanded)',
  `weight` int(11) NOT NULL DEFAULT 0 COMMENT 'Link weight among links in the same menu at the same depth.',
  `metadata` longblob DEFAULT NULL COMMENT 'A serialized array of data that may be used by the plugin instance.',
  `has_children` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Flag indicating whether any enabled links have this link as a parent (1 = enabled children exist, 0 = no enabled children).',
  `depth` smallint(6) NOT NULL DEFAULT 0 COMMENT 'The depth relative to the top level. A link with empty parent will have depth == 1.',
  `p1` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The first mlid in the materialized path. If N = depth, then pN must equal the mlid. If depth > 1 then p(N-1) must equal the parent link mlid. All pX where X > depth must equal zero. The columns p1 .. p9 are also called the parents.',
  `p2` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The second mlid in the materialized path. See p1.',
  `p3` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The third mlid in the materialized path. See p1.',
  `p4` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The fourth mlid in the materialized path. See p1.',
  `p5` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The fifth mlid in the materialized path. See p1.',
  `p6` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The sixth mlid in the materialized path. See p1.',
  `p7` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The seventh mlid in the materialized path. See p1.',
  `p8` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The eighth mlid in the materialized path. See p1.',
  `p9` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The ninth mlid in the materialized path. See p1.',
  `form_class` varchar(255) DEFAULT NULL COMMENT 'meh',
  PRIMARY KEY (`mlid`),
  UNIQUE KEY `id` (`id`),
  KEY `menu_parents` (`menu_name`,`p1`,`p2`,`p3`,`p4`,`p5`,`p6`,`p7`,`p8`,`p9`),
  KEY `menu_parent_expand_child` (`menu_name`,`expanded`,`has_children`,`parent`(16)),
  KEY `route_values` (`route_name`(32),`route_param_key`(16))
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Contains the menu tree hierarchy.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node`
--

DROP TABLE IF EXISTS `node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node` (
  `nid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vid` int(10) unsigned DEFAULT NULL,
  `type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`nid`),
  UNIQUE KEY `node_field__uuid__value` (`uuid`),
  UNIQUE KEY `node__vid` (`vid`),
  KEY `node_field__type__target_id` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for node entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node__body`
--

DROP TABLE IF EXISTS `node__body`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node__body` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `body_value` longtext NOT NULL,
  `body_summary` longtext DEFAULT NULL,
  `body_format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `body_format` (`body_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for node field body.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node__comment`
--

DROP TABLE IF EXISTS `node__comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node__comment` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `comment_status` int(11) NOT NULL DEFAULT 0 COMMENT 'Whether comments are allowed on this entity: 0 = no, 1 = closed (read only), 2 = open (read/write).',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for node field comment.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node__field_image`
--

DROP TABLE IF EXISTS `node__field_image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node__field_image` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `field_image_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the file entity.',
  `field_image_alt` varchar(512) DEFAULT NULL COMMENT 'Alternative image text, for the image''s ''alt'' attribute.',
  `field_image_title` varchar(1024) DEFAULT NULL COMMENT 'Image title text, for the image''s ''title'' attribute.',
  `field_image_width` int(10) unsigned DEFAULT NULL COMMENT 'The width of the image in pixels.',
  `field_image_height` int(10) unsigned DEFAULT NULL COMMENT 'The height of the image in pixels.',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `field_image_target_id` (`field_image_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for node field field_image.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node__field_tags`
--

DROP TABLE IF EXISTS `node__field_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node__field_tags` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `field_tags_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `field_tags_target_id` (`field_tags_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for node field field_tags.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_access`
--

DROP TABLE IF EXISTS `node_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_access` (
  `nid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "node".nid this record affects.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The "language".langcode of this node.',
  `fallback` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'Boolean indicating whether this record should be used as a fallback if a language condition is not provided.',
  `gid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The grant ID a user must possess in the specified realm to gain this row''s privileges on the node.',
  `realm` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The realm in which the user must possess the grant ID. Modules can define one or more realms by implementing hook_node_grants().',
  `grant_view` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean indicating whether a user with the realm/grant pair can view this node.',
  `grant_update` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean indicating whether a user with the realm/grant pair can edit this node.',
  `grant_delete` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'Boolean indicating whether a user with the realm/grant pair can delete this node.',
  PRIMARY KEY (`nid`,`gid`,`realm`,`langcode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Identifies which realm/grant pairs a user must possess in…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_field_data`
--

DROP TABLE IF EXISTS `node_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_field_data` (
  `nid` int(10) unsigned NOT NULL,
  `vid` int(10) unsigned NOT NULL,
  `type` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `uid` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  `title` varchar(255) NOT NULL,
  `created` int(11) NOT NULL,
  `changed` int(11) NOT NULL,
  `promote` tinyint(4) NOT NULL,
  `sticky` tinyint(4) NOT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`nid`,`langcode`),
  KEY `node__id__default_langcode__langcode` (`nid`,`default_langcode`,`langcode`),
  KEY `node__vid` (`vid`),
  KEY `node_field__type__target_id` (`type`),
  KEY `node_field__uid__target_id` (`uid`),
  KEY `node_field__created` (`created`),
  KEY `node_field__changed` (`changed`),
  KEY `node__status_type` (`status`,`type`,`nid`),
  KEY `node__frontpage` (`promote`,`status`,`sticky`,`created`),
  KEY `node__title_type` (`title`(191),`type`(4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for node entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_field_revision`
--

DROP TABLE IF EXISTS `node_field_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_field_revision` (
  `nid` int(10) unsigned NOT NULL,
  `vid` int(10) unsigned NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `uid` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  `title` varchar(255) DEFAULT NULL,
  `created` int(11) DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `promote` tinyint(4) DEFAULT NULL,
  `sticky` tinyint(4) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`vid`,`langcode`),
  KEY `node__id__default_langcode__langcode` (`nid`,`default_langcode`,`langcode`),
  KEY `node_field__uid__target_id` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision data table for node entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_revision`
--

DROP TABLE IF EXISTS `node_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_revision` (
  `nid` int(10) unsigned NOT NULL,
  `vid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `revision_uid` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `revision_timestamp` int(11) DEFAULT NULL,
  `revision_log` longtext DEFAULT NULL,
  `revision_default` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`vid`),
  KEY `node__nid` (`nid`),
  KEY `node_field__langcode` (`langcode`),
  KEY `node_field__revision_uid__target_id` (`revision_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision table for node entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_revision__body`
--

DROP TABLE IF EXISTS `node_revision__body`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_revision__body` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `body_value` longtext NOT NULL,
  `body_summary` longtext DEFAULT NULL,
  `body_format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `body_format` (`body_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for node field body.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_revision__comment`
--

DROP TABLE IF EXISTS `node_revision__comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_revision__comment` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `comment_status` int(11) NOT NULL DEFAULT 0 COMMENT 'Whether comments are allowed on this entity: 0 = no, 1 = closed (read only), 2 = open (read/write).',
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for node field comment.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_revision__field_image`
--

DROP TABLE IF EXISTS `node_revision__field_image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_revision__field_image` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `field_image_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the file entity.',
  `field_image_alt` varchar(512) DEFAULT NULL COMMENT 'Alternative image text, for the image''s ''alt'' attribute.',
  `field_image_title` varchar(1024) DEFAULT NULL COMMENT 'Image title text, for the image''s ''title'' attribute.',
  `field_image_width` int(10) unsigned DEFAULT NULL COMMENT 'The width of the image in pixels.',
  `field_image_height` int(10) unsigned DEFAULT NULL COMMENT 'The height of the image in pixels.',
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `field_image_target_id` (`field_image_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for node field field_image.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node_revision__field_tags`
--

DROP TABLE IF EXISTS `node_revision__field_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node_revision__field_tags` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `field_tags_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `field_tags_target_id` (`field_tags_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for node field field_tags.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `path_alias`
--

DROP TABLE IF EXISTS `path_alias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `path_alias` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `revision_id` int(10) unsigned DEFAULT NULL,
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `path` varchar(255) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `status` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `path_alias_field__uuid__value` (`uuid`),
  UNIQUE KEY `path_alias__revision_id` (`revision_id`),
  KEY `path_alias__status` (`status`,`id`),
  KEY `path_alias__alias_langcode_id_status` (`alias`(191),`langcode`,`id`,`status`),
  KEY `path_alias__path_langcode_id_status` (`path`(191),`langcode`,`id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for path_alias entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `path_alias_revision`
--

DROP TABLE IF EXISTS `path_alias_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `path_alias_revision` (
  `id` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `path` varchar(255) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `status` tinyint(4) NOT NULL,
  `revision_default` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`),
  KEY `path_alias__id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision table for path_alias entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `queue`
--

DROP TABLE IF EXISTS `queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `queue` (
  `item_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary Key: Unique item ID.',
  `name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The queue name.',
  `data` longblob DEFAULT NULL COMMENT 'The arbitrary data for the item.',
  `expire` int(11) NOT NULL DEFAULT 0 COMMENT 'Timestamp when the claim lease expires on the item.',
  `created` int(11) NOT NULL DEFAULT 0 COMMENT 'Timestamp when the item was created.',
  PRIMARY KEY (`item_id`),
  KEY `name_created` (`name`,`created`),
  KEY `expire` (`expire`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores items in queues.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `router`
--

DROP TABLE IF EXISTS `router`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `router` (
  `name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Primary Key: Machine name of this route',
  `path` varchar(255) NOT NULL DEFAULT '' COMMENT 'The path for this URI',
  `pattern_outline` varchar(255) NOT NULL DEFAULT '' COMMENT 'The pattern',
  `fit` int(11) NOT NULL DEFAULT 0 COMMENT 'A numeric representation of how specific the path is.',
  `route` longblob DEFAULT NULL COMMENT 'A serialized Route object',
  `number_parts` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Number of parts in this router path.',
  PRIMARY KEY (`name`),
  KEY `pattern_outline_parts` (`pattern_outline`(191),`number_parts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Maps paths to various callbacks (access, page and title)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search_dataset`
--

DROP TABLE IF EXISTS `search_dataset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_dataset` (
  `sid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Search item ID, e.g. node ID for nodes.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The "languages".langcode of the item variant.',
  `type` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'Type of item, e.g. node.',
  `data` longtext NOT NULL COMMENT 'List of space-separated words from the item.',
  `reindex` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Set to force node reindexing.',
  PRIMARY KEY (`sid`,`langcode`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores items that will be searched.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search_index`
--

DROP TABLE IF EXISTS `search_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_index` (
  `word` varchar(50) NOT NULL DEFAULT '' COMMENT 'The "search_total".word that is associated with the search item.',
  `sid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "search_dataset".sid of the searchable item to which the word belongs.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The "languages".langcode of the item variant.',
  `type` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The "search_dataset".type of the searchable item to which the word belongs.',
  `score` float DEFAULT NULL COMMENT 'The numeric score of the word, higher being more important.',
  PRIMARY KEY (`word`,`sid`,`langcode`,`type`),
  KEY `sid_type` (`sid`,`langcode`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores the search index, associating words, items and…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search_total`
--

DROP TABLE IF EXISTS `search_total`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_total` (
  `word` varchar(50) NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique word in the search index.',
  `count` float DEFAULT NULL COMMENT 'The count of the word in the index using Zipf''s law to equalize the probability distribution.',
  PRIMARY KEY (`word`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores search totals for words.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `semaphore`
--

DROP TABLE IF EXISTS `semaphore`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `semaphore` (
  `name` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Primary Key: Unique name.',
  `value` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'A value for the semaphore.',
  `expire` double NOT NULL COMMENT 'A Unix timestamp with microseconds indicating when the semaphore should expire.',
  PRIMARY KEY (`name`),
  KEY `value` (`value`),
  KEY `expire` (`expire`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Table for holding semaphores, locks, flags, etc. that…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sequences`
--

DROP TABLE IF EXISTS `sequences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sequences` (
  `value` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'The value of the sequence.',
  PRIMARY KEY (`value`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores IDs.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `uid` int(10) unsigned NOT NULL COMMENT 'The "users".uid corresponding to a session, or 0 for anonymous user.',
  `sid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'A session ID (hashed). The value is generated by Drupal''s session handlers.',
  `hostname` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The IP address that last used this session ID (sid).',
  `timestamp` int(11) NOT NULL DEFAULT 0 COMMENT 'The Unix timestamp when this session last requested a page. Old records are purged by PHP automatically.',
  `session` longblob DEFAULT NULL COMMENT 'The serialized contents of the user''s session, an array of name/value pairs that persists across page requests by this session ID. Drupal loads the user''s session from here at the start of each request and saves it at the end.',
  PRIMARY KEY (`sid`),
  KEY `timestamp` (`timestamp`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Drupal''s session handlers read and write into the sessions…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shortcut`
--

DROP TABLE IF EXISTS `shortcut`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shortcut` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `shortcut_set` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shortcut_field__uuid__value` (`uuid`),
  KEY `shortcut_field__shortcut_set__target_id` (`shortcut_set`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for shortcut entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shortcut_field_data`
--

DROP TABLE IF EXISTS `shortcut_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shortcut_field_data` (
  `id` int(10) unsigned NOT NULL,
  `shortcut_set` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `link__uri` varchar(2048) DEFAULT NULL COMMENT 'The URI of the link.',
  `link__title` varchar(255) DEFAULT NULL COMMENT 'The link text.',
  `link__options` longblob DEFAULT NULL COMMENT 'Serialized array of options for the link.',
  `default_langcode` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`,`langcode`),
  KEY `shortcut__id__default_langcode__langcode` (`id`,`default_langcode`,`langcode`),
  KEY `shortcut_field__shortcut_set__target_id` (`shortcut_set`),
  KEY `shortcut_field__link__uri` (`link__uri`(30))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for shortcut entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shortcut_set_users`
--

DROP TABLE IF EXISTS `shortcut_set_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shortcut_set_users` (
  `uid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "users".uid for this set.',
  `set_name` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The "shortcut_set".set_name that will be displayed for this user.',
  PRIMARY KEY (`uid`),
  KEY `set_name` (`set_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Maps users to shortcut sets.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_index`
--

DROP TABLE IF EXISTS `taxonomy_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_index` (
  `nid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "node".nid this record tracks.',
  `tid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The term ID.',
  `status` int(11) NOT NULL DEFAULT 1 COMMENT 'Boolean indicating whether the node is published (visible to non-administrators).',
  `sticky` tinyint(4) DEFAULT 0 COMMENT 'Boolean indicating whether the node is sticky.',
  `created` int(11) NOT NULL DEFAULT 0 COMMENT 'The Unix timestamp when the node was created.',
  PRIMARY KEY (`nid`,`tid`),
  KEY `term_node` (`tid`,`status`,`sticky`,`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Maintains denormalized information about node/term…';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term__parent`
--

DROP TABLE IF EXISTS `taxonomy_term__parent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term__parent` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `parent_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `revision_id` (`revision_id`),
  KEY `parent_target_id` (`parent_target_id`),
  KEY `bundle_delta_target_id` (`bundle`,`delta`,`parent_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for taxonomy_term field parent.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term_data`
--

DROP TABLE IF EXISTS `taxonomy_term_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term_data` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `revision_id` int(10) unsigned DEFAULT NULL,
  `vid` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`tid`),
  UNIQUE KEY `taxonomy_term_field__uuid__value` (`uuid`),
  UNIQUE KEY `taxonomy_term__revision_id` (`revision_id`),
  KEY `taxonomy_term_field__vid__target_id` (`vid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for taxonomy_term entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term_field_data`
--

DROP TABLE IF EXISTS `taxonomy_term_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term_field_data` (
  `tid` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `vid` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description__value` longtext DEFAULT NULL,
  `description__format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `weight` int(11) NOT NULL,
  `changed` int(11) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`tid`,`langcode`),
  KEY `taxonomy_term__id__default_langcode__langcode` (`tid`,`default_langcode`,`langcode`),
  KEY `taxonomy_term__revision_id` (`revision_id`),
  KEY `taxonomy_term_field__name` (`name`(191)),
  KEY `taxonomy_term__status_vid` (`status`,`vid`,`tid`),
  KEY `taxonomy_term__tree` (`vid`,`weight`,`name`(191)),
  KEY `taxonomy_term__vid_name` (`vid`,`name`(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for taxonomy_term entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term_field_revision`
--

DROP TABLE IF EXISTS `taxonomy_term_field_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term_field_revision` (
  `tid` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status` tinyint(4) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description__value` longtext DEFAULT NULL,
  `description__format` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `changed` int(11) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  `revision_translation_affected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`,`langcode`),
  KEY `taxonomy_term__id__default_langcode__langcode` (`tid`,`default_langcode`,`langcode`),
  KEY `taxonomy_term_field__description__format` (`description__format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision data table for taxonomy_term entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term_revision`
--

DROP TABLE IF EXISTS `taxonomy_term_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term_revision` (
  `tid` int(10) unsigned NOT NULL,
  `revision_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `revision_user` int(10) unsigned DEFAULT NULL COMMENT 'The ID of the target entity.',
  `revision_created` int(11) DEFAULT NULL,
  `revision_log_message` longtext DEFAULT NULL,
  `revision_default` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`revision_id`),
  KEY `taxonomy_term__tid` (`tid`),
  KEY `taxonomy_term_field__revision_user__target_id` (`revision_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The revision table for taxonomy_term entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxonomy_term_revision__parent`
--

DROP TABLE IF EXISTS `taxonomy_term_revision__parent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taxonomy_term_revision__parent` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `parent_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the target entity.',
  PRIMARY KEY (`entity_id`,`revision_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `parent_target_id` (`parent_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Revision archive storage for taxonomy_term field parent.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user__roles`
--

DROP TABLE IF EXISTS `user__roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user__roles` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to, which for an unversioned entity type is the same as the entity id',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `roles_target_id` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The ID of the target entity.',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `roles_target_id` (`roles_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for user field roles.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user__user_picture`
--

DROP TABLE IF EXISTS `user__user_picture`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user__user_picture` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to, which for an unversioned entity type is the same as the entity id',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `user_picture_target_id` int(10) unsigned NOT NULL COMMENT 'The ID of the file entity.',
  `user_picture_alt` varchar(512) DEFAULT NULL COMMENT 'Alternative image text, for the image''s ''alt'' attribute.',
  `user_picture_title` varchar(1024) DEFAULT NULL COMMENT 'Image title text, for the image''s ''title'' attribute.',
  `user_picture_width` int(10) unsigned DEFAULT NULL COMMENT 'The width of the image in pixels.',
  `user_picture_height` int(10) unsigned DEFAULT NULL COMMENT 'The height of the image in pixels.',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `user_picture_target_id` (`user_picture_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Data storage for user field user_picture.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `uid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  PRIMARY KEY (`uid`),
  UNIQUE KEY `user_field__uuid__value` (`uuid`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The base table for user entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_data`
--

DROP TABLE IF EXISTS `users_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_data` (
  `uid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "users".uid this record affects.',
  `module` varchar(50) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The name of the module declaring the variable.',
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The identifier of the data.',
  `value` longblob DEFAULT NULL COMMENT 'The value.',
  `serialized` tinyint(3) unsigned DEFAULT 0 COMMENT 'Whether value is serialized.',
  PRIMARY KEY (`uid`,`module`,`name`),
  KEY `module` (`module`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Stores module data as key/value pairs per user.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_field_data`
--

DROP TABLE IF EXISTS `users_field_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_field_data` (
  `uid` int(10) unsigned NOT NULL,
  `langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `preferred_langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `preferred_admin_langcode` varchar(12) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `name` varchar(60) NOT NULL,
  `pass` varchar(255) DEFAULT NULL,
  `mail` varchar(254) DEFAULT NULL,
  `timezone` varchar(32) DEFAULT NULL,
  `status` tinyint(4) DEFAULT NULL,
  `created` int(11) NOT NULL,
  `changed` int(11) DEFAULT NULL,
  `access` int(11) NOT NULL,
  `login` int(11) DEFAULT NULL,
  `init` varchar(254) DEFAULT NULL,
  `default_langcode` tinyint(4) NOT NULL,
  PRIMARY KEY (`uid`,`langcode`),
  UNIQUE KEY `user__name` (`name`,`langcode`),
  KEY `user__id__default_langcode__langcode` (`uid`,`default_langcode`,`langcode`),
  KEY `user_field__mail` (`mail`(191)),
  KEY `user_field__created` (`created`),
  KEY `user_field__access` (`access`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='The data table for user entities.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `watchdog`
--

DROP TABLE IF EXISTS `watchdog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `watchdog` (
  `wid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary Key: Unique watchdog event ID.',
  `uid` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'The "users".uid of the user who triggered the event.',
  `type` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Type of log message, for example "user" or "page not found."',
  `message` longtext NOT NULL COMMENT 'Text of log message to be passed into the t() function.',
  `variables` longblob NOT NULL COMMENT 'Serialized array of variables that match the message string and that is passed into the t() function.',
  `severity` tinyint(3) unsigned NOT NULL DEFAULT 0 COMMENT 'The severity level of the event. ranges from 0 (Emergency) to 7 (Debug)',
  `link` text DEFAULT NULL COMMENT 'Link to view the result of the event.',
  `location` text NOT NULL COMMENT 'URL of the origin of the event.',
  `referer` text DEFAULT NULL COMMENT 'URL of referring page.',
  `hostname` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'Hostname of the user who triggered the event.',
  `timestamp` int(11) NOT NULL DEFAULT 0 COMMENT 'Unix timestamp of when event occurred.',
  PRIMARY KEY (`wid`),
  KEY `type` (`type`),
  KEY `uid` (`uid`),
  KEY `severity` (`severity`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Table that contains logs of all system events.';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2023-10-11 14:38:35
