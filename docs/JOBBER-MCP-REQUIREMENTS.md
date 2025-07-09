# Jobber MCP Server Requirements

## Current Status
❌ **No existing Jobber MCP server package found**

Based on npm search results, there is no dedicated `jobber-mcp` package available. However, Jobber does provide API access that can be integrated with a custom MCP server.

## Jobber API Overview

### Available APIs
- **Jobber API v2**: REST API for job management, client management, invoicing, scheduling
- **Jobber GraphQL API**: More flexible querying capabilities
- **Webhook support**: Real-time event notifications

### Key Endpoints for DuetRight Integration
1. **Jobs API**
   - `GET /jobs` - List all jobs
   - `POST /jobs` - Create new job
   - `PUT /jobs/{id}` - Update job status
   - `GET /jobs/{id}` - Get job details

2. **Clients API**
   - `GET /clients` - List all clients
   - `POST /clients` - Create new client
   - `GET /clients/{id}` - Get client details

3. **Quotes API**
   - `GET /quotes` - List all quotes
   - `POST /quotes` - Create new quote
   - `PUT /quotes/{id}` - Update quote status

4. **Invoices API**
   - `GET /invoices` - List all invoices
   - `POST /invoices` - Create new invoice
   - `GET /invoices/{id}` - Get invoice details

## Custom MCP Server Implementation Plan

### Phase 1: Basic MCP Server Structure
```typescript
// jobber-mcp-server/src/index.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

const server = new Server({
  name: 'jobber-mcp-server',
  version: '1.0.0',
}, {
  capabilities: {
    tools: {},
  },
});

// Tool definitions for Jobber API integration
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'list_jobs',
        description: 'List all jobs from Jobber',
        inputSchema: {
          type: 'object',
          properties: {
            status: { type: 'string', description: 'Filter by job status' },
            client_id: { type: 'string', description: 'Filter by client ID' },
            limit: { type: 'number', description: 'Limit number of results' }
          }
        }
      },
      {
        name: 'create_job',
        description: 'Create a new job in Jobber',
        inputSchema: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'Job title' },
            description: { type: 'string', description: 'Job description' },
            client_id: { type: 'string', description: 'Client ID' },
            scheduled_date: { type: 'string', description: 'Scheduled date (ISO format)' }
          },
          required: ['title', 'client_id']
        }
      },
      {
        name: 'update_job_status',
        description: 'Update job status in Jobber',
        inputSchema: {
          type: 'object',
          properties: {
            job_id: { type: 'string', description: 'Job ID' },
            status: { type: 'string', description: 'New status' }
          },
          required: ['job_id', 'status']
        }
      },
      {
        name: 'list_clients',
        description: 'List all clients from Jobber',
        inputSchema: {
          type: 'object',
          properties: {
            limit: { type: 'number', description: 'Limit number of results' }
          }
        }
      },
      {
        name: 'create_quote',
        description: 'Create a new quote in Jobber',
        inputSchema: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'Quote title' },
            client_id: { type: 'string', description: 'Client ID' },
            line_items: { type: 'array', description: 'Array of line items' }
          },
          required: ['title', 'client_id']
        }
      }
    ]
  };
});
```

