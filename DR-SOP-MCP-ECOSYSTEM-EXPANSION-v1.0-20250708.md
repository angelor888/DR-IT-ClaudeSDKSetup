# DR-SOP-MCP-ECOSYSTEM-EXPANSION-v1.0-20250708

## Standard Operating Procedure: MCP Ecosystem Expansion & Business Integration

### 📋 **SOP Information**
- **Document ID:** DR-SOP-MCP-ECOSYSTEM-EXPANSION-v1.0-20250708
- **Created:** July 8, 2025
- **Author:** DuetRight IT Team with Claude Code
- **Category:** System Integration & Automation
- **Approval Status:** Active
- **Next Review:** January 8, 2026

---

## 🎯 **Purpose & Scope**

### **Objective**
Establish comprehensive Model Context Protocol (MCP) ecosystem for unified AI-powered business automation, expanding from basic development tools to complete business lifecycle management.

### **Scope**
- MCP server installation and configuration
- Custom server development for business-specific integrations
- Authentication framework establishment
- Documentation and team communication protocols

### **Business Impact**
- 286% ecosystem expansion (7 → 27 MCP servers)
- Complete business automation capability
- Unified AI interface for all operations
- Real-time intelligence and workflow optimization

---

## 📊 **Pre-Requirements**

### **Technical Prerequisites**
- Claude Code CLI installed and operational
- Node.js v18+ with npm
- Git repository access
- macOS/Linux environment
- Network access for package installation

### **Access Requirements**
- GitHub repository write access
- Slack workspace administration
- API access to target business services
- Administrative permissions for environment configuration

### **Knowledge Requirements**
- Basic command line proficiency
- Understanding of MCP protocol concepts
- API authentication principles
- Git workflow familiarity

---

## 🚀 **Installation Procedures**

### **Phase 1: Official Package Installations**

#### **Step 1.1: Communication & Collaboration Servers**
```bash
# Install core communication servers
claude mcp add slack "npx @modelcontextprotocol/server-slack@latest"
claude mcp add gmail "npx @gongrzhe/server-gmail-autoauth-mcp@latest"
claude mcp add notion "npx @notionhq/notion-mcp-server@latest"
claude mcp add gcal "npx mcp-google-calendar-plus@latest"
claude mcp add confluence "npx @aashari/mcp-server-atlassian-confluence@latest"
```

#### **Step 1.2: Business Integration Servers**
```bash
# Install business workflow servers
claude mcp add gdrive "npx @modelcontextprotocol/server-gdrive@latest"
claude mcp add airtable "npx airtable-mcp-server@latest"
claude mcp add firebase "npx @gannonh/firebase-mcp@latest"
```

#### **Step 1.3: Development & Infrastructure Servers**
```bash
# Install development and infrastructure servers
claude mcp add github "npx @andrebuzeli/github-mcp-v2@latest"
claude mcp add github-official "npx @modelcontextprotocol/server-github@latest"
claude mcp add playwright "npx @playwright/mcp@latest"
claude mcp add desktop-commander "npx @wonderwhy-er/desktop-commander@latest"
claude mcp add nx "npx nx-mcp@latest"
claude mcp add sequential-thinking "npx @modelcontextprotocol/server-sequential-thinking@latest"
claude mcp add filesystem "npx @modelcontextprotocol/server-filesystem@latest"
claude mcp add postgres "npx @modelcontextprotocol/server-postgres@latest"
claude mcp add neon "npx @neondatabase/mcp-server-neon@latest"
claude mcp add firecrawl "npx firecrawl-mcp@latest"
claude mcp add tavily "npx tavily-mcp@latest"
claude mcp add openai "npx openai-mcp-server@latest"
claude mcp add taiga "npx taiga-mcp-server@latest"
claude mcp add atlas "npx @boundless-oss/atlas@latest"
claude mcp add cloudflare "npx @cloudflare/mcp-server-cloudflare@latest"
```

### **Phase 2: Custom Server Development**

#### **Step 2.1: Initialize Development Environment**
```bash
# Initialize package.json for custom servers
npm init -y

# Configure for ES modules
# Edit package.json: "type": "module"

# Install dependencies
npm install @modelcontextprotocol/sdk@^1.15.0 @sendgrid/mail@^8.1.5 axios@^1.6.0 @matterport/sdk@^1.4.24 node-quickbooks@^2.0.46
```

#### **Step 2.2: Create Custom MCP Servers**

**SendGrid Email Automation Server**
- **File:** `sendgrid-mcp-server.js`
- **Capabilities:** Send individual/bulk emails, templates, automation
- **Registration:** `claude mcp add sendgrid "node /path/to/sendgrid-mcp-server.js"`

**Jobber Business Management Server**
- **File:** `jobber-mcp-server.js`
- **Capabilities:** Client management, job creation, invoice handling
- **API:** GraphQL-based with comprehensive business workflow support
- **Registration:** `claude mcp add jobber "node /path/to/jobber-mcp-server.js"`

