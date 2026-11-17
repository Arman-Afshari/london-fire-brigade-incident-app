# London Fire Brigade Incident Analysis App

A full-stack data project that takes raw London Fire Brigade (LFB) incident records, cleans and normalises them into a relational MySQL database, answers three research questions with SQL, and presents the results in a Node.js web dashboard.

Built for the **CM3010 Databases and Advanced Data Techniques** module.

<img width="662" height="738" alt="dashboard" src="https://github.com/user-attachments/assets/c054951c-16d3-4e77-b8f5-e1fa85a304ba" />

## Project at a glance

| | |
|---|---|
| **Data** | LFB incident records, 2024 onwards (248,681 incidents) |
| **Preprocessing** | Python, pandas |
| **Database** | MySQL 8.0, normalised to Third Normal Form (3NF) |
| **Backend** | Node.js, Express 5, mysql2 |
| **Frontend** | EJS templates, Chart.js, Leaflet.js |
| **Full write-up** | [Final report (PDF)](London%20Fire%20Brigade%20Incident%20Analysis%20Final%20Report.pdf) |

## Research questions

1. **Resource load:** which fire stations handled the most incidents?
2. **Incident taxonomy:** how do false alarms compare with real fires and special services (such as rescues)?
3. **Response efficiency:** what are the average, fastest and slowest first-pump response times, and do the outliers point to data errors?

## Key findings

- **Central London stations are the busiest.** Soho (6,553 incidents), Paddington (6,067), Lambeth (5,113), Euston (4,685) and North Kensington (4,629) lead the list.
- **False alarms make up almost half of all calls.** False alarms are 46.5% of incidents, special services 40.1% and fires 13.4%, so reducing false alarms could free up a lot of capacity.
- **Average first-pump response time is about 325 seconds (roughly 5.4 minutes).** The fastest recorded response is 1 second and the slowest is 1,200 seconds, so the extreme values are worth checking as possible data-entry issues.

### Query results

**Busiest stations chart**

![chart](https://github.com/user-attachments/assets/c23d7205-74dd-472c-950b-732089430171)

**Incident map**

![map](https://github.com/user-attachments/assets/333969c7-a105-4881-b715-82b8043c0eb3)

**Response times**

![query-response-times](https://github.com/user-attachments/assets/d5dcba9a-6728-43b1-925f-ad52aa2268c6)

## Database design

The raw data is a flat Excel file with 25+ columns and a lot of repeated information. I split it into three tables to remove redundancy and reach 3NF. For example, a station's borough depends on the station, not on the individual incident, so it lives in its own table.

<img width="2431" height="1476" alt="erd" src="https://github.com/user-attachments/assets/e7f8078a-1c23-4f69-b740-441fbacc2891" />

```
Station      (StationName PK, Borough)
IncidentType (TypeID PK, IncidentGroup, StopCodeDescription)
Incident     (IncidentNumber PK, DateOfCall, TimeOfCall, TypeID FK, StationName FK,
              Latitude, Longitude, ResponseTimeSeconds, PumpCount)
```

- `Station` to `Incident` is one-to-many (each incident is assigned to one ground station).
- `IncidentType` to `Incident` is one-to-many (each incident has one classification).
- Foreign keys enforce referential integrity between the tables.

## Data pipeline

1. **Extract:** `python_script.ipynb` reads the raw LFB Excel file with pandas.
2. **Transform:** it converts dates to MySQL format, drops rows missing key fields, extracts unique stations and incident types, and assigns type IDs.
3. **Load:** it writes `stations.csv`, `incident_types.csv` and `incidents.csv`, with missing values written as `NULL` so MySQL's `LOAD DATA` handles them cleanly.
4. **Clean up in SQL:** after import, `UPDATE` statements set coordinates and response times of `0` to `NULL`, so incidents aren't plotted at (0, 0) and don't skew averages.

## Web application

The Express server exposes a dashboard and two JSON endpoints:

| Route | Description |
|---|---|
| `/` | Dashboard with total incident count, chart and map |
| `/api/chart-data` | Top 5 busiest stations (`GROUP BY` query) for Chart.js |
| `/api/map-data` | Latest 500 incidents with coordinates, joined to `IncidentType`, for Leaflet |

## Repository structure

```
.
├── app.js                  # Express server and API routes
├── views/index.ejs         # Dashboard template
├── public/                 # Static assets
├── python_script.ipynb     # Data cleaning and normalisation
├── sql_script.sql          # Schema, import and research queries
├── stations.csv            # Station lookup table
├── incident_types.csv      # Incident type lookup table
├── incidents.csv           # Main incident table (~248k rows)
├── screenshots/            # Images used in this README
├── package.json
└── London Fire Brigade Incident Analysis Final Report.pdf
```

## Getting started

### Prerequisites

- [Node.js](https://nodejs.org) 18 or later
- MySQL Server 8.0 (and MySQL Workbench, optional)

### 1. Install dependencies

```bash
npm install
```

### 2. Create and populate the database

Run the schema section of `sql_script.sql` to create the `lfb_data` database and the three tables. The script only loads `incidents.csv`, so load the two lookup tables first (update the file paths to match your machine):

```sql
LOAD DATA LOCAL INFILE '/path/to/stations.csv'
INTO TABLE Station
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/path/to/incident_types.csv'
INTO TABLE IncidentType
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(IncidentGroup, StopCodeDescription, TypeID);
```

Then run the `LOAD DATA` statement for `incidents.csv` in `sql_script.sql`, followed by the cleanup `UPDATE` statements. If MySQL blocks the import, enable `local_infile` on the server and in your client connection.

### 3. Configure the database connection

The app reads its database credentials from environment variables, so no password is stored in the code:

| Variable | Default |
|---|---|
| `DB_HOST` | `localhost` |
| `DB_USER` | `root` |
| `DB_PASSWORD` | *(none)* |
| `DB_NAME` | `lfb_data` |

### 4. Run the app

```bash
DB_PASSWORD=your_password node app.js
```

Then open <http://localhost:3000>.

## Data source and licence

Incident data comes from the [London Datastore: London Fire Brigade Incident Records](https://data.london.gov.uk/dataset/london-fire-brigade-incident-records), published under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/). The raw Excel file is not included in this repository because of its size, so download it from the link above if you want to re-run the preprocessing step.

The code in this repository is released under the MIT licence.

## Possible improvements

- Add filters for date range, borough and incident type.
- Add a response-time chart by station or borough.
- Cluster map markers and let users load more than the latest 500 incidents.
- Investigate extreme response times to separate data errors from genuine delays.

## Author

**Arman Afshari**: [LinkedIn](https://www.linkedin.com/in/arman-afshari) · [GitHub](https://github.com/Arman-Afshari)
