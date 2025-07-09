# Claude SDK Examples & Documentation

## Why Use Claude SDK?

The Claude SDK provides powerful programmatic access to Claude's capabilities, enabling you to:

### 🚀 Build Intelligent Applications
- **Custom AI Assistants**: Create specialized tools for your domain
- **Automated Workflows**: Integrate AI into your existing processes
- **Interactive Applications**: Build chat interfaces, code assistants, and more

### 💻 Enhance Development Workflows
- **Automated Code Review**: Analyze code quality and suggest improvements
- **Documentation Generation**: Create comprehensive docs from code
- **Test Generation**: Automatically generate test cases
- **Refactoring Assistant**: Get AI-powered code transformation suggestions

### 📊 Data Processing & Analysis
- **Text Analysis**: Extract insights from documents
- **Data Transformation**: Convert between formats intelligently
- **Report Generation**: Create summaries and reports
- **Language Translation**: Build multilingual applications

### 🔧 DevOps & Automation
- **PR Description Generation**: Automatically create detailed PR descriptions
- **Issue Triage**: Categorize and respond to issues
- **Commit Message Generation**: Create meaningful commit messages
- **CI/CD Integration**: Add AI checks to your pipeline

## Quick Start

### Prerequisites
1. Get your API key from [Anthropic Console](https://console.anthropic.com/settings/keys)
2. Set environment variable: `export ANTHROPIC_API_KEY='your-key-here'`

### Python Examples

```bash
cd ~/.config/claude/sdk-examples/python
source venv/bin/activate
python basic_example.py
```

Available examples:
- `basic_example.py` - Simple message creation
- `streaming_example.py` - Real-time streaming responses
- `code_analysis.py` - Automated code review

### TypeScript Examples

```bash
cd ~/.config/claude/sdk-examples/typescript
npx tsx basic-example.ts
```

Available examples:
- `basic-example.ts` - Type-safe message creation
- `streaming-example.ts` - Streaming with event handling
- `code-review-automation.ts` - Build a code review tool

## Use Cases

### 1. Code Review Automation
```python
# Analyze any code snippet
analysis = analyze_code(client, code_snippet, "python")
print(analysis)  # Get issues, suggestions, and quality score
```

### 2. Real-time Chat Applications
```typescript
// Stream responses for better UX
for await (const event of stream) {
  if (event.type === 'content_block_delta') {
    process.stdout.write(event.delta.text);
  }
}
```

### 3. Batch Processing
```python
# Process multiple documents efficiently
results = []
for document in documents:
    result = client.messages.create(
        model="claude-sonnet-4-20250514",
        messages=[{"role": "user", "content": f"Summarize: {document}"}]
    )
    results.append(result)
```

### 4. Integration with MCP Services
The SDK works seamlessly with your MCP setup:
- Use filesystem MCP to read files, then analyze with Claude
- Store results in SQLite using the MCP SQLite server
- Fetch web content with MCP fetch, then summarize with Claude

## Advanced Features

### Custom System Prompts
```python
client.messages.create(
    system="You are an expert in quantum computing. Use technical terminology.",
    messages=[{"role": "user", "content": "Explain superposition"}]
)
```

### Temperature Control
```typescript
// Lower temperature (0.0-0.3) for focused, deterministic responses
// Higher temperature (0.7-1.0) for creative, varied responses
await anthropic.messages.create({
    temperature: 0.2,
    // ... other parameters
});
```

### Token Management
```python
# Set appropriate max_tokens based on expected response length
# Monitor usage for cost optimization
message = client.messages.create(
    max_tokens=4096,  # Adjust based on needs
    # ... other parameters
)
```

## Best Practices

1. **Error Handling**: Always wrap API calls in try-catch blocks
2. **Rate Limiting**: Implement exponential backoff for retries
3. **API Key Security**: Never commit API keys to version control
4. **Prompt Engineering**: Be specific and provide context
5. **Model Selection**: Choose the right model for your use case
   - claude-sonnet: Balanced performance and cost
   - claude-opus: Maximum capability
   - claude-haiku: Fast and economical

## Integration Ideas

### With Your MCP Setup
1. **Intelligent File Processing**: Read files with MCP filesystem, analyze with Claude
2. **Enhanced Git Workflow**: Use MCP git to get diffs, Claude to write commit messages
3. **Database Insights**: Query with MCP SQLite, analyze results with Claude
4. **Web Research**: Fetch content with MCP fetch, summarize with Claude

### Build Your Own Tools
1. **PR Assistant**: Automate PR reviews and suggestions
2. **Documentation Generator**: Create docs from code comments
3. **Test Suite Builder**: Generate comprehensive test cases
4. **Migration Helper**: Assist in code modernization
5. **Learning Assistant**: Create interactive coding tutorials

## Resources

- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [Python SDK Reference](https://github.com/anthropics/anthropic-sdk-python)
- [TypeScript SDK Reference](https://github.com/anthropics/anthropic-sdk-typescript)
- [Claude Model Guide](https://docs.anthropic.com/claude/docs/models-overview)

## Troubleshooting

### API Key Issues
```bash
# Check if key is set
echo $ANTHROPIC_API_KEY

# Set temporarily
export ANTHROPIC_API_KEY='sk-...'

# Set permanently (add to ~/.zshrc)
echo "export ANTHROPIC_API_KEY='sk-...'" >> ~/.zshrc
```

### Import Errors
```bash
# Python
pip install -r requirements.txt

# TypeScript
npm install
```

### Rate Limits
Implement retry logic:
```python
import time
from anthropic import RateLimitError

for attempt in range(3):
    try:
        response = client.messages.create(...)
        break
    except RateLimitError:
        time.sleep(2 ** attempt)
```

## Next Steps

1. **Get API Key**: Visit [console.anthropic.com](https://console.anthropic.com)
2. **Run Examples**: Try the provided examples
3. **Build Something**: Create your own AI-powered tool
4. **Share & Learn**: Join the Anthropic community

Happy building! 🚀