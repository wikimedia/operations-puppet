-- MySQL dump 10.15  Distrib 10.0.30-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: wikistats
-- ------------------------------------------------------
-- Server version	10.0.30-MariaDB-0+deb8u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `wikistats`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `wikistats` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `wikistats`;

--
-- Table structure for table `accwiki`
--

DROP TABLE IF EXISTS `accwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accwiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`url`)
) ENGINE=MyISAM AUTO_INCREMENT=3763 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `anarchopedias`
--

DROP TABLE IF EXISTS `anarchopedias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `anarchopedias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(64) DEFAULT NULL,
  `gettype` varchar(32) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=39 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `atwiki`
--

DROP TABLE IF EXISTS `atwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `atwiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `name` varchar(255) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=131 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `editthis`
--

DROP TABLE IF EXISTS `editthis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `editthis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `inactive` tinyint(4) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `prefix` varchar(64) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=43277 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `elwiki`
--

DROP TABLE IF EXISTS `elwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elwiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `longname` varchar(64) DEFAULT NULL,
  `inactive` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `longname` (`longname`)
) ENGINE=MyISAM AUTO_INCREMENT=590 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `extensions`
--

DROP TABLE IF EXISTS `extensions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `extensions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shortname` varchar(100) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1265 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fnord`
--

DROP TABLE IF EXISTS `fnord`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fnord` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=136 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gamepedias`
--

DROP TABLE IF EXISTS `gamepedias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gamepedias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `prefix` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=903 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gentoo`
--

DROP TABLE IF EXISTS `gentoo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gentoo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `prefix` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=3324 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gratiswiki`
--

DROP TABLE IF EXISTS `gratiswiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gratiswiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `longname` varchar(64) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `longname` (`longname`)
) ENGINE=MyISAM AUTO_INCREMENT=1236 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hyperwave`
--

DROP TABLE IF EXISTS `hyperwave`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hyperwave` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hexip` varchar(32) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `link` tinytext,
  `title` varchar(256) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `type` tinyint(4) DEFAULT NULL,
  `http` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=49 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `incubator`
--

