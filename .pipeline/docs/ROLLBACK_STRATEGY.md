# Rollback Strategy Documentation

## Overview
This CI/CD pipeline implements a robust rollback strategy to ensure zero-downtime deployments and the ability to quickly revert to a working version if a deployment fails.

## How It Works

### 1. Version Tagging
- Every build is tagged with its build number: `buy01-pipeline-service-registry:build-5`
- Images are also tagged as `:latest` for docker-compose compatibility

### 2. Backup Before Deploy
Before deploying a new version:
```bash
Current working version → Tagged as :previous
Previous backup (:previous) → Tagged as :previous-old (then deleted after successful deployment)
```

### 3. Health Checks
After deployment, the system performs health checks on:
- **Service Registry (Eureka)**: `http://localhost:8761`
- **API Gateway**: `http://localhost:8080/actuator/health`
- **Frontend**: `http://localhost:4200`

If ANY health check fails → **Automatic Rollback**

### 4. Automatic Rollback
If deployment fails:
1. Stop failed containers
2. Restore `:previous` images as `:latest`
3. Restart containers with previous version
4. Verify health of restored version

### 5. Cleanup Strategy
**Jenkins Server:**
- After transferring images to AWS, prune Docker images older than 1 hour
- Prevents Jenkins disk from filling up

**Deployment Server (AWS):**
- After successful deployment, prune images older than 2 hours
- Keeps only: current version + previous backup
- Automatic cleanup on each deployment

## Deployment Flow

```
Build #5 (Current Working) → Build #6 (New)
         ↓
     [Backup as :previous]
         ↓
     [Deploy Build #6]
         ↓
     [Health Checks]
         ↓
    ┌────┴────┐
    ↓         ↓
 SUCCESS   FAILURE
    ↓         ↓
Keep #6   Rollback
Delete    to #5
old #4    (previous)
```

## Manual Rollback

If you need to manually rollback:

```bash
# On Jenkins server
./rollback.sh
```

This will:
1. Connect to AWS deployment server
2. Stop current containers
3. Restore previous version
4. Start containers
5. Verify health

## Disk Space Management

### Jenkins Server (13.49.67.88)
- Automatic cleanup after image transfer
- Removes images older than 1 hour
- Triggered after every successful deployment

### AWS Server (51.21.198.139)  
- Cleanup runs during deployment
- Keeps current + previous (2 versions)
- Removes images older than 2 hours

## Testing the Rollback

To test the rollback mechanism:

1. **Simulate a deployment failure:**
   - Break a health check temporarily
   - Push broken code

2. **Observe automatic rollback:**
   ```
   ❌ Deployment health checks failed!
   🔄 INITIATING ROLLBACK
   ✅ ROLLBACK SUCCESSFUL!
   ```

3. **Verify previous version is running:**
   - Check http://51.21.198.139:4200
   - All services should be functional

## Monitoring

Check deployment status:
```bash
# On AWS server
ssh -i ~/Downloads/lastreal.pem ec2-user@51.21.198.139
cd /home/ec2-user/buy-01-app
docker-compose ps
docker images | grep buy01-pipeline
```

Expected output:
```
buy01-pipeline-frontend:latest        # Current
buy01-pipeline-frontend:build-6       # Current (same)
buy01-pipeline-frontend:previous      # Backup
```

## Rollback Decision Tree

```
Deployment Failed?
    ↓
    Yes → Health checks failed?
           ↓
           Yes → Automatic rollback to :previous
                 ↓
                 Previous version starts
                 ↓
                 Alert team via email
    ↓
    No → Deployment succeeded
         ↓
         Delete old :previous-old
         ↓
         Keep current :previous as new backup
         ↓
         Continue normal operations
```

## Benefits

✅ **Zero Downtime**: Always have a working version available  
✅ **Automatic Recovery**: No manual intervention needed  
✅ **Disk Space Managed**: Automatic cleanup prevents disk full  
✅ **Version History**: Track deployments via build numbers  
✅ **Quick Rollback**: 30 seconds to restore previous version  
✅ **Health Verification**: Ensures services are actually working  

## Recovery Time Objectives (RTO)

- **Detection**: Immediate (health checks after deployment)
- **Decision**: Automatic (no human intervention)  
- **Rollback**: ~30 seconds
- **Verification**: 15 seconds (health checks)
- **Total RTO**: < 1 minute

## Important Notes

⚠️ **Always keep at least 2 versions** (current + previous)  
⚠️ **Health checks run for 15 seconds** after deployment  
⚠️ **Rollback uses :previous tag** - ensure it exists  
⚠️ **Jenkins cleanup runs after transfer** - images removed from Jenkins server  
⚠️ **AWS cleanup keeps 2 hours history** - adjust if needed  

## Configuration

Edit cleanup timing in:

**Jenkinsfile:**
```groovy
docker image prune -a -f --filter "until=1h"  // Jenkins cleanup
```

**deploy.sh:**
```bash
docker image prune -a -f --filter "until=2h"  // AWS cleanup
```
