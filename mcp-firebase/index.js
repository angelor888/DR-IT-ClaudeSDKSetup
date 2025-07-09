#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

class FirebaseMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "firebase-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.initializeFirebase();
    this.setupToolHandlers();
    
    // Error handling
    this.server.onerror = (error) => console.error("[MCP Error]", error);
    process.on("SIGINT", async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  initializeFirebase() {
    try {
      if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          databaseURL: process.env.FIREBASE_DATABASE_URL
        });
      } else {
        console.error("Firebase service account key not provided");
      }
    } catch (error) {
      console.error("Firebase initialization error:", error.message);
    }
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: "firestore_read",
            description: "Read document from Firestore collection",
            inputSchema: {
              type: "object",
              properties: {
                collection: {
                  type: "string",
                  description: "Firestore collection name",
                },
                documentId: {
                  type: "string",
                  description: "Document ID to read",
                }
              },
              required: ["collection", "documentId"]
            },
          },
          {
            name: "firestore_write",
            description: "Write document to Firestore collection",
            inputSchema: {
              type: "object",
              properties: {
                collection: {
                  type: "string",
                  description: "Firestore collection name",
                },
                documentId: {
                  type: "string",
                  description: "Document ID (optional, will generate if empty)",
                },
                data: {
                  type: "object",
                  description: "Document data to write",
                }
              },
              required: ["collection", "data"]
            },
          },
          {
            name: "firestore_query",
            description: "Query Firestore collection with filters",
            inputSchema: {
              type: "object",
              properties: {
                collection: {
                  type: "string",
                  description: "Firestore collection name",
                },
                field: {
                  type: "string",
                  description: "Field to filter on",
                },
                operator: {
                  type: "string",
                  description: "Query operator (==, !=, <, <=, >, >=)",
                },
                value: {
                  type: "string",
                  description: "Value to compare against",
                },
                limit: {
                  type: "number",
                  description: "Maximum number of results (default: 10)",
                  default: 10
                }
              },
              required: ["collection"]
            },
          },
          {
            name: "firestore_delete",
            description: "Delete document from Firestore collection",
            inputSchema: {
              type: "object",
              properties: {
                collection: {
                  type: "string",
                  description: "Firestore collection name",
                },
                documentId: {
                  type: "string",
                  description: "Document ID to delete",
                }
              },
              required: ["collection", "documentId"]
            },
          },
          {
            name: "auth_create_user",
            description: "Create a new Firebase user",
            inputSchema: {
              type: "object",
              properties: {
                email: {
                  type: "string",
                  description: "User email address",
                },
                password: {
                  type: "string",
                  description: "User password",
                },
                displayName: {
                  type: "string",
                  description: "User display name (optional)",
                }
              },
              required: ["email", "password"]
            },
          },
          {
            name: "auth_get_user",
            description: "Get Firebase user by email or UID",
            inputSchema: {
              type: "object",
              properties: {
                identifier: {
                  type: "string",
                  description: "User email or UID",
                },
                type: {
                  type: "string",
                  enum: ["email", "uid"],
                  description: "Type of identifier",
                  default: "email"
                }
              },
              required: ["identifier"]
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "firestore_read":
            return await this.firestoreRead(args.collection, args.documentId);
          
          case "firestore_write":
            return await this.firestoreWrite(args.collection, args.documentId, args.data);
          
          case "firestore_query":
            return await this.firestoreQuery(args.collection, args.field, args.operator, args.value, args.limit);
          
          case "firestore_delete":
            return await this.firestoreDelete(args.collection, args.documentId);
          
          case "auth_create_user":
            return await this.authCreateUser(args.email, args.password, args.displayName);
          
          case "auth_get_user":
            return await this.authGetUser(args.identifier, args.type);
          
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

  async firestoreRead(collection, documentId) {
    const db = admin.firestore();
    const doc = await db.collection(collection).doc(documentId).get();
    
    if (!doc.exists) {
      throw new Error(`Document ${documentId} not found in collection ${collection}`);
    }

    return {
      content: [
        {
          type: "text",
          text: `Document retrieved successfully:\n\nCollection: ${collection}\nDocument ID: ${documentId}\nData:\n${JSON.stringify(doc.data(), null, 2)}`,
        },
      ],
    };
  }

  async firestoreWrite(collection, documentId, data) {
    const db = admin.firestore();
    const collectionRef = db.collection(collection);
    
    let docRef;
    if (documentId) {
      docRef = collectionRef.doc(documentId);
      await docRef.set(data);
    } else {
      docRef = await collectionRef.add(data);
      documentId = docRef.id;
    }

    return {
      content: [
        {
          type: "text",
          text: `Document written successfully:\n\nCollection: ${collection}\nDocument ID: ${documentId}\nData written:\n${JSON.stringify(data, null, 2)}`,
        },
      ],
    };
  }

  async firestoreQuery(collection, field, operator, value, limit = 10) {
    const db = admin.firestore();
    let query = db.collection(collection);
    
    if (field && operator && value) {
      query = query.where(field, operator, value);
    }
    
    const snapshot = await query.limit(limit).get();
    
    const results = [];
    snapshot.forEach(doc => {
      results.push({
        id: doc.id,
        data: doc.data()
      });
    });

    return {
      content: [
        {
          type: "text",
          text: `Query results:\n\nCollection: ${collection}\nFilter: ${field ? `${field} ${operator} ${value}` : 'No filter'}\nResults found: ${results.length}\n\n${JSON.stringify(results, null, 2)}`,
        },
      ],
    };
  }

  async firestoreDelete(collection, documentId) {
    const db = admin.firestore();
    await db.collection(collection).doc(documentId).delete();

    return {
      content: [
        {
          type: "text",
          text: `Document deleted successfully:\n\nCollection: ${collection}\nDocument ID: ${documentId}`,
        },
      ],
    };
  }

  async authCreateUser(email, password, displayName) {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName
    });

    return {
      content: [
        {
          type: "text",
          text: `User created successfully:\n\nUID: ${userRecord.uid}\nEmail: ${userRecord.email}\nDisplay Name: ${userRecord.displayName || 'Not set'}\nCreated: ${userRecord.metadata.creationTime}`,
        },
      ],
    };
  }

  async authGetUser(identifier, type = 'email') {
    let userRecord;
    
    if (type === 'email') {
      userRecord = await admin.auth().getUserByEmail(identifier);
    } else {
      userRecord = await admin.auth().getUser(identifier);
    }

    return {
      content: [
        {
          type: "text",
          text: `User found:\n\nUID: ${userRecord.uid}\nEmail: ${userRecord.email}\nDisplay Name: ${userRecord.displayName || 'Not set'}\nEmail Verified: ${userRecord.emailVerified}\nDisabled: ${userRecord.disabled}\nLast Sign In: ${userRecord.metadata.lastSignInTime || 'Never'}\nCreated: ${userRecord.metadata.creationTime}`,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Firebase MCP server running on stdio");
  }
}

const server = new FirebaseMCPServer();
server.run().catch(console.error);