#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import axios from 'axios';

class JobberMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'jobber-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    // Jobber API configuration
    this.baseURL = 'https://api.getjobber.com/api/graphql';
    this.apiKey = process.env.JOBBER_API_KEY;
    this.apiSecret = process.env.JOBBER_API_SECRET;
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'get_clients',
            description: 'Get list of clients from Jobber',
            inputSchema: {
              type: 'object',
              properties: {
                limit: {
                  type: 'number',
                  description: 'Maximum number of clients to return',
                  default: 10,
                },
                search: {
                  type: 'string',
                  description: 'Search term for client name or email',
                },
              },
            },
          },
          {
            name: 'create_client',
            description: 'Create a new client in Jobber',
            inputSchema: {
              type: 'object',
              properties: {
                name: {
                  type: 'string',
                  description: 'Client name',
                },
                email: {
                  type: 'string',
                  description: 'Client email address',
                },
                phone: {
                  type: 'string',
                  description: 'Client phone number',
                },
                address: {
                  type: 'string',
                  description: 'Client address',
                },
              },
              required: ['name'],
            },
          },
          {
            name: 'get_jobs',
            description: 'Get list of jobs from Jobber',
            inputSchema: {
              type: 'object',
              properties: {
                clientId: {
                  type: 'string',
                  description: 'Filter by specific client ID',
                },
                status: {
                  type: 'string',
                  description: 'Filter by job status (active, completed, cancelled)',
                },
                limit: {
                  type: 'number',
                  description: 'Maximum number of jobs to return',
                  default: 10,
                },
              },
            },
          },
          {
            name: 'create_job',
            description: 'Create a new job in Jobber',
            inputSchema: {
              type: 'object',
              properties: {
                clientId: {
                  type: 'string',
                  description: 'Client ID for the job',
                },
                title: {
                  type: 'string',
                  description: 'Job title',
                },
                description: {
                  type: 'string',
                  description: 'Job description',
                },
                startDate: {
                  type: 'string',
                  description: 'Job start date (YYYY-MM-DD)',
                },
              },
              required: ['clientId', 'title'],
            },
          },
          {
            name: 'get_invoices',
            description: 'Get list of invoices from Jobber',
            inputSchema: {
              type: 'object',
              properties: {
                clientId: {
                  type: 'string',
                  description: 'Filter by specific client ID',
                },
                status: {
                  type: 'string',
                  description: 'Filter by invoice status (draft, sent, paid, overdue)',
                },
                limit: {
                  type: 'number',
                  description: 'Maximum number of invoices to return',
                  default: 10,
                },
              },
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'get_clients':
          return await this.getClients(request.params.arguments);
        case 'create_client':
          return await this.createClient(request.params.arguments);
        case 'get_jobs':
          return await this.getJobs(request.params.arguments);
        case 'create_job':
          return await this.createJob(request.params.arguments);
        case 'get_invoices':
          return await this.getInvoices(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  async makeJobberRequest(query, variables = {}) {
    if (!this.apiKey || !this.apiSecret) {
      throw new Error('Jobber API credentials not configured. Set JOBBER_API_KEY and JOBBER_API_SECRET environment variables.');
    }

    try {
      const response = await axios.post(
        this.baseURL,
        {
          query,
          variables,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
            'X-JOBBER-GRAPHQL-VERSION': '2023-03-15',
          },
        }
      );

      return response.data;
    } catch (error) {
      throw new Error(`Jobber API error: ${error.response?.data?.message || error.message}`);
    }
  }

  async getClients(args) {
    const query = `
      query GetClients($first: Int, $filter: ClientFilter) {
        clients(first: $first, filter: $filter) {
          nodes {
            id
            name
            email
            phoneNumber
            address {
              street
              city
              province
              postalCode
            }
            createdAt
            updatedAt
          }
          totalCount
        }
      }
    `;

    const variables = {
      first: args.limit || 10,
      filter: args.search ? { name: { contains: args.search } } : {},
    };

    try {
      const result = await this.makeJobberRequest(query, variables);
      
      return {
        content: [
          {
            type: 'text',
            text: `Found ${result.data.clients.totalCount} clients:\n\n${result.data.clients.nodes.map(client => 
              `• ${client.name} (${client.email || 'No email'}) - ${client.phoneNumber || 'No phone'}`
            ).join('\n')}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get clients: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async createClient(args) {
    const mutation = `
      mutation CreateClient($input: ClientCreateInput!) {
        clientCreate(input: $input) {
          client {
            id
            name
            email
            phoneNumber
          }
          userErrors {
            field
            message
          }
        }
      }
    `;

    const variables = {
      input: {
        name: args.name,
        email: args.email,
        phoneNumber: args.phone,
        address: args.address ? { street: args.address } : undefined,
      },
    };

    try {
      const result = await this.makeJobberRequest(mutation, variables);
      
      if (result.data.clientCreate.userErrors.length > 0) {
        throw new Error(result.data.clientCreate.userErrors.map(e => e.message).join(', '));
      }

      const client = result.data.clientCreate.client;
      return {
        content: [
          {
            type: 'text',
            text: `Client created successfully: ${client.name} (ID: ${client.id})`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to create client: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getJobs(args) {
    const query = `
      query GetJobs($first: Int, $filter: JobFilter) {
        jobs(first: $first, filter: $filter) {
          nodes {
            id
            title
            description
            jobStatus
            startDate
            client {
              id
              name
            }
            createdAt
          }
          totalCount
        }
      }
    `;

    const variables = {
      first: args.limit || 10,
      filter: {
        ...(args.clientId && { clientId: args.clientId }),
        ...(args.status && { jobStatus: args.status.toUpperCase() }),
      },
    };

    try {
      const result = await this.makeJobberRequest(query, variables);
      
      return {
        content: [
          {
            type: 'text',
            text: `Found ${result.data.jobs.totalCount} jobs:\n\n${result.data.jobs.nodes.map(job => 
              `• ${job.title} (${job.jobStatus}) - Client: ${job.client.name} - Start: ${job.startDate || 'Not scheduled'}`
            ).join('\n')}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get jobs: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async createJob(args) {
    const mutation = `
      mutation CreateJob($input: JobCreateInput!) {
        jobCreate(input: $input) {
          job {
            id
            title
            description
            jobStatus
            client {
              name
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    `;

    const variables = {
      input: {
        clientId: args.clientId,
        title: args.title,
        description: args.description,
        startDate: args.startDate,
      },
    };

    try {
      const result = await this.makeJobberRequest(mutation, variables);
      
      if (result.data.jobCreate.userErrors.length > 0) {
        throw new Error(result.data.jobCreate.userErrors.map(e => e.message).join(', '));
      }

      const job = result.data.jobCreate.job;
      return {
        content: [
          {
            type: 'text',
            text: `Job created successfully: ${job.title} for ${job.client.name} (ID: ${job.id})`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to create job: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getInvoices(args) {
    const query = `
      query GetInvoices($first: Int, $filter: InvoiceFilter) {
        invoices(first: $first, filter: $filter) {
          nodes {
            id
            invoiceNumber
            total
            status
            dueDate
            client {
              id
              name
            }
            createdAt
          }
          totalCount
        }
      }
    `;

    const variables = {
      first: args.limit || 10,
      filter: {
        ...(args.clientId && { clientId: args.clientId }),
        ...(args.status && { status: args.status.toUpperCase() }),
      },
    };

    try {
      const result = await this.makeJobberRequest(query, variables);
      
      return {
        content: [
          {
            type: 'text',
            text: `Found ${result.data.invoices.totalCount} invoices:\n\n${result.data.invoices.nodes.map(invoice => 
              `• #${invoice.invoiceNumber} - $${invoice.total} (${invoice.status}) - Client: ${invoice.client.name} - Due: ${invoice.dueDate || 'No due date'}`
            ).join('\n')}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get invoices: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Jobber MCP server running on stdio');
  }
}

const server = new JobberMCPServer();
server.run().catch(console.error);