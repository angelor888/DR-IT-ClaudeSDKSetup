# Claude Code Screenshot Workflow

This document details how to effectively use Claude Code's screenshot and image processing capabilities for development workflows.

## Overview

Claude Code supports visual input through screenshots and images, enabling:
- UI/UX feedback and improvement suggestions
- Bug identification from visual evidence
- Code review with visual context
- Design system validation
- Error analysis from screenshot logs

## Supported Image Formats

- **PNG** (recommended for screenshots)
- **JPG/JPEG** (for photographs)
- **GIF** (for animations)
- **WebP** (for web-optimized images)

## Screenshot Integration Methods

### 1. Direct Screenshot Upload

```bash
# Take screenshot and pipe to Claude
claude "analyze this UI for accessibility issues" /path/to/screenshot.png
```

### 2. System Screenshot Integration

#### macOS
```bash
# Take screenshot and save to clipboard
cmd+shift+4

# Take screenshot and save to file
screencapture -i ~/Desktop/screenshot.png

# Pass to Claude
claude "review this interface design" ~/Desktop/screenshot.png
```

#### Linux
```bash
# Take screenshot with gnome-screenshot
gnome-screenshot -f screenshot.png

# Take screenshot with scrot
scrot screenshot.png

# Pass to Claude
claude "identify usability issues" screenshot.png
```

### 3. Automated Screenshot Testing

#### Browser Testing with Puppeteer
```javascript
// screenshot-test.js
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'test-screenshot.png' });
  
  await browser.close();
})();
```

#### Playwright Integration
```javascript
// playwright-screenshot.js
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'ui-test.png' });
  
  await browser.close();
})();
```

### 4. CI/CD Screenshot Validation

#### GitHub Actions Example
```yaml
# .github/workflows/visual-testing.yml
name: Visual Testing

on: [push, pull_request]

jobs:
  visual-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '22.x'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build application
      run: npm run build
      
    - name: Start application
      run: npm start &
      
    - name: Wait for application
      run: sleep 10
      
    - name: Take screenshots
      run: |
        npx playwright test --headed
        
    - name: Analyze screenshots with Claude
      run: |
        for screenshot in screenshots/*.png; do
          claude "analyze this UI for potential issues" "$screenshot" >> analysis.md
        done
        
    - name: Upload analysis
      uses: actions/upload-artifact@v3
      with:
        name: ui-analysis
        path: analysis.md
```

## Common Use Cases

### 1. UI/UX Review
```bash
# Take screenshot of application
screencapture -i ui-screenshot.png

# Analyze with Claude
claude "Review this interface for usability issues and suggest improvements" ui-screenshot.png
```

### 2. Bug Reporting
```bash
# Take screenshot of error
screencapture -i error-screenshot.png

# Analyze error with Claude
claude "Identify the error shown in this screenshot and suggest fixes" error-screenshot.png
```

### 3. Design System Validation
```bash
# Take screenshot of component
screencapture -i component-screenshot.png

# Validate against design system
claude "Check if this component follows our design system guidelines" component-screenshot.png
```

### 4. Cross-browser Testing
```bash
# Take screenshots across browsers
for browser in chrome firefox safari; do
  playwright-screenshot --browser=$browser --output=${browser}-screenshot.png
done

# Analyze differences
claude "Compare these browser screenshots and identify rendering differences" *.png
```

## Advanced Screenshot Workflows

### 1. Automated Visual Regression Testing

```bash
#!/bin/bash
# visual-regression-test.sh

# Take baseline screenshot
screencapture -i baseline.png

# Make changes to code
git checkout feature-branch

# Take new screenshot  
screencapture -i current.png

# Compare with Claude
claude "Compare these two screenshots and identify any visual regressions" baseline.png current.png
```

### 2. Performance Visualization

```javascript
// performance-screenshot.js
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  // Start performance monitoring
  await page.tracing.start({ path: 'trace.json' });
  
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'performance-screenshot.png' });
  
  await page.tracing.stop();
  await browser.close();
})();
```

### 3. Accessibility Testing

```bash
# Take screenshot of application
screencapture -i accessibility-test.png

# Analyze for accessibility issues
claude "Analyze this interface for accessibility issues including color contrast, text size, and navigation clarity" accessibility-test.png
```

## Integration with MCP Servers

