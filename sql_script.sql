-- 1. Create the Database Schema
CREATE DATABASE IF NOT EXISTS lfb_data;
USE lfb_data;

-- 2. Create 'Station' Table (3rd Normal Form: Separating location data)
CREATE TABLE Station (
    StationName VARCHAR(100) PRIMARY KEY,
    Borough VARCHAR(100)
);

-- 3. Create 'IncidentType' Table (3rd Normal Form: Separating classifications)
CREATE TABLE IncidentType (
    TypeID INT PRIMARY KEY,
    IncidentGroup VARCHAR(50),
    StopCodeDescription VARCHAR(255)
);

-- 4. Create 'Incident' Table (Main Transactional Table)
CREATE TABLE Incident (
    IncidentNumber VARCHAR(20) PRIMARY KEY,
    DateOfCall DATE,
    TimeOfCall TIME,
    TypeID INT,
    StationName VARCHAR(100),
    Latitude DECIMAL(10, 6),   -- Precision required for Leaflet Map
    Longitude DECIMAL(10, 6),
    ResponseTimeSeconds INT,
    PumpCount INT,
    
    -- Foreign Keys ensuring Referential Integrity
    FOREIGN KEY (StationName) REFERENCES Station(StationName),
    FOREIGN KEY (TypeID) REFERENCES IncidentType(TypeID)
);

-- 5. Efficient Bulk Import using LOAD DATA
LOAD DATA LOCAL INFILE 'D:/projects/lfb-app/incidents.csv' 
INTO TABLE Incident 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS 
(IncidentNumber, @DateStr, TimeOfCall, TypeID, StationName, @Lat, @Lon, @Resp, @Pump) 
SET 
    DateOfCall = STR_TO_DATE(@DateStr, '%Y-%m-%d'), 
    Latitude = NULLIF(@Lat, 'NULL'),            -- Converts string "NULL" to SQL NULL
    Longitude = NULLIF(@Lon, 'NULL'),           -- Converts string "NULL" to SQL NULL
    ResponseTimeSeconds = NULLIF(@Resp, 'NULL'),
    PumpCount = NULLIF(TRIM(@Pump), '');        -- Trims whitespace to prevent integer errors

-- 6. Post-Import Data Cleaning
-- Ensures that spatial visualizations do not plot points at (0,0) coordinates.
SET SQL_SAFE_UPDATES = 0;
UPDATE Incident SET Latitude = NULL WHERE Latitude = 0;
UPDATE Incident SET Longitude = NULL WHERE Longitude = 0;
UPDATE Incident SET ResponseTimeSeconds = NULL WHERE ResponseTimeSeconds = 0;
SET SQL_SAFE_UPDATES = 1;


SELECT 
    StationName, 
    COUNT(*) AS TotalIncidents 
FROM Incident 
WHERE StationName IS NOT NULL
GROUP BY StationName 
ORDER BY TotalIncidents DESC 
LIMIT 5;


SELECT 
    T.IncidentGroup, 
    COUNT(I.IncidentNumber) AS TotalCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Incident), 2) AS Percentage
FROM Incident I
JOIN IncidentType T ON I.TypeID = T.TypeID
GROUP BY T.IncidentGroup
ORDER BY TotalCount DESC;


SELECT 
    ROUND(AVG(ResponseTimeSeconds), 0) AS AvgResponse_Seconds, 
    MIN(ResponseTimeSeconds) AS Fastest_Seconds,
    MAX(ResponseTimeSeconds) AS Slowest_Seconds
FROM Incident 
WHERE ResponseTimeSeconds IS NOT NULL AND ResponseTimeSeconds > 0;