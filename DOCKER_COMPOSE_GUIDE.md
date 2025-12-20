# Docker Compose Setup & Testing Guide

## Quick Start

### 1. Start All Services
```bash
cd /home/daniel/25RP19824-Turikumwenimana-Project
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml up -d
```

### 2. Wait for Services to Initialize
```bash
sleep 10
```

### 3. Verify All Services Are Running
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml ps
```

---

## Service Ports & Access

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Frontend | 80 | http://localhost | Web UI for expense tracking |
| API | 3000 | http://localhost:3000 | REST API endpoints |
| Database | 5432 | postgres://localhost | PostgreSQL database |
| Prometheus | 9090 | http://localhost:9090 | Metrics collection & queries |
| Grafana | 3001 | http://localhost:3001 | Dashboards (admin/admin123) |
| AlertManager | 9093 | http://localhost:9093 | Alert management |

---

## Testing Checklist

### ✓ Test 1: Health Check
```bash
curl http://localhost:3000/health | jq .
```
**Expected Response:**
```json
{
  "status": "healthy",
  "service": "25rp19824-turikumwenimana-api",
  "timestamp": "2025-12-20T17:06:00.000Z",
  "uptime": 12345.678
}
```

### ✓ Test 2: User Registration
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username":"newuser",
    "email":"newuser@example.com",
    "password":"password123",
    "fullName":"New User"
  }' | jq .
```
**Expected Response:** Success message with user details

### ✓ Test 3: User Login
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}' | jq -r '.token')

echo "Token: $TOKEN"
```
**Expected Response:** Valid JWT token

### ✓ Test 4: Add Expense
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}' | jq -r '.token')

curl -X POST http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Test Expense","amount":50.00,"category":"Food"}' | jq .
```
**Expected Response:** New expense with ID and timestamp

### ✓ Test 5: Get Expenses
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}' | jq -r '.token')

curl http://localhost:3000/api/v1/expenses \
  -H "Authorization: Bearer $TOKEN" | jq .
```
**Expected Response:** Array of user's expenses

### ✓ Test 6: Metrics Endpoint
```bash
curl http://localhost:3000/metrics | head -50
```
**Expected Response:** Prometheus format metrics
```
# HELP process_cpu_user_seconds_total Total user CPU time spent in seconds.
# TYPE process_cpu_user_seconds_total counter
process_cpu_user_seconds_total 0.777954
...
```

### ✓ Test 7: Prometheus Query
```bash
curl 'http://localhost:9090/api/v1/query?query=http_requests_total' | jq .
```
**Expected Response:** Array of metrics with values

### ✓ Test 8: Frontend Access
```bash
curl -I http://localhost/
```
**Expected Response:**
```
HTTP/1.1 200 OK
Content-Type: text/html
```

---

## Database Testing

### Connect to PostgreSQL
```bash
docker exec -it 25rp19824-turikumwenimana-db psql -U postgres -d expenses_db
```

### Check Tables
```sql
\dt
```

### Count Expenses
```sql
SELECT COUNT(*) FROM expenses;
```

### View Users
```sql
SELECT username, email, role FROM users;
```

### Exit PostgreSQL
```
\q
```

---

## Monitoring Testing

### 1. View Prometheus Targets
Open: http://localhost:9090/targets

Should show:
- ✓ api-service (25rp19824-turikumwenimana-api:3000) - UP
- ✓ database (25rp19824-turikumwenimana-db:5432) - UP
- ✓ prometheus (localhost:9090) - UP

### 2. Query Metrics in Prometheus
Go to: http://localhost:9090/graph

Try queries:
- `http_requests_total`
- `process_resident_memory_bytes`
- `http_request_duration_ms`
- `db_connection_pool_size`

### 3. View Grafana Dashboards
Open: http://localhost:3001
- Username: admin
- Password: admin123

---

## Common Commands

### View Service Logs
```bash
# All services
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml logs

# Specific service
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml logs api
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml logs db
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml logs prometheus
```

### Stop All Services
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml down
```

### Restart Services
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml restart
```

### Rebuild Images
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml build
```

### View Container Status
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml ps
```

### Clean Up (Remove Everything)
```bash
docker compose -f docker-compose.yml -f docker-compose-monitoring.yml down -v
```

---

## Troubleshooting

### API Not Responding
```bash
# Check logs
docker compose logs api

# Verify database connection
docker compose logs db

# Restart API
docker compose restart api
```

### Metrics Not Showing
```bash
# Check Prometheus logs
docker compose logs prometheus

# Verify API metrics endpoint
curl http://localhost:3000/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq .
```

### Database Connection Error
```bash
# Verify database is running
docker compose ps db

# Check database logs
docker compose logs db

# Rebuild database container
docker compose up -d --build db
```

### Port Already in Use
```bash
# Find what's using the port (e.g., 3000)
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or change the port in docker-compose.yml
```

---

## Performance Testing

### Generate Load (10 API Requests)
```bash
for i in {1..10}; do
  curl -s http://localhost:3000/health > /dev/null &
done
wait
```

### Check Metrics After Load
```bash
curl -s http://localhost:3000/metrics | grep http_requests_total
```

### Monitor in Real-Time
```bash
# Terminal 1: Watch metrics
watch -n 1 'curl -s http://localhost:3000/metrics | grep http_requests_total'

# Terminal 2: Send requests
for i in {1..100}; do curl -s http://localhost:3000/health > /dev/null; done
```

---

## Data Persistence

All data is persisted in Docker volumes:
- `postgres_data` - Database files
- `prometheus_data` - Metrics history
- `grafana_data` - Dashboard configurations
- `alertmanager_data` - Alert history

Data survives container restarts:
```bash
docker compose down  # Stops containers, keeps volumes
docker compose up -d  # Restarts with same data
```

To delete all data:
```bash
docker compose down -v  # Removes volumes too
```

---

## Git Commands

### View Recent Changes
```bash
git log --oneline -5
```

### Show What Changed
```bash
git show HEAD
```

### View Uncommitted Changes
```bash
git status
```

### Commit Changes
```bash
git add .
git commit -m "Your message here"
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Network                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                  │
│  │   Frontend   │    │      API     │                  │
│  │   (nginx)    │───→│   (Node.js)  │                  │
│  │   Port 80    │    │   Port 3000  │                  │
│  └──────────────┘    └──────────────┘                  │
│                            │                            │
│                            ▼                            │
│                    ┌──────────────┐                     │
│                    │   Database   │                     │
│                    │ (PostgreSQL) │                     │
│                    │   Port 5432  │                     │
│                    └──────────────┘                     │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │
│  │ Prometheus   │    │   Grafana    │    │ AlertMgr │  │
│  │  Port 9090   │───→│   Port 3001  │    │ Port 9093│  │
│  └──────────────┘    └──────────────┘    └──────────┘  │
│         ▲                                                │
│         │ (scrapes every 30s)                           │
│         │                                                │
│         └────────────────API /metrics                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Security Notes

- Frontend communicates with API over HTTP (can use HTTPS in production)
- All database connections use internal Docker network (no external exposure)
- JWT tokens used for API authentication (7-day expiration)
- Rate limiting: 100 requests per 15 minutes
- Non-root user in API container (nodejs:1001)

---

## Summary

✓ All 6 services running in Docker containers
✓ Database persisted with PostgreSQL volumes
✓ Metrics collected and stored in Prometheus
✓ Real-time monitoring with Grafana
✓ Alert management with AlertManager
✓ Full API testing available
✓ Frontend UI fully functional
✓ Production-ready configuration

**System Status:** OPERATIONAL ✅