**Matterport 3D Visualization Server**
- **File:** `matterport-mcp-server.js`
- **Capabilities:** 3D model management, analytics, embed generation
- **Registration:** `claude mcp add matterport "node /path/to/matterport-mcp-server.js"`

**QuickBooks Financial Management Server**
- **File:** `quickbooks-mcp-server.js`
- **Capabilities:** Customer management, invoicing, financial reporting
- **Authentication:** OAuth 2.0 with sandbox/production modes
- **Registration:** `claude mcp add quickbooks "node /path/to/quickbooks-mcp-server.js"`

#### **Step 2.3: Server Architecture Pattern**
```javascript
// Standard MCP server structure
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

class CustomMCPServer {
  constructor() {
    this.server = new Server({
      name: 'service-mcp-server',
      version: '1.0.0'
    }, {
      capabilities: { tools: {} }
    });
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    // Tool registration and handling logic
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Service MCP server running on stdio');
  }
}
```

### **Phase 3: Authentication Framework**

#### **Step 3.1: Environment Configuration**
```bash
# Create/update environment file
vim ~/.config/claude/environment
```

#### **Step 3.2: Service Authentication Variables**
```bash
# Core Services
SLACK_BOT_TOKEN=xoxb-[token]
SLACK_SIGNING_SECRET=[secret]
SLACK_APP_TOKEN=xapp-[token]

# Google Services
GOOGLE_CLIENT_ID=[id]
GOOGLE_CLIENT_SECRET=[secret]
GOOGLE_DRIVE_CLIENT_ID=[id]
GOOGLE_DRIVE_CLIENT_SECRET=[secret]
GOOGLE_DRIVE_REFRESH_TOKEN=[token]

# Business Tools
AIRTABLE_API_KEY=[key]
AIRTABLE_BASE_ID=[id]
FIREBASE_PROJECT_ID=[id]
FIREBASE_PRIVATE_KEY=[key]
FIREBASE_CLIENT_EMAIL=[email]
SENDGRID_API_KEY=[key]
SENDGRID_FROM_EMAIL=[email]

# Financial & CRM
JOBBER_API_KEY=[key]
JOBBER_API_SECRET=[secret]
QUICKBOOKS_CONSUMER_KEY=[key]
QUICKBOOKS_CONSUMER_SECRET=[secret]
QUICKBOOKS_ACCESS_TOKEN=[token]
QUICKBOOKS_ACCESS_TOKEN_SECRET=[secret]
QUICKBOOKS_REALM_ID=[id]

# Documentation
CONFLUENCE_BASE_URL=[url]
CONFLUENCE_USERNAME=[email]
CONFLUENCE_API_TOKEN=[token]

# Development & Infrastructure
GITHUB_TOKEN=[token]
OPENAI_API_KEY=[key]
POSTGRES_CONNECTION_STRING=[string]
CLOUDFLARE_API_TOKEN=[token]
```

### **Phase 4: Integration & Testing**

#### **Step 4.1: Verification Commands**
```bash
# Verify installation
claude mcp list | wc -l  # Should show 27

# Test specific servers
claude mcp list | grep -E "(confluence|sendgrid|jobber)"

# Check environment
grep -c "_TOKEN\|_KEY\|_SECRET" ~/.config/claude/environment
```

#### **Step 4.2: Functionality Testing**
```bash
# Test custom server syntax
node -c "import('./sendgrid-mcp-server.js')"

# Verify dependencies
npm ls --depth=0 | grep -E "(sdk|sendgrid|quickbooks)"

# Check file permissions
ls -la *-mcp-server.js
```

---

## 📋 **Server Categories & Capabilities**

### **🌐 Communication & Collaboration (5 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Slack | Workspace integration, automated reports | Bot Token, Signing Secret |
| Gmail | Email management, client communication | OAuth 2.0 |
| Notion | Documentation, knowledge management | Integration Token |
| Google Calendar | Scheduling, project timelines | OAuth 2.0 |
| Confluence | SOP creation, page publishing, notifications | API Token |

### **🏢 Business Integrations (7 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Google Drive | Cloud storage, document management | OAuth 2.0 |
| Airtable | Database, project tracking | API Key |
| Firebase | Backend services, real-time data | Service Account |
| SendGrid | Email automation, campaigns | API Key |
| Jobber | Service business management | API Key/Secret |
| Matterport | 3D property visualization | API Key |
| QuickBooks | Accounting, financial management | OAuth 2.0 |

### **💻 Development & DevOps (6 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| GitHub Enhanced | 15 comprehensive development tools | Personal Access Token |
| GitHub Official | Alternative integration | Personal Access Token |
| Playwright | Browser automation, testing | None |
| Desktop Commander | Terminal operations | None |
| Nx | Monorepo management | None |
| Sequential Thinking | Advanced problem solving | None |

### **🗄️ Data & Database (3 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Filesystem | File system operations | None |
| PostgreSQL | Database operations, reporting | Connection String |
| Neon | Serverless database management | API Key |

