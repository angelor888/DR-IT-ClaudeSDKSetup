# Troubleshooting Guide

## Common Issues and Solutions

### 1. Credit Balance Too Low

**Error**: `Your credit balance is too low to access the Anthropic API`

**Solution**:
1. Log in to [console.anthropic.com](https://console.anthropic.com)
2. Navigate to Billing
3. Add credits to your account
4. Wait a few minutes for the balance to update

### 2. Docker Services Not Starting

**Error**: MCP containers fail to start or exit immediately

**Solutions**:
- **Check Docker Desktop**: Ensure Docker Desktop is running
  ```bash
  docker info
  ```
- **Check logs**: View container logs for specific errors
  ```bash
  docker logs mcp-filesystem-enhanced
  ```
- **Resource limits**: Increase Docker Desktop memory allocation
- **Port conflicts**: Check if ports 8082-8090 are in use
  ```bash
  lsof -i :8082
  ```

### 3. API Key Not Found

**Error**: `ANTHROPIC_API_KEY environment variable not set`

**Solutions**:
1. Ensure key is in ~/.env or ~/easy-mcp/.env
2. Source your shell profile:
   ```bash
   source ~/.zshrc
   ```
3. Verify the key is loaded:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

### 4. Permission Denied Errors

**Error**: `Permission denied` when running scripts

**Solution**:
```bash
chmod +x ~/.config/claude/scripts/*.sh
chmod 600 ~/.env
```

### 5. LaunchAgent Not Working

**Error**: Auto-updates not running

**Solutions**:
1. Check if loaded:
   ```bash
   launchctl list | grep claude
   ```
2. Reload agent:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.claude.autoupdate.plist
   launchctl load ~/Library/LaunchAgents/com.claude.autoupdate.plist
   ```
3. Check logs:
   ```bash
   cat ~/.config/claude/logs/auto-update-error.log
   ```

### 6. Python Virtual Environment Issues

**Error**: `No module named 'anthropic'`

**Solution**:
```bash
cd ~/.config/claude/sdk-examples/python
source venv/bin/activate
pip install anthropic
```

### 7. TypeScript Compilation Errors

**Error**: TypeScript build fails

**Solution**:
```bash
cd ~/.config/claude/sdk-examples/typescript
npm install
npm run build
```

### 8. Model Name Errors

**Error**: `Invalid model` or model not found

**Solution**: Use correct model names:
- `claude-3-5-sonnet-20241022` (most capable)
- `claude-3-opus-20240229` (previous flagship)
- `claude-3-haiku-20240307` (fastest)

### 9. Network Connection Issues

**Error**: Connection timeouts or DNS failures

**Solutions**:
- Check internet connection
- Verify proxy settings if behind corporate firewall
- Try using different DNS servers
- Check if Anthropic API is accessible:
  ```bash
  curl -I https://api.anthropic.com
  ```

### 10. Container Build Failures

**Error**: Docker build fails for MCP services

**Solution**:
```bash
cd ~/easy-mcp
docker-compose build --no-cache
docker-compose up -d
```

## Getting Help

If issues persist:
1. Check the logs: `claude-logs`
2. Run diagnostics: `./scripts/verify-installation.sh`
3. Create an issue at: https://github.com/angelor888/DR-IT-ClaudeSDKSetup/issues