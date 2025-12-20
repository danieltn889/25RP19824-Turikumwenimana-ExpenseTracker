const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  user: process.env.DB_USER || 'expenseuser',
  password: process.env.DB_PASSWORD || 'expensepass',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'expensetracker'
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    service: '25rp19824-turikumwenimana-api',
    timestamp: new Date().toISOString()
  });
});

// Create expense
app.post('/api/expenses', async (req, res) => {
  try {
    const { description, amount, category } = req.body;
    const id = uuidv4();
    const result = await pool.query(
      'INSERT INTO expenses (id, description, amount, category, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING *',
      [id, description, amount, category]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all expenses
app.get('/api/expenses', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM expenses ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`25rp19824-turikumwenimana API running on port ${PORT}`);
});
