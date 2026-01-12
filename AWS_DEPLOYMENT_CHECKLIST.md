# SonarQube AWS Deployment - Quick Checklist

## ⚠️ Before You Push

### 1. Add Port 9000 to AWS Security Group
- [ ] Go to AWS Console → EC2 → Security Groups
- [ ] Find your instance's security group
- [ ] Add inbound rule: Port 9000, TCP, Source: Your IP (or 0.0.0.0/0 for testing)

**Without this, SonarQube won't be accessible!**

---

## 🚀 Deployment Steps

### 2. Push to GitHub
```bash
git push origin othmane
```

Jenkins will automatically:
- ✅ Build your code
- ✅ Deploy docker-compose to AWS
- ✅ Start SonarQube + PostgreSQL on AWS
- ✅ Run code analysis
- ✅ Check quality gate

### 3. Wait for Deployment (~5 minutes)
- Watch Jenkins build progress
- SonarQube takes 2-3 minutes to start first time

### 4. Access SonarQube
```
http://YOUR_AWS_IP:9000
```
Replace YOUR_AWS_IP with your EC2 public IP (same as your Jenkins)

**Login:** admin / admin
**⚠️ Change password immediately!**

### 5. Generate Token
- Click profile → My Account → Security
- Generate Token: "Jenkins Pipeline", Global Analysis Token
- **Copy the token** (you can't see it again!)

### 6. Add Token to Jenkins
- Jenkins → Manage Jenkins → Credentials → Add
- Kind: Secret text
- Secret: Paste your token
- ID: `sonarqube-token` (exactly this!)

### 7. Install Jenkins Plugin
- Manage Jenkins → Plugins
- Search: "SonarQube Scanner"
- Install and restart

### 8. Configure SonarQube Server in Jenkins
- Manage Jenkins → System → SonarQube servers
- Add SonarQube:
  - Name: `SonarQube` (exactly this!)
  - Server URL: `http://YOUR_AWS_IP:9000`
  - Token: Select `sonarqube-token`
- Save

### 9. Test It
```bash
git commit --allow-empty -m "test: SonarQube analysis"
git push origin othmane
```

Watch Jenkins console for:
```
🔍 Running SonarQube Code Analysis...
✅ Quality Gate passed with status: OK
```

---

## ✅ Verification

### Check SonarQube is Running on AWS
```bash
ssh -i ~/Downloads/lastreal.pem ec2-user@YOUR_AWS_IP
docker ps | grep sonar
```

Should see:
- `buy01-sonarqube`
- `buy01-sonarqube-db`

### Check Logs
```bash
docker logs buy01-sonarqube
# Look for: "SonarQube is operational"
```

---

## 🎉 Done!

Once all steps are complete:
- ✅ SonarQube running on AWS
- ✅ Jenkins analyzing code automatically
- ✅ Quality gates enforced
- ✅ Pipeline fails on quality issues
- ✅ Email notifications working

## 📚 Need Help?

- **Detailed Guide:** [SONARQUBE_AWS_DEPLOYMENT.md](SONARQUBE_AWS_DEPLOYMENT.md)
- **Original Setup Guide:** [SONARQUBE_SETUP.md](SONARQUBE_SETUP.md)
- **Implementation Checklist:** [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)

---

**Current Status:** Ready to push! 🚀

All code changes are committed. Just need to:
1. Add port 9000 to AWS Security Group
2. Push to GitHub
3. Follow the steps above
