-- 1. Run below query to obtain all userids and their service total;
-- 2. Paste into excel and split into three groups of 0-15k, 15-30k and 30k plus;
-- 3. Insert the UserID's for each group into the HMissingServiceLines temp table and execute script;
-- 4. Repeat for each group.

-- STEP 1:
#SELECT concat("('",UserID, "'),"), SUM(Price) AS 'TotalPrice' FROM LineItems202312 AS LI JOIN Portfolio AS P ON LI.UserID = P.BillingUserID WHERE PackageItemID IN ('0','2') AND Status != 'VOID' 
#AND Price > 0 AND LOWER(P.PortfolioName) NOT LIKE '%eseye%' AND LOWER(PortfolioName) NOT LIKE '%dataflex%' GROUP BY UserID ORDER BY TotalPrice ASC;

-- STEP 2:
SET @LITable = 'LineItems202312'; #current months lineitem table
SET @PLITable = 'LineItems202311'; #previous months lineitem table
SET @CMonthStart = '2024-01-01'; #1st of current month

DROP TEMPORARY TABLE IF EXISTS HMissingServiceLines;
CREATE TEMPORARY TABLE HMissingServiceLines (BillingUserID CHAR(32), MissingLinesByICCID TEXT);

#Insert batch of portfolios to check here
INSERT INTO HMissingServiceLines (BillingUserID) VALUES
('38aa2498ed76e8aaea1bf722edbd4e0f'),
('a122fb3180032a772c1150bf93a43f97'),
('cefff9b8a0e04496d5df9e99aa188956'),
('2b905493aa3c3c368fd3d390623eaf21'),
('c4e74138c89dcb9ff900df3579ad5939'),
('a0dd787404e9e5c8b6336f2f4ee8172a')
;

-- drop temporary table if exists Htest;
-- create temporary table Htest (counter int, useridcount int, results text);

DELIMITER $$

BEGIN NOT ATOMIC 
	DECLARE counter INT DEFAULT 0;
    DECLARE userIDcount INT;
    DECLARE currentuserID CHAR(32);
    
    SELECT COUNT(*) INTO userIDcount FROM HMissingServiceLines;
    
    WHILE counter < userIDcount DO
		SELECT BillingUserID INTO currentuserID FROM HMissingServiceLines LIMIT 1 OFFSET counter;
        
        -- insert into Htest values (counter, `useridcount`, currentuserID);
        
		SET @SQL = CONCAT('UPDATE HMissingServiceLines AS T1 JOIN (SELECT DISTINCT(group_concat(O.ICCID)) AS ''MissingICCIDs'', PLI.UserID AS ''UserID'' FROM ', @PLITable, ' AS PLI JOIN Owner2Dacct AS O ON PLI.Owner2DacctID = O.ID 
        WHERE PackageItemID IN (''0'', ''2'') AND (O.Terminated >= ''', @CMonthStart, ''' OR O.Terminated IS NULL) AND PLI.Owner2DacctID < 1000000000 AND PLI.UserID = ''', currentuserID, ''' AND `Status` != ''VOID'' AND
		O.ICCID NOT IN (SELECT O.ICCID FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''0'' AND `Status` != ''VOID'')) AS T2 ON T1.BillingUserID = T2.UserID
        SET T1.MissingLinesByICCID = T2.MissingICCIDs');
        
        PREPARE STMT FROM @SQL;
        EXECUTE STMT;
        
        SET counter = counter + 1;
    
   END WHILE; 
END;    
$$;

DELIMITER ;

SELECT PortfolioName, HMissingServiceLines.BillingUserID, MissingLinesByICCID FROM HMissingServiceLines JOIN Portfolio USING (BillingUserID) ORDER BY MissingLinesByICCID DESC;

-- STEP 3 FOR REPORT:
SELECT Owner2DacctID, PackageID, PackageItemID, StartDate, StopDate, Price, `Status`, Activated, `Terminated` FROM LineItems202311 AS LI join Owner2Dacct AS O ON O.ID = LI.Owner2DacctID where O.ICCID = '8944538523016317888';
-- SELECT Owner2DacctID, PackageID, PackageItemID, StartDate, StopDate, Price, `Status`, Activated, `Terminated` FROM LineItems202312 AS LI join Owner2Dacct AS O ON O.ID = LI.Owner2DacctID where O.ICCID = '8944538523026180292';