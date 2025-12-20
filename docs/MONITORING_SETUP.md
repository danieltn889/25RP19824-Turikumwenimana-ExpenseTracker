# Monitoring & Observability Setup Guide
**Student ID:** 25RP19824  
**Project:** Turikumwenimana Expense Tracker  
**Date:** December 20, 2025

## Overview
This document describes the comprehensive monitoring and observability setup for the Expense Tracker application.

---

## 1. Monitoring Stack

### Components
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Application Logs**: Structured logging with Winston

### Architecture
```
Application (API) → Prometheus → Grafana (Visualization)
                       ↓
                  Alertmanager → Notifications
```

---

## 2. Metrics Collection

### 2.1 Prometheus Configuration

**Scrape Intervals:**
- API Service: Every 30 seconds
- Database: Every 60 seconds
- Prometheus self-monitoring: Every 15 seconds

**Configuration:** `/monitoring/prometheus.yml`

```yaml
scrape_configs:
  - job_name: 'api-service'
    static_configs:
      - targets: ['api:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

### 2.2 Application Metrics

**Default Metrics (prom-client):**
- `process_cpu_seconds_total`: CPU usage
- `process_resident_memory_bytes`: Memory usage
- `nodejs_heap_size_total_bytes`: Node.js heap size
- `nodejs_heap_size_used_bytes`: Node.js heap usage
- `nodejs_eventloop_lag_seconds`: Event loop lag

**Custom Application Metrics:**

| Metric Name | Type | Description | Labels |
|------------|------|-------------|--------|
| `http_requests_total` | Counter | Total HTTP requests | method, route, status_code |
| `http_request_duration_ms` | Histogram | Request duration in ms | method, route, status_code |
| `active_users_total` | Gauge | Number of registered users | - |
| `total_expenses_count` | Gauge | Total expenses in system | - |
| `db_query_duration_seconds` | Histogram | Database query duration | query_type |

**Accessing Metrics:**
```bash
curl http://localhost:3000/metrics
```

---

## 3. Health Checks

### 3.1 API Health Check

**Endpoint:** `GET /health`

**Checks Performed:**
1. Service availability
2. Database connectivity
3. Memory usage
4. Process uptime

**Response Format:**
```json
{
  "status": "healthy|degraded|unhealthy",
  "service": "25rp19824-turikumwenimana-api",
  "timestamp": "2025-12-20T10:30:00.000Z",
  "uptime": 3600.5,
  "checks": {
    "database": "healthy|unhealthy",
    "memory": "healthy|warning"
  },
  "memory": {
    "heapUsedMB": 45,
    "heapTotalMB": 100
  }
}
```

**Status Codes:**
- `200`: All systems healthy
- `503`: Service degraded or unhealthy

### 3.2 Docker Health Checks

**API Service:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Database Service:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U expenseuser"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**Frontend Service:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
  interval: 30s
  timeout: 5s
  retries: 3
```

---

## 4. Alerting Configuration

### 4.1 Alert Rules

**Location:** `/monitoring/alerts.yml`

**Alert Levels:**
- **Critical**: Immediate action required (service down, data loss risk)
- **Warning**: Investigation needed (performance degradation, resource usage)

**Configured Alerts:**

| Alert Name | Severity | Condition | Duration | Action |
|-----------|----------|-----------|----------|--------|
| ServiceDown | Critical | `up{job="api-service"} == 0` | 2m | Restart service |
| DatabaseDown | Critical | `up{job="database"} == 0` | 1m | Check database |
| HighMemoryUsage | Warning | Memory > 256MB | 5m | Monitor/optimize |
| HighResponseTime | Warning | p95 latency > 1s | 3m | Optimize queries |
| HighErrorRate | Warning | 5xx errors > 5% | 2m | Check logs |

### 4.2 Alertmanager Configuration

**Location:** `/monitoring/alertmanager.yml`

**Features:**
- Alert grouping by severity and cluster
- 10-second group wait time
- 12-hour repeat interval
- Webhook notifications
- Alert inhibition (critical alerts suppress warnings)

**Routing:**
```
All Alerts → Group by severity → Route to receivers
                                ↓
                         Critical/Warning handlers
```

---

## 5. Log Aggregation

### 5.1 Application Logging

**Logger:** Winston  
**Format:** JSON structured logs  
**Location:** Container stdout/stderr

**Log Levels:**
- `error`: Critical failures
- `warn`: Warning conditions
- `info`: Informational messages
- `debug`: Detailed debug information

**Example Log Entry:**
```json
{
  "level": "info",
  "message": "User logged in: testuser",
  "service": "25rp19824-turikumwenimana-api",
  "timestamp": "2025-12-20T10:30:00.000Z"
}
```

