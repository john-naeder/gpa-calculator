-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: mysql
-- Generation Time: Feb 23, 2025 at 01:30 PM
-- Server version: 5.7.44
-- PHP Version: 8.2.23

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `GPA`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`%` PROCEDURE `Over_All_Term` ()   BEGIN
    DECLARE i INT DEFAULT 1;

    CREATE TEMPORARY TABLE all_term (
        `term` VARCHAR(7),
        `Credits` INT,
        `10_point_scale` DECIMAL(10,2),
        `4_point_scale` DECIMAL(10,2),
        `Letter_grade` VARCHAR(2),
        `Classification` VARCHAR(10)
    );

    WHILE (i < 6) DO
        INSERT INTO all_term (
            term, 
            `Credits`,
            `10_point_scale`, 
            `4_point_scale`, 
            `Letter_grade`, 
            `Classification`
        )
        VALUES (
            i, 
            F_Tong_TC_term(i),
            F_GPA_He10_term(i), 
            F_GPA_He4_term(i), 
            F_GPA_CHU_term(i), 
            F_XepLoai_term(i)
        );
        
        SET i = i + 1;
    END WHILE;
    
    INSERT INTO all_term (
        term, 
        `Credits`,
        `10_point_scale`, 
        `4_point_scale`, 
        `Letter_grade`, 
        `Classification`
    )
    VALUES (
		"Overall", 
        F_Tong_TC(),
        F_GPA_He10(), 
        F_GPA_He4(), 
        F_GPA_CHU(), 
        F_XepLoai()
    );

    SELECT * FROM all_term;
    
    DROP TEMPORARY TABLE all_term;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`%` FUNCTION `calculate_needed_points` (`SoTCConLai` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total_points DECIMAL(10,2);
    DECLARE total_credits INT;
    DECLARE current_average DECIMAL(10,2);

    SELECT SUM(TKHP_He4 * SoTC) INTO total_points
    FROM Grades
    WHERE TKHP_He4 >=0 
    	AND TKHP_He4 IS NOT NULL 
        AND MaHocPhan NOT LIKE '%ATQGTC%';

    SELECT SUM(SoTC) INTO total_credits
    FROM Grades
    WHERE TKHP_He4 >=0 
    	AND TKHP_He4 IS NOT NULL 
        AND MaHocPhan NOT LIKE '%ATQGTC%';

    SET current_average = total_points / total_credits;

    RETURN (3.6 * (total_credits + SoTCConLai) - total_points) / SoTCConLai;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_CHU` () RETURNS VARCHAR(2) CHARSET utf8mb4 
READS SQL DATA
DETERMINISTIC
BEGIN 
    DECLARE heChu VARCHAR(2);
    DECLARE HE_4 DECIMAL(10,2);
    
    SELECT F_GPA_He4() INTO HE_4;

    IF HE_4 > 3.8 AND HE_4 <= 4 THEN
        SET heChu = 'A+';
    ELSEIF HE_4 > 3.5 AND HE_4 <= 3.8 THEN
        SET heChu = 'A';
    ELSEIF HE_4 > 3 AND HE_4 <= 3.5 THEN
        SET heChu = 'B+';
    ELSEIF HE_4 >2.4 AND HE_4 <= 3 THEN
        SET heChu = 'B';
    ELSEIF HE_4 > 2 AND HE_4 <= 2.4 THEN
        SET heChu = 'C+';
    ELSEIF HE_4 > 1.5 AND HE_4 <= 2 THEN
        SET heChu = 'C';
    ELSEIF HE_4 > 1 AND HE_4 <= 1.5  THEN
        SET heChu = 'D+';
    ELSEIF HE_4 > 0 AND HE_4 <= 1 THEN
        SET heChu = 'D';
    ELSE
        SET heChu = 'F';
    END IF;
    
    RETURN heChu;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_CHU_term` (`term` INT) RETURNS VARCHAR(2) CHARSET utf8mb4 
READS SQL DATA
DETERMINISTIC
BEGIN 
    DECLARE heChu VARCHAR(2);
    DECLARE HE_4 DECIMAL(10,2);
    
    SELECT F_GPA_He4_term(term) INTO HE_4;

    IF HE_4 > 3.8 AND HE_4 <= 4 THEN
        SET heChu = 'A+';
    ELSEIF HE_4 > 3.5 AND HE_4 <= 3.8 THEN
        SET heChu = 'A';
    ELSEIF HE_4 > 3 AND HE_4 <= 3.5 THEN
        SET heChu = 'B+';
    ELSEIF HE_4 >2.4 AND HE_4 <= 3 THEN
        SET heChu = 'B';
    ELSEIF HE_4 > 2 AND HE_4 <= 2.4 THEN
        SET heChu = 'C+';
    ELSEIF HE_4 > 1.5 AND HE_4 <= 2 THEN
        SET heChu = 'C';
    ELSEIF HE_4 > 1 AND HE_4 <= 1.5  THEN
        SET heChu = 'D+';
    ELSEIF HE_4 > 0 AND HE_4 <= 1 THEN
        SET heChu = 'D';
    ELSE
        SET heChu = 'F';
    END IF;
    
    RETURN heChu;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_He10` () RETURNS DECIMAL(10,2) READS SQL DATA
DETERMINISTIC BEGIN
    DECLARE gpa DECIMAL(10,2);
    
    SELECT IFNULL(SUM(TKHP * SoTC) / NULLIF(SUM(SoTC), 0), 0) INTO gpa
    FROM Grades 
    WHERE TKHP >= 0 
      AND TKHP IS NOT NULL 
      AND `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%';
    
    RETURN gpa;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_He10_term` (`term` INT) RETURNS DECIMAL(10,2) READS SQL DATA
DETERMINISTIC BEGIN
    DECLARE gpa DECIMAL(10,2);
    
    SELECT SUM(TKHP*SoTC)/ SUM(SoTC) INTO gpa
    FROM Grades 
    WHERE TKHP >= 0 
    	AND TKHP IS NOT NULL 
        AND HocKi = term
		AND `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%';
    
    RETURN gpa;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_He4` () RETURNS DECIMAL(10,2) READS SQL DATA
DETERMINISTIC  BEGIN
    DECLARE GPA_He4 DECIMAL(10,2);
    SELECT SUM(TKHP_He4 * SoTC) / SUM(SoTC) INTO GPA_He4 FROM Grades 
    WHERE TKHP_He4 >=0 
    	AND TKHP_He4 IS NOT NULL 
        AND `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%';
    RETURN GPA_He4;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_GPA_He4_term` (`term` INT) RETURNS DECIMAL(10,2) READS SQL DATA
DETERMINISTIC  BEGIN
    DECLARE gpa DECIMAL(10,2);
    
    SELECT SUM(TKHP_He4*SoTC)/ SUM(SoTC) INTO gpa
    FROM Grades WHERE TKHP_He4 >= 0 
    	AND TKHP IS NOT NULL 
    	AND HocKi = term 
        AND `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%';
    
    RETURN gpa;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_Tong_TC` () RETURNS INT(11) READS SQL DATA
DETERMINISTIC  BEGIN

DECLARE soTC INT;

	SELECT SUM(`Grades`.`SoTC`) INTO soTC FROM `Grades` 
		WHERE `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%'
    		AND `Grades`.`TKHP` > 0;
    RETURN soTC;

END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_Tong_TC_term` (`term` INT) RETURNS INT(11) READS SQL DATA
DETERMINISTIC BEGIN

DECLARE soTC INT;

	SELECT SUM(`Grades`.`SoTC`) INTO soTC FROM `Grades` 
		WHERE `Grades`.`MaHocPhan` NOT LIKE '%ATQGTC%'
    		AND `Grades`.`TKHP` > 0
            AND `Grades`.`HocKi` = term;
    RETURN soTC;

END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_XepLoai` () RETURNS VARCHAR(10) CHARSET utf8mb4 READS SQL DATA
DETERMINISTIC  BEGIN 
	DECLARE XepLoai VARCHAR(10);
    DECLARE HE_4 DECIMAL(10,2);
    SELECT F_GPA_He4() INTO HE_4;
    
    IF HE_4 >= 3.6 THEN 
    	SET XepLoai = 'Xuất sắc';
    ELSEIF HE_4 >= 3.20 then 
    	SET XepLoai = 'Giỏi' ;
    ELSEIF HE_4 >= 2.5 then 
    	SET XepLoai = 'Khá' ;
    ELSEIF HE_4 >= 2 then 
    	SET XepLoai = 'Trung bình' ;
    ELSE 
    	SET XepLoai = 'Yếu';
    END IF;
    RETURN XepLoai;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `F_XepLoai_term` (`term` INT) RETURNS VARCHAR(10) CHARSET utf8mb4 READS SQL DATA
DETERMINISTIC BEGIN 
DECLARE XepLoai VARCHAR(10);
    DECLARE HE_4 DECIMAL(10,2);
    SELECT F_GPA_He4_term(term) INTO HE_4;
    
    IF HE_4 >= 3.6 THEN 
    	SET XepLoai = 'Xuất sắc';
    ELSEIF HE_4 >= 3.20 then 
    	SET XepLoai = 'Giỏi' ;
    ELSEIF HE_4 >= 2.5 then 
    	SET XepLoai = 'Khá' ;
    ELSEIF HE_4 >= 2 then 
    	SET XepLoai = 'Trung bình' ;
    ELSE 
    	SET XepLoai = 'Yếu';
    END IF;
    RETURN XepLoai;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Grades`
--

CREATE TABLE `Grades` (
  `STT` int(11) DEFAULT NULL,
  `HocKi` int(1) DEFAULT NULL,
  `MaHocPhan` varchar(20) PRIMARY KEY,
  `TenHocPhan` varchar(100) NOT NULL UNIQUE,
  `SoTC` int(1) NOT NULL,
  `TKHP` decimal(10,1) NOT NULL DEFAULT '-1.0',
  `TKHP_He4` decimal(10,1) DEFAULT '-1.0',
  `TKHP_HeChu` varchar(2) DEFAULT '-1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_general_ci;

--
-- Dumping data for table `Grades`
--

-- INSERT INTO `Grades` (`STT`, `HocKi`, `MaHocPhan`, `TenHocPhan`, `SoTC`, `TKHP`, `TKHP_He4`, `TKHP_HeChu`) VALUES
-- (32, 5, 'ATCN13', 'Tiếng Anh 4', 3, 9.2, 4.0, 'A+'),
-- (22, 4, 'PCT11', 'Lập Trình Java', 3, 8.6, 3.8, 'A'),
-- (18, 3, 'AT1LLDL1', 'Lịch sử Đảng cộng sản Việt Nam', 2, 5.9, 2.0, 'C'),
-- (10, 1, 'AT1LLLM1', 'Triết học Mác - Lênin', 3, 7.7, 3.0, 'B'),
-- (4, 2, 'AT1LLLM2', 'Kinh tế chính trị Mác - Lênin', 2, 9.1, 4.0, 'A+'),
-- (1, 2, 'AT1LLLM3', 'Chủ nghĩa xã hội khoa học', 2, 7.8, 3.5, 'B+'),
-- (20, 3, 'ATLLLM4', 'Khoa học quản lý (môn thay thế)', 2, 8.6, 3.8, 'A'),
-- (19, 3, 'ATLLTH1', 'Tư tưởng Hồ Chí Minh', 2, 7.5, 3.0, 'B'),
-- (28, 5, 'ATATKH10', 'Công nghệ phần mềm', 3, 8.2, 3.5, 'B+'),
-- (23, 4, 'ATATPM3', 'Công nghệ web an toàn', 3, 8.7, 3.8, 'A'),
-- (14, 2, 'ATCBNN1', 'Tiếng Anh 1', 3, 10.0, 4.0, 'A+'),
-- (21, 3, 'ATCBNN2', 'Tiếng Anh 2', 3, 10.0, 4.0, 'A+'),
-- (16, 4, 'ATCBNN3', 'Tiếng Anh 3', 3, 10.0, 4.0, 'A+'),
-- (27, 5, 'ATCN35', 'An toàn mạng máy tính (tự chọn)', 3, 8.0, 3.5, 'B+'),
-- (6, 1, 'ATCTHT13', 'Kiến trúc máy tính và hợp ngữ', 3, 5.2, 1.5, 'D+'),
-- (9, 1, 'ATLLDL2', 'Kỹ năng mềm', 2, 7.0, 3.0, 'B'),
-- (13, 1, 'ATQGTC1', 'Giáo dục thể chất 1', 1, 8.7, 3.8, 'A'),
-- (15, 3, 'ATQGTC2', 'Giáo dục thể chất 2', 1, 8.2, 3.5, 'B+'),
-- (24, 4, 'ATQGTC3', 'Giáo dục thể chất 3', 1, 8.2, 3.5, 'B+'),
-- (17, 2, 'CLC1ATCBTT6', 'Toán rời rạc', 3, 8.3, 3.5, 'B+'),
-- (30, 5, 'CNCT35', 'Phân tích và thiết kế thuật toán ', 3, 8.1, 3.5, 'B+'),
-- (11, 3, 'NAT5', 'Cấu trúc dữ liệu và giải thuật', 4, 9.2, 4.0, 'A+'),
-- (2, 3, 'NAT7', 'Mạng máy tính', 4, 7.0, 3.0, 'B'),
-- (31, 5, 'NAT8', 'Quản trị mạng', 3, 9.7, 4.0, 'A+'),
-- (12, 1, 'PCB14', 'Giải tích', 4, 6.9, 2.4, 'C+'),
-- (3, 1, 'PCB15', 'Đại số tuyến tính', 3, 7.7, 3.0, 'B'),
-- (8, 1, 'PCB17', 'Nhập môn công nghệ thông tin', 2, 8.2, 3.5, 'B+'),
-- (25, 4, 'PCT10', 'Hệ quản trị và an toàn cơ sở dữ liệu', 3, 8.6, 3.8, 'A'),
-- (7, 4, 'PCT17', 'Lập trình ứng dụng web', 3, 9.6, 4.0, 'A+'),
-- (5, 2, 'PCT2', 'Lập trình hướng đối tượng với C++', 4, 9.3, 4.0, 'A+'),
-- (26, 4, 'PCT25', 'Lập trình ứng dụng cho thiết bị di động', 3, 9.1, 4.0, 'A+'),
-- (29, 5, 'PCT7', 'Nguyên lý hệ điều hành', 3, 7.8, 3.5, 'B+');


--
-- Triggers `Grades`
--
DELIMITER $$
CREATE TRIGGER `Update_grades` BEFORE UPDATE ON `Grades` FOR EACH ROW BEGIN
    DECLARE he4 FLOAT;
    DECLARE heChu VARCHAR(2);

    IF NEW.TKHP >= 9.0 AND NEW.TKHP <= 10.0 THEN
        SET he4 = 4.0;
        SET heChu = 'A+';
    ELSEIF NEW.TKHP >= 8.5 AND NEW.TKHP < 9 THEN
        SET he4 = 3.8;
        SET heChu = 'A';
    ELSEIF NEW.TKHP >= 7.8 AND NEW.TKHP < 8.5 THEN
        SET he4 = 3.5;
        SET heChu = 'B+';
    ELSEIF NEW.TKHP >= 7.0 AND NEW.TKHP < 7.8 THEN
        SET he4 = 3.0;
        SET heChu = 'B';
    ELSEIF NEW.TKHP >= 6.3 AND NEW.TKHP < 7 THEN
        SET he4 = 2.4;
        SET heChu = 'C+';
    ELSEIF NEW.TKHP >= 5.5 AND NEW.TKHP < 6.3 THEN
        SET he4 = 2.0;
        SET heChu = 'C';
    ELSEIF NEW.TKHP >= 4.8 AND NEW.TKHP < 5.5 THEN
        SET he4 = 1.5;
        SET heChu = 'D+';
    ELSEIF NEW.TKHP >= 4.0 AND NEW.TKHP < 4.8 THEN
        SET he4 = 1.0;
        SET heChu = 'D';
    ELSEIF NEW.TKHP >= 0.0 AND NEW.TKHP < 4 THEN
        SET he4 = 0.0;
        SET heChu = 'F';
    END IF;

    SET NEW.TKHP_He4 = he4;
    SET NEW.TKHP_HeChu = heChu;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `calculate_grades` BEFORE INSERT ON `Grades` FOR EACH ROW BEGIN
    DECLARE he4 FLOAT;
    DECLARE heChu VARCHAR(2);

    IF NEW.TKHP >= 9.0 AND NEW.TKHP <= 10.0 THEN
        SET he4 = 4.0;
        SET heChu = 'A+';
    ELSEIF NEW.TKHP >= 8.5 AND NEW.TKHP < 9 THEN
        SET he4 = 3.8;
        SET heChu = 'A';
    ELSEIF NEW.TKHP >= 7.8 AND NEW.TKHP < 8.5 THEN
        SET he4 = 3.5;
        SET heChu = 'B+';
    ELSEIF NEW.TKHP >= 7.0 AND NEW.TKHP < 7.8 THEN
        SET he4 = 3.0;
        SET heChu = 'B';
    ELSEIF NEW.TKHP >= 6.3 AND NEW.TKHP < 7 THEN
        SET he4 = 2.4;
        SET heChu = 'C+';
    ELSEIF NEW.TKHP >= 5.5 AND NEW.TKHP < 6.3 THEN
        SET he4 = 2.0;
        SET heChu = 'C';
    ELSEIF NEW.TKHP >= 4.8 AND NEW.TKHP < 5.5 THEN
        SET he4 = 1.5;
        SET heChu = 'D+';
    ELSEIF NEW.TKHP >= 4.0 AND NEW.TKHP < 4.8 THEN
        SET he4 = 1.0;
        SET heChu = 'D';
    ELSEIF NEW.TKHP >= 0.0 AND NEW.TKHP < 4 THEN
        SET he4 = 0.0;
        SET heChu = 'F';
    END IF;

    SET NEW.TKHP_He4 = he4;
    SET NEW.TKHP_HeChu = heChu;
END
$$
DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
