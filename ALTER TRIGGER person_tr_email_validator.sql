/****** Object:  Trigger [dbo].[person_tr_email_validator]    Script Date: 11/17/2015 12:39:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==============================================
-- Author:	Kevin Foster
-- Create date: 2015-10-01
-- Description:	Trigger used to validate email
--   addresses being entered into patient charts.
-- ==============================================
ALTER TRIGGER [dbo].[person_tr_email_validator]
ON [dbo].[person] for INSERT, UPDATE 
AS 
BEGIN
	SET NOCOUNT ON;
	IF EXISTS (--is invalid email?
		SELECT email_address FROM inserted 
		WHERE ISNULL(email_address,'')<>'' 
		AND email_address NOT LIKE '%_@[a-z,0-9,_,-]%.[a-z][a-z]%'   --previous regex:  '%_@%_.__%'
	)
	BEGIN
		DECLARE @email VARCHAR(1000) = (SELECT email_address FROM inserted )
		DECLARE @comment VARCHAR(1000)  = (SELECT email_address_comment FROM inserted )

		DECLARE @errmsg VARCHAR(4000) = '                          '+CHAR(10)+
		CHAR(10)+
		'Invalid email address entered.  Please correct it or enter n/a in the comment field.  Expected syntax:  name@example.com'+CHAR(10)+
		CHAR(10)+
		REPLICATE(' ',20)+'                                       Best regards, NextCare IT'+REPLICATE(' ',100)+
		CHAR(10)+
		CHAR(10)+
		CHAR(10)
		
		RAISERROR (@errmsg,11,1);
	END
END