### 5.2 Accessing Logs

**View all API logs:**
```bash
docker compose logs api -f
```

**View last 100 lines:**
```bash
docker compose logs api --tail 100
```

**Filter by error level:**
```bash
docker compose logs api | grep ERROR
```

**Export logs to file:**
```bash
docker compose logs api > logs/api-$(date +%Y%m%d).log
```

---

## 6. Grafana Dashboards

### 6.1 Access
- **URL:** http://localhost:3001
- **Username:** admin
- **Password:** admin123

### 6.2 Recommended Dashboards

**Application Overview:**
- Request rate (req/sec)
- Response times (p50, p95, p99)
- Error rate (%)
- Active users count
- Total expenses count

**System Metrics:**
- CPU usage (%)
- Memory usage (MB)
- Disk I/O
- Network traffic

**Database Metrics:**
- Connection pool usage
- Query duration
- Active connections
- Database size

### 6.3 Creating Dashboards

1. Login to Grafana
2. Add Prometheus as data source:
   - URL: `http://prometheus:9090`
3. Import or create new dashboard
4. Add panels with PromQL queries

**Example Queries:**
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m])

# Memory usage
process_resident_memory_bytes / 1024 / 1024

# Active users
active_users_total
```

---

## 7. Monitoring Deployment

### 7.1 Start Monitoring Stack

**Start all services:**
```bash
docker compose up -d
```

**Verify services:**
```bash
docker compose ps
```

**Expected output:**
```
api         Running (healthy)
db          Running (healthy)
frontend    Running (healthy)
prometheus  Running
grafana     Running
alertmanager Running
```

### 7.2 Verify Monitoring

**Check Prometheus targets:**
```bash
curl http://localhost:9090/api/v1/targets
```

**Check metrics are being collected:**
```bash
curl http://localhost:9090/api/v1/query?query=up
```

**Check Grafana is accessible:**
```bash
curl http://localhost:3001/api/health
```

**Check alerts are configured:**
```bash
curl http://localhost:9090/api/v1/rules
```

---

## 8. Monitoring Best Practices

### 8.1 Metrics
- ✅ Use consistent naming conventions
- ✅ Add relevant labels for filtering
- ✅ Monitor both technical and business metrics
- ✅ Set appropriate retention periods
- ✅ Document metric meanings

### 8.2 Alerts
- ✅ Alert on symptoms, not causes
- ✅ Make alerts actionable
- ✅ Avoid alert fatigue with proper thresholds
- ✅ Include runbook links in annotations
- ✅ Test alerts regularly

### 8.3 Logs
- ✅ Use structured logging (JSON)
- ✅ Include relevant context (user_id, request_id)
- ✅ Log at appropriate levels
- ✅ Avoid logging sensitive data
- ✅ Implement log rotation

### 8.4 Health Checks
- ✅ Check critical dependencies
- ✅ Return quickly (<5 seconds)
- ✅ Use appropriate HTTP status codes
- ✅ Include detailed status information
- ✅ Don't perform heavy operations

---

## 9. Troubleshooting Monitoring

### Prometheus not scraping metrics
```bash
# Check Prometheus logs
docker compose logs prometheus

# Verify target is reachable
docker compose exec prometheus wget -O- http://api:3000/metrics

# Check Prometheus config
docker compose exec prometheus cat /etc/prometheus/prometheus.yml
```

### Grafana not showing data
```bash
# Check Grafana logs
docker compose logs grafana

# Verify Prometheus data source
curl http://localhost:3001/api/datasources

# Test Prometheus query
curl 'http://localhost:9090/api/v1/query?query=up'
```

### Alerts not firing
```bash
# Check Alertmanager logs
docker compose logs alertmanager

# Verify alert rules
curl http://localhost:9090/api/v1/rules

# Check active alerts
curl http://localhost:9090/api/v1/alerts
```

---

## 10. Evidence Collection

### For Assessment
```bash
# Capture Prometheus metrics
curl http://localhost:3000/metrics > evidence/prometheus-metrics.txt

# Export Grafana dashboards
# (via Grafana UI → Dashboard → Share → Export)

# Capture alert rules
curl http://localhost:9090/api/v1/rules > evidence/alert-rules.json

# Document health check
curl http://localhost:3000/health > evidence/health-check.json

# Capture service logs
docker compose logs api --tail 200 > evidence/api-logs.txt
docker compose logs db --tail 100 > evidence/db-logs.txt
```

---

## 11. References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Winston Logging](https://github.com/winstonjs/winston)
- [Docker Health Checks](https://docs.docker.com/engine/reference/builder/#healthcheck)
