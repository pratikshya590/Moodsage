const mysql = require('mysql2/promise');

// A "pool" keeps a few connections open and reuses them (faster than
// opening a new connection for every request).
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'moodsage',
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z', // store and read all dates in UTC
});

module.exports = pool;