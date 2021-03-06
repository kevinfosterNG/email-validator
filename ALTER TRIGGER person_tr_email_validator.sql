
-- ==============================================
-- Author:	Kevin Foster
-- Create date: 2015-10-01
-- Description:	Trigger used to validate email
--   addresses being entered into patient charts.
-- 2019-07-05 kf Added steps after the prompt to 
--		clear out any invalid entry reverting it
--		back to what the email/email n/a fields
--		were prior to the UPDATE
-- ==============================================
ALTER TRIGGER [dbo].[person_tr_email_validator]
ON [dbo].[person] for INSERT, UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;
	IF EXISTS (--is invalid email?
		SELECT email_address FROM inserted 
		WHERE ISNULL(email_address,'')<>'' 
		AND email_address NOT LIKE '%_@[a-z,0-9,_,-]%.[a-z][a-z]%'   --previous regex:  '%_@%_.__%'
	)
	BEGIN
		IF EXISTS (SELECT person_id FROM deleted)	--was an update of an existing person
		BEGIN 
			PRINT 'Updating existing person'
			UPDATE p SET email_address = d.email_address, email_ind=d.email_ind, enable_email_address_ind=d.enable_email_address_ind
			FROM person p
			INNER JOIN deleted d ON p.person_id=d.person_id
		END
		ELSE	--was a new person insert
		BEGIN
			PRINT 'Inserting a new person'
			UPDATE p SET email_address='', email_ind='', enable_email_address_ind='N'
			FROM person p 
			INNER JOIN inserted i ON p.person_id=i.person_id
		END
	
		DECLARE @errmsg VARCHAR(4000) = '                          '+CHAR(10)+
		CHAR(10)+
		'Invalid email address entered.  Please correct it or enter n/a in the comment field.  Expected syntax:  name@example.com'+CHAR(10)+CHAR(10)+
		REPLICATE(' ',20)+'                                       Best regards, NextCare IT'+REPLICATE(' ',100)+CHAR(10)+CHAR(10)+CHAR(10)
		RAISERROR (@errmsg,11,1);
	END
END