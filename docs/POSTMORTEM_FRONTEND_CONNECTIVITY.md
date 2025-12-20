# Post-Mortem: Frontend-Backend Connectivity Issue
**Student ID:** 25RP19824  
**Project:** Turikumwenimana Expense Tracker  
**Incident Date:** December 20, 2025  
**Report Date:** December 20, 2025  
**Author:** Daniel Turikumwenimana

---

## Executive Summary

On December 20, 2025, the Expense Tracker application experienced issues with frontend-backend connectivity that prevented users from logging in and accessing the application. The issue was resolved within 30 minutes through systematic troubleshooting and configuration fixes.

**Impact:** Users unable to access login/signup functionality  
**Duration:** ~30 minutes  
**Root Cause:** Incorrect API endpoint configuration and JavaScript syntax errors  
**Resolution:** Fixed nginx proxy configuration and corrected JavaScript syntax

---

## Timeline

### Detection (21:00 UTC)
- User reported that login and signup modals were not functioning
- Browser console showed JavaScript errors and failed API calls

### Investigation (21:00 - 21:15 UTC)
- Checked Docker container status - all services running
- Verified backend API endpoints working correctly via curl
- Tested direct API access on port 3000 - successful
- Identified issue: frontend making requests to wrong endpoint
- Found JavaScript syntax error in frontend code

### Resolution (21:15 - 21:20 UTC)
- **Fix 1:** Updated `API_BASE` constant from `http://localhost:3000/api/v1` to `/api/v1`
  - This ensures requests go through nginx proxy instead of direct CORS requests
- **Fix 2:** Removed duplicate closing braces in `loadSummary()` function
  - Eliminated JavaScript syntax error preventing page load
- **Fix 3:** Corrected nginx proxy_pass configuration
  - Changed from `http://api:3000/` to `http://api:3000/api/`
  - Ensures proper API route forwarding

### Verification (21:20 - 21:30 UTC)
- Rebuilt and restarted frontend container
- Tested user registration - successful
- Tested user login - successful  
- Tested expense creation - successful
- Tested expense retrieval - successful
- Verified proper user isolation

---

## Root Cause Analysis

### Primary Causes

1. **Incorrect API Endpoint Configuration**
   - Frontend JavaScript had hardcoded `http://localhost:3000` endpoint
   - This caused CORS issues when accessing from `http://localhost`
   - Proper approach: Use relative URLs through nginx proxy

2. **JavaScript Syntax Error**
   - Duplicate catch blocks and closing braces in `loadSummary()` function
   - Prevented JavaScript from loading properly
   - Caused "Uncaught SyntaxError" in browser console

3. **Nginx Proxy Misconfiguration**
   - Initial proxy_pass stripped `/api/` prefix incorrectly
   - Backend routes expect `/api/v1/*` paths
   - Required adjustment to preserve full path

### Contributing Factors

- Insufficient frontend-backend integration testing
- Docker layer caching prevented code updates from being applied initially
- Changed from pre-built images to local builds required configuration updates

---

## What Went Well

✅ **Quick Detection**
- Issue reported immediately by end user
- Clear error messages in browser console

✅ **Systematic Troubleshooting**
- Verified each component independently
- Used curl to test API directly
- Checked Docker logs for all services

✅ **Effective Tools**
- Docker compose logs provided visibility
- curl enabled API verification
- Browser DevTools showed exact errors

✅ **Documentation**
- Clear error messages helped identify issues
- Service naming conventions were consistent

---

## What Could Be Improved

❌ **Testing Gaps**
- No end-to-end tests for frontend-backend integration
- Missing automated tests for login/signup flows
- Should have tested in browser before declaring complete

❌ **Configuration Management**
- API endpoint configuration should be environment-based
- Build process didn't catch syntax errors
- No pre-deployment validation

❌ **Monitoring**
- No automated health checks for frontend JavaScript
- Missing synthetic monitoring for user flows
- Should alert on JavaScript errors

---

## Action Items

### Immediate (Completed)
- [x] Fix API_BASE configuration to use relative URLs
- [x] Remove JavaScript syntax errors
- [x] Correct nginx proxy configuration
- [x] Test all user flows manually

### Short-term (Next 1-2 days)
- [ ] Add end-to-end tests with Playwright or Cypress
- [ ] Implement JavaScript linting in CI/CD pipeline
- [ ] Add synthetic monitoring for login/signup flows
- [ ] Document frontend-backend integration requirements

### Long-term (Next sprint)
- [ ] Implement automated browser testing in CI/CD
- [ ] Add frontend error monitoring (e.g., Sentry)
- [ ] Create comprehensive integration test suite
- [ ] Improve configuration management with environment variables

---

## Lessons Learned

### Technical Insights

1. **Docker Layer Caching**
   - Using `--no-cache` flag ensures fresh builds
   - Important when developing with Docker
   - Consider using volume mounts for development

2. **Frontend-Backend Communication**
   - Relative URLs prevent CORS issues
   - Nginx proxy simplifies architecture
   - Always test through the full stack

3. **JavaScript Error Handling**
   - Syntax errors prevent entire page load
   - Use linting tools (ESLint) to catch errors early
   - Browser DevTools are essential for debugging

### Process Improvements

1. **Testing Strategy**
   - Unit tests are not sufficient
   - Need integration and E2E tests
   - Test all user-facing flows before deployment

2. **Deployment Process**
   - Rebuild containers when code changes
   - Verify health checks after deployment
   - Test critical user flows manually

3. **Monitoring**
   - Backend monitoring alone is insufficient
   - Need frontend error tracking
   - Synthetic monitoring catches user-facing issues

---

## Preventive Measures

### Code Quality
```bash
# Add ESLint to catch syntax errors
npm install --save-dev eslint

# Run linting in CI/CD
npm run lint
```

### Testing
```bash
# Add E2E tests
npm install --save-dev cypress

# Test critical flows
- User registration
- User login
- Expense creation
- Expense listing
```

### Monitoring
```bash
# Frontend error tracking
- Implement Sentry or similar
- Monitor JavaScript errors
- Track user interactions

# Synthetic monitoring
- Regular health checks from external service
- Test login flow every 5 minutes
- Alert on failures
```

---

## Related Issues

- API authentication implementation (#1)
- Docker configuration updates (#2)
- Nginx proxy setup (#3)

---

## Appendix

### Error Messages Encountered

```
Uncaught SyntaxError: expected expression, got '}'
localhost:676:3

Uncaught ReferenceError: handleLogin is not defined
onclick http://localhost/:1
```

### Configuration Changes

**Before:**
```javascript
const API_BASE = 'http://localhost:3000/api/v1';
```

**After:**
```javascript
const API_BASE = '/api/v1';
```

**Before:**
```nginx
proxy_pass http://api:3000/;
```

**After:**
```nginx
proxy_pass http://api:3000/api/;
```

### Testing Results

| Test Case | Status | Notes |
|-----------|--------|-------|
| User Registration | ✅ Pass | Returns JWT token |
| User Login | ✅ Pass | Authenticates successfully |
| Expense Creation | ✅ Pass | Uses authenticated user_id |
| Expense Retrieval | ✅ Pass | Returns only user's expenses |
| User Isolation | ✅ Pass | Users see only their data |

---

## Sign-off

**Prepared by:** Daniel Turikumwenimana (25RP19824)  
**Date:** December 20, 2025  
**Reviewed by:** [Supervisor Name]  
**Status:** Resolved
