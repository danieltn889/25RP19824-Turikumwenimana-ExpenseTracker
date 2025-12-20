const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { v4: uuidv4 } = require('uuid');
// const { query } = require('./db');
// const logger = require('./logger');
const { query } = require('./db');
const logger = require('./logger');
const {
  authenticateToken,
  authenticateAdmin,
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
  changePassword
} = require('./auth');

// Prometheus metrics
const promClient = require('prom-client');

// Use the global registry
const register = promClient.register;

// Default metrics
promClient.collectDefaultMetrics();

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeUsers = new promClient.Gauge({
  name: 'active_users_total',
  help: 'Number of active users in the system'
});

const totalExpenses = new promClient.Gauge({
  name: 'total_expenses_count',
  help: 'Total number of expenses in the system'
});

require('dotenv').config();

const app = express();
const port = process.env.API_PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.options('*', cors()); // Handle preflight requests
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Prometheus metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route?.path || req.path || 'unknown';
    httpRequestDuration.labels(req.method, route, res.statusCode.toString()).observe(duration);
    httpRequestTotal.labels(req.method, route, res.statusCode.toString()).inc();
  });
  next();
});

// Rate limiting
// const limiter = rateLimit({
//   windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
//   max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
//   message: 'Too many requests, please try again later',
//   standardHeaders: true,
//   legacyHeaders: false
// });
// app.use(limiter);

// Test route
app.get('/ping', (req, res) => {
  res.json({ message: 'pong' });
});

// ============ HEALTH CHECK ============
app.get('/health', async (req, res) => {
  console.log('Health check requested');
  const health = {
    status: 'healthy',
    service: '25rp19824-turikumwenimana-api',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      database: 'unknown',
      memory: 'unknown'
    }
  };

  // Database connectivity check
  try {
    const result = await query('SELECT 1 as health');
    health.checks.database = result.rows.length > 0 ? 'healthy' : 'unhealthy';
  } catch (err) {
    health.checks.database = 'unhealthy';
    health.status = 'degraded';
    logger.error(`Database health check failed: ${err.message}`);
  }

  // Memory check
  const memUsage = process.memoryUsage();
  const memUsageMB = Math.round(memUsage.heapUsed / 1024 / 1024);
  health.checks.memory = memUsageMB < 500 ? 'healthy' : 'warning';
  health.memory = { heapUsedMB: memUsageMB, heapTotalMB: Math.round(memUsage.heapTotal / 1024 / 1024) };

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// ============ PROMETHEUS METRICS ============
app.get('/metrics', async (req, res) => {
  console.log('Metrics endpoint called at', new Date().toISOString());
  
  // Update gauge metrics
  try {
    const usersResult = await query('SELECT COUNT(*) as count FROM users');
    activeUsers.set(parseInt(usersResult.rows[0].count));
    
    const expensesResult = await query('SELECT COUNT(*) as count FROM expenses');
    totalExpenses.set(parseInt(expensesResult.rows[0].count));
  } catch (err) {
    logger.error(`Failed to update metrics: ${err.message}`);
  }
  
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// ============ AUTHENTICATION ENDPOINTS ============
// Login
app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const result = await loginUser(username, password);
    res.json(result);
  } catch (err) {
    logger.error(`Login error: ${err.message}`);
    res.status(401).json({ error: err.message });
  }
});

// Register
app.post('/api/v1/auth/register', async (req, res) => {
  try {
    const { username, email, fullName, password } = req.body;
    const result = await registerUser(username, email, fullName, password);
    res.json(result);
  } catch (err) {
    logger.error(`Register error: ${err.message}`);
    res.status(400).json({ error: err.message });
  }
});

