--Backup person accounts about to be updated
IF NOT EXISTS (select 1 from sysobjects where name='person_email_hotfix_bak_20151008' and xtype='U')
BEGIN
	PRINT 'Backing up person table data.'
	SELECT person_id, email_address, email_address_comment INTO person_email_hotfix_bak_20151008 
	FROM person 
	WHERE ISNULL(email_address,'')<>'' AND email_address NOT LIKE '%_@_%.__%'
END

CREATE TABLE #domain_list (domain VARCHAR(50),tld VARCHAR(10), cnt INT)
INSERT INTO #domain_list (domain, tld) 
VALUES ('@yahoo','.com'),('@gmail','.com'),('@cox','.net'),('@hotmail','.com')
,('@aol','.com'),('@earthlink','.net'),('@msn','.com'),('@att','.net'),('@bellsouth','.net')
,('@baylor','.edu'),('@bannerhealth','.com'),('@comcast','.net')
,('@icloud','.com'),('@nextcare','.com'),('@netzero','.net'),('@outlook','.com')
,('@ohiohealth','.com'),('@sbcglobal','.net')
,('@verizon','.net')

DECLARE @domain VARCHAR(50) --= '@yahoo'
DECLARE @tld VARCHAR(10) --= '.com'

DECLARE domain_cursor CURSOR FOR 
SELECT domain, tld FROM #domain_list

OPEN domain_cursor
FETCH NEXT FROM domain_cursor INTO @domain, @tld
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @domain+@tld
	
	UPDATE person SET email_address=SUBSTRING(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld),0,LEN(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld)) - CHARINDEX('@',REVERSE(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld)))+1)+@domain+@tld
	--SELECT person_id, email_address, email_address_comment, SUBSTRING(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld),0,LEN(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld)) - CHARINDEX('@',REVERSE(REPLACE(email_address,@domain+REPLACE(@tld,'.','@'),@domain+@tld)))+1)+@domain+@tld AS fixed_email FROM person 
	WHERE ISNULL(email_address,'')<>'' AND email_address NOT LIKE '%_@_%.__%'
	AND (
		email_address like '%'+@domain+'%' AND 
		email_address NOT LIKE '%'+@domain+@tld
	)

	UPDATE #domain_list SET cnt = @@ROWCOUNT WHERE domain=@domain and tld=@tld

	FETCH NEXT FROM domain_cursor INTO @domain, @tld
END

CLOSE domain_cursor
DEALLOCATE domain_cursor

/*Finally, map all remaining invalid emails into the comment field.*/
UPDATE person set email_address_comment=LEFT(ISNULL(email_address_comment,'')+email_address,50), email_address=NULL
--SELECT person_id, email_address, email_address_comment, LEFT(ISNULL(email_address_comment,'')+email_address,50)
FROM person 
WHERE ISNULL(email_address,'')<>'' AND email_address NOT LIKE '%_@_%.__%'

--Clean up
SELECT * FROM #domain_list
DROP TABLE #domain_list