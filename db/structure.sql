-- MySQL dump 10.13  Distrib 5.5.29, for osx10.8 (i386)
--
-- Host: localhost    Database: krazychat_dev
-- ------------------------------------------------------
-- Server version	5.5.29

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
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `password_digest` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `facebook_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `time_zone` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `time_zone_offset` mediumint(9) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_accounts_on_user_id` (`user_id`),
  UNIQUE KEY `index_accounts_on_facebook_id` (`facebook_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `android_devices`
--

DROP TABLE IF EXISTS `android_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `android_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` char(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `device_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `client_version` varchar(5) COLLATE utf8_unicode_ci NOT NULL,
  `os_version` varchar(5) COLLATE utf8_unicode_ci NOT NULL,
  `registration_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_android_devices_on_device_id` (`device_id`),
  KEY `index_android_devices_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `avatar_images`
--

DROP TABLE IF EXISTS `avatar_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `avatar_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `image` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_avatar_images_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `avatar_videos`
--

DROP TABLE IF EXISTS `avatar_videos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `avatar_videos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `video` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_avatar_videos_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `emails`
--

DROP TABLE IF EXISTS `emails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `emails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `user_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `hashed_email` char(64) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_emails_on_email` (`email`),
  UNIQUE KEY `index_emails_on_hashed_email` (`hashed_email`),
  KEY `index_emails_on_account_id` (`account_id`),
  KEY `index_emails_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `emoticons`
--

DROP TABLE IF EXISTS `emoticons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `emoticons` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `image` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `local_file_path` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `sha1` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `group_avatar_images`
--

DROP TABLE IF EXISTS `group_avatar_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group_avatar_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `creator_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `image` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_group_avatar_images_on_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `group_wallpaper_images`
--

DROP TABLE IF EXISTS `group_wallpaper_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group_wallpaper_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `creator_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `image` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_group_wallpaper_images_on_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `creator_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `join_code` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `topic` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_groups_on_join_code` (`join_code`),
  KEY `index_groups_on_creator_id` (`creator_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `incoming_texts`
--

DROP TABLE IF EXISTS `incoming_texts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `incoming_texts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `raw_body` text COLLATE utf8_unicode_ci,
  `from` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `recipient` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `text` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `callback_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `error_code` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invites`
--

DROP TABLE IF EXISTS `invites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `recipient_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `invited_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invited_phone` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `new_user` tinyint(1) NOT NULL,
  `can_log_in` tinyint(1) NOT NULL,
  `group_id` char(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invite_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `clicked` tinyint(1) NOT NULL DEFAULT '0',
  `skip_sending` tinyint(1) NOT NULL DEFAULT '0',
  `source` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_invites_on_sender_id` (`sender_id`),
  KEY `index_invites_on_recipient_id` (`recipient_id`),
  KEY `index_invites_on_group_id` (`group_id`),
  KEY `index_invites_on_invite_token` (`invite_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ios_devices`
--

DROP TABLE IF EXISTS `ios_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ios_devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` char(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `device_id` char(32) COLLATE utf8_unicode_ci NOT NULL,
  `client_version` varchar(5) COLLATE utf8_unicode_ci NOT NULL,
  `os_version` varchar(5) COLLATE utf8_unicode_ci NOT NULL,
  `push_token` char(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_ios_devices_on_device_id` (`device_id`),
  KEY `index_ios_devices_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `message_attachments`
--

DROP TABLE IF EXISTS `message_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `message_attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` char(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `one_to_one_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message_id` char(10) COLLATE utf8_unicode_ci NOT NULL,
  `attachment` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `media_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `content_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `file_size` int(11) NOT NULL,
  `preview_width` int(11) DEFAULT NULL,
  `preview_height` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_message_attachments_on_group_id` (`group_id`),
  KEY `index_message_attachments_on_message_id` (`message_id`),
  KEY `index_message_attachments_on_one_to_one_id` (`one_to_one_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `one_to_one_wallpaper_images`
--

DROP TABLE IF EXISTS `one_to_one_wallpaper_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `one_to_one_wallpaper_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `image` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_one_to_one_wallpaper_images_on_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phones`
--

DROP TABLE IF EXISTS `phones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `user_id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `number` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `hashed_number` char(64) COLLATE utf8_unicode_ci NOT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT '0',
  `unsubscribed` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `verification_code` char(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_phones_on_number` (`number`),
  UNIQUE KEY `index_phones_on_hashed_number` (`hashed_number`),
  KEY `index_phones_on_account_id` (`account_id`),
  KEY `index_phones_on_user_id` (`user_id`),
  KEY `index_phones_on_verified` (`verified`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rpush_apps`
--

DROP TABLE IF EXISTS `rpush_apps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rpush_apps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `environment` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `certificate` text COLLATE utf8_unicode_ci,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `connections` int(11) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `auth_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `client_secret` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `access_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `access_token_expiration` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rpush_feedback`
--

DROP TABLE IF EXISTS `rpush_feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rpush_feedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device_token` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `failed_at` datetime NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `app` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rpush_feedback_on_device_token` (`device_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rpush_notifications`
--

DROP TABLE IF EXISTS `rpush_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rpush_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `badge` int(11) DEFAULT NULL,
  `device_token` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sound` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'default',
  `alert` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `expiry` int(11) DEFAULT '86400',
  `delivered` tinyint(1) NOT NULL DEFAULT '0',
  `delivered_at` datetime DEFAULT NULL,
  `failed` tinyint(1) NOT NULL DEFAULT '0',
  `failed_at` datetime DEFAULT NULL,
  `error_code` int(11) DEFAULT NULL,
  `error_description` text COLLATE utf8_unicode_ci,
  `deliver_after` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `alert_is_json` tinyint(1) DEFAULT '0',
  `type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `collapse_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `delay_while_idle` tinyint(1) NOT NULL DEFAULT '0',
  `registration_ids` mediumtext COLLATE utf8_unicode_ci,
  `app_id` int(11) NOT NULL,
  `retries` int(11) DEFAULT '0',
  `uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fail_after` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rapns_notifications_multi` (`app_id`,`delivered`,`failed`,`deliver_after`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` char(8) COLLATE utf8_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `username` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `status` enum('available','away','do_not_disturb') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'available',
  `status_text` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deactivated` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-04-08 16:49:25
INSERT INTO schema_migrations (version) VALUES ('20131001192546');

INSERT INTO schema_migrations (version) VALUES ('20131002214704');

INSERT INTO schema_migrations (version) VALUES ('20131003153120');

INSERT INTO schema_migrations (version) VALUES ('20131003162500');

INSERT INTO schema_migrations (version) VALUES ('20131003205039');

INSERT INTO schema_migrations (version) VALUES ('20131004155252');

INSERT INTO schema_migrations (version) VALUES ('20131008223611');

INSERT INTO schema_migrations (version) VALUES ('20131009162525');

INSERT INTO schema_migrations (version) VALUES ('20131009193925');

INSERT INTO schema_migrations (version) VALUES ('20131015143647');

INSERT INTO schema_migrations (version) VALUES ('20131029141942');

INSERT INTO schema_migrations (version) VALUES ('20131029165608');

INSERT INTO schema_migrations (version) VALUES ('20131106205908');

INSERT INTO schema_migrations (version) VALUES ('20131111204037');

INSERT INTO schema_migrations (version) VALUES ('20131112200132');

INSERT INTO schema_migrations (version) VALUES ('20131114141853');

INSERT INTO schema_migrations (version) VALUES ('20131114201706');

INSERT INTO schema_migrations (version) VALUES ('20131114221959');

INSERT INTO schema_migrations (version) VALUES ('20131118153325');

INSERT INTO schema_migrations (version) VALUES ('20131119131536');

INSERT INTO schema_migrations (version) VALUES ('20131119132207');

INSERT INTO schema_migrations (version) VALUES ('20131119165021');

INSERT INTO schema_migrations (version) VALUES ('20131119171612');

INSERT INTO schema_migrations (version) VALUES ('20131119195654');

INSERT INTO schema_migrations (version) VALUES ('20131119200729');

INSERT INTO schema_migrations (version) VALUES ('20131119231201');

INSERT INTO schema_migrations (version) VALUES ('20131121152559');

INSERT INTO schema_migrations (version) VALUES ('20131121184910');

INSERT INTO schema_migrations (version) VALUES ('20131125152955');

INSERT INTO schema_migrations (version) VALUES ('20131126173444');

INSERT INTO schema_migrations (version) VALUES ('20131129203308');

INSERT INTO schema_migrations (version) VALUES ('20131202142335');

INSERT INTO schema_migrations (version) VALUES ('20131202165559');

INSERT INTO schema_migrations (version) VALUES ('20131202165600');

INSERT INTO schema_migrations (version) VALUES ('20131202165601');

INSERT INTO schema_migrations (version) VALUES ('20131202165602');

INSERT INTO schema_migrations (version) VALUES ('20131202165603');

INSERT INTO schema_migrations (version) VALUES ('20131202165604');

INSERT INTO schema_migrations (version) VALUES ('20131203201851');

INSERT INTO schema_migrations (version) VALUES ('20131206171513');

INSERT INTO schema_migrations (version) VALUES ('20131209235938');

INSERT INTO schema_migrations (version) VALUES ('20131217172934');

INSERT INTO schema_migrations (version) VALUES ('20131220132745');

INSERT INTO schema_migrations (version) VALUES ('20131220144240');

INSERT INTO schema_migrations (version) VALUES ('20140103212016');

INSERT INTO schema_migrations (version) VALUES ('20140109190320');

INSERT INTO schema_migrations (version) VALUES ('20140109192600');

INSERT INTO schema_migrations (version) VALUES ('20140117145107');

INSERT INTO schema_migrations (version) VALUES ('20140120202824');

INSERT INTO schema_migrations (version) VALUES ('20140121153729');

INSERT INTO schema_migrations (version) VALUES ('20140128220106');

INSERT INTO schema_migrations (version) VALUES ('20140129153001');

INSERT INTO schema_migrations (version) VALUES ('20140130183911');

INSERT INTO schema_migrations (version) VALUES ('20140130222415');

INSERT INTO schema_migrations (version) VALUES ('20140131164058');

INSERT INTO schema_migrations (version) VALUES ('20140203154504');

INSERT INTO schema_migrations (version) VALUES ('20140212154758');

INSERT INTO schema_migrations (version) VALUES ('20140212182237');

INSERT INTO schema_migrations (version) VALUES ('20140213224056');

INSERT INTO schema_migrations (version) VALUES ('20140214050049');

INSERT INTO schema_migrations (version) VALUES ('20140214050050');

INSERT INTO schema_migrations (version) VALUES ('20140214050051');

INSERT INTO schema_migrations (version) VALUES ('20140214050052');

INSERT INTO schema_migrations (version) VALUES ('20140224203738');

INSERT INTO schema_migrations (version) VALUES ('20140226155522');

INSERT INTO schema_migrations (version) VALUES ('20140228164658');

INSERT INTO schema_migrations (version) VALUES ('20140306223147');

INSERT INTO schema_migrations (version) VALUES ('20140307154517');

INSERT INTO schema_migrations (version) VALUES ('20140312155807');

INSERT INTO schema_migrations (version) VALUES ('20140408204911');
