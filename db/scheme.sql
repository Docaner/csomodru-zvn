-- MySQL dump 10.13  Distrib 8.0.19, for Win64 (x86_64)
--
-- Host: 46.174.49.142    Database: s1_csomain
-- ------------------------------------------------------
-- Server version	5.5.5-10.11.4-MariaDB-1~deb12u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `questprogress`
--

DROP TABLE IF EXISTS `questprogress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `questprogress` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `UserID` int(10) unsigned NOT NULL,
  `QuestKey` varchar(32) DEFAULT NULL,
  `StartTime` datetime DEFAULT NULL,
  `EndTime` datetime DEFAULT NULL,
  `Progress` int(11) DEFAULT NULL,
  `Complete` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  KEY `questprogress_foregin_idx` (`UserID`),
  CONSTRAINT `questprogress_foregin` FOREIGN KEY (`UserID`) REFERENCES `user` (`ID`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=231508 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `SteamID` varchar(32) NOT NULL,
  `LastName` varchar(32) DEFAULT NULL,
  `LastIP` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `user_unique` (`SteamID`)
) ENGINE=InnoDB AUTO_INCREMENT=47124 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `zombiedata`
--

DROP TABLE IF EXISTS `zombiedata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `zombiedata` (
  `UserID` int(10) unsigned NOT NULL,
  `Money` int(11) DEFAULT NULL,
  `Ammo` int(11) DEFAULT NULL,
  `MKey` int(11) DEFAULT NULL,
  `AKey` int(11) DEFAULT NULL,
  `Experience` int(11) DEFAULT NULL,
  `ZClass` int(11) DEFAULT NULL,
  `Knife` int(11) DEFAULT NULL,
  `SkinKey` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`UserID`),
  CONSTRAINT `zombiedata_forieng` FOREIGN KEY (`UserID`) REFERENCES `user` (`ID`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Dumping routines for database 's1_csomain'
--
/*!50003 DROP PROCEDURE IF EXISTS `zp_login_quests` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `zp_login_quests`(
	#Идентификатор пользователя
	uID INT UNSIGNED,
	/*
	Квесты по умолчанию, если нет доступных
	quest - номер квеста
	days - за какое количество дней необходимо выполнить
	[{questKey:"nigers", days:2},{...},...]
	*/
	quests VARCHAR(512)
)
BEGIN
	DECLARE nums INT DEFAULT 0;
	
	DECLARE i INT DEFAULT 0;
	DECLARE obj VARCHAR(128);
	DECLARE len INT;
	DECLARE questString VARCHAR(32);
	DECLARE days INT;
	
	DECLARE today DATETIME DEFAULT NOW();
	DECLARE endday DATETIME DEFAULT today;
    
	#Количество активных квестов
   SELECT COUNT(*) INTO nums FROM questprogress WHERE UserID = uID AND today < EndTime; 
   
	IF nums <= 0 THEN
		SELECT JSON_LENGTH(quests) INTO len;
		
		#Если не определилась длина
		IF !len THEN
			ROLLBACK;
		END IF;
		
		WHILE i < len DO
			#Извлекаем конец даты
			SELECT JSON_EXTRACT(quests,CONCAT('$[',i,']')) INTO obj;
			SELECT JSON_UNQUOTE(JSON_EXTRACT(obj, "$.questKey")) INTO questString;
			SELECT JSON_EXTRACT(obj, "$.days") INTO days;
			
			#вычисляем конец даты
			SELECT ADDDATE(today, INTERVAL days DAY) INTO endday;
			##Вставляем записи
			INSERT INTO questprogress (UserID, QuestKey, StartTime, EndTime, Progress, Complete) VALUE (uID, questString, today, endday, 0, FALSE);
			SELECT i + 1 INTO i;
		END WHILE;
	END IF; 
	
	#Вывод квестов                                                         
	SELECT 
		ID, 
		QuestKey,
		DATE_FORMAT(StartTime, "%d.%m (%H:%i)") AS StartTime, 
		DATE_FORMAT(EndTime, "%d.%m (%H:%i)") AS EndTime, 
		Progress,
		Complete
	FROM questprogress WHERE UserID = uID AND today < EndTime; 
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `zp_login_user` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `zp_login_user`(
	SteamID VARCHAR(32),
	LastIP VARCHAR(15),
	LastName VARCHAR(32), 
	Money INT,
	Ammo INT,
	MKey INT,
	AKey INT,
	Experience INT,
	ZClass INT,
	Knife INT,
	SkinKey VARCHAR(32)
)
BEGIN
	DECLARE UserID INT UNSIGNED DEFAULT 0;
    
   #Поиск игрока
   SELECT user.ID INTO UserID FROM user WHERE user.SteamID = SteamID LIMIT 1;
    
   #Если игрок не зарегистрированн
	IF !UserID THEN
		#Вставка нового пользователя
		INSERT INTO user (user.SteamID, user.LastIP, user.LastName) VALUES (SteamID, LastIP, LastName);
      #Последний вставленый id
      SELECT LAST_INSERT_ID() INTO UserID;
      #Сохранение первичных данных для нового пользователя
      INSERT INTO zombiedata VALUES (UserID, Money, Ammo, MKey, AKey, Experience, ZClass, Knife, SkinKey);
   ELSE
   	UPDATE user SET user.LastIP = LastIP, user.LastName = LastName WHERE user.ID = UserID;
	END IF;
    
   SELECT * FROM zombiedata WHERE zombiedata.UserID = UserID;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `zp_set_quest` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `zp_set_quest`(
	qID INT UNSIGNED,
	qKey VARCHAR(32),
	qProgress INT,	
	qComplete TINYINT(1)
)
BEGIN
	UPDATE questprogress SET Progress = qProgress, Complete = qComplete, QuestKey = qKey WHERE ID = qID;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `zp_set_zombiedata` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `zp_set_zombiedata`(
	UserID INT UNSIGNED,
	LastIP VARCHAR(15),
	LastName VARCHAR(32), 
	Money INT,
	Ammo INT,
	MKey INT,
	AKey INT,
	Experience INT,
	ZClass INT,
	Knife INT,
	SkinKey VARCHAR(32)
)
BEGIN
	UPDATE user SET user.LastIP = LastIP, user.LastName = LastName WHERE user.ID = UserID;
	REPLACE INTO zombiedata VALUE (UserID, Money, Ammo, MKey, AKey, Experience, ZClass, Knife, SkinKey);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-08  8:08:12
