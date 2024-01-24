#CALCULATE REBATE SIMS FOR PREPAY
SET @UserID = '08799468e569efcea5fb45653bf23409';
SET @PkgID = '19493';
SET @LITable = 'LineItems202312'; #current month's lineitem table
SET @PLITable = 'LineItems202311'; #previous month's lineitem table
SET @PMonthStart = '2023-12-01';#Used to search O2D table for which SIMs have been terminated - 1st of last month
SET @PMonthEnd = '2023-12-31';#Used to search O2D table for which SIMs have been terminated - last day of last month
SET @CMonthStart = '2024-01-01'; #1st of current month
SET @DeviceUserID = ''; #Used to search O2D table for which SIMs have been terminated - populated automatically below

#Populates @DeviceUserID Variable using BillingUserID 
SELECT DeviceUserID INTO @DeviceUserID FROM billing.Portfolio WHERE BillingUserID = @UserID; 

DROP TEMPORARY TABLE IF EXISTS HFinalResults;
DROP TEMPORARY TABLE IF EXISTS HRTransfers;
DROP TEMPORARY TABLE IF EXISTS HRPMonthData;
DROP TEMPORARY TABLE IF EXISTS HRCMonthData;

CREATE TEMPORARY TABLE HRTransfers(ICCID BIGINT NOT NULL, PRIMARY KEY (ICCID), OLDPackageID INT DEFAULT "0", OLDUserID TEXT DEFAULT "0", CurrentPackageID INT DEFAULT "0", CurrentUserID TEXT DEFAULT "0", TransferredINOUT TEXT DEFAULT "NULL");
CREATE TEMPORARY TABLE HRPMonthData(ICCID BIGINT, OLDPackageID INT, OLDUserID TEXT);
CREATE TEMPORARY TABLE HRCMonthData(ICCID BIGINT, CurrentPackageID INT, CurrentUserID TEXT);