// Get user profile
app.get('/api/v1/auth/profile', authenticateToken, async (req, res) => {
  try {
    const result = await getUserProfile(req.user.id);
    res.json(result);
  } catch (err) {
    logger.error(`Get profile error: ${err.message}`);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

// Update user profile
app.put('/api/v1/auth/profile', authenticateToken, async (req, res) => {
  try {
    const { fullName, email } = req.body;
    const result = await updateUserProfile(req.user.id, fullName, email);
    res.json(result);
  } catch (err) {
    logger.error(`Update profile error: ${err.message}`);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Change password
app.put('/api/v1/auth/password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    await changePassword(req.user.id, currentPassword, newPassword);
    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    logger.error(`Change password error: ${err.message}`);
    res.status(400).json({ error: err.message });
  }
});

// ============ EXPENSE ENDPOINTS (USER) ============
app.post('/api/v1/expenses', authenticateToken, async (req, res) => {
  try {
    const { description, amount, category } = req.body;

    if (!description || !amount || !category) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const userId = req.user.id;
    const id = uuidv4();
    const result = await query(
      'INSERT INTO expenses (id, user_id, description, amount, category) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [id, userId, description, amount, category]
    );

    logger.info(`Expense created: ${id} for user: ${req.user.username}`);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    logger.error(`Create expense error: ${err.message}`);
    res.status(500).json({ error: 'Failed to create expense' });
  }
});

// Get user's expenses with filters
app.get('/api/v1/expenses', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Simple query - get all expenses for the user
    const result = await query(
      `SELECT * FROM expenses WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId]
    );

    logger.info(`Retrieved ${result.rows.length} expenses for user: ${req.user.username}`);
    res.json(result.rows);
  } catch (err) {
    logger.error(`Get expenses error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch expenses' });
  }
});

// Get single expense
app.get('/api/v1/expenses/:id', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await query(
      'SELECT * FROM expenses WHERE id = $1 AND user_id = $2',
      [req.params.id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Expense not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Get expense error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch expense' });
  }
});

// Update expense
app.put('/api/v1/expenses/:id', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { description, amount, category } = req.body;

    const checkResult = await query(
      'SELECT user_id FROM expenses WHERE id = $1',
      [req.params.id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Expense not found' });
    }

    if (checkResult.rows[0].user_id !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const result = await query(
      'UPDATE expenses SET description = COALESCE($1, description), amount = COALESCE($2, amount), category = COALESCE($3, category), updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING *',
      [description, amount, category, req.params.id]
    );

    logger.info(`Expense updated: ${req.params.id} for user: ${req.user.username}`);
    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Update expense error: ${err.message}`);
    res.status(500).json({ error: 'Failed to update expense' });
  }
});

// Delete expense
app.delete('/api/v1/expenses/:id', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const checkResult = await query(
      'SELECT user_id FROM expenses WHERE id = $1',
      [req.params.id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Expense not found' });
    }

    if (checkResult.rows[0].user_id !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    await query('DELETE FROM expenses WHERE id = $1', [req.params.id]);

    logger.info(`Expense deleted: ${req.params.id} for user: ${req.user.username}`);
    res.json({ message: 'Expense deleted successfully' });
  } catch (err) {
    logger.error(`Delete expense error: ${err.message}`);
    res.status(500).json({ error: 'Failed to delete expense' });
  }
});

// Get user's summary statistics
app.get('/api/v1/summary', authenticateToken, async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        COUNT(*)::text as total_expenses,
        TO_CHAR(SUM(amount), '999,999.99') as total_amount,
        TO_CHAR(AVG(amount), '999,999.99') as average_amount,
        TO_CHAR(MIN(amount), '999,999.99') as min_amount,
        TO_CHAR(MAX(amount), '999,999.99') as max_amount
      FROM expenses 
      WHERE user_id = $1`,
      [req.user.id]
    );

    logger.info(`Summary generated for user: ${req.user.username}`);
    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Get summary error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch summary' });
  }
});

// ============ ADMIN ENDPOINTS ============

// Get all users (admin only)
app.get('/api/v1/admin/users', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, username, email, full_name, role, is_active, created_at FROM users ORDER BY created_at DESC'
    );

    logger.info(`Admin fetched all users`);
    res.json(result.rows);
  } catch (err) {
    logger.error(`Get users error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get user details (admin only)
app.get('/api/v1/admin/users/:userId', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, username, email, full_name, role, is_active, created_at FROM users WHERE id = $1',
      [req.params.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Get user error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Get user's expenses statistics (admin only)
app.get('/api/v1/admin/users/:userId/expenses', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    let whereClause = 'WHERE user_id = $1';
    let params = [req.params.userId];
    let paramCount = 1;

    if (startDate) {
      paramCount++;
      whereClause += ` AND created_at >= $${paramCount}`;
      params.push(new Date(startDate));
    }

    if (endDate) {
      paramCount++;
      whereClause += ` AND created_at <= $${paramCount}`;
      params.push(new Date(endDate));
    }

    const result = await query(
      `SELECT * FROM expenses ${whereClause} ORDER BY created_at DESC`,
      params
    );

    logger.info(`Admin fetched expenses for user: ${req.params.userId}`);
    res.json(result.rows);
  } catch (err) {
    logger.error(`Get user expenses error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch expenses' });
  }
});

