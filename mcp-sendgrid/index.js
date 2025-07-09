#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import sgMail from '@sendgrid/mail';
import fetch from 'node-fetch';
import dotenv from 'dotenv';

dotenv.config();

class SendGridMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "sendgrid-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.apiKey = process.env.SENDGRID_API_KEY;
    this.baseUrl = 'https://api.sendgrid.com/v3';
    
    if (this.apiKey) {
      sgMail.setApiKey(this.apiKey);
    }
    
    this.setupToolHandlers();
    
    // Error handling
    this.server.onerror = (error) => console.error("[MCP Error]", error);
    process.on("SIGINT", async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "sendgrid_send_email",
            description: "Send transactional email via SendGrid",
            inputSchema: {
              type: "object",
              properties: {
                to: {
                  type: "string",
                  description: "Recipient email address",
                },
                subject: {
                  type: "string",
                  description: "Email subject line",
                },
                text: {
                  type: "string",
                  description: "Plain text email content",
                },
                html: {
                  type: "string",
                  description: "HTML email content (optional)",
                },
                from: {
                  type: "string",
                  description: "Sender email address (optional, uses default if not provided)",
                },
                fromName: {
                  type: "string",
                  description: "Sender name (optional)",
                },
                replyTo: {
                  type: "string",
                  description: "Reply-to email address (optional)",
                },
                templateId: {
                  type: "string",
                  description: "SendGrid template ID (optional)",
                },
                dynamicTemplateData: {
                  type: "object",
                  description: "Dynamic template data for personalization (optional)",
                }
              },
              required: ["to", "subject", "text"]
            },
          },
          {
            name: "sendgrid_send_bulk_email",
            description: "Send bulk emails to multiple recipients",
            inputSchema: {
              type: "object",
              properties: {
                recipients: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      email: { type: "string" },
                      name: { type: "string" }
                    },
                    required: ["email"]
                  },
                  description: "Array of recipient objects with email and optional name",
                },
                subject: {
                  type: "string",
                  description: "Email subject line",
                },
                text: {
                  type: "string",
                  description: "Plain text email content",
                },
                html: {
                  type: "string",
                  description: "HTML email content (optional)",
                },
                from: {
                  type: "string",
                  description: "Sender email address (optional)",
                },
                fromName: {
                  type: "string",
                  description: "Sender name (optional)",
                },
                templateId: {
                  type: "string",
                  description: "SendGrid template ID (optional)",
                }
              },
              required: ["recipients", "subject", "text"]
            },
          },
          {
            name: "sendgrid_list_templates",
            description: "List SendGrid email templates",
            inputSchema: {
              type: "object",
              properties: {
                generations: {
                  type: "string",
                  enum: ["legacy", "dynamic"],
                  description: "Template generation type",
                  default: "dynamic"
                },
                pageSize: {
                  type: "number",
                  description: "Number of templates per page (default: 10)",
                  default: 10
                }
              }
            },
          },
          {
            name: "sendgrid_get_template",
            description: "Get details of a specific email template",
            inputSchema: {
              type: "object",
              properties: {
                templateId: {
                  type: "string",
                  description: "SendGrid template ID",
                }
              },
              required: ["templateId"]
            },
          },
          {
            name: "sendgrid_create_template",
            description: "Create a new email template",
            inputSchema: {
              type: "object",
              properties: {
                name: {
                  type: "string",
                  description: "Template name",
                },
                generation: {
                  type: "string",
                  enum: ["legacy", "dynamic"],
                  description: "Template generation type",
                  default: "dynamic"
                }
              },
              required: ["name"]
            },
          },
          {
            name: "sendgrid_add_contact",
            description: "Add contact to SendGrid marketing lists",
            inputSchema: {
              type: "object",
              properties: {
                email: {
                  type: "string",
                  description: "Contact email address",
                },
                firstName: {
                  type: "string",
                  description: "Contact first name (optional)",
                },
                lastName: {
                  type: "string",
                  description: "Contact last name (optional)",
                },
                customFields: {
                  type: "object",
                  description: "Custom field data (optional)",
                },
                listIds: {
                  type: "array",
                  items: { type: "string" },
                  description: "List IDs to add contact to (optional)",
                }
              },
              required: ["email"]
            },
          },
          {
            name: "sendgrid_list_contacts",
            description: "List contacts from SendGrid marketing",
            inputSchema: {
              type: "object",
              properties: {
                pageSize: {
                  type: "number",
                  description: "Number of contacts per page (default: 10)",
                  default: 10
                },
                pageToken: {
                  type: "string",
                  description: "Page token for pagination (optional)",
                }
              }
            },
          },
          {
            name: "sendgrid_list_marketing_lists",
            description: "List all marketing lists",
            inputSchema: {
              type: "object",
              properties: {
                pageSize: {
                  type: "number",
                  description: "Number of lists per page (default: 10)",
                  default: 10
                }
              }
            },
          },
          {
            name: "sendgrid_create_marketing_list",
            description: "Create a new marketing list",
            inputSchema: {
              type: "object",
              properties: {
                name: {
                  type: "string",
                  description: "List name",
                }
              },
              required: ["name"]
            },
          },
          {
            name: "sendgrid_get_email_stats",
            description: "Get email delivery and engagement statistics",
            inputSchema: {
              type: "object",
              properties: {
                startDate: {
                  type: "string",
                  description: "Start date for stats (YYYY-MM-DD format)",
                },
                endDate: {
                  type: "string",
                  description: "End date for stats (YYYY-MM-DD format)",
                },
                aggregatedBy: {
                  type: "string",
                  enum: ["day", "week", "month"],
                  description: "How to aggregate the stats",
                  default: "day"
                }
              },
              required: ["startDate", "endDate"]
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "sendgrid_send_email":
            return await this.sendEmail(args);
          
          case "sendgrid_send_bulk_email":
            return await this.sendBulkEmail(args);
          
          case "sendgrid_list_templates":
            return await this.listTemplates(args.generations, args.pageSize);
          
          case "sendgrid_get_template":
            return await this.getTemplate(args.templateId);
          
          case "sendgrid_create_template":
            return await this.createTemplate(args.name, args.generation);
          
          case "sendgrid_add_contact":
            return await this.addContact(args);
          
          case "sendgrid_list_contacts":
            return await this.listContacts(args.pageSize, args.pageToken);
          
          case "sendgrid_list_marketing_lists":
            return await this.listMarketingLists(args.pageSize);
          
          case "sendgrid_create_marketing_list":
            return await this.createMarketingList(args.name);
          
          case "sendgrid_get_email_stats":
            return await this.getEmailStats(args.startDate, args.endDate, args.aggregatedBy);
          
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: "text",
              text: `Error: ${error.message}`,
            },
          ],
        };
      }
    });
  }

  async makeSendGridRequest(endpoint, method = 'GET', data = null) {
    if (!this.apiKey) {
      throw new Error("SendGrid API key is required");
    }

    const url = `${this.baseUrl}/${endpoint}`;
    
    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    };

    if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
      options.body = JSON.stringify(data);
    }

    const response = await fetch(url, options);
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`SendGrid API error: ${response.status} ${response.statusText} - ${errorText}`);
    }

    return await response.json();
  }

  async sendEmail(args) {
    const {
      to,
      subject,
      text,
      html,
      from = process.env.SENDGRID_FROM_EMAIL,
      fromName,
      replyTo,
      templateId,
      dynamicTemplateData
    } = args;

    if (!from) {
      throw new Error("From email address is required (set SENDGRID_FROM_EMAIL or provide from parameter)");
    }

    const msg = {
      to,
      from: fromName ? { email: from, name: fromName } : from,
      subject,
      text,
      html,
      replyTo,
      templateId,
      dynamicTemplateData
    };

    // Remove undefined properties
    Object.keys(msg).forEach(key => msg[key] === undefined && delete msg[key]);

    const response = await sgMail.send(msg);

    return {
      content: [
        {
          type: "text",
          text: `Email sent successfully:\\n\\nMessage ID: ${response[0].headers['x-message-id']}\\nTo: ${to}\\nSubject: ${subject}\\nStatus: ${response[0].statusCode}`,
        },
      ],
    };
  }

  async sendBulkEmail(args) {
    const {
      recipients,
      subject,
      text,
      html,
      from = process.env.SENDGRID_FROM_EMAIL,
      fromName,
      templateId
    } = args;

    if (!from) {
      throw new Error("From email address is required");
    }

    const msg = {
      to: recipients,
      from: fromName ? { email: from, name: fromName } : from,
      subject,
      text,
      html,
      templateId,
      isMultiple: true
    };

    // Remove undefined properties
    Object.keys(msg).forEach(key => msg[key] === undefined && delete msg[key]);

    const response = await sgMail.sendMultiple(msg);

    return {
      content: [
        {
          type: "text",
          text: `Bulk email sent successfully:\\n\\nRecipients: ${recipients.length}\\nSubject: ${subject}\\nStatus: ${response[0].statusCode}\\nMessage ID: ${response[0].headers['x-message-id']}`,
        },
      ],
    };
  }

  async listTemplates(generations = 'dynamic', pageSize = 10) {
    const data = await this.makeSendGridRequest(`templates?generations=${generations}&page_size=${pageSize}`);
    const templates = data.templates || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${templates.length} ${generations} templates:\\n\\n` +
                templates.map(template => 
                  `ID: ${template.id}\\nName: ${template.name}\\nGeneration: ${template.generation}\\nUpdated: ${template.updated_at}\\n`
                ).join('\\n'),
        },
      ],
    };
  }

  async getTemplate(templateId) {
    const data = await this.makeSendGridRequest(`templates/${templateId}`);

    return {
      content: [
        {
          type: "text",
          text: `Template Details:\\n\\nID: ${data.id}\\nName: ${data.name}\\nGeneration: ${data.generation}\\nCreated: ${data.created_at}\\nUpdated: ${data.updated_at}\\nVersions: ${data.versions?.length || 0}`,
        },
      ],
    };
  }

  async createTemplate(name, generation = 'dynamic') {
    const templateData = {
      name,
      generation
    };

    const data = await this.makeSendGridRequest('templates', 'POST', templateData);

    return {
      content: [
        {
          type: "text",
          text: `Template created successfully:\\n\\nID: ${data.id}\\nName: ${data.name}\\nGeneration: ${data.generation}\\nCreated: ${data.created_at}`,
        },
      ],
    };
  }

  async addContact(args) {
    const { email, firstName, lastName, customFields, listIds } = args;

    const contactData = {
      contacts: [{
        email,
        first_name: firstName,
        last_name: lastName,
        custom_fields: customFields
      }],
      list_ids: listIds
    };

    // Remove undefined properties
    Object.keys(contactData.contacts[0]).forEach(key => 
      contactData.contacts[0][key] === undefined && delete contactData.contacts[0][key]
    );

    const data = await this.makeSendGridRequest('marketing/contacts', 'PUT', contactData);

    return {
      content: [
        {
          type: "text",
          text: `Contact added successfully:\\n\\nEmail: ${email}\\nJob ID: ${data.job_id}\\nContact Count: ${data.contact_count}\\nNew Count: ${data.new_count}`,
        },
      ],
    };
  }

  async listContacts(pageSize = 10, pageToken) {
    let endpoint = `marketing/contacts?page_size=${pageSize}`;
    if (pageToken) {
      endpoint += `&page_token=${pageToken}`;
    }

    const data = await this.makeSendGridRequest(endpoint);
    const contacts = data.result || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${contacts.length} contacts:\\n\\n` +
              contacts.map(contact => 
                `ID: ${contact.id}\\nEmail: ${contact.email}\\nName: ${contact.first_name || ''} ${contact.last_name || ''}\\nCreated: ${contact.created_at}\\nUpdated: ${contact.updated_at}\\n`
              ).join('\\n') +
              (data._metadata?.next ? `\\nNext Page Token: ${data._metadata.next}` : ''),
        },
      ],
    };
  }

  async listMarketingLists(pageSize = 10) {
    const data = await this.makeSendGridRequest(`marketing/lists?page_size=${pageSize}`);
    const lists = data.result || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${lists.length} marketing lists:\\n\\n` +
              lists.map(list => 
                `ID: ${list.id}\\nName: ${list.name}\\nContact Count: ${list.contact_count}\\nCreated: ${list.created_at}\\n`
              ).join('\\n'),
        },
      ],
    };
  }

  async createMarketingList(name) {
    const listData = { name };
    const data = await this.makeSendGridRequest('marketing/lists', 'POST', listData);

    return {
      content: [
        {
          type: "text",
          text: `Marketing list created successfully:\\n\\nID: ${data.id}\\nName: ${data.name}\\nContact Count: ${data.contact_count}\\nCreated: ${data.created_at}`,
        },
      ],
    };
  }

  async getEmailStats(startDate, endDate, aggregatedBy = 'day') {
    const endpoint = `stats?start_date=${startDate}&end_date=${endDate}&aggregated_by=${aggregatedBy}`;
    const data = await this.makeSendGridRequest(endpoint);
    const stats = data[0]?.stats || [];

    let statsText = `Email Statistics (${startDate} to ${endDate}):\\n\\n`;
    
    stats.forEach(stat => {
      const metrics = stat.metrics;
      statsText += `Date: ${stat.date}\\n`;
      statsText += `  Delivered: ${metrics.delivered || 0}\\n`;
      statsText += `  Opens: ${metrics.opens || 0}\\n`;
      statsText += `  Clicks: ${metrics.clicks || 0}\\n`;
      statsText += `  Bounces: ${metrics.bounces || 0}\\n`;
      statsText += `  Spam Reports: ${metrics.spam_reports || 0}\\n`;
      statsText += `  Unsubscribes: ${metrics.unsubscribes || 0}\\n\\n`;
    });

    return {
      content: [
        {
          type: "text",
          text: statsText,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("SendGrid MCP server running on stdio");
  }
}

const server = new SendGridMCPServer();
server.run().catch(console.error);