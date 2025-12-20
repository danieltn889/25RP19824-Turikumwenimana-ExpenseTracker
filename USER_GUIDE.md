# Expense Tracker Application - User Guide

## Overview
Your Expense Tracker is now live with a beautiful, responsive interface featuring user authentication and complete expense management capabilities.

## Quick Start

### 1. **Access the Application**
```
URL: http://localhost/
```

### 2. **Create an Account**
- Click "Sign Up" on the login page
- Enter username, email, full name, and password
- Click "Sign Up"
- You'll be automatically logged in and directed to the dashboard

### 3. **Login**
- Enter your username and password
- Click "Login"
- Your session will be saved in your browser

### 4. **Manage Expenses**

#### Add an Expense:
1. Fill in the description (e.g., "Lunch at Cafe")
2. Enter the amount (e.g., 15.50)
3. Select a category (Food, Transport, Entertainment, Utilities, Other)
4. Click "Add Expense"

#### View Expenses:
- All your expenses appear immediately below the form
- Shows: Description, Category, Amount, Delete button

#### Delete an Expense:
- Click the "Delete" button on any expense
- Confirm the deletion
- Expense is removed from your account

#### View Summary:
- Right panel shows your statistics:
  - **Total Expenses**: Sum of all your expenses
  - **Number of Expenses**: Count of transactions
  - **Average Expense**: Average amount per transaction

### 5. **Logout**
- Click the "Logout" button in the top-right corner
- Confirm the logout
- You'll return to the login page

---

## Features

### 🎨 User Interface
- **Modern Design**: Gradient purple background with clean white cards
- **Responsive**: Works perfectly on mobile, tablet, and desktop
- **Intuitive**: Easy-to-use interface with clear navigation
- **Persistent**: Your session is saved in your browser

### 🔐 Security
- **JWT Tokens**: 24-hour session tokens
- **Encrypted Passwords**: Bcrypt hashing with 10 rounds
- **Data Isolation**: Each user only sees their own expenses
- **Secure API**: All endpoints protected with authentication

### 💾 Data Management
- **Real-time Updates**: Changes appear instantly
- **Automatic Calculations**: Summary updates as you add/delete expenses
- **Database Backed**: All data persists in PostgreSQL
- **Multi-user**: Completely separate accounts

---

## Responsive Design

### Mobile (< 768px)
```
┌─────────────────┐
│ Expense Tracker │
│  25RP19824      │
├─────────────────┤
│ Add Expense     │
│ ┌─────────────┐ │
│ │Description  │ │
│ ├─────────────┤ │
│ │Amount       │ │
│ ├─────────────┤ │
│ │Category     │ │
│ ├─────────────┤ │
│ │Add Expense  │ │
│ └─────────────┘ │
│                 │
│ Recent Expenses │
│ ─────────────── │
│ • Lunch $15.50  │
│ • Bus $2.00     │
│                 │
│ Summary:        │
│ Total: $17.50   │
│ Count: 2        │
│ Average: $8.75  │
└─────────────────┘
```

### Desktop (> 768px)
```
┌──────────────────────────────────────────────────────┐
│ 💰 Expense Tracker     👤 testuser    [Logout]      │
├────────────────────────────────┬─────────────────────┤
│                                │                     │
│ Add New Expense                │ Summary             │
│ ┌──────────────────────────┐   │ ┌─────────────────┐ │
│ │Description               │   │ │Total Expenses   │ │
│ │Amount | Category | [Add] │   │ │$17.50           │ │
│ └──────────────────────────┘   │ ├─────────────────┤ │
│                                │ │# of Expenses    │ │
│ Recent Expenses                │ │2                │ │
│ ──────────────────────────     │ ├─────────────────┤ │
│ Lunch        Food    $15.50 [X]│ │Average Expense  │ │
│ Bus Fare     Transport $2.00 [X]│ │$8.75            │ │
│                                │ └─────────────────┘ │
└────────────────────────────────┴─────────────────────┘
```

---

## Test Accounts

### Pre-created Account
```
Username: testuser
Password: password123
Email: test@example.com
```

### Create Your Own
Use the "Sign Up" button to create additional accounts.

---

## API Endpoints

### Authentication
```
POST /api/v1/auth/register
  - Body: {username, email, fullName, password}
  - Returns: {user, token}

POST /api/v1/auth/login
  - Body: {username, password}
  - Returns: {user, token}
```

### Expenses (Protected - Requires Token)
```
POST /api/v1/expenses
  - Add new expense
  - Body: {description, amount, category}

GET /api/v1/expenses
  - Get user's expenses

GET /api/v1/expenses/:id
  - Get specific expense

PUT /api/v1/expenses/:id
  - Update expense

DELETE /api/v1/expenses/:id
  - Delete expense
```

### Summary (Protected)
```
GET /api/v1/summary
  - Returns: {totalAmount, count, averageAmount}
```

---

## Troubleshooting

### Can't Login
- Check username and password are correct
- Make sure you signed up first
- Try creating a new account

### Expenses Not Showing
- Refresh the page (F5)
- Logout and login again
- Check that you're logged in (see username in top-right)

### Can't Add Expense
- Make sure you entered all fields
- Amount must be a number
- Category must be selected

### Lost Session
- Your session is saved automatically
- If you close the browser, you'll need to login again
- Session expires after 24 hours

---

## File Upload & More Features

This is Version 1.0 of the Expense Tracker with core features. Future versions could include:
- 📊 Expense charts and graphs
- 📅 Monthly/yearly reports
- 💳 Multiple currency support
- 🔔 Spending alerts
- 📁 Receipt uploads
- 👥 Expense sharing

---

## Architecture

```
Frontend (Nginx + HTML/CSS/JS)
    ↓ HTTP/REST
API Service (Node.js + Express)
    ↓ SQL
Database (PostgreSQL)
```

### Tech Stack
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Node.js 18, Express.js 4.18
- **Database**: PostgreSQL 15
- **Authentication**: JWT + Bcrypt
- **Container**: Docker + Docker Compose
- **CI/CD**: GitHub Actions
- **Repository**: GitHub

---

## Contact & Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the AUTHENTICATION_GUIDE.md for API details
3. Check GitHub repository: https://github.com/danieltn889/25RP19824-Turikumwenimana-ExpenseTracker

---

**Version**: 1.0  
**Student ID**: 25RP19824  
**Name**: Turikumwenimana  
**Deadline**: December 21, 2025 11:00 AM

🎉 Enjoy your Expense Tracker!
