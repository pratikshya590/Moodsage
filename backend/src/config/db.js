const mysql = require('mysql2/promise');

// Cloud MySQL (TiDB) needs an encrypted connection; local MySQL does not.
const useSsl = process.env.DB_SSL === 'true';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z', // store and read all dates as UTC
  ...(useSsl && { ssl: { minVersion: 'TLSv1.2', rejectUnauthorized: true } }),
});

module.exports = pool;