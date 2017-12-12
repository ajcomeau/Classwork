

USE MASTER
GO

IF EXISTS(SELECT * FROM SYS.databases WHERE name = 'JobSearchPlus')
BEGIN
	DROP DATABASE JobSearchPlus;
END
GO

CREATE DATABASE JobSearchPlus
GO

USE JobSearchPlus

CREATE TABLE BusinessTypes
(
	BusinessType varchar(50) NOT NULL,
	CONSTRAINT PK_BusinessTypes PRIMARY KEY (BusinessType)
)

GO


INSERT INTO			BusinessTypes
					(BusinessType)
VALUES				
('Accounting'),
('Advertising/Marketing'),
('Agriculture'),
('Architecture'),
('Arts/Entertainment'),
('Aviation'),
('Beauty/Fitness'),
('Business Services'),
('Communications'),
('Computer/Hardware'),
('Computer/Services'),
('Computer/Software'),
('Computer/Training'),
('Construction'),
('Consulting'),
('Crafts/Hobbies'),
('Education'),
('Electrical'),
('Electronics'),
('Employment'),
('Engineering'),
('Environmental'),
('Fashion'),
('Financial'),
('Food/Beverage'),
('Government'),
('Health/Medicine'),
('Home & Garden'),
('Immigration'),
('Import/Export'),
('Industrial'),
('Industrial Medicine'),
('Information Services'),
('Insurance'),
('Internet'),
('Legal & Law'),
('Logistics'),
('Manufacturing'),
('Mapping/Surveying'),
('Marine/Maritime'),
('Motor Vehicle'),
('Multimedia'),
('Network Marketing'),
('News & Weather'),
('Non-Profit'),
('Petrochemical'),
('Pharmaceutical'),
('Printing/Publishing'),
('Real Estate'),
('Restaurants'),
('Restaurants Services'),
('Service Clubs'),
('Service Industry'),
('Shopping/Retail'),
('Spiritual/Religious'),
('Sports/Recreation'),
('Storage/Warehousing'),
('Technologies'),
('Transportation'),
('Travel'),
('Utilities'),
('Venture Capital'),
('Wholesale')



GO

CREATE TABLE Sources
(
	SourceID int NOT NULL IDENTITY(1,1),
	SourceName varchar(75) NOT NULL,
	SourceType varchar(35),
	SourceLink varchar(255),
	SourceDesc varchar(255),
	CONSTRAINT PK_Sources PRIMARY KEY (SourceID)
)

GO

CREATE INDEX IDX_Sources_SourceName ON Sources(SourceName)
CREATE INDEX IDX_Sources_SourceType ON Sources(SourceType)

GO

CREATE TABLE Companies
(
	CompanyID int NOT NULL IDENTITY(1,1),
	CompanyName varchar(75) NOT NULL,
	Address1 varchar(75),
	Address2 varchar(75),
	City varchar(50),
	StateAbbrev varchar(2),
	ZIP varchar(10),
	Phone varchar(14),
	FAX varchar(14),
	Email varchar(50),
	Website varchar(255),
	CompanyDesc varchar(1024),
	BusinessType varchar(50),
	Agency bit CONSTRAINT DF_Companies_Agency DEFAULT 0,
	CONSTRAINT PK_Companies PRIMARY KEY (CompanyID)
)

GO

CREATE INDEX IDX_Companies_City ON Companies(City)
CREATE INDEX IDX_Sources_CompanyName ON Companies(CompanyName)
CREATE INDEX IDX_Sources_State ON Companies(StateAbbrev)
CREATE UNIQUE INDEX IDX_Sources_UniqueCompany ON Companies(CompanyName, Address1)
CREATE INDEX IDX_Sources_ZIP ON Companies(ZIP)

GO