// Get user's summary (admin only)
app.get('/api/v1/admin/users/:userId/summary', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const { month, year } = req.query;
    let whereClause = 'WHERE user_id = $1';
    let params = [req.params.userId];
    let paramCount = 1;

    if (month && year) {
      paramCount++;
      whereClause += ` AND EXTRACT(MONTH FROM created_at) = $${paramCount} AND EXTRACT(YEAR FROM created_at) = $${++paramCount}`;
      params.push(month, year);
    } else if (year) {
      paramCount++;
      whereClause += ` AND EXTRACT(YEAR FROM created_at) = $${paramCount}`;
      params.push(year);
    }

    const result = await query(
      `SELECT 
        COUNT(*)::text as total_expenses,
        TO_CHAR(SUM(amount), '999,999.99') as total_amount,
        TO_CHAR(AVG(amount), '999,999.99') as average_amount,
        TO_CHAR(MIN(amount), '999,999.99') as min_amount,
        TO_CHAR(MAX(amount), '999,999.99') as max_amount
      FROM expenses ${whereClause}`,
      params
    );

    logger.info(`Admin generated summary for user: ${req.params.userId}`);
    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Get user summary error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch summary' });
  }
});

// Deactivate user (admin only)
app.put('/api/v1/admin/users/:userId/deactivate', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const result = await query(
      'UPDATE users SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [req.params.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    logger.info(`Admin deactivated user: ${req.params.userId}`);
    res.json({ message: 'User deactivated successfully' });
  } catch (err) {
    logger.error(`Deactivate user error: ${err.message}`);
    res.status(500).json({ error: 'Failed to deactivate user' });
  }
});

// Activate user (admin only)
app.put('/api/v1/admin/users/:userId/activate', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const result = await query(
      'UPDATE users SET is_active = TRUE, updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [req.params.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    logger.info(`Admin activated user: ${req.params.userId}`);
    res.json({ message: 'User activated successfully' });
  } catch (err) {
    logger.error(`Activate user error: ${err.message}`);
    res.status(500).json({ error: 'Failed to activate user' });
  }
});

// Get global statistics (admin only)
app.get('/api/v1/admin/statistics', authenticateToken, authenticateAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT 
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM expenses) as total_expenses,
        TO_CHAR((SELECT COALESCE(SUM(amount), 0) FROM expenses), '999,999.99') as total_amount,
        (SELECT COUNT(*) FILTER (WHERE role = 'admin') FROM users) as admin_count,
        (SELECT COUNT(*) FILTER (WHERE role = 'user') FROM users) as user_count
    `);

    logger.info(`Admin fetched global statistics`);
    res.json(result.rows[0]);
  } catch (err) {
    logger.error(`Get statistics error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// Error handling
app.use((err, req, res, _next) => {
  logger.error(`Unhandled error: ${err.message}`);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(port, () => {
  logger.info(`25rp19824-turikumwenimana API listening on port ${port}`);
  console.log(`API running on port ${port}`);
});

module.exports = app;
