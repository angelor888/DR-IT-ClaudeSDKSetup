#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fetch from 'node-fetch';
import dotenv from 'dotenv';

dotenv.config();

class MatterportMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "matterport-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.baseUrl = 'https://web-api.matterport.com/api/v1';
    this.accessToken = process.env.MATTERPORT_ACCESS_TOKEN;
    
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
            name: "matterport_list_models",
            description: "List Matterport 3D models/tours",
            inputSchema: {
              type: "object",
              properties: {
                limit: {
                  type: "number",
                  description: "Maximum number of models to return (default: 10)",
                  default: 10
                },
                offset: {
                  type: "number",
                  description: "Number of models to skip (pagination)",
                  default: 0
                },
                search: {
                  type: "string",
                  description: "Search query for model names (optional)",
                }
              }
            },
          },
          {
            name: "matterport_get_model",
            description: "Get detailed information about a specific 3D model",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_get_model_details",
            description: "Get comprehensive model details including metadata",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_list_assets",
            description: "List assets (photos, floor plans) for a model",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                },
                assetType: {
                  type: "string",
                  enum: ["photo", "floorplan", "all"],
                  description: "Type of assets to retrieve",
                  default: "all"
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_get_embed_code",
            description: "Get embed code for a 3D model",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                },
                width: {
                  type: "number",
                  description: "Embed width in pixels (default: 853)",
                  default: 853
                },
                height: {
                  type: "number",
                  description: "Embed height in pixels (default: 480)",
                  default: 480
                },
                autoplay: {
                  type: "boolean",
                  description: "Whether to autoplay the tour",
                  default: false
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_get_sharing_link",
            description: "Get sharing link for a 3D model",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_update_model",
            description: "Update model information (name, description, etc.)",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                },
                name: {
                  type: "string",
                  description: "New model name (optional)",
                },
                description: {
                  type: "string",
                  description: "New model description (optional)",
                },
                tags: {
                  type: "array",
                  items: { type: "string" },
                  description: "Model tags (optional)",
                }
              },
              required: ["modelId"]
            },
          },
          {
            name: "matterport_get_analytics",
            description: "Get analytics data for a model",
            inputSchema: {
              type: "object",
              properties: {
                modelId: {
                  type: "string",
                  description: "Matterport model ID",
                },
                startDate: {
                  type: "string",
                  description: "Start date for analytics (YYYY-MM-DD format)",
                },
                endDate: {
                  type: "string",
                  description: "End date for analytics (YYYY-MM-DD format)",
                }
              },
              required: ["modelId"]
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "matterport_list_models":
            return await this.listModels(args.limit, args.offset, args.search);
          
          case "matterport_get_model":
            return await this.getModel(args.modelId);
          
          case "matterport_get_model_details":
            return await this.getModelDetails(args.modelId);
          
          case "matterport_list_assets":
            return await this.listAssets(args.modelId, args.assetType);
          
          case "matterport_get_embed_code":
            return await this.getEmbedCode(args.modelId, args.width, args.height, args.autoplay);
          
          case "matterport_get_sharing_link":
            return await this.getSharingLink(args.modelId);
          
          case "matterport_update_model":
            return await this.updateModel(args.modelId, args.name, args.description, args.tags);
          
          case "matterport_get_analytics":
            return await this.getAnalytics(args.modelId, args.startDate, args.endDate);
          
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

  async makeMatterportRequest(endpoint, method = 'GET', data = null) {
    if (!this.accessToken) {
      throw new Error("Matterport access token is required");
    }

    const url = `${this.baseUrl}/${endpoint}`;
    
    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    };

    if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
      options.body = JSON.stringify(data);
    }

    const response = await fetch(url, options);
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Matterport API error: ${response.status} ${response.statusText} - ${errorText}`);
    }

    return await response.json();
  }

  async listModels(limit = 10, offset = 0, search) {
    let endpoint = `models?limit=${limit}&offset=${offset}`;
    
    if (search) {
      endpoint += `&search=${encodeURIComponent(search)}`;
    }

    const data = await this.makeMatterportRequest(endpoint);
    const models = data.results || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${models.length} models:\n\n` +
                models.map(model => 
                  `ID: ${model.id}\nName: ${model.name || 'Untitled'}\nStatus: ${model.status}\nCreated: ${model.created}\nViews: ${model.view_count || 0}\nSize: ${model.size || 'N/A'} MB\nURL: https://my.matterport.com/show/?m=${model.id}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async getModel(modelId) {
    const data = await this.makeMatterportRequest(`models/${modelId}`);

    return {
      content: [
        {
          type: "text",
          text: `Model Details:\n\nID: ${data.id}\nName: ${data.name || 'Untitled'}\nDescription: ${data.description || 'No description'}\nStatus: ${data.status}\nCreated: ${data.created}\nModified: ${data.modified}\nViews: ${data.view_count || 0}\nSize: ${data.size || 'N/A'} MB\nDuration: ${data.scan_duration || 'N/A'} minutes\nPublic: ${data.is_public ? 'Yes' : 'No'}\nURL: https://my.matterport.com/show/?m=${data.id}`,
        },
      ],
    };
  }

  async getModelDetails(modelId) {
    const data = await this.makeMatterportRequest(`models/${modelId}/details`);

    let detailsText = `Comprehensive Model Details:\n\nID: ${data.id}\nName: ${data.name || 'Untitled'}\nDescription: ${data.description || 'No description'}\nStatus: ${data.status}\nCreated: ${data.created}\nModified: ${data.modified}\n`;

    if (data.metadata) {
      detailsText += `\nMetadata:\n`;
      Object.entries(data.metadata).forEach(([key, value]) => {
        detailsText += `  ${key}: ${value}\n`;
      });
    }

    if (data.location) {
      detailsText += `\nLocation:\nAddress: ${data.location.address || 'N/A'}\nCity: ${data.location.city || 'N/A'}\nCountry: ${data.location.country || 'N/A'}\n`;
    }

    if (data.tags && data.tags.length > 0) {
      detailsText += `\nTags: ${data.tags.join(', ')}\n`;
    }

    return {
      content: [
        {
          type: "text",
          text: detailsText,
        },
      ],
    };
  }

  async listAssets(modelId, assetType = 'all') {
    let endpoint = `models/${modelId}/assets`;
    
    if (assetType !== 'all') {
      endpoint += `?type=${assetType}`;
    }

    const data = await this.makeMatterportRequest(endpoint);
    const assets = data.results || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${assets.length} assets for model ${modelId}:\n\n` +
                assets.map(asset => 
                  `Type: ${asset.type}\nID: ${asset.id}\nName: ${asset.name || 'Untitled'}\nSize: ${asset.width}x${asset.height}\nURL: ${asset.url}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async getEmbedCode(modelId, width = 853, height = 480, autoplay = false) {
    const autoplayParam = autoplay ? '&play=1' : '';
    const embedCode = `<iframe width="${width}" height="${height}" src="https://my.matterport.com/show/?m=${modelId}${autoplayParam}" frameborder="0" allowfullscreen allow="xr-spatial-tracking"></iframe>`;

    return {
      content: [
        {
          type: "text",
          text: `Embed Code for Model ${modelId}:\n\nHTML:\n${embedCode}\n\nDirect Link:\nhttps://my.matterport.com/show/?m=${modelId}${autoplayParam}\n\nDimensions: ${width}x${height}px\nAutoplay: ${autoplay ? 'Enabled' : 'Disabled'}`,
        },
      ],
    };
  }

  async getSharingLink(modelId) {
    const data = await this.makeMatterportRequest(`models/${modelId}/sharing`);

    return {
      content: [
        {
          type: "text",
          text: `Sharing Information for Model ${modelId}:\n\nPublic URL: ${data.public_url || `https://my.matterport.com/show/?m=${modelId}`}\nPrivate URL: ${data.private_url || 'N/A'}\nPassword Protected: ${data.password_protected ? 'Yes' : 'No'}\nSharing Enabled: ${data.sharing_enabled ? 'Yes' : 'No'}`,
        },
      ],
    };
  }

  async updateModel(modelId, name, description, tags) {
    const updateData = {};
    
    if (name) updateData.name = name;
    if (description) updateData.description = description;
    if (tags) updateData.tags = tags;

    const data = await this.makeMatterportRequest(`models/${modelId}`, 'PATCH', updateData);

    return {
      content: [
        {
          type: "text",
          text: `Model updated successfully:\n\nID: ${data.id}\nName: ${data.name}\nDescription: ${data.description || 'No description'}\nTags: ${data.tags ? data.tags.join(', ') : 'No tags'}\nModified: ${data.modified}`,
        },
      ],
    };
  }

  async getAnalytics(modelId, startDate, endDate) {
    let endpoint = `models/${modelId}/analytics`;
    
    const params = [];
    if (startDate) params.push(`start_date=${startDate}`);
    if (endDate) params.push(`end_date=${endDate}`);
    
    if (params.length > 0) {
      endpoint += `?${params.join('&')}`;
    }

    const data = await this.makeMatterportRequest(endpoint);

    return {
      content: [
        {
          type: "text",
          text: `Analytics for Model ${modelId}:\n\nPeriod: ${startDate || 'All time'} to ${endDate || 'Present'}\n\nTotal Views: ${data.total_views || 0}\nUnique Visitors: ${data.unique_visitors || 0}\nAverage Session Duration: ${data.avg_session_duration || 'N/A'} minutes\nTotal Time Viewed: ${data.total_time_viewed || 'N/A'} hours\nBounce Rate: ${data.bounce_rate || 'N/A'}%\nTop Referrers: ${data.top_referrers ? data.top_referrers.join(', ') : 'N/A'}`,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Matterport MCP server running on stdio");
  }
}

const server = new MatterportMCPServer();
server.run().catch(console.error);