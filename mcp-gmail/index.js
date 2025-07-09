#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { google } from 'googleapis';
import dotenv from 'dotenv';

dotenv.config();

class GmailMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "gmail-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupGoogleAuth();
    this.setupToolHandlers();
    
    // Error handling
    this.server.onerror = (error) => console.error("[MCP Error]", error);
    process.on("SIGINT", async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  setupGoogleAuth() {
    const credentials = {
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      redirect_uris: ['urn:ietf:wg:oauth:2.0:oob']
    };

    this.oauth2Client = new google.auth.OAuth2(
      credentials.client_id,
      credentials.client_secret,
      credentials.redirect_uris[0]
    );

    if (process.env.GOOGLE_REFRESH_TOKEN) {
      this.oauth2Client.setCredentials({
        refresh_token: process.env.GOOGLE_REFRESH_TOKEN
      });
    }

    this.gmail = google.gmail({ version: 'v1', auth: this.oauth2Client });
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "gmail_list_messages",
            description: "List Gmail messages with optional filters",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "Gmail search query (e.g., 'is:unread', 'from:example@email.com')",
                },
                maxResults: {
                  type: "number",
                  description: "Maximum number of messages to return (default: 10)",
                  default: 10
                },
                labelIds: {
                  type: "array",
                  items: { type: "string" },
                  description: "Filter by label IDs (optional)",
                }
              }
            },
          },
          {
            name: "gmail_read_message",
            description: "Read a specific Gmail message",
            inputSchema: {
              type: "object",
              properties: {
                messageId: {
                  type: "string",
                  description: "Gmail message ID",
                },
                format: {
                  type: "string",
                  enum: ["full", "metadata", "minimal"],
                  description: "Message format level",
                  default: "full"
                }
              },
              required: ["messageId"]
            },
          },
          {
            name: "gmail_send_message",
            description: "Send an email via Gmail",
            inputSchema: {
              type: "object",
              properties: {
                to: {
                  type: "string",
                  description: "Recipient email address",
                },
                subject: {
                  type: "string",
                  description: "Email subject",
                },
                body: {
                  type: "string",
                  description: "Email body (plain text or HTML)",
                },
                cc: {
                  type: "string",
                  description: "CC recipients (comma-separated)",
                },
                bcc: {
                  type: "string",
                  description: "BCC recipients (comma-separated)",
                },
                isHtml: {
                  type: "boolean",
                  description: "Whether body is HTML format",
                  default: false
                }
              },
              required: ["to", "subject", "body"]
            },
          },
          {
            name: "gmail_reply_message",
            description: "Reply to a Gmail message",
            inputSchema: {
              type: "object",
              properties: {
                messageId: {
                  type: "string",
                  description: "Original message ID to reply to",
                },
                body: {
                  type: "string",
                  description: "Reply body",
                },
                replyAll: {
                  type: "boolean",
                  description: "Whether to reply to all recipients",
                  default: false
                },
                isHtml: {
                  type: "boolean",
                  description: "Whether body is HTML format",
                  default: false
                }
              },
              required: ["messageId", "body"]
            },
          },
          {
            name: "gmail_add_label",
            description: "Add labels to a Gmail message",
            inputSchema: {
              type: "object",
              properties: {
                messageId: {
                  type: "string",
                  description: "Gmail message ID",
                },
                labelIds: {
                  type: "array",
                  items: { type: "string" },
                  description: "Label IDs to add",
                }
              },
              required: ["messageId", "labelIds"]
            },
          },
          {
            name: "gmail_remove_label",
            description: "Remove labels from a Gmail message",
            inputSchema: {
              type: "object",
              properties: {
                messageId: {
                  type: "string",
                  description: "Gmail message ID",
                },
                labelIds: {
                  type: "array",
                  items: { type: "string" },
                  description: "Label IDs to remove",
                }
              },
              required: ["messageId", "labelIds"]
            },
          },
          {
            name: "gmail_list_labels",
            description: "List all Gmail labels",
            inputSchema: {
              type: "object",
              properties: {}
            },
          },
          {
            name: "gmail_create_draft",
            description: "Create a draft email in Gmail",
            inputSchema: {
              type: "object",
              properties: {
                to: {
                  type: "string",
                  description: "Recipient email address",
                },
                subject: {
                  type: "string",
                  description: "Email subject",
                },
                body: {
                  type: "string",
                  description: "Email body",
                },
                cc: {
                  type: "string",
                  description: "CC recipients (comma-separated)",
                },
                bcc: {
                  type: "string",
                  description: "BCC recipients (comma-separated)",
                },
                isHtml: {
                  type: "boolean",
                  description: "Whether body is HTML format",
                  default: false
                }
              },
              required: ["to", "subject", "body"]
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "gmail_list_messages":
            return await this.listMessages(args.query, args.maxResults, args.labelIds);
          
          case "gmail_read_message":
            return await this.readMessage(args.messageId, args.format);
          
          case "gmail_send_message":
            return await this.sendMessage(args.to, args.subject, args.body, args.cc, args.bcc, args.isHtml);
          
          case "gmail_reply_message":
            return await this.replyMessage(args.messageId, args.body, args.replyAll, args.isHtml);
          
          case "gmail_add_label":
            return await this.addLabel(args.messageId, args.labelIds);
          
          case "gmail_remove_label":
            return await this.removeLabel(args.messageId, args.labelIds);
          
          case "gmail_list_labels":
            return await this.listLabels();
          
          case "gmail_create_draft":
            return await this.createDraft(args.to, args.subject, args.body, args.cc, args.bcc, args.isHtml);
          
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

  async listMessages(query, maxResults = 10, labelIds) {
    const params = {
      userId: 'me',
      maxResults: maxResults,
      q: query,
      labelIds: labelIds
    };

    const response = await this.gmail.users.messages.list(params);
    const messages = response.data.messages || [];

    // Get detailed info for each message
    const detailedMessages = await Promise.all(
      messages.slice(0, 5).map(async (msg) => {
        const details = await this.gmail.users.messages.get({
          userId: 'me',
          id: msg.id,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date']
        });
        
        const headers = details.data.payload.headers;
        const from = headers.find(h => h.name === 'From')?.value || 'Unknown';
        const subject = headers.find(h => h.name === 'Subject')?.value || 'No Subject';
        const date = headers.find(h => h.name === 'Date')?.value || 'Unknown';
        
        return {
          id: msg.id,
          from,
          subject,
          date,
          snippet: details.data.snippet
        };
      })
    );

    return {
      content: [
        {
          type: "text",
          text: `Found ${messages.length} messages:\n\n` +
                detailedMessages.map(msg => 
                  `ID: ${msg.id}\nFrom: ${msg.from}\nSubject: ${msg.subject}\nDate: ${msg.date}\nSnippet: ${msg.snippet}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async readMessage(messageId, format = 'full') {
    const response = await this.gmail.users.messages.get({
      userId: 'me',
      id: messageId,
      format: format
    });

    const message = response.data;
    const headers = message.payload.headers || [];
    
    const from = headers.find(h => h.name === 'From')?.value || 'Unknown';
    const to = headers.find(h => h.name === 'To')?.value || 'Unknown';
    const subject = headers.find(h => h.name === 'Subject')?.value || 'No Subject';
    const date = headers.find(h => h.name === 'Date')?.value || 'Unknown';

    let body = '';
    if (format === 'full') {
      body = this.extractMessageBody(message.payload);
    }

    return {
      content: [
        {
          type: "text",
          text: `Message Details:\n\nID: ${messageId}\nFrom: ${from}\nTo: ${to}\nSubject: ${subject}\nDate: ${date}\nSnippet: ${message.snippet}\n\n${body ? `Body:\n${body}` : 'Body not included'}`,
        },
      ],
    };
  }

  extractMessageBody(payload) {
    let body = '';
    
    if (payload.body && payload.body.data) {
      body = Buffer.from(payload.body.data, 'base64').toString();
    } else if (payload.parts) {
      for (const part of payload.parts) {
        if (part.mimeType === 'text/plain' && part.body.data) {
          body = Buffer.from(part.body.data, 'base64').toString();
          break;
        }
      }
    }
    
    return body;
  }

  async sendMessage(to, subject, body, cc, bcc, isHtml = false) {
    const headers = [
      `To: ${to}`,
      `Subject: ${subject}`,
      cc ? `Cc: ${cc}` : null,
      bcc ? `Bcc: ${bcc}` : null,
      `Content-Type: ${isHtml ? 'text/html' : 'text/plain'}; charset=utf-8`
    ].filter(Boolean);

    const email = headers.join('\r\n') + '\r\n\r\n' + body;
    const encodedEmail = Buffer.from(email).toString('base64').replace(/\+/g, '-').replace(/\//g, '_');

    const response = await this.gmail.users.messages.send({
      userId: 'me',
      requestBody: {
        raw: encodedEmail
      }
    });

    return {
      content: [
        {
          type: "text",
          text: `Email sent successfully:\n\nMessage ID: ${response.data.id}\nTo: ${to}\nSubject: ${subject}`,
        },
      ],
    };
  }

  async replyMessage(messageId, body, replyAll = false, isHtml = false) {
    // Get original message to extract reply details
    const originalMessage = await this.gmail.users.messages.get({
      userId: 'me',
      id: messageId,
      format: 'full'
    });

    const headers = originalMessage.data.payload.headers;
    const originalFrom = headers.find(h => h.name === 'From')?.value;
    const originalTo = headers.find(h => h.name === 'To')?.value;
    const originalSubject = headers.find(h => h.name === 'Subject')?.value;
    const messageIdHeader = headers.find(h => h.name === 'Message-ID')?.value;

    let replyTo = originalFrom;
    if (replyAll && originalTo) {
      const allRecipients = [originalFrom, originalTo].join(', ');
      replyTo = allRecipients;
    }

    const replySubject = originalSubject.startsWith('Re:') ? originalSubject : `Re: ${originalSubject}`;

    const replyHeaders = [
      `To: ${replyTo}`,
      `Subject: ${replySubject}`,
      `In-Reply-To: ${messageIdHeader}`,
      `References: ${messageIdHeader}`,
      `Content-Type: ${isHtml ? 'text/html' : 'text/plain'}; charset=utf-8`
    ];

    const email = replyHeaders.join('\r\n') + '\r\n\r\n' + body;
    const encodedEmail = Buffer.from(email).toString('base64').replace(/\+/g, '-').replace(/\//g, '_');

    const response = await this.gmail.users.messages.send({
      userId: 'me',
      requestBody: {
        raw: encodedEmail,
        threadId: originalMessage.data.threadId
      }
    });

    return {
      content: [
        {
          type: "text",
          text: `Reply sent successfully:\n\nMessage ID: ${response.data.id}\nReplying to: ${originalFrom}\nSubject: ${replySubject}\nReply All: ${replyAll}`,
        },
      ],
    };
  }

  async addLabel(messageId, labelIds) {
    await this.gmail.users.messages.modify({
      userId: 'me',
      id: messageId,
      requestBody: {
        addLabelIds: labelIds
      }
    });

    return {
      content: [
        {
          type: "text",
          text: `Labels added successfully:\n\nMessage ID: ${messageId}\nLabels added: ${labelIds.join(', ')}`,
        },
      ],
    };
  }

  async removeLabel(messageId, labelIds) {
    await this.gmail.users.messages.modify({
      userId: 'me',
      id: messageId,
      requestBody: {
        removeLabelIds: labelIds
      }
    });

    return {
      content: [
        {
          type: "text",
          text: `Labels removed successfully:\n\nMessage ID: ${messageId}\nLabels removed: ${labelIds.join(', ')}`,
        },
      ],
    };
  }

  async listLabels() {
    const response = await this.gmail.users.labels.list({
      userId: 'me'
    });

    const labels = response.data.labels || [];

    return {
      content: [
        {
          type: "text",
          text: `Available labels:\n\n` +
                labels.map(label => 
                  `ID: ${label.id}\nName: ${label.name}\nType: ${label.type}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async createDraft(to, subject, body, cc, bcc, isHtml = false) {
    const headers = [
      `To: ${to}`,
      `Subject: ${subject}`,
      cc ? `Cc: ${cc}` : null,
      bcc ? `Bcc: ${bcc}` : null,
      `Content-Type: ${isHtml ? 'text/html' : 'text/plain'}; charset=utf-8`
    ].filter(Boolean);

    const email = headers.join('\r\n') + '\r\n\r\n' + body;
    const encodedEmail = Buffer.from(email).toString('base64').replace(/\+/g, '-').replace(/\//g, '_');

    const response = await this.gmail.users.drafts.create({
      userId: 'me',
      requestBody: {
        message: {
          raw: encodedEmail
        }
      }
    });

    return {
      content: [
        {
          type: "text",
          text: `Draft created successfully:\n\nDraft ID: ${response.data.id}\nTo: ${to}\nSubject: ${subject}`,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Gmail MCP server running on stdio");
  }
}

const server = new GmailMCPServer();
server.run().catch(console.error);