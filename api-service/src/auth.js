const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { query } = require('./db');
const logger = require('./logger');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Generate JWT token
function generateToken(user) {
  return jwt.sign(
    { id: user.id, username: user.username, role: user.role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
}

// Verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
}

// Hash password
async function hashPassword(password) {
  return bcrypt.hash(password, 10);
}

// Compare password
async function comparePassword(password, hash) {
  return bcrypt.compare(password, hash);
}

// Middleware: Check if user is authenticated
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }

  req.user = decoded;
  next();
}

// Middleware: Check if user is admin
function authenticateAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

// Register new user
async function registerUser(username, email, password, fullName) {
  try {
    // Check if user exists
    const existingUser = await query(
      'SELECT id FROM users WHERE username = $1 OR email = $2',
      [username, email]
    );

    if (existingUser.rows.length > 0) {
      return { success: false, error: 'Username or email already exists' };
    }

    const hashedPassword = await hashPassword(password);
    const { v4: uuidv4 } = require('uuid');
    const userId = uuidv4();

    const result = await query(
      'INSERT INTO users (id, username, email, password, full_name, role) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [userId, username, email, hashedPassword, fullName || username, 'user']
    );

    const user = result.rows[0];
    const token = generateToken(user);

    logger.info(`User registered: ${username}`);

    return {
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      }
    };
  } catch (err) {
    logger.error(`Registration error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

// Login user
async function loginUser(username, password) {
  try {
    const result = await query(
      'SELECT * FROM users WHERE username = $1 AND is_active = TRUE',
      [username]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'Invalid credentials' };
    }

    const user = result.rows[0];
    const passwordMatch = await comparePassword(password, user.password);

    if (!passwordMatch) {
      return { success: false, error: 'Invalid credentials' };
    }

    const token = generateToken(user);

    logger.info(`User logged in: ${username}`);

    return {
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        full_name: user.full_name,
        profile_image: user.profile_image
      }
    };
  } catch (err) {
    logger.error(`Login error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

// Get user profile
async function getUserProfile(userId) {
  try {
    const result = await query(
      'SELECT id, username, email, full_name, profile_image, role, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'User not found' };
    }

    return { success: true, user: result.rows[0] };
  } catch (err) {
    logger.error(`Get profile error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

// Update user profile
async function updateUserProfile(userId, updates) {
  try {
    const { full_name, profile_image } = updates;
    const result = await query(
      'UPDATE users SET full_name = COALESCE($1, full_name), profile_image = COALESCE($2, profile_image), updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
      [full_name, profile_image, userId]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'User not found' };
    }

    logger.info(`User profile updated: ${userId}`);
    return { success: true, user: result.rows[0] };
  } catch (err) {
    logger.error(`Update profile error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

// Change password
async function changePassword(userId, oldPassword, newPassword) {
  try {
    const result = await query(
      'SELECT password FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'User not found' };
    }

    const passwordMatch = await comparePassword(oldPassword, result.rows[0].password);
    if (!passwordMatch) {
      return { success: false, error: 'Current password is incorrect' };
    }

    const hashedPassword = await hashPassword(newPassword);
    await query(
      'UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [hashedPassword, userId]
    );

    logger.info(`Password changed for user: ${userId}`);
    return { success: true, message: 'Password changed successfully' };
  } catch (err) {
    logger.error(`Change password error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

module.exports = {
  generateToken,
  verifyToken,
  hashPassword,
  comparePassword,
  authenticateToken,
  authenticateAdmin,
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
  changePassword
};
