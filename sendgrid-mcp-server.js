#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import sgMail from '@sendgrid/mail';

class SendGridMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'sendgrid-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    // Initialize SendGrid
    if (process.env.SENDGRID_API_KEY) {
      sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    }
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'send_email',
            description: 'Send an email via SendGrid',
            inputSchema: {
              type: 'object',
              properties: {
                to: {
                  type: 'string',
                  description: 'Recipient email address',
                },
                subject: {
                  type: 'string',
                  description: 'Email subject',
                },
                content: {
                  type: 'string',
                  description: 'Email content (HTML or text)',
                },
                from: {
                  type: 'string',
                  description: 'Sender email address (optional, uses default)',
                },
                contentType: {
                  type: 'string',
                  description: 'Content type: text/plain or text/html',
                  default: 'text/html',
                },
              },
              required: ['to', 'subject', 'content'],
            },
          },
          {
            name: 'send_bulk_email',
            description: 'Send bulk emails via SendGrid',
            inputSchema: {
              type: 'object',
              properties: {
                recipients: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Array of recipient email addresses',
                },
                subject: {
                  type: 'string',
                  description: 'Email subject',
                },
                content: {
                  type: 'string',
                  description: 'Email content (HTML or text)',
                },
                from: {
                  type: 'string',
                  description: 'Sender email address (optional)',
                },
              },
              required: ['recipients', 'subject', 'content'],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'send_email':
          return await this.sendEmail(request.params.arguments);
        case 'send_bulk_email':
          return await this.sendBulkEmail(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  async sendEmail(args) {
    try {
      const msg = {
        to: args.to,
        from: args.from || process.env.SENDGRID_FROM_EMAIL || 'noreply@duetright.com',
        subject: args.subject,
        html: args.contentType === 'text/html' ? args.content : undefined,
        text: args.contentType === 'text/plain' ? args.content : undefined,
      };

      if (!msg.html && !msg.text) {
        msg.html = args.content; // Default to HTML
      }

      const result = await sgMail.send(msg);
      
      return {
        content: [
          {
            type: 'text',
            text: `Email sent successfully to ${args.to}. Message ID: ${result[0].headers?.['x-message-id'] || 'N/A'}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to send email: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async sendBulkEmail(args) {
    try {
      const messages = args.recipients.map(recipient => ({
        to: recipient,
        from: args.from || process.env.SENDGRID_FROM_EMAIL || 'noreply@duetright.com',
        subject: args.subject,
        html: args.content,
      }));

      const results = await sgMail.send(messages);
      
      return {
        content: [
          {
            type: 'text',
            text: `Bulk email sent successfully to ${args.recipients.length} recipients. Status codes: ${results.map(r => r.statusCode).join(', ')}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to send bulk email: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('SendGrid MCP server running on stdio');
  }
}

const server = new SendGridMCPServer();
server.run().catch(console.error);