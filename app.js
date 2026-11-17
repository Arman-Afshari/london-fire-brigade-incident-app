const express = require('express');
const mysql = require('mysql2');
const app = express();

// 1. Database Connection
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: process.env.DB_PASSWORD,
    database: 'lfb_data'
});

db.connect((err) => {
    if (err) console.error('Error connecting:', err);
    else console.log('✅ Connected to MySQL');
});

// 2. Setup View Engine
app.set('view engine', 'ejs');
app.use(express.static('public')); // Allow access to CSS/Images

// 3. Main Dashboard Route ( The UI )
app.get('/', (req, res) => {
    // We run a query to get Total Count to show on the dashboard
    db.query('SELECT COUNT(*) AS total FROM Incident', (err, results) => {
        const count = results[0].total;
        res.render('index', { totalIncidents: count });
    });
});

// 4. API Route for the Map (Returns JSON Data)
// We limit to 500 recent incidents to keep the map fast
app.get('/api/map-data', (req, res) => {
    const query = `
        SELECT I.IncidentNumber, I.DateOfCall, I.StationName, I.Latitude, I.Longitude, T.IncidentGroup 
        FROM Incident I
        JOIN IncidentType T ON I.TypeID = T.TypeID
        WHERE I.Latitude IS NOT NULL 
        ORDER BY I.DateOfCall DESC 
        LIMIT 500
    `;
    db.query(query, (err, results) => {
        if (err) {
            console.error(err); // Log error to console so server doesn't crash
            res.status(500).send("Database Error");
        } else {
            res.json(results);
        }
    });
});

// 5. Start Server
app.listen(3000, () => {
    console.log('🚀 Web App running at http://localhost:3000');
});

// 6. API Route for the Chart (Top 5 Stations)
app.get('/api/chart-data', (req, res) => {
    const query = `
        SELECT StationName, COUNT(*) as count 
        FROM Incident 
        WHERE StationName IS NOT NULL 
        GROUP BY StationName 
        ORDER BY count DESC 
        LIMIT 5
    `;
    db.query(query, (err, results) => {
        if (err) throw err;
        // Format data for Chart.js (Labels and Values)
        const labels = results.map(row => row.StationName);
        const data = results.map(row => row.count);
        res.json({ labels, data });
    });
});