### Phase 2: Authentication Setup
```typescript
// Authentication using Jobber API token
class JobberAPIClient {
  private apiToken: string;
  private baseURL: string = 'https://api.getjobber.com/api/v2';

  constructor(apiToken: string) {
    this.apiToken = apiToken;
  }

  private async makeRequest(endpoint: string, options: RequestInit = {}) {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.apiToken}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    if (!response.ok) {
      throw new Error(`Jobber API error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  }

  async listJobs(params: { status?: string; client_id?: string; limit?: number }) {
    const queryParams = new URLSearchParams();
    if (params.status) queryParams.append('status', params.status);
    if (params.client_id) queryParams.append('client_id', params.client_id);
    if (params.limit) queryParams.append('limit', params.limit.toString());

    return this.makeRequest(`/jobs?${queryParams}`);
  }

  async createJob(jobData: any) {
    return this.makeRequest('/jobs', {
      method: 'POST',
      body: JSON.stringify(jobData)
    });
  }

  // Additional methods for other endpoints...
}
```

### Phase 3: Environment Configuration
```bash
# Required environment variables
JOBBER_API_TOKEN=your_jobber_api_token_here
JOBBER_API_URL=https://api.getjobber.com/api/v2
```

### Phase 4: Package Configuration
```json
{
  "name": "jobber-mcp-server",
  "version": "1.0.0",
  "description": "MCP server for Jobber API integration",
  "main": "build/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node build/index.js",
    "dev": "tsx src/index.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.15.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "tsx": "^4.0.0"
  },
  "bin": {
    "jobber-mcp-server": "build/index.js"
  }
}
```

## Integration Steps

### 1. Development Environment Setup
```bash
# Create new directory for custom MCP server
mkdir -p ~/Projects/jobber-mcp-server
cd ~/Projects/jobber-mcp-server

# Initialize Node.js project
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk
npm install -D typescript @types/node tsx

# Create TypeScript configuration
npx tsc --init
```

### 2. Jobber API Access Setup
1. Log in to Jobber account
2. Navigate to Settings > API & Integrations
3. Generate API token with appropriate permissions:
   - Jobs: Read, Write
   - Clients: Read, Write
   - Quotes: Read, Write
   - Invoices: Read, Write

### 3. Testing & Verification
```bash
# Test API connectivity
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json" \
     https://api.getjobber.com/api/v2/jobs

# Test MCP server locally
npm run build
npm start
```

### 4. Claude Integration
```bash
# Install custom MCP server
claude mcp add jobber "node ~/Projects/jobber-mcp-server/build/index.js"

# Test integration
claude "List my recent jobs from Jobber"
claude "Create a new job for client XYZ"
```

## Authentication Requirements

### Jobber API Token
- **Location**: Jobber Settings > API & Integrations
- **Permissions needed**:
  - Jobs: Read, Write
  - Clients: Read, Write
  - Quotes: Read, Write
  - Invoices: Read, Write
- **Environment Variable**: `JOBBER_API_TOKEN`

### Security Considerations
- Store API token securely in environment variables
- Implement rate limiting to respect Jobber API limits
- Add error handling for API failures
- Log API usage for monitoring

## Expected Functionality

Once implemented, the Jobber MCP server will enable:

1. **Job Management**
   - List all jobs with filtering options
   - Create new jobs with client assignment
   - Update job statuses (scheduled, in-progress, completed)
   - Get detailed job information

2. **Client Management**
   - List all clients
   - Create new clients
   - Get client details and history

3. **Quote Generation**
   - Create automated quotes
   - Update quote statuses
   - Convert quotes to jobs

4. **Invoice Processing**
   - Generate invoices from completed jobs
   - Track invoice statuses
   - Send invoices to clients

## Development Timeline

- **Phase 1**: Basic server structure and API client (2-3 hours)
- **Phase 2**: Tool implementations and testing (4-6 hours)
- **Phase 3**: Error handling and optimization (2-3 hours)
- **Phase 4**: Integration testing with Claude (1-2 hours)

**Total estimated time**: 9-14 hours of development

## Alternative Solutions

If custom development is not feasible immediately:

1. **Zapier Integration**: Use existing Zapier connectors with webhook triggers
2. **Direct API Calls**: Use Claude's general HTTP request capabilities
3. **Scheduled Reports**: Export Jobber data to CSV/JSON for periodic ingestion

## Next Steps

1. ✅ Document requirements (this file)
2. ⏳ Set up development environment
3. ⏳ Obtain Jobber API token
4. ⏳ Implement basic MCP server structure
5. ⏳ Test with Claude integration
6. ⏳ Deploy and configure for production use

---

**Note**: This is a custom development project. Unlike other MCP servers that have existing packages, the Jobber integration requires building a custom solution tailored to DuetRight's specific workflows and requirements.