CREATE TABLE Activities
(
	ActivityID int NOT NULL IDENTITY(1,1),
	LeadID int NOT NULL,
	ActivityDate datetime NOT NULL
		CONSTRAINT DF_Activities_ActivityDate DEFAULT GETDATE(),
	ActivityType varchar(25) NOT NULL,
	ActivityDetails varchar(255),
	Complete bit
		CONSTRAINT DF_Activities_Complete DEFAULT (0),
	ReferenceLink varchar(255)
	CONSTRAINT PK_Activities PRIMARY KEY (ActivityID)
)

GO

CREATE INDEX IDX_Activities_ActivityDate ON Activities(ActivityDate)
CREATE INDEX IDX_Activities_ActivityID ON Activities(ActivityID)
CREATE INDEX IDX_Activities_ActivityType ON Activities(ActivityType)
CREATE INDEX IDX_Activities_LeadID ON Activities(LeadID)

GO	



CREATE TABLE ActivityTypes
(
	ActivityType varchar(25) NOT NULL,
	CONSTRAINT PK_ActivityTypes PRIMARY KEY (ActivityType)
)

GO

CREATE TABLE Contacts
(
	ContactID int NOT NULL IDENTITY(1,1),
	CompanyID int NOT NULL,
	CourtesyTitle varchar(25),
	ContactFirstName varchar(50) NOT NULL,
	ContactLastName varchar(50) NOT NULL,
	Title varchar(50),
	Phone varchar(14),
	Extension varchar(10),
	Fax varchar(14),
	Email varchar(50),
	Comments varchar(255),
	Active bit CONSTRAINT DF_Contacts_Active DEFAULT (-1),
	CONSTRAINT PK_Contacts PRIMARY KEY (ContactID)
)

GO

CREATE INDEX IDX_Contacts_LastName ON Contacts(ContactLastName)
CREATE INDEX IDX_Contacts_CompanyID ON Contacts(CompanyID)
CREATE INDEX IDX_Contacts_Title ON Contacts(Title)
CREATE UNIQUE INDEX IDX_Contacts_UniqueComp ON Contacts(ContactID, ContactFirstName, ContactLastName, Title)

GO

CREATE TABLE Leads
(
	LeadID int NOT NULL IDENTITY(1,1),
	RecordDate datetime NOT NULL
		CONSTRAINT DF_Leads_RecordDate DEFAULT GETDATE(),
	JobTitle varchar(75) NOT NULL,
	LeadDesc varchar(2048),
	EmploymentType varchar(25),
	Location varchar(50),
	Active bit NOT NULL
		CONSTRAINT DF_Leads_Active DEFAULT (-1),
	CompanyID int,
	AgencyID int,
	ContactID int,
	SourceID int,
	ModifiedDate datetime NOT NULL CONSTRAINT DF_Leads_ModifiedDate DEFAULT GETDATE(),
	Selected bit
	CONSTRAINT DF_Leads_Selected DEFAULT (0),
	CONSTRAINT PK_Leads PRIMARY KEY (LeadID),
	CONSTRAINT CK_NoFutureLads CHECK (RecordDate <= GETDATE())
)

CREATE INDEX IDX_Leads_RecordDate ON Leads(RecordDate)
CREATE INDEX IDX_Leads_JobTitle ON Leads(JobTitle)
CREATE INDEX IDX_Leads_EmploymentType ON Leads(EmploymentType)
CREATE INDEX IDX_Leads_CompanyID ON Leads(CompanyID)
CREATE INDEX IDX_Leads_AgencyID ON Leads(AgencyID)
CREATE INDEX IDX_Leads_ContactID ON Leads(ContactID)
CREATE INDEX IDX_Leads_SourceID ON Leads(SourceID)

GO

CREATE TRIGGER TRG_Leads_ModifiedDate
ON Leads
FOR UPDATE
AS
BEGIN

UPDATE		L
SET			L.ModifiedDate = GETDATE()			
FROM		LEADS L
INNER JOIN	inserted i
ON			i.LeadID = L.LeadID

