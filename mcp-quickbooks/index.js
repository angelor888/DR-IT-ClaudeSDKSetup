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

class QuickBooksMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: "quickbooks-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.baseUrl = process.env.QB_SANDBOX === 'true' 
      ? 'https://sandbox-quickbooks.api.intuit.com'
      : 'https://quickbooks.api.intuit.com';
    
    this.accessToken = process.env.QB_ACCESS_TOKEN;
    this.companyId = process.env.QB_COMPANY_ID;
    
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
            name: "qb_get_company_info",
            description: "Get QuickBooks company information",
            inputSchema: {
              type: "object",
              properties: {}
            },
          },
          {
            name: "qb_get_profit_loss",
            description: "Get Profit & Loss report",
            inputSchema: {
              type: "object",
              properties: {
                startDate: {
                  type: "string",
                  description: "Start date (YYYY-MM-DD format)",
                },
                endDate: {
                  type: "string",
                  description: "End date (YYYY-MM-DD format)",
                },
                summarizeColumnBy: {
                  type: "string",
                  enum: ["Month", "Quarter", "Year", "Week"],
                  description: "How to summarize columns",
                  default: "Month"
                }
              },
              required: ["startDate", "endDate"]
            },
          },
          {
            name: "qb_get_balance_sheet",
            description: "Get Balance Sheet report",
            inputSchema: {
              type: "object",
              properties: {
                asOfDate: {
                  type: "string",
                  description: "As of date (YYYY-MM-DD format)",
                },
                summarizeColumnBy: {
                  type: "string",
                  enum: ["Month", "Quarter", "Year"],
                  description: "How to summarize columns",
                  default: "Month"
                }
              },
              required: ["asOfDate"]
            },
          },
          {
            name: "qb_list_customers",
            description: "List customers",
            inputSchema: {
              type: "object",
              properties: {
                maxResults: {
                  type: "number",
                  description: "Maximum number of results (default: 20)",
                  default: 20
                },
                active: {
                  type: "boolean",
                  description: "Filter by active status",
                  default: true
                }
              }
            },
          },
          {
            name: "qb_create_customer",
            description: "Create a new customer",
            inputSchema: {
              type: "object",
              properties: {
                name: {
                  type: "string",
                  description: "Customer name",
                },
                companyName: {
                  type: "string",
                  description: "Company name (optional)",
                },
                email: {
                  type: "string",
                  description: "Email address (optional)",
                },
                phone: {
                  type: "string",
                  description: "Phone number (optional)",
                }
              },
              required: ["name"]
            },
          },
          {
            name: "qb_list_items",
            description: "List items/products/services",
            inputSchema: {
              type: "object",
              properties: {
                maxResults: {
                  type: "number",
                  description: "Maximum number of results (default: 20)",
                  default: 20
                },
                type: {
                  type: "string",
                  enum: ["Inventory", "NonInventory", "Service"],
                  description: "Filter by item type (optional)",
                }
              }
            },
          },
          {
            name: "qb_create_invoice",
            description: "Create a new invoice",
            inputSchema: {
              type: "object",
              properties: {
                customerId: {
                  type: "string",
                  description: "Customer ID",
                },
                lineItems: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      itemId: {
                        type: "string",
                        description: "Item/Service ID",
                      },
                      quantity: {
                        type: "number",
                        description: "Quantity",
                      },
                      unitPrice: {
                        type: "number",
                        description: "Unit price",
                      },
                      description: {
                        type: "string",
                        description: "Line item description (optional)",
                      }
                    },
                    required: ["itemId", "quantity", "unitPrice"]
                  },
                  description: "Invoice line items",
                },
                dueDate: {
                  type: "string",
                  description: "Due date (YYYY-MM-DD format, optional)",
                }
              },
              required: ["customerId", "lineItems"]
            },
          },
          {
            name: "qb_create_bill",
            description: "Create a new bill (vendor bill)",
            inputSchema: {
              type: "object",
              properties: {
                vendorId: {
                  type: "string",
                  description: "Vendor ID",
                },
                amount: {
                  type: "number",
                  description: "Bill amount",
                },
                dueDate: {
                  type: "string",
                  description: "Due date (YYYY-MM-DD format, optional)",
                },
                memo: {
                  type: "string",
                  description: "Bill memo/description (optional)",
                }
              },
              required: ["vendorId", "amount"]
            },
          },
          {
            name: "qb_list_payments",
            description: "List payments received",
            inputSchema: {
              type: "object",
              properties: {
                maxResults: {
                  type: "number",
                  description: "Maximum number of results (default: 20)",
                  default: 20
                },
                startDate: {
                  type: "string",
                  description: "Filter payments from this date (YYYY-MM-DD)",
                },
                endDate: {
                  type: "string",
                  description: "Filter payments to this date (YYYY-MM-DD)",
                }
              }
            },
          }
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "qb_get_company_info":
            return await this.getCompanyInfo();
          
          case "qb_get_profit_loss":
            return await this.getProfitLoss(args.startDate, args.endDate, args.summarizeColumnBy);
          
          case "qb_get_balance_sheet":
            return await this.getBalanceSheet(args.asOfDate, args.summarizeColumnBy);
          
          case "qb_list_customers":
            return await this.listCustomers(args.maxResults, args.active);
          
          case "qb_create_customer":
            return await this.createCustomer(args.name, args.companyName, args.email, args.phone);
          
          case "qb_list_items":
            return await this.listItems(args.maxResults, args.type);
          
          case "qb_create_invoice":
            return await this.createInvoice(args.customerId, args.lineItems, args.dueDate);
          
          case "qb_create_bill":
            return await this.createBill(args.vendorId, args.amount, args.dueDate, args.memo);
          
          case "qb_list_payments":
            return await this.listPayments(args.maxResults, args.startDate, args.endDate);
          
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

  async makeQuickBooksRequest(endpoint, method = 'GET', data = null) {
    if (!this.accessToken || !this.companyId) {
      throw new Error("QuickBooks access token and company ID are required");
    }

    const url = `${this.baseUrl}/v3/company/${this.companyId}/${endpoint}`;
    
    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    };

    if (data && (method === 'POST' || method === 'PUT')) {
      options.body = JSON.stringify(data);
    }

    const response = await fetch(url, options);
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`QuickBooks API error: ${response.status} ${response.statusText} - ${errorText}`);
    }

    return await response.json();
  }

  async getCompanyInfo() {
    const data = await this.makeQuickBooksRequest('companyinfo/1');
    const companyInfo = data.QueryResponse.CompanyInfo[0];

    return {
      content: [
        {
          type: "text",
          text: `Company Information:\n\nName: ${companyInfo.CompanyName}\nLegal Name: ${companyInfo.LegalName || 'N/A'}\nAddress: ${companyInfo.CompanyAddr?.Line1 || 'N/A'}\nEmail: ${companyInfo.Email?.Address || 'N/A'}\nPhone: ${companyInfo.PrimaryPhone?.FreeFormNumber || 'N/A'}\nFiscal Year Start: ${companyInfo.FiscalYearStartMonth || 'N/A'}\nCountry: ${companyInfo.Country || 'N/A'}`,
        },
      ],
    };
  }

  async getProfitLoss(startDate, endDate, summarizeColumnBy = 'Month') {
    const endpoint = `reports/ProfitAndLoss?start_date=${startDate}&end_date=${endDate}&summarize_column_by=${summarizeColumnBy}`;
    const data = await this.makeQuickBooksRequest(endpoint);
    
    const report = data.QueryResponse.Report[0];
    const header = report.Header;
    const rows = report.Rows || [];

    let reportText = `Profit & Loss Report\n\nPeriod: ${startDate} to ${endDate}\nCompany: ${header.Customer || 'N/A'}\n\n`;

    // Process report rows
    rows.forEach(row => {
      if (row.Header && row.Header.Name) {
        reportText += `\n${row.Header.Name}:\n`;
        if (row.Rows) {
          row.Rows.forEach(subRow => {
            if (subRow.ColData) {
              const name = subRow.ColData[0]?.value || '';
              const amount = subRow.ColData[1]?.value || '0.00';
              if (name) {
                reportText += `  ${name}: $${amount}\n`;
              }
            }
          });
        }
      }
    });

    return {
      content: [
        {
          type: "text",
          text: reportText,
        },
      ],
    };
  }

  async getBalanceSheet(asOfDate, summarizeColumnBy = 'Month') {
    const endpoint = `reports/BalanceSheet?as_of_date=${asOfDate}&summarize_column_by=${summarizeColumnBy}`;
    const data = await this.makeQuickBooksRequest(endpoint);
    
    const report = data.QueryResponse.Report[0];
    const header = report.Header;
    const rows = report.Rows || [];

    let reportText = `Balance Sheet\n\nAs of: ${asOfDate}\nCompany: ${header.Customer || 'N/A'}\n\n`;

    // Process report rows
    rows.forEach(row => {
      if (row.Header && row.Header.Name) {
        reportText += `\n${row.Header.Name}:\n`;
        if (row.Rows) {
          row.Rows.forEach(subRow => {
            if (subRow.ColData) {
              const name = subRow.ColData[0]?.value || '';
              const amount = subRow.ColData[1]?.value || '0.00';
              if (name) {
                reportText += `  ${name}: $${amount}\n`;
              }
            }
          });
        }
      }
    });

    return {
      content: [
        {
          type: "text",
          text: reportText,
        },
      ],
    };
  }

  async listCustomers(maxResults = 20, active = true) {
    let query = `SELECT * FROM Customer`;
    if (active) {
      query += ` WHERE Active = true`;
    }
    query += ` MAXRESULTS ${maxResults}`;

    const data = await this.makeQuickBooksRequest(`query?query=${encodeURIComponent(query)}`);
    const customers = data.QueryResponse.Customer || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${customers.length} customers:\n\n` +
                customers.map(customer => 
                  `ID: ${customer.Id}\nName: ${customer.Name}\nCompany: ${customer.CompanyName || 'N/A'}\nEmail: ${customer.PrimaryEmailAddr?.Address || 'N/A'}\nPhone: ${customer.PrimaryPhone?.FreeFormNumber || 'N/A'}\nActive: ${customer.Active}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async createCustomer(name, companyName, email, phone) {
    const customerData = {
      Customer: {
        Name: name,
        CompanyName: companyName,
        PrimaryEmailAddr: email ? { Address: email } : undefined,
        PrimaryPhone: phone ? { FreeFormNumber: phone } : undefined
      }
    };

    const data = await this.makeQuickBooksRequest('customer', 'POST', customerData);
    const customer = data.QueryResponse.Customer[0];

    return {
      content: [
        {
          type: "text",
          text: `Customer created successfully:\n\nID: ${customer.Id}\nName: ${customer.Name}\nCompany: ${customer.CompanyName || 'N/A'}\nEmail: ${customer.PrimaryEmailAddr?.Address || 'N/A'}\nPhone: ${customer.PrimaryPhone?.FreeFormNumber || 'N/A'}`,
        },
      ],
    };
  }

  async listItems(maxResults = 20, type) {
    let query = `SELECT * FROM Item`;
    if (type) {
      query += ` WHERE Type = '${type}'`;
    }
    query += ` MAXRESULTS ${maxResults}`;

    const data = await this.makeQuickBooksRequest(`query?query=${encodeURIComponent(query)}`);
    const items = data.QueryResponse.Item || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${items.length} items:\n\n` +
                items.map(item => 
                  `ID: ${item.Id}\nName: ${item.Name}\nType: ${item.Type}\nDescription: ${item.Description || 'N/A'}\nUnit Price: $${item.UnitPrice || 'N/A'}\nActive: ${item.Active}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async createInvoice(customerId, lineItems, dueDate) {
    const invoiceData = {
      Invoice: {
        CustomerRef: { value: customerId },
        Line: lineItems.map((item, index) => ({
          Id: (index + 1).toString(),
          LineNum: index + 1,
          Amount: item.quantity * item.unitPrice,
          DetailType: "SalesItemLineDetail",
          SalesItemLineDetail: {
            ItemRef: { value: item.itemId },
            Qty: item.quantity,
            UnitPrice: item.unitPrice,
            Description: item.description
          }
        })),
        DueDate: dueDate
      }
    };

    const data = await this.makeQuickBooksRequest('invoice', 'POST', invoiceData);
    const invoice = data.QueryResponse.Invoice[0];

    return {
      content: [
        {
          type: "text",
          text: `Invoice created successfully:\n\nInvoice ID: ${invoice.Id}\nInvoice Number: ${invoice.DocNumber}\nCustomer: ${invoice.CustomerRef.name}\nTotal Amount: $${invoice.TotalAmt}\nDue Date: ${invoice.DueDate || 'Not set'}`,
        },
      ],
    };
  }

  async createBill(vendorId, amount, dueDate, memo) {
    const billData = {
      Bill: {
        VendorRef: { value: vendorId },
        Line: [{
          Amount: amount,
          DetailType: "AccountBasedExpenseLineDetail",
          AccountBasedExpenseLineDetail: {
            AccountRef: { value: "1" } // You may need to adjust this account reference
          }
        }],
        TotalAmt: amount,
        DueDate: dueDate,
        PrivateNote: memo
      }
    };

    const data = await this.makeQuickBooksRequest('bill', 'POST', billData);
    const bill = data.QueryResponse.Bill[0];

    return {
      content: [
        {
          type: "text",
          text: `Bill created successfully:\n\nBill ID: ${bill.Id}\nVendor: ${bill.VendorRef.name}\nAmount: $${bill.TotalAmt}\nDue Date: ${bill.DueDate || 'Not set'}\nMemo: ${bill.PrivateNote || 'N/A'}`,
        },
      ],
    };
  }

  async listPayments(maxResults = 20, startDate, endDate) {
    let query = `SELECT * FROM Payment`;
    
    if (startDate && endDate) {
      query += ` WHERE TxnDate >= '${startDate}' AND TxnDate <= '${endDate}'`;
    } else if (startDate) {
      query += ` WHERE TxnDate >= '${startDate}'`;
    } else if (endDate) {
      query += ` WHERE TxnDate <= '${endDate}'`;
    }
    
    query += ` MAXRESULTS ${maxResults}`;

    const data = await this.makeQuickBooksRequest(`query?query=${encodeURIComponent(query)}`);
    const payments = data.QueryResponse.Payment || [];

    return {
      content: [
        {
          type: "text",
          text: `Found ${payments.length} payments:\n\n` +
                payments.map(payment => 
                  `ID: ${payment.Id}\nCustomer: ${payment.CustomerRef?.name || 'N/A'}\nAmount: $${payment.TotalAmt}\nDate: ${payment.TxnDate}\nPayment Method: ${payment.PaymentMethodRef?.name || 'N/A'}\n`
                ).join('\n'),
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("QuickBooks MCP server running on stdio");
  }
}

const server = new QuickBooksMCPServer();
server.run().catch(console.error);