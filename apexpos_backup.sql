/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.3-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: apexpos
-- ------------------------------------------------------
-- Server version	11.8.6-MariaDB-0+deb13u1 from Debian

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `categories` VALUES
(1,'Beverages','2026-03-29 17:01:43'),
(2,'Food','2026-03-29 17:01:43'),
(3,'Dairy','2026-03-29 17:01:43'),
(4,'Personal Care','2026-03-29 17:01:43'),
(5,'Confectionery','2026-03-29 17:01:43'),
(7,'sweets','2026-04-02 11:22:10'),
(8,'Smoothie','2026-04-02 11:39:57'),
(9,'Sweet','2026-04-04 23:38:31'),
(10,'FanMilk','2026-04-04 23:38:58'),
(11,'beds','2026-04-04 23:39:15'),
(12,'fan','2026-04-07 12:41:50');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `customer_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `loyalty_points` int(11) NOT NULL DEFAULT 0,
  `total_spent` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_purchases` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`customer_id`),
  KEY `idx_phone` (`phone`),
  KEY `idx_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `customers` VALUES
(1,'Ama Owusu','+233244123456','ama@email.com','Kumasi, Ashanti',211,212.75,2,'2026-03-29 17:01:43','2026-04-01 12:32:37'),
(2,'Kwame Asante','+233201234567','kwame@email.com','Kumasi, Ashanti',41,41.98,1,'2026-03-29 17:01:43','2026-04-01 12:38:21');
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory` (
  `inventory_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `quantity_in_stock` int(11) NOT NULL DEFAULT 0,
  `low_stock_alert` int(11) NOT NULL DEFAULT 5,
  `last_restocked` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`inventory_id`),
  UNIQUE KEY `product_id` (`product_id`),
  CONSTRAINT `inventory_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory`
--

LOCK TABLES `inventory` WRITE;
/*!40000 ALTER TABLE `inventory` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `inventory` VALUES
(1,1,47,10,NULL,'2026-04-01 12:38:21'),
(2,2,118,20,NULL,'2026-04-05 15:36:22'),
(3,3,5,10,NULL,'2026-03-29 22:08:18'),
(4,4,33,5,NULL,'2026-04-02 13:00:19'),
(5,5,1,15,'2026-04-05 15:36:54','2026-04-07 12:53:52'),
(6,6,12,12,NULL,'2026-04-08 17:23:51'),
(7,7,11,5,NULL,'2026-04-01 12:38:37'),
(8,8,59,10,NULL,'2026-04-01 12:38:21'),
(9,9,77,20,NULL,'2026-04-05 11:14:14'),
(10,10,56,8,'2026-03-29 22:12:46','2026-03-29 22:12:46'),
(11,11,11,5,NULL,'2026-03-29 22:09:08'),
(12,12,149,30,NULL,'2026-03-29 22:08:47');
/*!40000 ALTER TABLE `inventory` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `inventory_adjustments`
--

DROP TABLE IF EXISTS `inventory_adjustments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_adjustments` (
  `adjustment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `adjustment_type` enum('sale','restock','adjustment','damage','return') NOT NULL,
  `quantity_change` int(11) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`adjustment_id`),
  KEY `product_id` (`product_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `inventory_adjustments_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `inventory_adjustments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_adjustments`
--

LOCK TABLES `inventory_adjustments` WRITE;
/*!40000 ALTER TABLE `inventory_adjustments` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `inventory_adjustments` VALUES
(1,10,7,'sale',-3,'Sale: TXN1774822075203','2026-03-29 22:07:55'),
(2,3,7,'sale',-1,'Sale: TXN1774822075203','2026-03-29 22:07:55'),
(3,2,7,'sale',-1,'Sale: TXN1774822075203','2026-03-29 22:07:55'),
(4,7,7,'sale',-1,'Sale: TXN1774822075203','2026-03-29 22:07:55'),
(5,9,7,'sale',-1,'Sale: TXN1774822075203','2026-03-29 22:07:55'),
(6,6,7,'sale',-1,'Sale: TXN1774822098508','2026-03-29 22:08:18'),
(7,3,7,'sale',-1,'Sale: TXN1774822098508','2026-03-29 22:08:18'),
(8,7,7,'sale',-1,'Sale: TXN1774822098508','2026-03-29 22:08:18'),
(9,10,7,'sale',-1,'Sale: TXN1774822116250','2026-03-29 22:08:36'),
(10,6,7,'sale',-7,'Sale: TXN1774822116250','2026-03-29 22:08:36'),
(11,12,7,'sale',-1,'Sale: TXN1774822127888','2026-03-29 22:08:47'),
(12,6,7,'sale',-1,'Sale: TXN1774822148065','2026-03-29 22:09:08'),
(13,11,7,'sale',-1,'Sale: TXN1774822148065','2026-03-29 22:09:08'),
(14,10,7,'restock',56,NULL,'2026-03-29 22:12:46'),
(15,6,16,'sale',-1,'Sale: TXN1775046520891','2026-04-01 12:28:40'),
(16,1,16,'sale',-1,'Sale: TXN1775046520891','2026-04-01 12:28:40'),
(17,6,16,'return',1,'Void: TXN1775046520891','2026-04-01 12:32:37'),
(18,1,16,'return',1,'Void: TXN1775046520891','2026-04-01 12:32:37'),
(19,1,18,'sale',-1,'Sale: TXN1775047101347','2026-04-01 12:38:21'),
(20,8,18,'sale',-1,'Sale: TXN1775047101347','2026-04-01 12:38:21'),
(21,4,18,'sale',-1,'Sale: TXN1775047101347','2026-04-01 12:38:21'),
(22,7,18,'sale',-5,'Sale: TXN1775047117640','2026-04-01 12:38:37'),
(23,2,25,'sale',-1,'Sale: TXN1775134819429','2026-04-02 13:00:19'),
(24,9,25,'sale',-1,'Sale: TXN1775134819429','2026-04-02 13:00:19'),
(25,4,25,'sale',-1,'Sale: TXN1775134819429','2026-04-02 13:00:19'),
(26,9,37,'sale',-1,'Sale: TXN1775387654523','2026-04-05 11:14:14'),
(27,2,40,'sale',-1,'Sale: TXN1775403255699','2026-04-05 15:34:15'),
(28,2,40,'return',1,'Void: TXN1775403255699','2026-04-05 15:36:22'),
(29,5,40,'restock',1,NULL,'2026-04-05 15:36:54'),
(30,5,70,'sale',-1,'Sale: TXN1775566248799','2026-04-07 12:50:48'),
(31,5,71,'return',1,'Void: TXN1775566248799','2026-04-07 12:53:52'),
(32,6,85,'sale',-1,'Sale: TXN1775669031518','2026-04-08 17:23:51');
/*!40000 ALTER TABLE `inventory_adjustments` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sale_id` int(10) unsigned NOT NULL,
  `payment_method` enum('cash','mobile','card') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `cash_tendered` decimal(10,2) DEFAULT NULL,
  `change_given` decimal(10,2) DEFAULT 0.00,
  `reference_no` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`payment_id`),
  KEY `idx_payment_sale` (`sale_id`),
  KEY `idx_payment_method` (`payment_method`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `payments` VALUES
(1,1,'card',58.99,NULL,0.00,NULL,'2026-03-29 22:07:55'),
(2,2,'mobile',60.95,NULL,0.00,NULL,'2026-03-29 22:08:18'),
(3,3,'mobile',151.80,NULL,0.00,NULL,'2026-03-29 22:08:36'),
(4,4,'mobile',1.15,NULL,0.00,NULL,'2026-03-29 22:08:47'),
(5,5,'cash',46.00,56.00,10.00,NULL,'2026-03-29 22:09:08'),
(6,6,'mobile',26.45,NULL,0.00,NULL,'2026-04-01 12:28:40'),
(7,7,'cash',41.98,NULL,0.00,NULL,'2026-04-01 12:38:21'),
(8,8,'card',184.00,NULL,0.00,NULL,'2026-04-01 12:38:37'),
(9,9,'mobile',36.80,NULL,0.00,NULL,'2026-04-02 13:00:19'),
(10,10,'card',0.86,NULL,0.00,NULL,'2026-04-05 11:14:14'),
(11,11,'cash',2.88,NULL,0.00,NULL,'2026-04-05 15:34:15'),
(12,12,'cash',4.60,5.00,0.40,NULL,'2026-04-07 12:50:48'),
(13,13,'cash',4.14,NULL,0.00,NULL,'2026-04-08 17:23:51');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `product_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_name` varchar(150) NOT NULL,
  `category_id` int(10) unsigned DEFAULT NULL,
  `supplier_id` int(10) unsigned DEFAULT NULL,
  `barcode` varchar(50) DEFAULT NULL,
  `selling_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `cost_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `emoji_icon` varchar(10) DEFAULT '?',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `barcode` (`barcode`),
  KEY `supplier_id` (`supplier_id`),
  KEY `idx_barcode` (`barcode`),
  KEY `idx_category` (`category_id`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE SET NULL,
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`supplier_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `products` VALUES
(1,'Coca Cola 500ml',1,1,'5000112637922',5.00,3.50,'🥤',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(2,'Indomie Chicken',2,2,'8992761150014',2.50,1.50,'🍜',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(3,'Fan Ice Vanilla',NULL,NULL,'6001007127006',3.00,2.00,'📦',1,'2026-03-29 17:01:43','2026-04-04 23:39:31'),
(4,'Milo 400g',2,2,'4800361210016',28.00,20.00,'🫙',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(5,'Voltic Water 1.5L',1,1,'6001007090002',4.00,2.50,'💧',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(6,'Cowbell Milk 400g',NULL,NULL,'8000700115078',18.00,13.00,'📦',1,'2026-03-29 17:01:43','2026-04-07 12:42:04'),
(7,'Uncle Ben Rice 2kg',2,2,'5010034003066',32.00,24.00,'🍚',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(8,'Geisha Soap',NULL,NULL,'6001007108097',3.50,2.00,'🧼',1,'2026-03-29 17:01:43','2026-04-01 12:49:25'),
(9,'Mentos Mint',5,5,'8000700181432',1.50,0.80,'🍬',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(10,'Cadbury Chocolate',NULL,NULL,'7622201720056',6.10,4.00,'📦',1,'2026-03-29 17:01:43','2026-04-07 12:42:14'),
(11,'Pampas Butter 250g',3,4,'6001007120014',22.00,16.00,'🧈',1,'2026-03-29 17:01:43','2026-03-29 17:01:43'),
(12,'Tom Tom Candy',5,5,'8000700012501',1.00,0.50,'🍭',1,'2026-03-29 17:01:43','2026-03-29 17:01:43');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `sale_items`
--

DROP TABLE IF EXISTS `sale_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sale_items` (
  `sale_item_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sale_id` int(10) unsigned NOT NULL,
  `product_id` int(10) unsigned NOT NULL,
  `product_name` varchar(150) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `unit_price` decimal(10,2) NOT NULL,
  `unit_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  `line_total` decimal(10,2) NOT NULL,
  PRIMARY KEY (`sale_item_id`),
  KEY `idx_sale` (`sale_id`),
  KEY `idx_product` (`product_id`),
  CONSTRAINT `sale_items_ibfk_1` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON DELETE CASCADE,
  CONSTRAINT `sale_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sale_items`
--

LOCK TABLES `sale_items` WRITE;
/*!40000 ALTER TABLE `sale_items` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `sale_items` VALUES
(1,1,10,'Cadbury Chocolate',3,6.00,4.00,18.00),
(2,1,3,'Fan Ice Vanilla',1,3.00,2.00,3.00),
(3,1,2,'Indomie Chicken',1,2.50,1.50,2.50),
(4,1,7,'Uncle Ben Rice 2kg',1,32.00,24.00,32.00),
(5,1,9,'Mentos Mint',1,1.50,0.80,1.50),
(6,2,6,'Cowbell Milk 400g',1,18.00,13.00,18.00),
(7,2,3,'Fan Ice Vanilla',1,3.00,2.00,3.00),
(8,2,7,'Uncle Ben Rice 2kg',1,32.00,24.00,32.00),
(9,3,10,'Cadbury Chocolate',1,6.00,4.00,6.00),
(10,3,6,'Cowbell Milk 400g',7,18.00,13.00,126.00),
(11,4,12,'Tom Tom Candy',1,1.00,0.50,1.00),
(12,5,6,'Cowbell Milk 400g',1,18.00,13.00,18.00),
(13,5,11,'Pampas Butter 250g',1,22.00,16.00,22.00),
(14,6,6,'Cowbell Milk 400g',1,18.00,13.00,18.00),
(15,6,1,'Coca Cola 500ml',1,5.00,3.50,5.00),
(16,7,1,'Coca Cola 500ml',1,5.00,3.50,5.00),
(17,7,8,'Geisha Soap',1,3.50,2.00,3.50),
(18,7,4,'Milo 400g',1,28.00,20.00,28.00),
(19,8,7,'Uncle Ben Rice 2kg',5,32.00,24.00,160.00),
(20,9,2,'Indomie Chicken',1,2.50,1.50,2.50),
(21,9,9,'Mentos Mint',1,1.50,0.80,1.50),
(22,9,4,'Milo 400g',1,28.00,20.00,28.00),
(23,10,9,'Mentos Mint',1,1.50,0.80,1.50),
(24,11,2,'Indomie Chicken',1,2.50,1.50,2.50),
(25,12,5,'Voltic Water 1.5L',1,4.00,2.50,4.00),
(26,13,6,'Cowbell Milk 400g',1,18.00,13.00,18.00);
/*!40000 ALTER TABLE `sale_items` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `sales`
--

DROP TABLE IF EXISTS `sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales` (
  `sale_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `transaction_ref` varchar(30) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `customer_id` int(10) unsigned DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_pct` decimal(5,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `sale_status` enum('completed','voided','refunded') NOT NULL DEFAULT 'completed',
  `notes` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`sale_id`),
  UNIQUE KEY `transaction_ref` (`transaction_ref`),
  KEY `customer_id` (`customer_id`),
  KEY `idx_transaction_ref` (`transaction_ref`),
  KEY `idx_sale_date` (`created_at`),
  KEY `idx_cashier` (`user_id`),
  CONSTRAINT `sales_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `sales_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales`
--

LOCK TABLES `sales` WRITE;
/*!40000 ALTER TABLE `sales` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `sales` VALUES
(1,'TXN1774822075203',7,NULL,57.00,10.00,5.70,7.69,58.99,'completed',NULL,'2026-03-29 22:07:55'),
(2,'TXN1774822098508',7,1,53.00,0.00,0.00,7.95,60.95,'completed',NULL,'2026-03-29 22:08:18'),
(3,'TXN1774822116250',7,1,132.00,0.00,0.00,19.80,151.80,'completed',NULL,'2026-03-29 22:08:36'),
(4,'TXN1774822127888',7,NULL,1.00,0.00,0.00,0.15,1.15,'completed',NULL,'2026-03-29 22:08:47'),
(5,'TXN1774822148065',7,NULL,40.00,0.00,0.00,6.00,46.00,'completed',NULL,'2026-03-29 22:09:08'),
(6,'TXN1775046520891',16,1,23.00,0.00,0.00,3.45,26.45,'voided','Customer request — by Admin User','2026-04-01 12:28:40'),
(7,'TXN1775047101347',18,2,36.50,0.00,0.00,5.47,41.98,'completed',NULL,'2026-04-01 12:38:21'),
(8,'TXN1775047117640',18,NULL,160.00,0.00,0.00,24.00,184.00,'completed',NULL,'2026-04-01 12:38:37'),
(9,'TXN1775134819429',25,NULL,32.00,0.00,0.00,4.80,36.80,'completed',NULL,'2026-04-02 13:00:19'),
(10,'TXN1775387654523',37,NULL,1.50,50.00,0.75,0.11,0.86,'completed',NULL,'2026-04-05 11:14:14'),
(11,'TXN1775403255699',40,NULL,2.50,0.00,0.00,0.38,2.88,'voided','Other — by Admin User','2026-04-05 15:34:15'),
(12,'TXN1775566248799',70,NULL,4.00,0.00,0.00,0.60,4.60,'voided','Manager override — by Grace Mensah','2026-04-07 12:50:48'),
(13,'TXN1775669031518',85,NULL,18.00,80.00,14.40,0.54,4.14,'completed',NULL,'2026-04-08 17:23:51');
/*!40000 ALTER TABLE `sales` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `suppliers` (
  `supplier_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suppliers`
--

LOCK TABLES `suppliers` WRITE;
/*!40000 ALTER TABLE `suppliers` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `suppliers` VALUES
(1,'Coca Cola GH','+233302000001',NULL,NULL,'2026-03-29 17:01:43'),
(2,'Nestle Ghana','+233302000002',NULL,NULL,'2026-03-29 17:01:43'),
(3,'Unilever GH','+233302000003',NULL,NULL,'2026-03-29 17:01:43'),
(4,'Promasidor','+233302000004',NULL,NULL,'2026-03-29 17:01:43'),
(5,'Perfetti','+233302000005',NULL,NULL,'2026-03-29 17:01:43');
/*!40000 ALTER TABLE `suppliers` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `transaction_logs`
--

DROP TABLE IF EXISTS `transaction_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_logs` (
  `log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `action` varchar(80) NOT NULL,
  `detail` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`log_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_log_date` (`created_at`),
  KEY `idx_log_action` (`action`),
  CONSTRAINT `transaction_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=116 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transaction_logs`
--

LOCK TABLES `transaction_logs` WRITE;
/*!40000 ALTER TABLE `transaction_logs` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `transaction_logs` VALUES
(1,NULL,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-03-29 21:41:22'),
(2,NULL,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-03-29 21:55:31'),
(3,7,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-03-29 22:05:58'),
(4,7,'Admin User','SALE','TXN1774822075203 | card | GHS 58.99',NULL,'2026-03-29 22:07:55'),
(5,7,'Admin User','SALE','TXN1774822098508 | mobile | GHS 60.95',NULL,'2026-03-29 22:08:18'),
(6,7,'Admin User','SALE','TXN1774822116250 | mobile | GHS 151.80',NULL,'2026-03-29 22:08:36'),
(7,7,'Admin User','SALE','TXN1774822127888 | mobile | GHS 1.15',NULL,'2026-03-29 22:08:47'),
(8,7,'Admin User','SALE','TXN1774822148065 | cash | GHS 46.00',NULL,'2026-03-29 22:09:08'),
(9,7,'Admin User','PRODUCT_UPDATE','Updated product ID: 10',NULL,'2026-03-29 22:09:35'),
(10,7,'Admin User','PRODUCT_UPDATE','Updated product ID: 3',NULL,'2026-03-29 22:10:41'),
(11,7,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-03-29 22:10:50'),
(12,7,'Admin User','PRODUCT_UPDATE','Updated product ID: 10',NULL,'2026-03-29 22:11:33'),
(13,7,'Admin User','RESTOCK','Product ID 10 +56',NULL,'2026-03-29 22:12:46'),
(14,9,'Kofi Asante','LOGIN','cashier signed in','::ffff:127.0.0.1','2026-03-29 22:13:25'),
(15,10,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-03-31 23:42:43'),
(16,10,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-01 00:05:20'),
(17,11,'Grace Mensah','LOGIN','manager signed in','::ffff:127.0.0.1','2026-04-01 00:05:37'),
(18,14,'Grace Mensah','LOGIN','manager signed in','::ffff:127.0.0.1','2026-04-01 00:09:50'),
(19,16,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-01 12:27:26'),
(20,16,'Admin User','SALE','TXN1775046520891 | mobile | GHS 26.45',NULL,'2026-04-01 12:28:40'),
(21,16,'Admin User','VOID','TXN1775046520891 | Reason: Customer request',NULL,'2026-04-01 12:32:37'),
(22,16,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-01 12:34:51'),
(23,17,'Grace Mensah','LOGIN','manager signed in','::ffff:127.0.0.1','2026-04-01 12:35:07'),
(24,17,'Grace Mensah','LOGOUT','manager signed out',NULL,'2026-04-01 12:36:14'),
(25,18,'Kofi Asante','LOGIN','cashier signed in','::ffff:127.0.0.1','2026-04-01 12:36:31'),
(26,18,'Kofi Asante','SALE','TXN1775047101347 | cash | GHS 41.98',NULL,'2026-04-01 12:38:21'),
(27,18,'Kofi Asante','SALE','TXN1775047117640 | card | GHS 184.00',NULL,'2026-04-01 12:38:37'),
(28,18,'Kofi Asante','LOGOUT','cashier signed out',NULL,'2026-04-01 12:38:48'),
(29,16,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-01 12:39:02'),
(30,16,'Admin User','PRODUCT_UPDATE','Updated product ID: 8',NULL,'2026-04-01 12:49:25'),
(31,16,'Admin User','PRODUCT_UPDATE','Updated product ID: 6',NULL,'2026-04-01 12:49:46'),
(32,16,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-01 12:59:46'),
(33,19,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-02 11:01:59'),
(34,19,'Admin User','PRODUCT_UPDATE','Updated product ID: 10',NULL,'2026-04-02 11:04:20'),
(35,19,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-02 11:04:29'),
(36,19,'Admin User','PRODUCT_UPDATE','Updated product ID: 10',NULL,'2026-04-02 11:05:02'),
(37,22,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-02 11:21:48'),
(38,22,'Admin User','PRODUCT_UPDATE','Updated: Cadbury Chocolate → category: sweets',NULL,'2026-04-02 11:22:10'),
(39,22,'Admin User','PRODUCT_UPDATE','Updated: Cadbury Chocolate → category: none',NULL,'2026-04-02 11:22:18'),
(40,22,'Admin User','PRODUCT_UPDATE','Updated: Fan Ice Vanilla → category: Smoothie',NULL,'2026-04-02 11:39:57'),
(41,22,'Admin User','PRODUCT_UPDATE','Updated: Fan Ice Vanilla → category: none',NULL,'2026-04-02 11:40:16'),
(42,25,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-02 12:59:15'),
(43,25,'Admin User','SALE','TXN1775134819429 | mobile | GHS 36.80',NULL,'2026-04-02 13:00:19'),
(44,25,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-02 13:00:33'),
(45,27,'Kofi Asante','LOGIN','cashier signed in','::ffff:127.0.0.1','2026-04-02 13:00:51'),
(46,27,'Kofi Asante','LOGOUT','cashier signed out',NULL,'2026-04-02 13:01:19'),
(47,26,'Grace Mensah','LOGIN','manager signed in','::ffff:127.0.0.1','2026-04-02 13:01:51'),
(48,26,'Grace Mensah','LOGOUT','manager signed out',NULL,'2026-04-02 13:02:22'),
(49,25,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-02 13:02:47'),
(50,28,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-04 15:35:07'),
(51,31,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-04 17:26:03'),
(52,31,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-04 17:49:29'),
(53,34,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-04 23:22:50'),
(54,34,'Admin User','PRODUCT_UPDATE','Updated: Cowbell Milk 400g → category: Dairy',NULL,'2026-04-04 23:38:17'),
(55,34,'Admin User','PRODUCT_UPDATE','Updated: Cowbell Milk 400g → category: Sweet',NULL,'2026-04-04 23:38:31'),
(56,34,'Admin User','PRODUCT_UPDATE','Updated: Fan Ice Vanilla → category: FanMilk',NULL,'2026-04-04 23:38:58'),
(57,34,'Admin User','PRODUCT_UPDATE','Updated: Fan Ice Vanilla → category: beds',NULL,'2026-04-04 23:39:15'),
(58,34,'Admin User','PRODUCT_UPDATE','Updated: Fan Ice Vanilla → category: none',NULL,'2026-04-04 23:39:31'),
(59,34,'Admin User','PRODUCT_UPDATE','Updated: Cowbell Milk 400g → category: none',NULL,'2026-04-04 23:39:36'),
(60,37,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-05 11:04:22'),
(61,37,'Admin User','MOMO_INITIATE','Vodafone Cash | GHS 0.86 | 233500000000 | ref: APEX-1775387083767-GMI141',NULL,'2026-04-05 11:04:47'),
(62,37,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.86 | 233553885362 | ref: APEX-1775387101034-VRGLHE',NULL,'2026-04-05 11:05:09'),
(63,37,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-05 11:07:34'),
(64,37,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.86 | 233553885362 | ref: APEX-1775387264911-LTM45X',NULL,'2026-04-05 11:08:26'),
(65,37,'Admin User','SALE','TXN1775387654523 | card | GHS 0.86',NULL,'2026-04-05 11:14:14'),
(66,37,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-05 11:15:21'),
(67,37,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.86 | 233553885362 | ref: APEX-1775387729595-HK63GQ',NULL,'2026-04-05 11:15:32'),
(68,40,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-05 15:29:05'),
(69,40,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.86 | 233553885362 | ref: APEX-1775402960109-GTF8Q5',NULL,'2026-04-05 15:29:21'),
(70,40,'Admin User','SALE','TXN1775403255699 | cash | GHS 2.88',NULL,'2026-04-05 15:34:15'),
(71,40,'Admin User','VOID','TXN1775403255699 | Reason: Other',NULL,'2026-04-05 15:36:22'),
(72,40,'Admin User','RESTOCK','Product ID 5 +1',NULL,'2026-04-05 15:36:54'),
(73,43,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 02:14:18'),
(74,43,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.52 | 2335553885362 | ref: APEX-1775441680095-NWR28L',NULL,'2026-04-06 02:14:46'),
(75,46,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 21:53:27'),
(76,46,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 21:55:48'),
(77,52,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 21:58:46'),
(78,55,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 22:26:10'),
(79,55,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.52 | 233553885362 | ref: APEX-1775514488674-DWT6Z2',NULL,'2026-04-06 22:28:16'),
(80,55,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 2.07 | 233553885362 | ref: APEX-1775515549400-9GUXLI',NULL,'2026-04-06 22:45:51'),
(81,58,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-06 22:58:15'),
(82,58,'Admin User','MOMO_INITIATE','Vodafone Cash | GHS 0.52 | 233509650027 | ref: APEX-1775516312247-6XPWUZ',NULL,'2026-04-06 22:58:34'),
(83,58,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.52 | 233553885362 | ref: APEX-1775516490932-U9B7EJ',NULL,'2026-04-06 23:01:32'),
(84,58,'Admin User','MOMO_INITIATE','Vodafone Cash | GHS 0.52 | 233509650027 | ref: APEX-1775516551150-FAYE97',NULL,'2026-04-06 23:02:32'),
(85,58,'Admin User','MOMO_INITIATE','Vodafone Cash | GHS 0.52 | 233509650027 | ref: APEX-1775516662831-JM51TM',NULL,'2026-04-06 23:04:24'),
(86,61,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 02:27:44'),
(87,61,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.52 | 233553885362 | ref: APEX-1775528929400-IQXVOA',NULL,'2026-04-07 02:28:50'),
(88,64,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 02:31:27'),
(89,67,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 02:47:18'),
(90,67,'Admin User','MOMO_INITIATE','Telecel Cash | GHS 0.52 | 233509650027 | ref: APEX-1775530060937-O49GF7',NULL,'2026-04-07 02:47:42'),
(91,67,'Admin User','MOMO_INITIATE','AirtelTigo Money | GHS 0.52 | 233266504304 | ref: APEX-1775530110185-3ISHZD',NULL,'2026-04-07 02:48:32'),
(92,70,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 12:36:03'),
(93,70,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.34 | 233553885362 | ref: APEX-1775565522983-GK6TCO',NULL,'2026-04-07 12:38:47'),
(94,70,'Admin User','PRODUCT_UPDATE','Updated: Cadbury Chocolate → category: none',NULL,'2026-04-07 12:39:58'),
(95,70,'Admin User','PRODUCT_UPDATE','Updated: Cadbury Chocolate → category: sweets',NULL,'2026-04-07 12:41:31'),
(96,70,'Admin User','PRODUCT_UPDATE','Updated: Cowbell Milk 400g → category: fan',NULL,'2026-04-07 12:41:50'),
(97,70,'Admin User','PRODUCT_UPDATE','Updated: Cowbell Milk 400g → category: none',NULL,'2026-04-07 12:42:04'),
(98,70,'Admin User','PRODUCT_UPDATE','Updated: Cadbury Chocolate → category: none',NULL,'2026-04-07 12:42:14'),
(99,70,'Admin User','SALE','TXN1775566248799 | cash | GHS 4.60',NULL,'2026-04-07 12:50:48'),
(100,70,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-07 12:52:48'),
(101,71,'Grace Mensah','LOGIN','manager signed in','::ffff:127.0.0.1','2026-04-07 12:53:09'),
(102,71,'Grace Mensah','VOID','TXN1775566248799 | Reason: Manager override',NULL,'2026-04-07 12:53:52'),
(103,71,'Grace Mensah','LOGOUT','manager signed out',NULL,'2026-04-07 13:08:20'),
(104,72,'Kofi Asante','LOGIN','cashier signed in','::ffff:127.0.0.1','2026-04-07 13:09:50'),
(105,72,'Kofi Asante','LOGOUT','cashier signed out',NULL,'2026-04-07 13:11:46'),
(106,70,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 13:12:02'),
(107,73,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-07 16:50:14'),
(108,85,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-08 17:09:36'),
(109,85,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.34 | 233553885362 | ref: APEX-1775668749526-H1KHAK',NULL,'2026-04-08 17:19:13'),
(110,85,'Admin User','MOMO_INITIATE','Telecel Cash | GHS 0.34 | 233509650027 | ref: APEX-1775668776565-ARH1KO',NULL,'2026-04-08 17:19:38'),
(111,85,'Admin User','SALE','TXN1775669031518 | cash | GHS 4.14',NULL,'2026-04-08 17:23:51'),
(112,88,'Admin User','LOGIN','admin signed in','::ffff:127.0.0.1','2026-04-09 03:53:38'),
(113,88,'Admin User','MOMO_INITIATE','MTN Mobile Money | GHS 0.17 | 233553885362 | ref: APEX-1775706943589-X5K1VQ',NULL,'2026-04-09 03:55:46'),
(114,88,'Admin User','MOMO_INITIATE','Telecel Cash | GHS 0.17 | 233509650027 | ref: APEX-1775706968321-RD2M6A',NULL,'2026-04-09 03:56:09'),
(115,88,'Admin User','LOGOUT','admin signed out',NULL,'2026-04-09 04:17:48');
/*!40000 ALTER TABLE `transaction_logs` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','manager','cashier') NOT NULL DEFAULT 'cashier',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `users` VALUES
(88,'Admin User','admin','$2b$10$Yj.GmNDp7HpdZqA94krkWeWfFHic4SCfI61KXkLrbQOj8RPdUQ.P2','admin',1,'2026-04-09 03:53:38','2026-04-09 03:53:21','2026-04-09 03:53:38'),
(89,'Grace Mensah','manager','$2b$10$NbDGR8HAgNyw5HiR83SKD.ybHlifY0XNmUfqkOsvvwg1hSZIxkLs2','manager',1,NULL,'2026-04-09 03:53:21','2026-04-09 03:53:21'),
(90,'Kofi Asante','cashier','$2b$10$1kl8jYuNC7Gexp0fGwkw5eZRsRSuueYDxKl8YjpTMKDGva2IaOOcW','cashier',1,NULL,'2026-04-09 03:53:21','2026-04-09 03:53:21');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
commit;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-04-09  4:47:33
