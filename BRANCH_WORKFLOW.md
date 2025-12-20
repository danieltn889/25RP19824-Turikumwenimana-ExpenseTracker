# Branch Promotion Workflow

## Overview
This project uses a three-stage branch promotion strategy with automatic CI/CD:

```
developer → backup → main
    ↓         ↓        ↓
  Test    Integration  Production
```

## Workflow Stages

### Stage 1: DEVELOPER Branch
**Purpose:** Development and testing
- Make changes locally
- Push to `developer` branch
- GitHub Actions runs tests automatically
- If tests pass → Ready for integration testing

```bash
git checkout developer
# Make your changes
git add .
git commit -m "Your changes"
git push origin developer
```

**What runs automatically:**
✅ Unit tests  
✅ Linting  
✅ Code quality checks  

---

### Stage 2: BACKUP Branch
**Purpose:** Integration testing and validation
- After testing in developer, merge to `backup`
- GitHub Actions runs full integration suite
- If tests pass → Ready for production

```bash
git checkout backup
git merge developer
git push origin backup
```

**What runs automatically:**
✅ Full test suite  
✅ Docker build (test build)  
✅ Integration tests  

---

### Stage 3: MAIN Branch (Production)
**Purpose:** Production release
- After backup tests pass, merge to `main`
- GitHub Actions builds Docker images
- Pushes to Docker Hub automatically
- Deployment-ready images available

```bash
git checkout main
git merge backup
git push origin main
```

**What runs automatically:**
✅ Full tests  
✅ Docker build & push to Docker Hub  
✅ Version tagging  
✅ Security scanning  

---

## Complete Workflow Example

### Step 1: Start Development
```bash
git checkout developer
git pull origin developer
```

### Step 2: Make Changes
```bash
# Edit files
git add .
git commit -m "Add new expense category feature"
git push origin developer
```

**GitHub Actions runs automatically:**
- Tests pass ✅

### Step 3: Promote to Backup (Integration Testing)
```bash
git checkout backup
git pull origin backup
git merge developer
git push origin backup
```

**GitHub Actions runs automatically:**
- Integration tests pass ✅
- Docker builds successfully ✅

### Step 4: Release to Main (Production)
```bash
git checkout main
git pull origin main
git merge backup
git push origin main
```

**GitHub Actions runs automatically:**
- All tests pass ✅
- Docker images built ✅
- Images pushed to Docker Hub ✅
- Ready for Kubernetes deployment ✅

---

## Branch Rules

| Branch | Purpose | Auto-Build | Push to Hub |
|--------|---------|-----------|------------|
| developer | Development | ❌ Tests only | ❌ No |
| backup | Staging | ✅ Build test | ❌ No |
| main | Production | ✅ Build & Push | ✅ Yes |

---

## How to Check CI/CD Status

1. **Go to GitHub:** https://github.com/danieltn889/25RP19824-Turikumwenimana-ExpenseTracker
2. **Click "Actions" tab**
3. **See workflow status** for each branch push
4. **Green checkmark** = Success
5. **Red X** = Failed (check logs)

---

## Docker Hub Images

After pushing to `main`, images are automatically built and pushed:

```
dockertn889/25rp19824-turikumwenimana-api:latest
dockertn889/25rp19824-turikumwenimana-frontend:latest
```

Use these in Kubernetes or Docker Compose:
```bash
docker pull danieltn889/25rp19824-turikumwenimana-api:latest
docker pull danieltn889/25rp19824-turikumwenimana-frontend:latest
```

---

## Troubleshooting

### Push Rejected?
```bash
git pull origin <branch>
git push origin <branch>
```

### Need to see CI/CD logs?
Go to GitHub Actions tab and click the failed workflow

### Need to rollback?
```bash
git revert HEAD
git push origin <branch>
```

---

## Summary

Your workflow is now:
1. **Code on developer** → Tests run automatically
2. **Merge to backup** → Integration tests run
3. **Merge to main** → Docker images built and pushed to Docker Hub
4. **Deploy** → Use the Docker Hub images in production

All automated! Just commit and push! 🚀
