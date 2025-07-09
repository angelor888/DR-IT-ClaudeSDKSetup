# Security Best Practices for Claude SDK

## ⚠️ Important Security Notice

Since you shared your GitHub token in our conversation, here are critical security steps:

### Immediate Actions Required:

1. **Regenerate Your GitHub Token**
   - Go to https://github.com/settings/tokens
   - Find the token ending in `2dBMW4`
   - Click "Regenerate" or delete and create a new one
   - Update your `.env` file with the new token

2. **Review Token Permissions**
   - Your current token has very broad permissions
   - Create tokens with minimal required scopes:
     - For code reading: `repo` (public) or `repo:status`
     - For PR creation: `repo`, `pull_request`
     - Avoid: `delete_repo`, `admin:*` unless absolutely needed

## Security Configuration

### Environment Variables
```bash
# Never commit .env files
echo ".env" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# Set restrictive permissions
chmod 600 ~/.config/claude/.env
chmod 600 ~/easy-mcp/.env
```

### Secure Token Storage

#### Option 1: macOS Keychain
```bash
# Store token in keychain
security add-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w

# Retrieve in scripts
export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w)
```

#### Option 2: Environment File with Encryption
```bash
# Encrypt sensitive files
openssl enc -aes-256-cbc -salt -in .env -out .env.enc
# Decrypt when needed
openssl enc -d -aes-256-cbc -in .env.enc -out .env
```

### Git Security

```bash
# Check for exposed secrets
git log --all --full-history -- "**/.env"
git log --all --full-history -p | grep -E "ghp_|sk-ant|api_key"

# Remove sensitive data from history (if needed)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```

## API Key Best Practices

### 1. Rotation Schedule
- Rotate API keys every 90 days
- Immediately rotate if exposed
- Keep audit log of rotations

### 2. Scope Limitation
```python
# Use read-only tokens for analysis
READ_ONLY_TOKEN = os.environ.get("GITHUB_READ_TOKEN")
# Use write tokens only when needed
WRITE_TOKEN = os.environ.get("GITHUB_WRITE_TOKEN")
```

### 3. Rate Limiting
```python
import time
from functools import wraps

def rate_limit(calls_per_minute=20):
    min_interval = 60.0 / calls_per_minute
    last_called = [0.0]
    
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time.time() - last_called[0]
            left_to_wait = min_interval - elapsed
            if left_to_wait > 0:
                time.sleep(left_to_wait)
            ret = func(*args, **kwargs)
            last_called[0] = time.time()
            return ret
        return wrapper
    return decorator

@rate_limit(calls_per_minute=20)
def call_claude_api():
    # Your API call here
    pass
```

## Monitoring & Alerts

### Token Usage Monitoring
```bash
# Check GitHub token usage
gh api /rate_limit

# Monitor Anthropic usage (add to cron)
curl -H "anthropic-version: 2023-06-01" \
     -H "x-api-key: $ANTHROPIC_API_KEY" \
     https://api.anthropic.com/v1/usage
```

### Security Checklist

- [ ] All API keys stored in environment variables
- [ ] `.env` files in `.gitignore`
- [ ] Tokens have minimal required permissions
- [ ] Regular token rotation scheduled
- [ ] No tokens in code or commits
- [ ] Monitoring setup for unusual usage
- [ ] Backup authentication methods configured

## Emergency Response

If a token is compromised:

1. **Immediately revoke** the token
2. **Audit** recent usage in provider dashboard
3. **Check** for unauthorized access
4. **Rotate** all related credentials
5. **Review** security practices

## Additional Resources

- [GitHub Token Security](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure)
- [Anthropic API Security](https://docs.anthropic.com/claude/docs/api-security)
- [OWASP API Security](https://owasp.org/www-project-api-security/)