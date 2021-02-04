/*******************************Query 1*******************************/

IF OBJECT_ID (N'getUserRolesReport', N'IF') IS NOT NULL  
    DROP FUNCTION getUserRolesReport;  
GO  
CREATE FUNCTION getUserRolesReport ()  
RETURNS TABLE  
AS  
RETURN
( 
SELECT 
  /*report_categories.user_id,*/
  report_categories.first_name,
  report_categories.last_name,
  /*report_categories.role_id,*/
  report_categories.role_name,
  report_categories.role_description
FROM
(
  -- report categories
  SELECT
    Users.ID AS user_id,
    Users.FirstName AS first_name,
    Users.LastName AS last_name,
    Roles.ID AS role_id,
    Roles.Name AS role_name ,
	Roles.Description AS role_description
  FROM Users
  JOIN Roles ON Users.RoleID=Roles.ID
) AS report_categories
);


SELECT * FROM getUserRolesReport()


/*******************************Query 2*******************************/

/*IF OBJECT_ID (N'dbo.getGuestCount', N'FN') IS NOT NULL  
    DROP FUNCTION getGuestCount;  
GO  
CREATE FUNCTION dbo.getGuestCount(@class_id int)  
RETURNS int
AS   
BEGIN 	
	DECLARE @retVal int;
	SET @retVal=(SELECT COUNT(*) FROM GuestClass WHERE ClassID=@class_id);
	IF (@retVal IS NULL)   
        SET @retVal = 0;  
    RETURN @retVal;
END;


SELECT DISTINCT Class.Name AS ClassName, dbo.getGuestCount(Class.ID) AS GuestCount FROM Class JOIN GuestClass ON Class.ID=GuestClass.ClassID;*/

SELECT DISTINCT Class.Name AS ClassName, Count(*) AS GuestCount FROM Class JOIN GuestClass ON Class.ID=GuestClass.ClassID
GROUP BY Class.Name;

/*******************************Query 3*******************************/

SELECT DISTINCT Guests.Name AS GuestName, Class.Name AS ClassName, gc.Level,
					CASE 
						WHEN (gc.Level between 1 and 5)
						THEN 'BEGINNER'
						WHEN (gc.Level between 5 and 10)
						THEN 'INTERMEDIATE'
						WHEN (gc.Level > 10)
						THEN 'EXPERT'
					END
					AS Grouping
 FROM Guests JOIN GuestClass gc ON gc.GuestID= Guests.ID
 JOIN Class ON Class.ID=gc.ClassID
 ORDER BY GuestName

/*******************************Query 4*******************************/

IF OBJECT_ID (N'dbo.getLevelGroup', N'FN') IS NOT NULL  
    DROP FUNCTION getLevelGroup;  
GO  
CREATE FUNCTION dbo.getLevelGroup(@level int)  
RETURNS varchar(250)
AS   
BEGIN	
	DECLARE @retVal varchar(250);
	SET @retVal=(SELECT 
					CASE 
						WHEN (@level between 1 and 5)
						THEN 'BEGINNER'
						WHEN (@level between 5 and 10)
						THEN 'INTERMEDIATE'
						WHEN (@level > 10)
						THEN 'EXPERT'
					END
				);

	IF (@retVal IS NULL)   
        SET @retVal = '';  
    RETURN @retVal;
END;


 SELECT DISTINCT Guests.Name AS GuestName, Class.Name AS ClassName, gc.Level, dbo.getLevelGroup(gc.Level) AS Grouping
 FROM Guests JOIN GuestClass gc ON gc.GuestID= Guests.ID
 JOIN Class ON Class.ID=gc.ClassID
 ORDER BY GuestName


 /*******************************Query 5*******************************/

 IF OBJECT_ID (N'getRoomStatusReport', N'IF') IS NOT NULL  
    DROP FUNCTION getRoomStatusReport;  
GO  
CREATE FUNCTION getRoomStatusReport (@inputdate Date, @status varchar(50))  
RETURNS TABLE  
AS  
RETURN
( 
SELECT 
  /*report_RoomsAvailable.room_id,*/
  report_RoomsAvailable.room_name,
  /*report_RoomsAvailable.room_status_id,*/
  report_RoomsAvailable.room_status,
 /* report_RoomsAvailable.tavern_id,*/
  report_RoomsAvailable.tavern_name
FROM
(
  -- report categories
 SELECT Rooms.ID AS room_id,
		Rooms.Name AS room_name,
		Rooms.RoomStatusID AS room_status_id,
		RoomStatus.Name AS room_status,
		Tavern.ID AS tavern_id,
		Tavern.Name AS tavern_name
 FROM RoomStays JOIN Rooms ON RoomStays.RoomsID=Rooms.ID
 JOIN RoomStatus ON Rooms.RoomStatusID=RoomStatus.ID 
 JOIN Tavern ON Rooms.TavernID=Tavern.ID
 WHERE RoomStatus.Name=@status
 AND @inputdate NOT BETWEEN FromDate AND ToDate
 ) AS report_RoomsAvailable

 );

 SELECT * FROM getRoomStatusReport('01/27/2021','Available');


 /*******************************Query 6*******************************/

ALTER FUNCTION [dbo].[getRoomStatusReport] (@inputdate Date,@status varchar(50),@minRange money, @maxRange money)  
RETURNS TABLE  
AS  
RETURN
( 
SELECT 
  report_RoomsAvailable.room_id,
  report_RoomsAvailable.room_name,
  report_RoomsAvailable.room_status_id,
  report_RoomsAvailable.room_status,
  report_RoomsAvailable.room_price,
  report_RoomsAvailable.tavern_id,
  report_RoomsAvailable.tavern_name  
FROM
(
  -- report categories
 SELECT TOP 10 
		Rooms.ID AS room_id,
		Rooms.Name AS room_name,
		Rooms.RoomStatusID AS room_status_id,
		RoomStatus.Name AS room_status,
		Rooms.RoomRate AS room_price,		
		Tavern.ID AS tavern_id,
		Tavern.Name AS tavern_name
 FROM RoomStays JOIN Rooms ON RoomStays.RoomsID=Rooms.ID
 JOIN RoomStatus ON Rooms.RoomStatusID=RoomStatus.ID 
 JOIN Tavern ON Rooms.TavernID=Tavern.ID
 WHERE RoomStatus.Name=@status
 AND @inputdate NOT BETWEEN FromDate AND ToDate
 AND RoomRate between @minRange and @maxRange
 ORDER BY ABS(RoomRate-@minRange) ASC
 ) AS report_RoomsAvailable
 );

  SELECT * FROM getRoomStatusReport('01/27/2021','Available',10,50);


/*******************************Query 7*******************************/

INSERT INTO Rooms (
			[Name],			
			[RoomStatusID],
			[TavernID],
			[RoomRate]
			)
			VALUES (
			(SELECT TOP 1 CONCAT(room_name,'_',NEWID()) from getRoomStatusReport('01/27/2021','Available',10,50)),
			(SELECT TOP 1 room_status_id from getRoomStatusReport('01/27/2021','Available',10,50)),
			(SELECT TOP 1 ID FROM Tavern WHERE Tavern.ID<>(SELECT TOP 1 tavern_id from getRoomStatusReport('01/27/2021','Available',10,50))),
			(SELECT TOP 1 CAST(room_price AS money)-0.01 from getRoomStatusReport('01/27/2021','Available',10,50))
			);

SELECT * FROM Rooms ORDER BY RoomRate ASC;