### **🔍 Research & Intelligence (3 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Firecrawl | Web scraping, competitor analysis | API Key |
| Tavily | Real-time web search | API Key |
| OpenAI | Enhanced AI capabilities | API Key |

### **📋 Project Management (2 servers)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Taiga | Agile project management | URL/Username/Password |
| Atlas | Startup project management | None |

### **☁️ Infrastructure (1 server)**
| Server | Capability | Authentication |
|--------|------------|----------------|
| Cloudflare | CDN, DNS, security management | API Token, Account ID |

---

## 🔐 **Security & Compliance**

### **Authentication Best Practices**
1. **Environment Isolation:** Store all credentials in `~/.config/claude/environment`
2. **No Commits:** Never commit API keys or tokens to version control
3. **Least Privilege:** Use minimum required permissions for each service
4. **Token Rotation:** Regularly rotate API keys and access tokens
5. **Secure Storage:** Use secure credential management systems

### **File Permissions**
```bash
# Set secure permissions
chmod 600 ~/.config/claude/environment
chmod 644 /path/to/*-mcp-server.js
```

### **Network Security**
- Use HTTPS for all API communications
- Validate SSL certificates
- Implement rate limiting where appropriate
- Monitor API usage for anomalies

---

## 📊 **Monitoring & Maintenance**

### **Health Checks**
```bash
# Weekly verification
claude mcp list | wc -l
git status --porcelain
npm outdated
```

### **Update Procedures**
```bash
# Update packages quarterly
npm update
claude mcp remove [server-name]
claude mcp add [server-name] "npx [package]@latest"
```

### **Documentation Updates**
- Update MCP-SERVERS-INSTALLED.md after changes
- Maintain LEARNINGS-[date].md for insights
- Keep CLAUDE.md context current

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Authentication Failures**
```bash
# Symptoms: "invalid_auth" errors
# Resolution: 
1. Verify token format and expiration
2. Check service permissions/scopes
3. Restart Claude Code after env changes
```

#### **Installation Failures**
```bash
# Symptoms: Package not found or install errors
# Resolution:
1. Check npm package name and version
2. Verify network connectivity
3. Clear npm cache: npm cache clean --force
```

#### **Custom Server Errors**
```bash
# Symptoms: Server won't start or crashes
# Resolution:
1. Check Node.js version compatibility
2. Verify ES module syntax
3. Test with: node --check server.js
```

### **Support Escalation**
1. **Level 1:** Check documentation and common issues
2. **Level 2:** Review logs and error messages
3. **Level 3:** Escalate to development team with full context

---

## 📈 **Success Metrics**

### **Quantitative Indicators**
- **Server Count:** 27 total MCP servers operational
- **Ecosystem Growth:** 286% expansion from baseline
- **Authentication Coverage:** 25 services configured
- **Custom Development:** 4 business-specific integrations

### **Qualitative Indicators**
- Complete business lifecycle automation capability
- Unified AI interface for all operations
- Reduced context switching between tools
- Enhanced team collaboration and documentation

### **ROI Measurements**
- Time saved in cross-platform operations
- Improved workflow automation efficiency
- Enhanced business process documentation
- Reduced manual task overhead

---

## 📚 **Related Documentation**

### **Internal References**
- `MCP-SERVERS-INSTALLED.md` - Complete server listing
- `LEARNINGS-2025-07-09.md` - Technical insights and patterns
- `CLAUDE.md` - Project context and configuration
- Environment configuration: `~/.config/claude/environment`

### **External Resources**
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic SDK Reference](https://docs.anthropic.com/en/api/client-sdks)

---

## ✅ **Checklist for Implementation**

### **Pre-Implementation**
- [ ] Verify Claude Code CLI operational
- [ ] Confirm GitHub repository access
- [ ] Gather service API credentials
- [ ] Review network and security requirements

### **Implementation Phase**
- [ ] Install official MCP packages (19 servers)
- [ ] Develop custom servers (4 servers)
- [ ] Configure authentication framework
- [ ] Update documentation and Git repository
- [ ] Test functionality and integration

### **Post-Implementation**
- [ ] Verify all 27 servers operational
- [ ] Complete authentication setup
- [ ] Train team on new capabilities
- [ ] Establish monitoring procedures
- [ ] Schedule quarterly review

---

## 📞 **Support Information**

### **Primary Contacts**
- **Technical Lead:** DuetRight IT Team
- **Documentation:** Claude Code AI Assistant
- **Emergency Contact:** System Administrator

### **Resources**
- **Repository:** DR-IT-ClaudeSDKSetup
- **Slack Channel:** #it-report
- **Documentation Library:** #sop-library

---

*This SOP represents the comprehensive procedure for establishing a complete MCP ecosystem for business automation. Follow all steps in sequence for optimal results.*

**Document Control:**
- **Version:** 1.0
- **Effective Date:** July 8, 2025
- **Review Cycle:** Semi-annual
- **Next Review:** January 8, 2026