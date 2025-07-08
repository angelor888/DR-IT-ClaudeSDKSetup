# Claude API Pricing Guide

## Current Pricing (as of January 2025)

### Model Pricing

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Notes |
|-------|----------------------|------------------------|--------|
| Claude 3.5 Sonnet | $3.00 | $15.00 | Most capable, best for complex tasks |
| Claude 3 Opus | $15.00 | $75.00 | Previous flagship, very capable |
| Claude 3 Haiku | $0.25 | $1.25 | Fastest, most cost-effective |

### Token Estimation
- 1 token ≈ 4 characters
- 1,000 tokens ≈ 750 words
- Average request: 100-500 tokens
- Average response: 200-1000 tokens

## Cost Optimization Strategies

### 1. Model Selection
```python
# Use Haiku for simple tasks
client.messages.create(
    model="claude-3-haiku-20240307",  # $0.25/$1.25 per 1M
    max_tokens=100,  # Limit response length
    messages=[{"role": "user", "content": "Simple question"}]
)

# Use Sonnet for complex tasks
client.messages.create(
    model="claude-3-5-sonnet-20241022",  # $3/$15 per 1M
    max_tokens=2048,
    messages=[{"role": "user", "content": "Complex analysis task"}]
)
```

### 2. Token Limits
- Always set `max_tokens` appropriately
- Use system prompts to encourage conciseness
- Implement response caching where applicable

### 3. Batching Requests
- Combine multiple small queries
- Use streaming for real-time feedback
- Cache common responses

## Usage Estimates

### Development/Testing
- Daily testing: ~10,000 tokens
- Monthly cost: ~$0.10 - $1.00

### Light Production Use
- 100 requests/day @ 500 tokens each
- Monthly cost: ~$5 - $50

### Heavy Production Use
- 1,000 requests/day @ 1,000 tokens each
- Monthly cost: ~$100 - $1,000

## Monitoring Usage

### Anthropic Console
1. Log in to [console.anthropic.com](https://console.anthropic.com)
2. Navigate to Usage dashboard
3. Set up usage alerts

### Programmatic Monitoring
```python
# Track usage in your application
import json
from datetime import datetime

def log_api_usage(model, input_tokens, output_tokens):
    usage = {
        "timestamp": datetime.now().isoformat(),
        "model": model,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "estimated_cost": calculate_cost(model, input_tokens, output_tokens)
    }
    
    with open("api_usage.log", "a") as f:
        f.write(json.dumps(usage) + "\n")
```

## Cost Control Measures

### 1. Rate Limiting
```python
from time import sleep
from datetime import datetime, timedelta

class RateLimiter:
    def __init__(self, max_requests_per_minute=10):
        self.max_requests = max_requests_per_minute
        self.requests = []
    
    def wait_if_needed(self):
        now = datetime.now()
        self.requests = [r for r in self.requests 
                        if now - r < timedelta(minutes=1)]
        
        if len(self.requests) >= self.max_requests:
            sleep(60)
            self.requests = []
        
        self.requests.append(now)
```

### 2. Budget Alerts
- Set up alerts in Anthropic console
- Implement daily/monthly budget caps
- Monitor unusual usage patterns

### 3. Caching Strategy
```python
import hashlib
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_claude_request(prompt_hash):
    # Cache responses for identical prompts
    return make_api_call(prompt_hash)

def get_response(prompt):
    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
    return cached_claude_request(prompt_hash)
```

## Free Tier and Credits

### Initial Credits
- New accounts may receive free credits
- Credits expire after a certain period
- Check console for current balance

### Adding Credits
1. Go to Billing in console
2. Add payment method
3. Purchase credits in increments
4. Set up auto-recharge if needed

## Cost Comparison

### Typical Use Cases

| Use Case | Model | Monthly Volume | Estimated Cost |
|----------|-------|----------------|----------------|
| Chatbot | Haiku | 10K conversations | $5-15 |
| Code Review | Sonnet | 1K reviews | $30-100 |
| Content Generation | Sonnet | 500 articles | $50-200 |
| Data Analysis | Opus | 100 reports | $100-500 |

## Best Practices

1. **Start with Haiku** for prototyping
2. **Profile your usage** before production
3. **Set budget alerts** early
4. **Cache aggressively** for repeated queries
5. **Monitor regularly** for anomalies
6. **Use streaming** for better UX without extra cost
7. **Batch similar requests** when possible