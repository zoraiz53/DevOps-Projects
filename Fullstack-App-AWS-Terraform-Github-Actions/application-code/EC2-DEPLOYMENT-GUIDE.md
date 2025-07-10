# 🚀 EC2 Cross-Server Deployment Guide

This guide will help you deploy the Python backend and frontend on separate EC2 instances.

## 📋 Prerequisites

- Two EC2 instances (Ubuntu 20.04+ recommended)
- SSH access to both instances
- Basic knowledge of AWS EC2 and security groups

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP/HTTPS    ┌─────────────────┐
│   Frontend EC2  │ ───────────────► │   Backend EC2   │
│   Port: 3000    │                  │   Port: 5000    │
│   Public IP     │                  │   Public IP     │
└─────────────────┘                  └─────────────────┘
```

## 🔧 Step 1: Prepare Your Code

1. **Clone or copy your project to both EC2 instances**
2. **Ensure you have the following files on both servers:**
   - `backend/` folder (on backend EC2)
   - `frontend/` folder (on frontend EC2)
   - `deploy-backend.sh` (on backend EC2)
   - `deploy-frontend.sh` (on frontend EC2)

## 🔒 Step 2: Configure Security Groups

### Backend EC2 Security Group
- **Inbound Rules:**
  - SSH (Port 22): Your IP
  - Custom TCP (Port 5000): 0.0.0.0/0 (or specific frontend IP)

### Frontend EC2 Security Group
- **Inbound Rules:**
  - SSH (Port 22): Your IP
  - Custom TCP (Port 3000): 0.0.0.0/0 (for web access)
  - Custom TCP (Port 80): 0.0.0.0/0 (optional, for HTTP)
  - Custom TCP (Port 443): 0.0.0.0/0 (optional, for HTTPS)

## 🚀 Step 3: Deploy Backend

### On Backend EC2 Instance:

1. **SSH into your backend EC2:**
   ```bash
   ssh -i your-key.pem ubuntu@your-backend-ec2-ip
   ```

2. **Upload your project files:**
   ```bash
   # Option 1: Using scp
   scp -r ./backend ubuntu@your-backend-ec2-ip:~/
   scp ./deploy-backend.sh ubuntu@your-backend-ec2-ip:~/
   
   # Option 2: Using git
   git clone your-repo-url
   cd your-repo
   ```

3. **Run the deployment script:**
   ```bash
   chmod +x deploy-backend.sh
   ./deploy-backend.sh
   ```

4. **Note the backend URL:**
   The script will output something like:
   ```
   Backend URL: http://54.123.45.67:5000
   ```

## 🎨 Step 4: Deploy Frontend

### On Frontend EC2 Instance:

1. **SSH into your frontend EC2:**
   ```bash
   ssh -i your-key.pem ubuntu@your-frontend-ec2-ip
   ```

2. **Upload your project files:**
   ```bash
   # Option 1: Using scp
   scp -r ./frontend ubuntu@your-frontend-ec2-ip:~/
   scp ./deploy-frontend.sh ubuntu@your-frontend-ec2-ip:~/
   
   # Option 2: Using git
   git clone your-repo-url
   cd your-repo
   ```

3. **Run the deployment script:**
   ```bash
   chmod +x deploy-frontend.sh
   ./deploy-frontend.sh
   ```

4. **When prompted, enter your backend URL:**
   ```
   Backend URL: http://54.123.45.67:5000
   ```

## ✅ Step 5: Verify Deployment

### Test Backend:
```bash
# From any machine
curl http://your-backend-ec2-ip:5000/api/health
```

Expected response:
```json
{"status": "healthy", "service": "backend"}
```

### Test Frontend:
```bash
# From any machine
curl http://your-frontend-ec2-ip:3000/health
```

Expected response:
```json
{"status": "healthy", "service": "frontend", "backend_url": "http://54.123.45.67:5000"}
```

### Access Web Interface:
Open your browser and go to:
```
http://your-frontend-ec2-ip:3000
```

## 🔧 Step 6: Configuration Management

### Environment Variables

**Backend EC2:**
```bash
# View current environment
docker exec backend-container env | grep FLASK

