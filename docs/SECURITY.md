# Security Best Practices

## API Key Management

### Storage
- **Never** commit API keys to version control
- Store keys in environment variables or `.env` files
- Use proper file permissions (600) for sensitive files
- Rotate keys regularly (quarterly recommended)

### Environment Files
```bash
# Secure your .env files
chmod 600 ~/.env
chmod 600 ~/easy-mcp/.env

# Add to global gitignore
echo ".env" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

## Token Rotation

### Automated Rotation Script
```bash
~/.config/claude/sdk-examples/rotate-tokens.sh
```

### Manual Rotation Process
1. Generate new tokens from respective services
2. Update `.env` files
3. Restart services:
   ```bash
   mcp-restart
   source ~/.zshrc
   ```
4. Test connectivity
5. Revoke old tokens

## Docker Security

### Container Isolation
- Services run with minimal privileges
- No containers run as root
- Resource limits enforced
- Network isolation between services

### Secrets Management
```yaml
secrets:
  mcp_secret_key:
    file: ./secrets/mcp_secret.txt
```

## File Permissions

### Critical Files
```bash
# API Keys and Secrets
chmod 600 ~/.env
chmod 600 ~/easy-mcp/.env
chmod 600 ~/easy-mcp/secrets/*

# Scripts
chmod 755 ~/.config/claude/scripts/*.sh
chmod 644 ~/.config/claude/configs/*
```

## Network Security

### Service Exposure
- Services bound to localhost only
- No external ports exposed by default
- Use SSH tunneling for remote access

### HTTPS/TLS
- All API communications use HTTPS
- Certificate validation enabled
- No self-signed certificates accepted

## Audit and Monitoring

### Log Review
```bash
# Check for unauthorized access attempts
grep -E "error|fail|denied" ~/.config/claude/logs/*.log

# Monitor API usage
cat ~/.config/claude/logs/api-usage.log
```

### Activity Monitoring
- Review Anthropic console for unusual activity
- Check Docker logs for anomalies
- Monitor system resources

## Security Checklist

- [ ] API keys stored securely
- [ ] File permissions set correctly
- [ ] .env files not in version control
- [ ] Regular key rotation scheduled
- [ ] Docker services running with minimal privileges
- [ ] Logs reviewed regularly
- [ ] Updates applied promptly
- [ ] Backup of configuration exists
- [ ] No hardcoded credentials in scripts
- [ ] Network access properly restricted

## Incident Response

### If Key Compromised
1. Immediately revoke key in provider console
2. Generate new key
3. Update all .env files
4. Restart all services
5. Review logs for unauthorized usage
6. Report to security team if applicable

### Security Updates
```bash
# Run security updates
claude-update
docker-compose pull
docker-compose up -d
```

## Compliance

### Data Handling
- No sensitive data in logs
- PII handled according to policy
- Encryption at rest for stored data
- Regular security assessments

### Access Control
- Multi-factor authentication on all accounts
- Principle of least privilege
- Regular access reviews
- Service accounts documented