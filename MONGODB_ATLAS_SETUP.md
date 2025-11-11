# MongoDB Atlas Setup Guide

This guide explains how to set up MongoDB Cloud (Atlas) for DocExtract instead of running MongoDB locally.

## Why MongoDB Atlas?

- **Free Tier**: 512MB storage, perfect for development
- **No Local Setup**: No need to run MongoDB locally
- **Cloud Backup**: Automatic backups and high availability
- **Easy Connection**: Simple connection string

## Setup Steps

### 1. Create MongoDB Atlas Account

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Click "Try Free" or "Sign Up"
3. Create an account (or sign in with Google/GitHub)

### 2. Create a Free Cluster

1. After logging in, click "Build a Database"
2. Choose **FREE** tier (M0 Sandbox)
3. Select a cloud provider and region (choose one close to you)
4. Cluster Name: `DocExtract` (or any name you prefer)
5. Click "Create"

Wait 1-3 minutes for your cluster to be created.

### 3. Configure Database Access

1. In the left sidebar, click **"Database Access"**
2. Click "Add New Database User"
3. Authentication Method: **Password**
4. Username: `docextract_user` (or your choice)
5. Password: Click "Autogenerate Secure Password" (copy it!)
6. Database User Privileges: Select **"Read and write to any database"**
7. Click "Add User"

**Important**: Save your password somewhere safe!

### 4. Configure Network Access

1. In the left sidebar, click **"Network Access"**
2. Click "Add IP Address"
3. For development, click "Allow Access From Anywhere"
   - This adds `0.0.0.0/0` to the IP Access List
   - ⚠️ For production, restrict to specific IPs
4. Click "Confirm"

### 5. Get Connection String

1. Go to **"Database"** in the left sidebar
2. Click "Connect" button on your cluster
3. Choose "Connect your application"
4. Driver: **Python** (version 3.12 or later)
5. Copy the connection string:

```
mongodb+srv://docextract_user:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

6. **Replace `<password>`** with your actual password
7. **Add database name** after `.net/`:

```
mongodb+srv://docextract_user:your_password@cluster0.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
```

### 6. Update DocExtract Configuration

1. In your DocExtract project root, copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

2. Edit `.env` file:

```env
# LlamaParse API Key
LLAMA_CLOUD_API_KEY=llx-your-actual-api-key

# MongoDB Atlas Connection String
MONGODB_URL=mongodb+srv://docextract_user:your_password@cluster0.xxxxx.mongodb.net/docextract?retryWrites=true&w=majority
MONGODB_DB_NAME=docextract
```

3. **Important**: Comment out local MongoDB settings:

```env
# Option 2: Local MongoDB (COMMENTED OUT)
# MONGODB_URL=mongodb://admin:password123@mongodb:27017
# MONGODB_DB_NAME=docextract
```

### 7. Update docker-compose.yml

The local MongoDB service is already commented out by default. If it's uncommented, make sure it stays commented:

```yaml
# MongoDB Database (Optional - comment out if using MongoDB Cloud)
# mongodb:
#   image: mongo:7.0
#   ...
```

Also ensure backend doesn't depend on MongoDB service:

```yaml
backend:
  # ...
  # depends_on:
  #   mongodb:
  #     condition: service_healthy
```

### 8. Test Connection

Start your services:

```bash
docker-compose up --build
```

Check backend logs for successful connection:

```bash
docker-compose logs backend
```

You should see:
```
Connected to MongoDB: docextract
```

### 9. Verify in Atlas Dashboard

1. Go to your Atlas cluster dashboard
2. Click "Browse Collections"
3. After running the app and creating documents, you should see:
   - Database: `docextract`
   - Collection: `extracted_documents`
   - Documents with your data

## Connection String Format

MongoDB Atlas connection strings have this format:

```
mongodb+srv://username:password@cluster.host.mongodb.net/database?options
```

- **Protocol**: `mongodb+srv://` (uses DNS seedlist)
- **Username**: Your database user
- **Password**: User's password (URL-encoded if special chars)
- **Host**: Your cluster hostname
- **Database**: Database name (`docextract`)
- **Options**: Query parameters for connection settings

### URL Encoding Passwords

If your password contains special characters, URL-encode them:

| Character | Encoded |
|-----------|---------|
| @         | %40     |
| :         | %3A     |
| /         | %2F     |
| #         | %23     |
| ?         | %3F     |
| &         | %26     |