### Puppeteer MCP Server
```javascript
// Use MCP server for screenshot automation
const mcp = require('@anthropic-ai/mcp-puppeteer');

const server = new mcp.PuppeteerServer();

// Take screenshot via MCP
await server.screenshot({
  url: 'http://localhost:3000',
  path: 'mcp-screenshot.png',
  options: {
    fullPage: true,
    quality: 90
  }
});
```

## Claude Code Settings for Screenshots

### Configuration
```json
{
  "imageProcessing": {
    "enabled": true,
    "maxSize": "10MB",
    "supportedFormats": ["png", "jpg", "jpeg", "gif", "webp"],
    "compressionLevel": 80
  },
  "screenshotIntegration": {
    "autoAnalyze": true,
    "saveToProject": true,
    "defaultPath": "./screenshots/"
  }
}
```

## Best Practices

### 1. File Organization
```
project/
├── screenshots/
│   ├── baseline/
│   ├── current/
│   └── analysis/
├── docs/
│   └── visual-testing.md
└── scripts/
    └── screenshot-workflow.sh
```

### 2. Naming Conventions
```bash
# Include timestamp and context
screenshot-$(date +%Y%m%d-%H%M%S)-login-page.png
bug-report-$(date +%Y%m%d)-checkout-error.png
ui-review-$(date +%Y%m%d)-dashboard.png
```

### 3. Automated Cleanup
```bash
#!/bin/bash
# cleanup-screenshots.sh

# Delete screenshots older than 30 days
find ./screenshots -name "*.png" -mtime +30 -delete

# Compress older screenshots
find ./screenshots -name "*.png" -mtime +7 -exec gzip {} \;
```

## Troubleshooting

### Common Issues

1. **Large File Sizes**: Compress images before uploading
2. **Unsupported Formats**: Convert to PNG/JPG
3. **Poor Quality**: Use appropriate resolution and compression
4. **Timeout Issues**: Reduce image size or increase timeout

### File Size Optimization
```bash
# Compress PNG with pngquant
pngquant --quality=65-80 input.png --output compressed.png

# Compress JPEG with ImageMagick
convert input.jpg -quality 80 compressed.jpg

# Batch optimization
for img in *.png; do
  pngquant --quality=65-80 "$img" --output "compressed-$img"
done
```

## Integration Examples

### 1. Jest Visual Testing
```javascript
// __tests__/visual.test.js
const puppeteer = require('puppeteer');

describe('Visual Tests', () => {
  let browser, page;
  
  beforeAll(async () => {
    browser = await puppeteer.launch();
    page = await browser.newPage();
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  test('Homepage renders correctly', async () => {
    await page.goto('http://localhost:3000');
    await page.screenshot({ path: 'test-homepage.png' });
    
    // Analyze with Claude (in CI/CD pipeline)
    // claude "verify this homepage matches design requirements" test-homepage.png
  });
});
```

### 2. Storybook Integration
```javascript
// .storybook/screenshot-addon.js
import { addons } from '@storybook/addons';

addons.register('screenshot-addon', () => {
  const takeScreenshot = () => {
    // Take screenshot of current story
    html2canvas(document.body).then(canvas => {
      const screenshot = canvas.toDataURL();
      // Send to Claude for analysis
    });
  };
  
  return {
    title: 'Screenshot',
    type: 'tool',
    match: ({ viewMode }) => viewMode === 'story',
    render: () => `<button onclick="takeScreenshot()">Analyze with Claude</button>`
  };
});
```

## Memory Integration

Screenshots can be integrated with Claude's memory system:

```bash
# memorize screenshot analysis
claude "# memorize: Dashboard redesign shows improved user flow" dashboard-v2.png

# This will be saved to Claude.md for future reference
```

## Security Considerations

1. **Sensitive Data**: Avoid screenshots containing passwords, API keys, or personal information
2. **File Permissions**: Set appropriate permissions on screenshot directories
3. **Cleanup**: Regularly delete old screenshots to prevent data accumulation
4. **Sanitization**: Remove sensitive information before sharing screenshots

## Conclusion

Claude Code's screenshot workflow enables powerful visual analysis and feedback loops in development processes. By integrating screenshots with automated testing, CI/CD pipelines, and development workflows, teams can maintain high visual quality and quickly identify issues.