DROP TABLE IF EXISTS `incubator`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `incubator` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `textstats` tinyint(4) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `feedurl` varchar(255) DEFAULT NULL,
  `rc_date` varchar(128) DEFAULT NULL,
  `rc_user` varchar(128) DEFAULT NULL,
  `rc_title` varchar(255) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `test_flag` tinyint(4) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `versionurl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=11376 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `interwiki`
--

DROP TABLE IF EXISTS `interwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `interwiki` (
  `iw_prefix` char(32) NOT NULL DEFAULT '',
  `iw_url` char(127) NOT NULL DEFAULT '',
  `iw_local` tinyint(1) NOT NULL DEFAULT '0',
  `iw_trans` tinyint(1) NOT NULL DEFAULT '0',
  UNIQUE KEY `iw_prefix` (`iw_prefix`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `langcodes`
--

DROP TABLE IF EXISTS `langcodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `langcodes` (
  `alpha3` char(3) DEFAULT NULL,
  `alpha3t` char(3) DEFAULT NULL,
  `alpha2` char(2) DEFAULT NULL,
  `namefr` varchar(255) DEFAULT NULL,
  `nameen` varchar(255) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `langlinks`
--

DROP TABLE IF EXISTS `langlinks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `langlinks` (
  `ll_from` int(8) unsigned NOT NULL DEFAULT '0',
  `ll_lang` varchar(10) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `ll_title` varchar(255) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  UNIQUE KEY `ll_from` (`ll_from`,`ll_lang`),
  KEY `ll_lang` (`ll_lang`,`ll_title`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lxde`
--

DROP TABLE IF EXISTS `lxde`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lxde` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(64) DEFAULT NULL,
  `gettype` varchar(32) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=14 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mediawikis`
--

DROP TABLE IF EXISTS `mediawikis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mediawikis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `feedurl` varchar(255) DEFAULT NULL,
  `rc_date` varchar(128) DEFAULT NULL,
  `rc_user` varchar(128) DEFAULT NULL,
  `rc_title` varchar(255) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `test_flag` tinyint(4) DEFAULT NULL,
  `versionurl` varchar(255) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_fallback` varchar(255) DEFAULT NULL,
  `si_misermode` varchar(255) DEFAULT NULL,
  `si_maxuploadsize` varchar(255) DEFAULT NULL,
  `si_rightscode` varchar(255) DEFAULT NULL,
  `si_readonly` varchar(255) DEFAULT NULL,
  `si_rtl` varchar(255) DEFAULT NULL,
  `si_readonlyreason` varchar(255) DEFAULT NULL,
  `lang` varchar(128) DEFAULT NULL,
  `loclang` varchar(255) DEFAULT NULL,
  `si_dbclass` varchar(255) DEFAULT NULL,
  `si_closed` varchar(255) DEFAULT NULL,
  `old_statsurl` varchar(255) DEFAULT NULL,
  `si_langconversion` varchar(255) DEFAULT NULL,
  `si_titleconversion` varchar(255) DEFAULT NULL,
  `si_linkprefix` varchar(255) DEFAULT NULL,
  `si_linktrail` varchar(255) DEFAULT NULL,
  `si_git-hash` varchar(255) DEFAULT NULL,
  `si_imagewhitelistenabled` varchar(255) DEFAULT NULL,
  `si_logo` varchar(255) DEFAULT NULL,
  `si_externalimages` varchar(255) DEFAULT NULL,
  `si_favicon` varchar(255) DEFAULT NULL,
  `si_linkprefixcharset` varchar(255) DEFAULT NULL,
  `si_legaltitlechars` varchar(255) DEFAULT NULL,
  `si_invalidusernamechars` varchar(255) DEFAULT NULL,
  `si_fixarabicunicode` varchar(255) DEFAULT NULL,
  `si_fixmalayalamunicode` varchar(255) DEFAULT NULL,
  `si_maxarticlesize` varchar(255) DEFAULT NULL,
  `si_servername` varchar(255) DEFAULT NULL,
  `si_uploadsenabled` varchar(255) DEFAULT NULL,
  `si_minuploadchunksize` varchar(255) DEFAULT NULL,
  `si_thumblimits` varchar(255) DEFAULT NULL,
  `si_imagelimits` varchar(255) DEFAULT NULL,
  `si_centralidlookupprovider` varchar(255) DEFAULT NULL,
  `si_allcentralidlookupproviders` varchar(255) DEFAULT NULL,
  `si_interwikimagic` varchar(255) DEFAULT NULL,
  `si_extensiondistributor` varchar(255) DEFAULT NULL,
  `si_hhvmversion` varchar(255) DEFAULT NULL,
  `si_git-branch` varchar(255) DEFAULT NULL,
  `si_variants` varchar(255) DEFAULT NULL,
  `si_fishbowl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=20238 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mediawikis_extensions`
--

DROP TABLE IF EXISTS `mediawikis_extensions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mediawikis_extensions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mediawikis_id` int(11) NOT NULL,
  `extensions_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3251 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `metapedias`
--

DROP TABLE IF EXISTS `metapedias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metapedias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `textstats` tinyint(4) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `feedurl` varchar(255) DEFAULT NULL,
  `rc_date` varchar(128) DEFAULT NULL,
  `rc_user` varchar(128) DEFAULT NULL,
  `rc_title` varchar(255) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `lang` varchar(255) DEFAULT NULL,
  `loclang` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=3592 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `miraheze`
--

DROP TABLE IF EXISTS `miraheze`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `miraheze` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `prefix` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=26338 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `neoseeker`
--

DROP TABLE IF EXISTS `neoseeker`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `neoseeker` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prefix` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `statsurl` tinytext,
  `inactive` tinyint(4) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=6196 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `opensuse`
--

DROP TABLE IF EXISTS `opensuse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `opensuse` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=730 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `quotes`
--

DROP TABLE IF EXISTS `quotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quotes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `quote` text CHARACTER SET ucs2,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=896 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `qweki`
--

DROP TABLE IF EXISTS `qweki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `qweki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=20 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `referata`
--

DROP TABLE IF EXISTS `referata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `referata` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prefix` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `statsurl` tinytext,
  `inactive` tinyint(4) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=56 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `richdex`
--

DROP TABLE IF EXISTS `richdex`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `richdex` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `prefix` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=259 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rodovid`
--

DROP TABLE IF EXISTS `rodovid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rodovid` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `s23`
--

DROP TABLE IF EXISTS `s23`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `s23` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2919 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scoutwiki`
--

DROP TABLE IF EXISTS `scoutwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scoutwiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=17 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shoutwiki`
--

DROP TABLE IF EXISTS `shoutwiki`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shoutwiki` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(64) DEFAULT NULL,
  `gettype` varchar(32) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `name` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=693 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `site_stats`
--

DROP TABLE IF EXISTS `site_stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `site_stats` (
  `ss_row_id` int(8) unsigned NOT NULL DEFAULT '0',
  `ss_total_views` bigint(20) unsigned DEFAULT '0',
  `ss_total_edits` bigint(20) unsigned DEFAULT '0',
  `ss_good_articles` bigint(20) unsigned DEFAULT '0',
  `ss_total_pages` bigint(20) DEFAULT '-1',
  `ss_users` bigint(20) DEFAULT '-1',
  `ss_admins` int(10) DEFAULT '-1',
  `ss_images` int(10) DEFAULT '0',
  `ss_active_users` bigint(20) DEFAULT '-1',
  UNIQUE KEY `ss_row_id` (`ss_row_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sourceforge`
--

DROP TABLE IF EXISTS `sourceforge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sourceforge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `prefix` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tasks` (
  `page_id` int(8) unsigned NOT NULL DEFAULT '0',
  `status` enum('!','1','2','3','','x') NOT NULL DEFAULT '',
  `owner` varchar(255) NOT NULL DEFAULT '',
  `summary` mediumtext NOT NULL,
  `hidden` enum('y','n') NOT NULL DEFAULT 'n',
  KEY `owner_idx` (`owner`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `uncyclomedia`
--

DROP TABLE IF EXISTS `uncyclomedia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `uncyclomedia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_fallback` varchar(255) DEFAULT NULL,
  `si_misermode` varchar(255) DEFAULT NULL,
  `si_maxuploadsize` varchar(255) DEFAULT NULL,
  `si_rightscode` varchar(255) DEFAULT NULL,
  `si_readonly` varchar(255) DEFAULT NULL,
  `si_rtl` varchar(255) DEFAULT NULL,
  `si_readonlyreason` varchar(255) DEFAULT NULL,
  `si_dbclass` varchar(255) DEFAULT NULL,
  `si_closed` varchar(255) DEFAULT NULL,
  `si_langconversion` varchar(255) DEFAULT NULL,
  `si_titleconversion` varchar(255) DEFAULT NULL,
  `si_linkprefix` varchar(255) DEFAULT NULL,
  `si_linktrail` varchar(255) DEFAULT NULL,
  `si_git-hash` varchar(255) DEFAULT NULL,
  `si_imagewhitelistenabled` varchar(255) DEFAULT NULL,
  `si_logo` varchar(255) DEFAULT NULL,
  `si_externalimages` varchar(255) DEFAULT NULL,
  `si_favicon` varchar(255) DEFAULT NULL,
  `si_linkprefixcharset` varchar(255) DEFAULT NULL,
  `lang` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`),
  UNIQUE KEY `statsurl` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=79 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `w3cwikis`
--

DROP TABLE IF EXISTS `w3cwikis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `w3cwikis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `prefix` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=179 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `werkstatt`
--

DROP TABLE IF EXISTS `werkstatt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `werkstatt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `added_ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `added_sc` varchar(64) DEFAULT NULL,
  `feedurl` varchar(255) DEFAULT NULL,
  `rc_date` varchar(128) DEFAULT NULL,
  `rc_user` varchar(128) DEFAULT NULL,
  `rc_title` varchar(255) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `test_flag` tinyint(4) DEFAULT NULL,
  `versionurl` varchar(255) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_fallback` varchar(255) DEFAULT NULL,
  `si_misermode` varchar(255) DEFAULT NULL,
  `si_maxuploadsize` varchar(255) DEFAULT NULL,
  `si_rightscode` varchar(255) DEFAULT NULL,
  `si_readonly` varchar(255) DEFAULT NULL,
  `si_rtl` varchar(255) DEFAULT NULL,
  `si_readonlyreason` varchar(255) DEFAULT NULL,
  `lang` varchar(128) DEFAULT NULL,
  `loclang` varchar(255) DEFAULT NULL,
  `si_dbclass` varchar(255) DEFAULT NULL,
  `si_closed` varchar(255) DEFAULT NULL,
  `old_statsurl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=1576 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikdotis`
--

DROP TABLE IF EXISTS `wikdotis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikdotis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `inactive` tinyint(4) DEFAULT NULL,
  `http` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=8443 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikia`
--

DROP TABLE IF EXISTS `wikia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prefix` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `statsurl` tinytext,
  `inactive` tinyint(4) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=505812 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikible`
--

DROP TABLE IF EXISTS `wikible`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikible` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `statsurl` varchar(255) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `textstats` tinyint(4) DEFAULT NULL,
  `mainurl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `statsurl` (`statsurl`),
  UNIQUE KEY `statsurl_2` (`statsurl`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=1307 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikibooks`
--

DROP TABLE IF EXISTS `wikibooks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikibooks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=231 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikifur`
--

DROP TABLE IF EXISTS `wikifur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikifur` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `mainurl` tinytext,
  `activeusers` int(11) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`),
  UNIQUE KEY `statsurl` (`statsurl`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikinews`
--

DROP TABLE IF EXISTS `wikinews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikinews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=35 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikipedias`
--

DROP TABLE IF EXISTS `wikipedias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikipedias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` text,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=318 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikiquotes`
--

DROP TABLE IF EXISTS `wikiquotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikiquotes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=352 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikisite`
--

DROP TABLE IF EXISTS `wikisite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikisite` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `inactive` tinyint(4) DEFAULT NULL,
  `speciallink` tinyint(1) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=22925 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikisources`
--

DROP TABLE IF EXISTS `wikisources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikisources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=75 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikistats`
--

DROP TABLE IF EXISTS `wikistats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikistats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `label` varchar(128) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `color` varchar(32) DEFAULT NULL,
  `linktype` tinyint(4) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=MyISAM AUTO_INCREMENT=158 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikitravel`
--

DROP TABLE IF EXISTS `wikitravel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikitravel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=22 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikiversity`
--

DROP TABLE IF EXISTS `wikiversity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikiversity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikivoyage`
--

DROP TABLE IF EXISTS `wikivoyage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikivoyage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wikkii`
--

DROP TABLE IF EXISTS `wikkii`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wikkii` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prefix` varchar(64) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) NOT NULL DEFAULT '0',
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `images` int(11) DEFAULT NULL,
  `statsurl` tinytext,
  `inactive` tinyint(4) DEFAULT NULL,
  `activeusers` int(255) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `method` tinyint(4) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=3269 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wiktionaries`
--

DROP TABLE IF EXISTS `wiktionaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wiktionaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `started` date DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `status` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=437 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wmspecials`
--

DROP TABLE IF EXISTS `wmspecials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wmspecials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lang` varchar(128) DEFAULT NULL,
  `prefix` varchar(16) DEFAULT NULL,
  `total` int(11) DEFAULT NULL,
  `good` int(11) DEFAULT NULL,
  `views` int(11) DEFAULT NULL,
  `edits` int(11) DEFAULT NULL,
  `users` int(11) DEFAULT NULL,
  `admins` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `loclang` varchar(128) DEFAULT NULL,
  `url` varchar(128) DEFAULT NULL,
  `images` int(11) DEFAULT NULL,
  `loclanglink` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `activeusers` int(11) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `statsurl` varchar(255) DEFAULT NULL,
  `inactive` tinyint(4) DEFAULT NULL,
  `http` smallint(6) DEFAULT NULL,
  `vurl` varchar(255) DEFAULT NULL,
  `si_mainpage` varchar(255) DEFAULT NULL,
  `si_base` varchar(255) DEFAULT NULL,
  `si_sitename` varchar(255) DEFAULT NULL,
  `si_generator` varchar(255) DEFAULT NULL,
  `si_phpversion` varchar(255) DEFAULT NULL,
  `si_phpsapi` varchar(255) DEFAULT NULL,
  `si_dbtype` varchar(255) DEFAULT NULL,
  `si_dbversion` varchar(255) DEFAULT NULL,
  `si_rev` varchar(255) DEFAULT NULL,
  `si_case` varchar(255) DEFAULT NULL,
  `si_rights` varchar(255) DEFAULT NULL,
  `si_lang` varchar(255) DEFAULT NULL,
  `si_fallback8bitEncoding` varchar(255) DEFAULT NULL,
  `si_writeapi` varchar(255) DEFAULT NULL,
  `si_timezone` varchar(255) DEFAULT NULL,
  `si_timeoffset` varchar(255) DEFAULT NULL,
  `si_articlepath` varchar(255) DEFAULT NULL,
  `si_scriptpath` varchar(255) DEFAULT NULL,
  `si_script` varchar(255) DEFAULT NULL,
  `si_variantarticlepath` varchar(255) DEFAULT NULL,
  `si_server` varchar(255) DEFAULT NULL,
  `si_wikiid` varchar(255) DEFAULT NULL,
  `si_time` varchar(255) DEFAULT NULL,
  `method` smallint(6) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `prefix` (`prefix`),
  UNIQUE KEY `prefix_2` (`prefix`)
) ENGINE=MyISAM AUTO_INCREMENT=136 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ws_usage_links`
--

DROP TABLE IF EXISTS `ws_usage_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ws_usage_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `listname` varchar(128) DEFAULT NULL,
  `prefix` varchar(128) DEFAULT NULL,
  `pagename` varchar(255) DEFAULT NULL,
  `active` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=119 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-05-16  1:51:36