Example:
```
Password: P@ssw0rd!
Encoded: P%40ssw0rd!
```

## Monitoring

### Atlas Dashboard

View your database activity:
1. Go to "Metrics" in your cluster
2. See:
   - Connections
   - Operations per second
   - Network traffic
   - Storage usage

### Application Logs

Check if backend is connecting:

```bash
# View backend logs
docker-compose logs -f backend

# Look for these messages:
# ✅ "Connected to MongoDB: docextract"
# ❌ "Failed to connect to MongoDB"
```

## Troubleshooting

### Connection Timeout

**Error**: `ServerSelectionTimeoutError`

**Solutions**:
1. Check network access settings (allow your IP)
2. Verify connection string is correct
3. Check if cluster is paused (free tier auto-pauses after inactivity)
4. Ensure password is URL-encoded

### Authentication Failed

**Error**: `Authentication failed`

**Solutions**:
1. Verify username and password
2. Check database user has correct privileges
3. Ensure password is URL-encoded

### Database Not Found

**Error**: Database doesn't appear in Atlas

**Solutions**:
1. Database is created automatically on first write
2. Run the app and create a document
3. Refresh Atlas dashboard

### Cluster Paused

Free tier clusters auto-pause after 60 days of inactivity.

**To Resume**:
1. Go to your cluster in Atlas
2. Click "Resume"
3. Wait 1-2 minutes for cluster to start

## Cost & Limits

### Free Tier (M0)

- **Storage**: 512 MB
- **RAM**: Shared
- **Backups**: None (manual export available)
- **Cost**: **FREE**
- **Good for**: Development, testing, small projects

### Estimated Usage

For DocExtract:
- **Per Document**: ~2-5 KB
- **100 documents**: ~500 KB
- **1000 documents**: ~5 MB

Free tier can handle **~100,000 documents** easily!

### Upgrading

If you need more:
1. Click "Upgrade" in Atlas
2. M2 tier: $9/month (2GB storage)
3. M5 tier: $25/month (5GB storage)

## Backup

### Manual Export

```bash
# Export database using mongodump
mongodump --uri="mongodb+srv://user:pass@cluster.mongodb.net/docextract" --out=./backup

# Restore from backup
mongorestore --uri="mongodb+srv://user:pass@cluster.mongodb.net/docextract" ./backup/docextract
```

### Atlas Backups

Available on paid tiers (M2+):
- Continuous backups
- Point-in-time recovery
- Automated snapshots

## Security Best Practices

### 1. Strong Passwords

```bash
# Generate secure password
openssl rand -base64 32
```

### 2. IP Whitelist

Instead of "Allow from anywhere":
```
# Development machine IP
203.0.113.10/32

# Production server IP
198.51.100.50/32
```

### 3. Least Privilege

Create separate users for different purposes:
- **Admin**: Full access (for you only)
- **App**: Read/write to `docextract` database only
- **Backup**: Read-only access

### 4. Environment Variables

Never commit `.env` to git:
```bash
# Add to .gitignore
echo ".env" >> .gitignore
```

### 5. Connection String Security

- Don't hardcode in source code
- Use environment variables
- Rotate passwords periodically

## Local Development with Atlas

Recommended setup:
- **Development**: Local MongoDB (faster, no internet needed)
- **Testing**: MongoDB Atlas (test cloud connectivity)
- **Production**: MongoDB Atlas (reliable, backed up)

Switch easily by changing `.env`:

```bash
# Use local MongoDB
MONGODB_URL=mongodb://admin:password123@localhost:27017/docextract

# Use MongoDB Atlas
MONGODB_URL=mongodb+srv://user:pass@cluster.mongodb.net/docextract
```

## Support

- **Atlas Documentation**: https://docs.atlas.mongodb.com
- **Community Forum**: https://community.mongodb.com
- **Stack Overflow**: Tag `mongodb-atlas`
- **Atlas Support**: Available on paid tiers

## Next Steps

After setting up MongoDB Atlas:

1. ✅ Test connection with DocExtract
2. ✅ Create some test documents
3. ✅ View data in Atlas dashboard
4. ✅ Set up IP whitelist for production
5. ✅ Configure backup strategy (if needed)
6. ✅ Monitor usage and set up alerts

Ready to deploy to production? See [RAILWAY_QUICK_START.md](RAILWAY_QUICK_START.md)