SET @dynamic_column_headers = ''; #Stores the dynamic columns as a result of the dynamic SQL query @dynamic_PkgItmID_columns
SET @dynamic_PkgItmID_columns = CONCAT('SELECT GROUP_CONCAT(distinct(PackageItemID) SEPARATOR ''a INT DEFAULT "0", '') AS PkgItmID INTO @dynamic_column_headers FROM ', @LITable, ' WHERE UserID = ''', @UserID, ''' AND PackageID = ''', @PkgID,''''); #Dynamic SQL query to obtain package item IDs for the portfolio/package
PREPARE dynamic_PkgItmID_columns FROM @dynamic_PkgItmID_columns;
EXECUTE dynamic_PkgItmID_columns;

#temporary table to store the final csv results of the rebate
SET @HFinalResultsTable = concat('CREATE TEMPORARY TABLE HFinalResults(TransferredIN BIGINT, TransferredOut BIGINT, `Terminated` BIGINT, `FromTo` TEXT, NewActivation BIGINT, ICCID BIGINT, ', @dynamic_column_headers, 'a INT DEFAULT "0", Total INT, UsedSiM TEXT, Rebate TEXT, PartialRefund TEXT, UsedNewSiM TEXT, CheckSiM TEXT)');
PREPARE FinalResultsTable FROM @HFinalResultsTable;
EXECUTE FinalResultsTable;
-----

#insert all of last months iccids and this months and then distinct them, then use a case statement to check if the userid of last month matches this month and vice versa to tell if it is a transfer in or our

#populates HRPMonthData table with last months active ICCIDs
SET @PMonthICCIDs = CONCAT('INSERT INTO HRPMonthData (ICCID, OLDPackageID, OLDUserID) SELECT DISTINCT(O.ICCID), PackageID, LI.UserID FROM ', @PLITable,' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE LI.UserID = ''', @UserID, ''' AND LI.PackageID = ''', @PkgID,''' AND PackageItemID IN (''0'',''2'') AND Owner2DacctID < 1000000000');
PREPARE STMT FROM @PMonthICCIDs;
EXECUTE STMT;

#populates HRCMonthData table with this months active ICCIDs
SET @CMonthICCIDs = CONCAT('INSERT INTO HRCMonthData (ICCID, CurrentPackageID, CurrentUserID) SELECT DISTINCT(O.ICCID), PackageID, LI.UserID FROM ', @LITable,' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE LI.UserID = ''', @UserID, ''' AND LI.PackageID = ''', @PkgID,''' AND PackageItemID IN (''0'',''2'') AND Owner2DacctID < 1000000000');
PREPARE STMT FROM @CMonthICCIDs;
EXECUTE STMT;

#inserts all of last months active ICCIDs into the HRTransfers table
INSERT INTO HRTransfers (ICCID, OLDPackageID, OLDUserID) SELECT * FROM HRPMonthData;

#updates all rows (which are last months active ICCIDs) with their PackageID and UserID from this month
UPDATE HRTransfers AS T1 LEFT JOIN HRCMonthData AS T2 ON T1.ICCID = T2.ICCID SET T1.CurrentPackageID = T2.CurrentPackageID, T1.CurrentUserID = T2.CurrentUserID;

#Inserts all ICCIDs into the HRTransfer table which were not on this portfolio from last month meaning they are new/have been transferred to this portfolio - uses the HRCMonthData table
INSERT INTO HRTransfers (ICCID, CurrentPackageID, CurrentUserID) SELECT ICCID, CurrentPackageID, CurrentUserID FROM HRCMonthData WHERE ICCID NOT IN (SELECT ICCID FROM HRTransfers);

#update all null values in the HRTransfers table to be "NULL" as it should then run faster - NOW REDUNDANT AS I MADE THE DEFAULT VALUE AT POINT OF TABLE CREATION 0
#UPDATE HRTransfers AS T1 JOIN (SELECT ICCID, ifnull(OLDPackageID, "0") AS OLDPackageID, ifnull(OLDUserID, "0") AS OLDUserID, ifnull(CurrentPackageID, "0") AS CurrentPackageID, ifnull(CurrentUserID, "0") AS CurrentUserID FROM HRTransfers) AS T2
#ON T1.ICCID = T2.ICCID SET T1.OLDPackageID = T2.OLDPackageID, T1.OLDUserID = T2.OLDUserID, T1.CurrentPackageID = T2.CurrentPackageID, T1.CurrentUserID = T2.CurrentUserID;

#updates the HRTransfers table with last month's PackageID AND UserID for those SIMs transferred to the portfolio - so for newly transferred SIMs, gets their previous UserID and PackageID 
#Anything where the OLDPackageID/OldUserID field is NULL is a new SIM
SET @SQL = CONCAT('UPDATE HRTransfers AS T1 JOIN (SELECT ICCID, PackageID, UserID FROM ', @PLITable ,' WHERE ICCID IN (SELECT ICCID FROM HRTransfers WHERE OLDPackageID = "0") AND PackageItemID IN (''0'',''2'')) AS T2 ON T1.ICCID = T2.ICCID 
SET T1.OLDPackageID = T2.PackageID, T1.OLDUserID = T2.UserID WHERE T1.OLDPackageID = "0";');
PREPARE STMT FROM @SQL;
EXECUTE STMT;

#updates the HRTransfers table with this month's PackageID AND UserID for those SIMs transferred from this portfolio to another - so for SIMs which were on this portfolio last month, finds out where they have been transferred to
SET @SQL = CONCAT('UPDATE HRTransfers AS T1 JOIN (SELECT ICCID, PackageID, UserID FROM ', @LITable ,' WHERE ICCID IN (SELECT ICCID FROM HRTransfers WHERE CurrentPackageID = "0" OR CurrentPackageID IS NULL) AND PackageItemID IN (''0'',''2'')) AS T2 ON T1.ICCID = T2.ICCID 
SET T1.CurrentPackageID = T2.PackageID, T1.CurrentUserID = T2.UserID WHERE T1.CurrentPackageID = "0" OR T1.CurrentPackageID IS NULL;');
PREPARE STMT FROM @SQL;
EXECUTE STMT;

#Populates the HRTransfers.TransferredINOUT column with whether a SIM has been transferred into the portfolio or out
UPDATE HRTransfers SET TransferredINOUT = "IN" WHERE OLDUserID != @UserID OR OLDPackageID != @PkgID;
UPDATE HRTransfers SET TransferredINOUT = "OUT" WHERE CurrentUserID != @UserID OR CurrentPackageID != @PkgID;
UPDATE HRTransfers SET TransferredINOUT = "SAME" WHERE OLDPackageID = CurrentPackageID AND OLDUserID = CurrentUserID;
UPDATE HRTransfers SET TransferredINOUT = "TERMINATED" WHERE CurrentPackageID IS NULL AND CurrentUserID IS NULL;

#Populations the HRTransfers.TransferredINOUT column with whether a SIM is a new activation
UPDATE HRTransfers SET TransferredINOUT = "NEW SIM" WHERE OLDPackageID = "0" AND OLDUserID = "0";

#populates all columns containing ICCIDs of the HFinalResults table 
INSERT INTO HFinalResults(TransferredIN) SELECT ICCID FROM HRTransfers WHERE TransferredINOUT = "IN";
INSERT INTO HFinalResults(TransferredOut) SELECT ICCID FROM HRTransfers WHERE TransferredINOUT = "OUT";
INSERT INTO HFinalResults(NewActivation) SELECT ICCID FROM HRTransfers WHERE TransferredINOUT = "NEW SIM";
INSERT INTO HFinalResults(`Terminated`) SELECT ICCID FROM HRTransfers WHERE TransferredINOUT = "TERMINATED";
INSERT INTO HFinalResults(ICCID) SELECT ICCID FROM HRTransfers WHERE TransferredINOUT = "SAME";

#Updates the origins of any ICCIDs transferred to this portfolio
UPDATE HFinalResults AS T1 JOIN (SELECT ICCID, concat(OLDPackageID, " / ", OLDUserID) AS FromTo FROM HRTransfers WHERE TransferredINOUT = "IN") AS T2 ON T1.TransferredIN = T2.ICCID SET T1.FromTo = T2.FromTo;

#Updates the destination of any ICCIDs transferred from this portfolio
UPDATE HFinalResults AS T1 JOIN (SELECT ICCID, concat(CurrentPackageID, " / ", CurrentUserID) AS FromTo FROM HRTransfers WHERE TransferredINOUT = "OUT") AS T2 ON T1.TransferredOut = T2.ICCID SET T1.FromTo = T2.FromTo;

SET @count_dynamic_PKGITMIDs = '';
SET @clean_dynamic_PKGITMIDs = '';

#compares the length of the @dynamic_column_headers variable before and after removing commas. The sum is the amount of commas (characters) that were removed divided by the length
#of the character removed (this tells us how many of that character/word was removed) as each column is separated by a comma except the last column therefore we add 1
SELECT ROUND ((LENGTH(@dynamic_column_headers) - LENGTH( REPLACE ( @dynamic_column_headers, ",", ""))) / LENGTH(",") + 1) AS count INTO @count_dynamic_PKGITMIDs;

#works but no longer need - good to know replaces everything in the patter/range specified
#select regexp_replace(@dynamic_column_headers, '[a-z-"]',"") INTO @clean_dynamic_PKGITMIDs;

#Dynamic SQL query to obtain package item IDs for the portfolio/package and insert into @clean_dynamic_PKGITMIDs variable
SET @clean_dynamic_PkgItmID_columns = CONCAT('SELECT GROUP_CONCAT(distinct(PackageItemID) SEPARATOR '', '') AS PkgItmID INTO @clean_dynamic_PKGITMIDs FROM ', @LITable, ' WHERE UserID = ''', @UserID, ''' AND PackageID = ''', @PkgID,''''); 
PREPARE clean_dynamic_PkgItmID_columns FROM @clean_dynamic_PkgItmID_columns;
EXECUTE clean_dynamic_PkgItmID_columns;

-- drop temporary table if exists DEBUG;
-- CREATE TEMPORARY TABLE DEBUG(`Loop` INT, variable text, Variablevalue varchar(20));
-- select * from DEBUG;

#NOT ATOMIC is required when creating a procedure outside of an anonymous block or stored procedure. It implies the procedure is not atomic ie some of the statements can fail and it won't be rolled back
#This block will loop through each of the dynamic pkgitmids and check if they have a usage line, if they do the HFinalResults table is populated with a 1 in that column.
DELIMITER $$
BEGIN NOT ATOMIC
	declare counter INT default 1; #used to count the loop and is compared to the count of dynamic pkgitmids to know when to terminate loop
    declare current_PKGITMID TEXT; #the current pkgitmid the loop is looking at
    declare clean_current_PKGITMID TEXT; #cleans the pkgitmid from 
    declare length_PKGITMIDs INT; #used to calculate the current pkgitmid when looping through the @clean_dynamic_PKGITMIDs which contains all dyn PKGITMIDs
    declare trimmed_clean_current_PKGITMID TEXT; #stores current PKGITMID for the loop with leading and trailing spaces removed
    declare imported_clean_dynamic_PKGITMID TEXT; #same as @clean_dynamic_PKGITMIDs
    
    SELECT @clean_dynamic_PKGITMIDs INTO imported_clean_dynamic_PKGITMID;
    
	WHILE counter <= @count_dynamic_PKGITMIDs DO
    
  --   insert into DEBUG(`Loop`, variable, variablevalue) VALUES 
-- 		(counter, "counter", counter),
-- 		(counter, "countofpkgitmids", @count_dynamic_PKGITMIDs),
--         (counter, "current_PKGITMID", current_PKGITMID),
--         (counter, "length_PKGITMIDs", length_PKGITMIDs),
--         (counter, "clean_current_PKGITMID", clean_current_PKGITMID),
--         (counter, "trimmed_clean_current_PKGITMID", trimmed_clean_current_PKGITMID),
--         (counter, "imported_clean_dynamic_PKGITMID", imported_clean_dynamic_PKGITMID);
--            
--         #SET current_PKGITMID = substring_index(imported_clean_dynamic_PKGITMID, ",", counter); #obtains the current pkgitmid including previous ones
	    
        #finds the current pkgitmid to look at for the loop
        SELECT substring_index(imported_clean_dynamic_PKGITMID, ",", counter) INTO current_PKGITMID;
         
		IF counter = 1 THEN
			SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID, count(O.ICCID) AS ICCIDCount FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''0'' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') 
            AND LI.UserID = ''', @UserID,''' GROUP BY O.ICCID) AS T2 ON T2.ICCID = T1.TransferredIN SET T1.0a = T2.ICCIDCount');
			PREPARE STMT FROM @SQL;
			EXECUTE STMT;
            
            SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''0'' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') 
            AND LI.UserID = ''', @UserID,''') AS T2 ON T2.ICCID = T1.ICCID SET T1.0a = ''1''');
			PREPARE STMT FROM @SQL;
			EXECUTE STMT;
            
            SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''0'' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') 
            AND LI.UserID = ''', @UserID,''' AND StartDate = ''', @CMonthStart, ''') AS T2 ON T2.ICCID = T1.NewActivation SET T1.0a = ''1''');
			PREPARE STMT FROM @SQL;
			EXECUTE STMT;
            
        ELSEIF counter >= 2 THEN
        
			SELECT length(substring_index(@clean_dynamic_PKGITMIDs, ",", counter-1))+2 INTO length_PKGITMIDs; #obtains the length of char up to the previous pkgitmid to be used to exclude the previous pkgitmid
			SELECT substr(current_PKGITMID, length_PKGITMIDs) INTO clean_current_PKGITMID; #removes the previous pkgitmids so we are left with only the current pkgitmid
			SELECT trim(clean_current_PKGITMID) INTO trimmed_clean_current_PKGITMID; #removes any leading or trailing spaces 
			
            #had to separate pkgitmid 2 from the rest here as the rest look at inbundle+outofbundle which pkgitmid 2 does not have and so would never return anything
            IF trimmed_clean_current_PKGITMID = 2 THEN
            
				SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID, count(O.ICCID) AS ICCIDCount FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''', trimmed_clean_current_PKGITMID, ''' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') 
				AND LI.UserID = ''', @UserID,''' GROUP BY O.ICCID) AS T2 ON T2.ICCID = ifnull(T1.NewActivation,0) SET T1.', trimmed_clean_current_PKGITMID, 'a = T2.ICCIDCount');
				PREPARE STMT FROM @SQL;
				EXECUTE STMT;
            
            ELSEIF trimmed_clean_current_PKGITMID = 19 THEN
            #same as above but it will join onto transferredout column instead. may also need to amend total query bit to exclude 19?
				SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID, count(O.ICCID) AS ICCIDCount FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''', trimmed_clean_current_PKGITMID, ''' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') 
				AND LI.UserID = ''', @UserID,''' GROUP BY O.ICCID) AS T2 ON T2.ICCID = ifnull(T1.TransferredOut,0) SET T1.', trimmed_clean_current_PKGITMID, 'a = T2.ICCIDCount');
				PREPARE STMT FROM @SQL;
				EXECUTE STMT;
            
            #ELSEIF trimmed_clean_current_PKGITMID > 2 THEN
            ELSEIF trimmed_clean_current_PKGITMID > 21 THEN
            
				SET @SQL = concat('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID AS ICCID, count(O.ICCID) AS ICCIDCount FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.ID WHERE PackageItemID = ''', trimmed_clean_current_PKGITMID, ''' AND Status NOT IN (''VOID'',''VOIDZERO'', ''BUNDLE'', ''VOIDBUNDLE'') AND OutOfBundleQuantity+InBundleQuantity > 0
				AND LI.UserID = ''', @UserID,''' GROUP BY O.ICCID) AS T2 ON (T2.ICCID = ifnull(T1.TransferredIN,0) OR T2.ICCID = ifnull(T1.Terminated,0) OR T2.ICCID = ifnull(T1.ICCID,0) OR T2.ICCID = ifnull(T1.NewActivation,0)) SET T1.', trimmed_clean_current_PKGITMID, 'a = T2.ICCIDCount');
				PREPARE STMT FROM @SQL;
				EXECUTE STMT;
                
            END IF;
		END IF;
			
  --   insert into DEBUG(`Loop`, variable, variablevalue) VALUES 
-- 		(counter, "counter", counter),
-- 		(counter, "countofpkgitmids", @count_dynamic_PKGITMIDs),
--         (counter, "current_PKGITMID", current_PKGITMID),
--         (counter, "length_PKGITMIDs", length_PKGITMIDs),
--         (counter, "clean_current_PKGITMID", clean_current_PKGITMID),
--         (counter, "trimmed_clean_current_PKGITMID", trimmed_clean_current_PKGITMID),
--         (counter, "imported_clean_dynamic_PKGITMID", imported_clean_dynamic_PKGITMID);
    
		SET counter = counter + 1;  
    
    END WHILE;	
END;
$$;

DELIMITER ;

#Stores the dynamic pkgitmid's column headers with the '+' sign inbetween for use in calculating which sims have a 1 in each column to populate the `Total` column .
SET @dynamic_column_titles_for_addition = ''; 
SELECT concat(replace(@clean_dynamic_PKGITMIDs,',','a + '), 'a') INTO @dynamic_column_titles_for_addition;

#updates the total column based on the values stored in each of the dyn pkgitmid columns
SET @SQL = CONCAT('update HFinalResults SET Total = ', @dynamic_column_titles_for_addition, ' where TransferredIN IS NOT NULL OR `Terminated` IS NOT NULL OR NewActivation IS NOT NULL OR ICCID IS NOT NULL');
PREPARE STMT FROM @SQL;
EXECUTE STMT;


UPDATE HFinalResults SET UsedSiM = CASE 
WHEN ICCID IS NOT NULL AND Total > 1 THEN "USED SIM"
WHEN TransferredIN IS NOT NULL AND Total > 2 THEN "USED SIM"
WHEN `Terminated` IS NOT NULL AND Total > 0 THEN "USED SIM"
ELSE UsedSiM = NULL
END,
PartialRefund = CASE
WHEN NewActivation IS NOT NULL AND Total = 1 THEN "PARTIAL REFUND"
ELSE PartialRefund = NULL
END,
UsedNewSiM = CASE 
WHEN NewActivation IS NOT NULL AND Total > 2 AND PartialRefund IS NULL THEN "USED NEW SIM"
ELSE UsedNewSiM = NULL
END,
Rebate = CASE
WHEN (UsedSiM != "USED SIM" OR UsedSiM IS NULL) AND TransferredOut IS NULL AND PartialRefund IS NULL AND UsedNewSiM IS NULL THEN "REBATE"
ELSE Rebate = NULL
END;


DELIMITER $$
#Sense checks on results
BEGIN NOT ATOMIC
	    
    DECLARE dynamic_pkgitmids_clean TEXT; #stores the column titles of each dynamic pkgitmid
    select replace(@dynamic_column_titles_for_addition,' + ',', ') INTO dynamic_pkgitmids_clean; #inserts the pkgitmids as title columns
    
    #subtracts the length of dynamic_pkgitmids_clean from itself where one is normal and the other has column 2a removed. If the result is more than 0 it means a partial column exists else it does not
    IF LENGTH(dynamic_pkgitmids_clean)-LENGTH(REPLACE(dynamic_pkgitmids_clean,', 2a,','')) > 0 THEN
		UPDATE HFinalResults SET CheckSiM = CASE
		WHEN 0a > 1 AND TransferredIN IS NULL THEN "CHECK"
        WHEN 0a > 0 AND (`Terminated` IS NOT NULL OR TransferredOut IS NOT NULL) THEN "CHECK"
        WHEN 0a = 0 AND NewActivation IS NOT NULL THEN "CHECK"
        WHEN 0a > 1 AND ICCID IS NOT NULL THEN "CHECK"
        WHEN 2a > 0 AND NewActivation IS NULL THEN "CHECK"
        WHEN 2a > 1 THEN "CHECK"
		ELSE NULL
		END;
	ELSE
		UPDATE HFinalResults SET CheckSiM = CASE
		WHEN 0a > 1 AND TransferredIN IS NULL THEN "CHECK"
        WHEN 0a > 0 AND (`Terminated` IS NOT NULL OR TransferredOut IS NOT NULL) THEN "CHECK"
        WHEN 0a = 0 AND NewActivation IS NOT NULL THEN "CHECK"
        WHEN 0a > 1 AND ICCID IS NOT NULL THEN "CHECK"
        ELSE NULL
		END;
	END IF;
    
    SET @SQL = CONCAT('UPDATE HFinalResults AS T1 JOIN (SELECT O.ICCID, COUNT(DISTINCT(Owner2DacctID)) AS O2DIDCount FROM ', @LITable, ' AS LI JOIN Owner2Dacct AS O ON LI.Owner2DacctID = O.Id WHERE LI.UserID = ''', @UserID, 
    ''' AND LI.PackageID = ''', @PkgID, ''' GROUP BY O.ICCID HAVING O2DIDCount > 1) AS T2 ON T1.ICCID = T2.ICCID SET CheckSiM = ''CHECK'''); 
	PREPARE STMT FROM @SQL;
    EXECUTE STMT;
END;

$$;

DELIMITER ;

#adds apostrophes to each column containing an ICCID so as the results are ready to export to excel
SET @apostrophecolumns = concat_ws(",", "SELECT concat('''',TransferredIN,'''') AS 'TransferredIN'","concat('''',TransferredOut,'''') AS 'TransferredOut'","concat('''',`Terminated`,'''') AS 'Terminated'", "FromTo","concat('''',NewActivation,'''') AS 'NewActivation'","concat('''',ICCID,'''') AS 'ICCID' ,");
SET @SQL = CONCAT(@apostrophecolumns, REPLACE(@clean_dynamic_PKGITMIDs,',','a,'), 'a, Total, UsedSiM, Rebate, PartialRefund, UsedNewSiM, CheckSiM FROM HFinalResults ORDER BY ICCID desc;');
PREPARE STMT FROM @SQL;
EXECUTE STMT;