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

class GoogleDriveMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "google-drive-mcp-server",
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

    this.drive = google.drive({ version: 'v3', auth: this.oauth2Client });
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "drive_list_files",
            description: "List files in Google Drive",
            inputSchema: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "Search query (optional)",
                },
                limit: {
                  type: "number",
                  description: "Maximum number of files to return (default: 10)",
                  default: 10
                },
                folderId: {
                  type: "string",
                  description: "Folder ID to search in (optional)",
                }
              }
            },
          },
          {
            name: "drive_search_files",
            description: "Search files in Google Drive by name or content",
            inputSchema: {
              type: "object",
              properties: {
                searchTerm: {
                  type: "string",
                  description: "Term to search for in file names",
                },
                mimeType: {
                  type: "string",
                  description: "File type to filter by (e.g., application/pdf)",
                },
                limit: {
                  type: "number",
                  description: "Maximum number of results (default: 20)",
                  default: 20
                }
              },
              required: ["searchTerm"]
            },
          },
          {
            name: "drive_get_file",
            description: "Get file metadata and content from Google Drive",
            inputSchema: {
              type: "object",
              properties: {
                fileId: {
                  type: "string",
                  description: "Google Drive file ID",
                },
                includeContent: {
                  type: "boolean",
                  description: "Whether to include file content (text files only)",
                  default: false
                }
              },
              required: ["fileId"]
            },
          },
          {
            name: "drive_upload_file",
            description: "Upload a file to Google Drive",
            inputSchema: {
              type: "object",
              properties: {
                name: {
                  type: "string",
                  description: "File name",
                },
                content: {
                  type: "string",
                  description: "File content (text files)",
                },
                mimeType: {
                  type: "string",
                  description: "MIME type (default: text/plain)",
                  default: "text/plain"
                },
                folderId: {
                  type: "string",
                  description: "Parent folder ID (optional)",
                }
              },
              required: ["name", "content"]
            },
          },
          {
            name: "drive_create_folder",
            description: "Create a new folder in Google Drive",
            inputSchema: {
              type: "object",
              properties: {
                name: {
                  type: "string",
                  description: "Folder name",
                },
                parentId: {
                  type: "string",
                  description: "Parent folder ID (optional)",
                }
              },
              required: ["name"]
            },
          },
          {
            name: "drive_share_file",
            description: "Share a file or folder with specified permissions",
            inputSchema: {
              type: "object",
              properties: {
                fileId: {
                  type: "string",
                  description: "File or folder ID to share",
                },
                email: {
                  type: "string",
                  description: "Email address to share with",
                },
                role: {
                  type: "string",
                  enum: ["reader", "commenter", "writer", "owner"],
                  description: "Permission role",
                  default: "reader"
                },
                type: {
                  type: "string",
                  enum: ["user", "group", "domain", "anyone"],
                  description: "Permission type",
                  default: "user"
                }
              },
              required: ["fileId", "email"]
            },
          },
          {
            name: "drive_delete_file",
            description: "Delete a file or folder from Google Drive",
            inputSchema: {
              type: "object",
              properties: {
                fileId: {
                  type: "string",
                  description: "File or folder ID to delete",
                }
              },
              required: ["fileId"]
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "drive_list_files":
            return await this.listFiles(args.query, args.limit, args.folderId);
          
          case "drive_search_files":
            return await this.searchFiles(args.searchTerm, args.mimeType, args.limit);
          
          case "drive_get_file":
            return await this.getFile(args.fileId, args.includeContent);
          
          case "drive_upload_file":
            return await this.uploadFile(args.name, args.content, args.mimeType, args.folderId);
          
          case "drive_create_folder":
            return await this.createFolder(args.name, args.parentId);
          
          case "drive_share_file":
            return await this.shareFile(args.fileId, args.email, args.role, args.type);
          
          case "drive_delete_file":
            return await this.deleteFile(args.fileId);
          
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

  async listFiles(query, limit = 10, folderId) {
    let searchQuery = '';
    
    if (folderId) {
      searchQuery = `'${folderId}' in parents`;
    }
    
    if (query) {
      searchQuery += searchQuery ? ` and ${query}` : query;
    }

    const response = await this.drive.files.list({
      q: searchQuery || undefined,
      pageSize: limit,
      fields: 'files(id, name, mimeType, size, modifiedTime, createdTime, owners)',
    });

    const files = response.data.files || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${files.length} files:\n\n` +
                files.map(file => 
                  `ID: ${file.id}\nName: ${file.name}\nType: ${file.mimeType}\nSize: ${file.size || 'N/A'} bytes\nModified: ${file.modifiedTime}\nOwner: ${file.owners?.[0]?.displayName || 'Unknown'}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async searchFiles(searchTerm, mimeType, limit = 20) {
    let query = `name contains '${searchTerm}'`;
    
    if (mimeType) {
      query += ` and mimeType='${mimeType}'`;
    }

    const response = await this.drive.files.list({
      q: query,
      pageSize: limit,
      fields: 'files(id, name, mimeType, size, modifiedTime, webViewLink)',
    });

    const files = response.data.files || [];

    return {
      content: [
        {
          type: "text",
          text: `Search results for "${searchTerm}":\n\nFound ${files.length} files:\n\n` +
                files.map(file => 
                  `Name: ${file.name}\nID: ${file.id}\nType: ${file.mimeType}\nSize: ${file.size || 'N/A'} bytes\nLink: ${file.webViewLink}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async getFile(fileId, includeContent = false) {
    const response = await this.drive.files.get({
      fileId: fileId,
      fields: 'id, name, mimeType, size, modifiedTime, createdTime, description, webViewLink, webContentLink',
    });

    const file = response.data;
    let content = '';

    if (includeContent && file.mimeType.startsWith('text/')) {
      try {
        const contentResponse = await this.drive.files.get({
          fileId: fileId,
          alt: 'media',
        });
        content = `\n\nFile Content:\n${contentResponse.data}`;
      } catch (error) {
        content = `\n\nContent could not be retrieved: ${error.message}`;
      }
    }

    return {
      content: [
        {
          type: "text",
          text: `File Details:\n\nName: ${file.name}\nID: ${file.id}\nType: ${file.mimeType}\nSize: ${file.size || 'N/A'} bytes\nCreated: ${file.createdTime}\nModified: ${file.modifiedTime}\nDescription: ${file.description || 'None'}\nView Link: ${file.webViewLink}\nDownload Link: ${file.webContentLink || 'N/A'}${content}`,
        },
      ],
    };
  }

  async uploadFile(name, content, mimeType = 'text/plain', folderId) {
    const fileMetadata = {
      name: name,
      parents: folderId ? [folderId] : undefined,
    };

    const media = {
      mimeType: mimeType,
      body: content,
    };

    const response = await this.drive.files.create({
      requestBody: fileMetadata,
      media: media,
      fields: 'id, name, webViewLink',
    });

    const file = response.data;

    return {
      content: [
        {
          type: "text",
          text: `File uploaded successfully:\n\nName: ${file.name}\nID: ${file.id}\nView Link: ${file.webViewLink}`,
        },
      ],
    };
  }

  async createFolder(name, parentId) {
    const fileMetadata = {
      name: name,
      mimeType: 'application/vnd.google-apps.folder',
      parents: parentId ? [parentId] : undefined,
    };

    const response = await this.drive.files.create({
      requestBody: fileMetadata,
      fields: 'id, name, webViewLink',
    });

    const folder = response.data;

    return {
      content: [
        {
          type: "text",
          text: `Folder created successfully:\n\nName: ${folder.name}\nID: ${folder.id}\nView Link: ${folder.webViewLink}`,
        },
      ],
    };
  }

  async shareFile(fileId, email, role = 'reader', type = 'user') {
    const permission = {
      type: type,
      role: role,
      emailAddress: email,
    };

    await this.drive.permissions.create({
      fileId: fileId,
      requestBody: permission,
      sendNotificationEmail: true,
    });

    return {
      content: [
        {
          type: "text",
          text: `File shared successfully:\n\nFile ID: ${fileId}\nShared with: ${email}\nRole: ${role}\nType: ${type}`,
        },
      ],
    };
  }

  async deleteFile(fileId) {
    await this.drive.files.delete({
      fileId: fileId,
    });

    return {
      content: [
        {
          type: "text",
          text: `File deleted successfully:\n\nFile ID: ${fileId}`,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Google Drive MCP server running on stdio");
  }
}

const server = new GoogleDriveMCPServer();
server.run().catch(console.error);