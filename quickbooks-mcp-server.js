#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import QuickBooks from 'node-quickbooks';

class QuickBooksMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'quickbooks-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    // QuickBooks configuration
    this.consumerKey = process.env.QUICKBOOKS_CONSUMER_KEY;
    this.consumerSecret = process.env.QUICKBOOKS_CONSUMER_SECRET;
    this.token = process.env.QUICKBOOKS_ACCESS_TOKEN;
    this.tokenSecret = process.env.QUICKBOOKS_ACCESS_TOKEN_SECRET;
    this.realmId = process.env.QUICKBOOKS_REALM_ID;
    this.sandbox = process.env.QUICKBOOKS_SANDBOX === 'true';
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'get_customers',
            description: 'Get list of customers from QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {
                limit: {
                  type: 'number',
                  description: 'Maximum number of customers to return',
                  default: 10,
                },
                search: {
                  type: 'string',
                  description: 'Search term for customer name',
                },
              },
            },
          },
          {
            name: 'create_customer',
            description: 'Create a new customer in QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {
                name: {
                  type: 'string',
                  description: 'Customer name',
                },
                email: {
                  type: 'string',
                  description: 'Customer email address',
                },
                phone: {
                  type: 'string',
                  description: 'Customer phone number',
                },
                address: {
                  type: 'object',
                  properties: {
                    line1: { type: 'string' },
                    city: { type: 'string' },
                    state: { type: 'string' },
                    postalCode: { type: 'string' },
                    country: { type: 'string' },
                  },
                  description: 'Customer address',
                },
              },
              required: ['name'],
            },
          },
          {
            name: 'get_items',
            description: 'Get list of items/products from QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {
                limit: {
                  type: 'number',
                  description: 'Maximum number of items to return',
                  default: 10,
                },
                active: {
                  type: 'boolean',
                  description: 'Filter by active items only',
                  default: true,
                },
              },
            },
          },
          {
            name: 'create_invoice',
            description: 'Create a new invoice in QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {
                customerId: {
                  type: 'string',
                  description: 'Customer ID for the invoice',
                },
                lineItems: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      itemId: { type: 'string' },
                      quantity: { type: 'number' },
                      unitPrice: { type: 'number' },
                      description: { type: 'string' },
                    },
                  },
                  description: 'Array of line items for the invoice',
                },
                dueDate: {
                  type: 'string',
                  description: 'Invoice due date (YYYY-MM-DD)',
                },
              },
              required: ['customerId', 'lineItems'],
            },
          },
          {
            name: 'get_invoices',
            description: 'Get list of invoices from QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {
                customerId: {
                  type: 'string',
                  description: 'Filter by specific customer ID',
                },
                status: {
                  type: 'string',
                  description: 'Filter by invoice status (Draft, Sent, Paid, etc.)',
                },
                limit: {
                  type: 'number',
                  description: 'Maximum number of invoices to return',
                  default: 10,
                },
              },
            },
          },
          {
            name: 'get_company_info',
            description: 'Get company information from QuickBooks',
            inputSchema: {
              type: 'object',
              properties: {},
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case 'get_customers':
          return await this.getCustomers(request.params.arguments);
        case 'create_customer':
          return await this.createCustomer(request.params.arguments);
        case 'get_items':
          return await this.getItems(request.params.arguments);
        case 'create_invoice':
          return await this.createInvoice(request.params.arguments);
        case 'get_invoices':
          return await this.getInvoices(request.params.arguments);
        case 'get_company_info':
          return await this.getCompanyInfo(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  getQuickBooksClient() {
    if (!this.consumerKey || !this.consumerSecret || !this.token || !this.tokenSecret || !this.realmId) {
      throw new Error('QuickBooks OAuth credentials not configured. Set QUICKBOOKS_CONSUMER_KEY, QUICKBOOKS_CONSUMER_SECRET, QUICKBOOKS_ACCESS_TOKEN, QUICKBOOKS_ACCESS_TOKEN_SECRET, and QUICKBOOKS_REALM_ID environment variables.');
    }

    return new QuickBooks(
      this.consumerKey,
      this.consumerSecret,
      this.token,
      this.tokenSecret,
      this.realmId,
      this.sandbox,
      true, // debug
      null, // minor version
      '2.0', // version
      this.sandbox ? QuickBooks.APP_CENTER_BASE : QuickBooks.BASE_URL
    );
  }

  async getCustomers(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      return new Promise((resolve) => {
        qbo.findCustomers({ limit: args.limit || 10 }, (err, customers) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to get customers: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const customerList = customers?.QueryResponse?.Customer || [];
          const filteredCustomers = args.search 
            ? customerList.filter(c => c.Name?.toLowerCase().includes(args.search.toLowerCase()))
            : customerList;

          resolve({
            content: [
              {
                type: 'text',
                text: `Found ${filteredCustomers.length} customers:\n\n${filteredCustomers.map(customer => 
                  `• ${customer.Name} (ID: ${customer.Id})\n  Email: ${customer.PrimaryEmailAddr?.Address || 'No email'}\n  Phone: ${customer.PrimaryPhone?.FreeFormNumber || 'No phone'}`
                ).join('\n\n')}`,
              },
            ],
          });
        });
      });
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get customers: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async createCustomer(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      const customer = {
        Name: args.name,
        CompanyName: args.name,
      };

      if (args.email) {
        customer.PrimaryEmailAddr = { Address: args.email };
      }

      if (args.phone) {
        customer.PrimaryPhone = { FreeFormNumber: args.phone };
      }

      if (args.address) {
        customer.BillAddr = {
          Line1: args.address.line1,
          City: args.address.city,
          CountrySubDivisionCode: args.address.state,
          PostalCode: args.address.postalCode,
          Country: args.address.country || 'US',
        };
      }

      return new Promise((resolve) => {
        qbo.createCustomer(customer, (err, result) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to create customer: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const newCustomer = result.QueryResponse.Customer[0];
          resolve({
            content: [
              {
                type: 'text',
                text: `Customer created successfully: ${newCustomer.Name} (ID: ${newCustomer.Id})`,
              },
            ],
          });
        });
      });
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to create customer: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getItems(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      return new Promise((resolve) => {
        qbo.findItems({ limit: args.limit || 10 }, (err, items) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to get items: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const itemList = items?.QueryResponse?.Item || [];
          const filteredItems = args.active !== false 
            ? itemList.filter(item => item.Active === 'true')
            : itemList;

          resolve({
            content: [
              {
                type: 'text',
                text: `Found ${filteredItems.length} items:\n\n${filteredItems.map(item => 
                  `• ${item.Name} (ID: ${item.Id})\n  Type: ${item.Type}\n  Price: $${item.UnitPrice || '0.00'}\n  Active: ${item.Active}`
                ).join('\n\n')}`,
              },
            ],
          });
        });
      });
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get items: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async createInvoice(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      const invoice = {
        CustomerRef: { value: args.customerId },
        Line: args.lineItems.map((item, index) => ({
          Id: (index + 1).toString(),
          LineNum: index + 1,
          Amount: (item.quantity || 1) * (item.unitPrice || 0),
          DetailType: 'SalesItemLineDetail',
          SalesItemLineDetail: {
            ItemRef: { value: item.itemId || '1' },
            Qty: item.quantity || 1,
            UnitPrice: item.unitPrice || 0,
          },
          Description: item.description,
        })),
      };

      if (args.dueDate) {
        invoice.DueDate = args.dueDate;
      }

      return new Promise((resolve) => {
        qbo.createInvoice(invoice, (err, result) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to create invoice: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const newInvoice = result.QueryResponse.Invoice[0];
          resolve({
            content: [
              {
                type: 'text',
                text: `Invoice created successfully: #${newInvoice.DocNumber} (ID: ${newInvoice.Id})\nTotal: $${newInvoice.TotalAmt}`,
              },
            ],
          });
        });
      });
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to create invoice: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getInvoices(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      return new Promise((resolve) => {
        qbo.findInvoices({ limit: args.limit || 10 }, (err, invoices) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to get invoices: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const invoiceList = invoices?.QueryResponse?.Invoice || [];
          let filteredInvoices = invoiceList;

          if (args.customerId) {
            filteredInvoices = filteredInvoices.filter(inv => inv.CustomerRef?.value === args.customerId);
          }

          if (args.status) {
            filteredInvoices = filteredInvoices.filter(inv => inv.EmailStatus === args.status);
          }

          resolve({
            content: [
              {
                type: 'text',
                text: `Found ${filteredInvoices.length} invoices:\n\n${filteredInvoices.map(invoice => 
                  `• #${invoice.DocNumber || invoice.Id} - $${invoice.TotalAmt}\n  Customer: ${invoice.CustomerRef?.name || 'Unknown'}\n  Date: ${invoice.TxnDate}\n  Due: ${invoice.DueDate || 'No due date'}\n  Status: ${invoice.EmailStatus || 'Unknown'}`
                ).join('\n\n')}`,
              },
            ],
          });
        });
      });
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

  async getCompanyInfo(args) {
    try {
      const qbo = this.getQuickBooksClient();
      
      return new Promise((resolve) => {
        qbo.getCompanyInfo(this.realmId, (err, companyInfo) => {
          if (err) {
            resolve({
              content: [
                {
                  type: 'text',
                  text: `Failed to get company info: ${err.message}`,
                },
              ],
              isError: true,
            });
            return;
          }

          const company = companyInfo?.QueryResponse?.CompanyInfo?.[0];
          resolve({
            content: [
              {
                type: 'text',
                text: `Company Information:\n\n` +
                  `Name: ${company?.CompanyName || 'Unknown'}\n` +
                  `Legal Name: ${company?.LegalName || 'Unknown'}\n` +
                  `Address: ${company?.CompanyAddr?.Line1 || ''}, ${company?.CompanyAddr?.City || ''}, ${company?.CompanyAddr?.CountrySubDivisionCode || ''}\n` +
                  `Phone: ${company?.PrimaryPhone?.FreeFormNumber || 'No phone'}\n` +
                  `Email: ${company?.Email?.Address || 'No email'}\n` +
                  `Website: ${company?.WebAddr?.URI || 'No website'}\n` +
                  `Fiscal Year Start: ${company?.FiscalYearStartMonth || 'Unknown'}\n` +
                  `Country: ${company?.Country || 'Unknown'}`,
              },
            ],
          });
        });
      });
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to get company info: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('QuickBooks MCP server running on stdio');
  }
}

const server = new QuickBooksMCPServer();
server.run().catch(console.error);