END

GO

CREATE TRIGGER TRG_Activities_ModifyLeadDate
ON Activities
FOR INSERT, UPDATE, DELETE
AS
BEGIN

UPDATE		L
SET			L.ModifiedDate = GETDATE()			
FROM		LEADS L
INNER JOIN	inserted i
ON			i.LeadID = L.LeadID

END

GO

-- Adding foreign keys
/*
ALTER TABLE Activities
	ADD CONSTRAINT FK_Activities_Leads FOREIGN KEY(LeadID) REFERENCES Leads(LeadID)
*/

CREATE TRIGGER TRG_ActivityModify
ON Activities
AFTER INSERT, UPDATE
AS
BEGIN
PRINT @@TRANCOUNT
IF EXISTS(SELECT * 
	FROM inserted i 
	WHERE i.LeadID NOT IN (SELECT LeadID FROM Leads))
	BEGIN
		RAISERROR('Specified LeadID does not exist. Error in foreign key.',16,1)
		ROLLBACK TRANSACTION 
	END
	PRINT @@TRANCOUNT
END
GO

CREATE TRIGGER TRG_ActivityDelete
ON Leads
AFTER DELETE
AS
BEGIN

IF EXISTS(SELECT * 
	FROM deleted i 
	WHERE i.LeadID IN (select distinct LeadID FROM Activities))
	BEGIN
		RAISERROR('Specified LeadID referenced by Activity records. Record not deleted.',16,1)
		ROLLBACK TRANSACTION 
	END
END
GO


ALTER TABLE Leads
	ADD 
	CONSTRAINT FK_Leads_Sources FOREIGN KEY(SourceID) REFERENCES Sources(SourceID),
	CONSTRAINT FK_Leads_Companies FOREIGN KEY(CompanyID) REFERENCES Companies(CompanyID),
	CONSTRAINT FK_Leads_Agencies FOREIGN KEY(AgencyID) REFERENCES Companies(CompanyID),
	CONSTRAINT FK_Leads_Contacts FOREIGN KEY(ContactID) REFERENCES Contacts(ContactID)

GO

ALTER TABLE Contacts
	ADD
	CONSTRAINT FK_Contacts_Companies FOREIGN KEY(CompanyID) REFERENCES Companies(CompanyID)

ALTER TABLE Companies
	ADD
	CONSTRAINT FK_Companies_BusinessTypes FOREIGN KEY(BusinessType) REFERENCES BusinessTypes(BusinessType)

ALTER TABLE Activities
	ADD
	CONSTRAINT FK_Activities_ActivityTypes FOREIGN KEY(ActivityType) REFERENCES ActivityTypes(ActivityType)

-- INSERT RECORDS

INSERT INTO Leads (JobTitle) VALUES ('Programmer')
INSERT INTO ActivityTypes (ActivityType) VALUES ('Resume')
INSERT INTO Activities (LeadID, ActivityType) VALUES (1, 'Resume')

DELETE FROM Leads

select * from Leads


/*
Test Checklist

1.) INSERT or UPDATE to Leads must fail any non-null non-existent values for:
	-	CompanyID
	-	AgencyID
	-	ContactID
	-	SourceID
2.) DELETE from Leads must fail for any records referenced by Activities table.
3.) INSERT or UPDATE to Activities must fail for any non-null, non-existent values for ActivityType.
4.) DELETE or UPDATE to ActivityTypes must catch any records referenced by Activities
	- UPDATE can either be denied or matching rows in Activities can be updated.
5.) DELETE or UPDATE to BusinessTypes must catch any records referenced by Companies
	- UPDATE can either be denied or matching rows in Companies can be updated.
7.) DELETE from Sources must fail for any records referenced by Leads
8.) DELETE from Companies must fail for any records referenced by Leads or Contacts.
9.) DELETE from Contacts must fail for any recors referenced by Leads or Companies