# Update environment (requires container restart)
docker stop backend-container
docker run -d \
    --name backend-container \
    --restart unless-stopped \
    -p 5000:5000 \
    -e FLASK_ENV=production \
    -e CUSTOM_VAR=value \
    python-backend
```

**Frontend EC2:**
```bash
# View current configuration
curl http://localhost:3000/config

# Update backend URL (requires container restart)
docker stop frontend-container
docker run -d \
    --name frontend-container \
    --restart unless-stopped \
    -p 3000:3000 \
    -e BACKEND_URL=http://new-backend-ip:5000 \
    -e FLASK_ENV=production \
    python-frontend
```

## 🛠️ Step 7: Monitoring and Maintenance

### View Logs:
```bash
# Backend logs
docker logs backend-container
docker logs -f backend-container  # Follow logs

# Frontend logs
docker logs frontend-container
docker logs -f frontend-container  # Follow logs
```

### Container Management:
```bash
# Check container status
docker ps

# Restart containers
docker restart backend-container
docker restart frontend-container

# Stop containers
docker stop backend-container frontend-container

# Start containers
docker start backend-container frontend-container
```

### Update Application:
```bash
# Pull latest code
git pull

# Rebuild and restart
./deploy-backend.sh  # On backend EC2
./deploy-frontend.sh # On frontend EC2
```

## 🔍 Troubleshooting

### Common Issues:

1. **Backend not accessible from frontend:**
   - Check security group rules
   - Verify backend is running: `docker ps`
   - Test connectivity: `curl http://backend-ip:5000/api/health`

2. **Frontend can't connect to backend:**
   - Check BACKEND_URL environment variable
   - Verify backend URL is correct
   - Test from frontend EC2: `curl http://backend-ip:5000/api/health`

3. **Port already in use:**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :5000
   sudo netstat -tulpn | grep :3000
   
   # Kill the process
   sudo kill -9 <PID>
   ```

4. **Docker permission issues:**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   
   # Log out and back in, or run:
   newgrp docker
   ```

### Health Checks:

**Backend Health Check:**
```bash
curl -f http://backend-ip:5000/api/health || echo "Backend is down"
```

**Frontend Health Check:**
```bash
curl -f http://frontend-ip:3000/health || echo "Frontend is down"
```

**Connection Test:**
```bash
# From frontend EC2
curl -X POST http://localhost:3000/api/connect
```

## 🔐 Security Considerations

1. **Use HTTPS in production:**
   - Set up SSL certificates
   - Configure reverse proxy (nginx)
   - Update BACKEND_URL to use HTTPS

2. **Restrict security group access:**
   - Limit SSH access to your IP
   - Consider using VPC for internal communication
   - Use specific IP ranges instead of 0.0.0.0/0

3. **Environment variables:**
   - Use AWS Secrets Manager for sensitive data
   - Don't hardcode credentials in Docker images

4. **Regular updates:**
   - Keep Docker images updated
   - Monitor for security patches
   - Regular backup of data

## 📊 Performance Optimization

1. **Use a reverse proxy (nginx):**
   - Load balancing
   - SSL termination
   - Static file serving

2. **Database considerations:**
   - Use RDS for persistent data
   - Implement connection pooling
   - Regular backups

3. **Monitoring:**
   - Set up CloudWatch alarms
   - Monitor container resource usage
   - Log aggregation

## 🎯 Next Steps

1. **Set up domain names** for both services
2. **Configure SSL certificates** using Let's Encrypt
3. **Set up monitoring and alerting**
4. **Implement CI/CD pipeline**
5. **Add database for persistent data storage**

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Docker logs: `docker logs container-name`
3. Verify security group configurations
4. Test network connectivity between instances 