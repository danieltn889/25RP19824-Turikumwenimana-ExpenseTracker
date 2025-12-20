# Incident Response Runbook
**Student ID:** 25RP19824  
**Project:** Turikumwenimana Expense Tracker  
**Last Updated:** December 20, 2025

## Overview
This runbook provides step-by-step procedures for responding to incidents in the Expense Tracker application.

---

## 1. Service Down Incidents

### 1.1 API Service Down
**Alert:** `ServiceDown` (Critical)  
**Symptoms:** API returns 503 errors, health checks fail, Prometheus shows `up{job="api-service"} == 0`

#### Investigation Steps:
```bash
# Check service status
docker compose ps api

# Check recent logs
docker compose logs api --tail 100

# Check container resource usage
docker stats 25rp19824-turikumwenimana-api --no-stream
```

#### Resolution:
```bash
# Restart the service
docker compose restart api

# If restart fails, rebuild and restart
docker compose build api
docker compose up -d api

# Verify recovery
curl http://localhost:3000/health
```

#### Post-Incident:
- Document the root cause in `/evidence/logs/`
- Update monitoring thresholds if needed
- Review application logs for patterns

---

### 1.2 Database Down
**Alert:** `DatabaseDown` (Critical)  
**Symptoms:** Connection errors, API health check shows database unhealthy

#### Investigation Steps:
```bash
# Check database status
docker compose ps db

# Check database logs
docker compose logs db --tail 50

# Test database connection
docker compose exec db psql -U expenseuser -d expensedb -c "SELECT 1;"
```

#### Resolution:
```bash
# Restart database
docker compose restart db

# Check data persistence
docker volume ls | grep 25rp19824

# Restore from backup if needed
docker compose exec db psql -U expenseuser -d expensedb < backup.sql
```

---

## 2. Performance Degradation

### 2.1 High Response Time
**Alert:** `HighResponseTime` (Warning)  
**Symptoms:** p95 latency > 1 second

#### Investigation Steps:
```bash
# Check slow queries
docker compose logs api | grep "query took"

# Check database connections
docker compose exec db psql -U expenseuser -d expensedb -c "SELECT count(*) FROM pg_stat_activity;"

# Review Prometheus metrics
curl http://localhost:9090/api/v1/query?query=http_request_duration_ms
```

#### Resolution:
- Identify slow endpoints from metrics
- Optimize database queries
- Add database indexes if needed
- Consider implementing caching

---

### 2.2 High Memory Usage
**Alert:** `HighMemoryUsage` (Warning)  
**Symptoms:** Container memory > 256MB

#### Investigation Steps:
```bash
# Check memory usage by container
docker stats --no-stream

# Check for memory leaks
docker compose exec api node -e "console.log(process.memoryUsage())"
```

#### Resolution:
```bash
# Restart service to clear memory
docker compose restart api

# If persistent, increase memory limit in docker-compose.yml
# Or optimize application code
```

---

## 3. High Error Rate

### 3.1 Server Errors (5xx)
**Alert:** `HighErrorRate` (Warning)  
**Symptoms:** Error rate > 5%

#### Investigation Steps:
```bash
# Check error logs
docker compose logs api | grep "ERROR"

# Check for authentication failures
docker compose logs api | grep "401\|403"

# Review database connection errors
docker compose logs api | grep "database"
```

#### Resolution:
- Fix identified bugs in application code
- Restart services if transient errors
- Check database connectivity
- Review recent deployments for regressions

---

## 4. Common Troubleshooting Commands

### Service Management
```bash
# View all services
docker compose ps

# View logs for specific service
docker compose logs [service-name] -f

# Restart specific service
docker compose restart [service-name]

# Restart all services
docker compose restart

# Check resource usage
docker stats
```

### Database Operations
```bash
# Connect to database
docker compose exec db psql -U expenseuser -d expensedb

# Check active connections
SELECT count(*) FROM pg_stat_activity;

# Check database size
SELECT pg_size_pretty(pg_database_size('expensedb'));

# Kill long-running queries
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active';
```

### Monitoring & Metrics
```bash
# Access Prometheus UI
open http://localhost:9090

# Access Grafana
open http://localhost:3001
# Login: admin / admin123

# Access Alertmanager
open http://localhost:9093

# Query metrics directly
curl http://localhost:3000/metrics
```

---

## 5. Escalation Procedures

### Level 1: Automated Response
- Health checks trigger automatic restarts (if configured)
- Alertmanager sends notifications

### Level 2: Manual Intervention
- Review logs and metrics
- Execute runbook procedures
- Apply fixes or workarounds

### Level 3: Code Changes Required
- Identify bugs or architectural issues
- Implement fixes in development
- Test thoroughly before deployment
- Deploy using CI/CD pipeline

---

## 6. Post-Incident Review Template

### Incident Summary
- **Date/Time:** 
- **Duration:** 
- **Severity:** 
- **Services Affected:** 

### Timeline
- **Detection:** How was the incident detected?
- **Response:** What actions were taken?
- **Resolution:** How was it resolved?

### Root Cause Analysis
- **Primary Cause:** 
- **Contributing Factors:** 

### Action Items
- [ ] Immediate fixes applied
- [ ] Monitoring improvements
- [ ] Code changes needed
- [ ] Documentation updates

### Lessons Learned
- What went well?
- What could be improved?
- How to prevent similar incidents?

---

## 7. Health Check Endpoints

### API Health Check
```bash
curl http://localhost:3000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "25rp19824-turikumwenimana-api",
  "timestamp": "2025-12-20T...",
  "uptime": 1234.56,
  "checks": {
    "database": "healthy",
    "memory": "healthy"
  },
  "memory": {
    "heapUsedMB": 45,
    "heapTotalMB": 100
  }
}
```

### Frontend Health Check
```bash
curl http://localhost/health
```

### Database Health Check
```bash
docker compose exec db pg_isready -U expenseuser
```

---

## 8. Emergency Contacts

- **System Administrator:** [Your Contact]
- **Database Administrator:** [Your Contact]
- **On-Call Engineer:** [Rotation Schedule]

---

## 9. Related Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Monitoring Setup](../MONITORING_SETUP.md)
- [Testing Guide](../TESTING_GUIDE.md)
- [User Guide](../USER_GUIDE.md)
