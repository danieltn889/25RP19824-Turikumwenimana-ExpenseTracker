const { Pool } = require('pg');
const logger = require('./logger');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'expenses_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  max: 10,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
  ssl: false,
});

pool.on('error', (err) => {
  logger.error('Unexpected error on idle client', err);
});

async function query(text, params) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug(`Executed query in ${duration}ms`);
    return res;
  } catch (error) {
    logger.error(`Database query error: ${error.message}`);
    throw error;
  }
}

async function getClient() {
  const client = await pool.connect();
  return client;
}

module.exports = {
  query,
  getClient,
  pool
};
