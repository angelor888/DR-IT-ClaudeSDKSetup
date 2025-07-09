# Jobber Quote Creation - Technical Learning

**Date:** July 8, 2025

## Summary

Successfully created Quote #1157 in Jobber using GraphQL API after discovering the required `saveToProductsAndServices` field for line items.

## Key Technical Details

### API Configuration
- **Endpoint:** `https://api.getjobber.com/api/graphql`
- **Authentication:** Bearer token from OAuth flow
- **Required Header:** `X-JOBBER-GRAPHQL-VERSION: 2025-01-20`

### Quote Creation Mutation

```graphql
mutation CreateQuote($attributes: QuoteCreateAttributes!) {
    quoteCreate(attributes: $attributes) {
        quote {
            id
            title
            quoteNumber
            client {
                name
            }
            createdAt
        }
        userErrors {
            message
        }
    }
}
```

### Required Fields for QuoteCreateAttributes

```json
{
    "clientId": "client_id_here",
    "propertyId": "property_id_here",  // Optional but recommended
    "title": "Quote title",
    "message": "Optional message",
    "lineItems": [
        {
            "name": "Line item name",
            "description": "Description",
            "quantity": 1.0,
            "unitPrice": 100.00,
            "saveToProductsAndServices": false  // REQUIRED!
        }
    ]
}
```

## Common Errors Encountered

1. **Missing saveToProductsAndServices field**
   - Error: `Variable $attributes of type QuoteCreateAttributes! was provided invalid value for lineItems.0.saveToProductsAndServices (Expected value to not be null)`
   - Solution: Add `"saveToProductsAndServices": false` to each line item

2. **Python boolean vs JSON boolean**
   - Error: `name 'false' is not defined`
   - Solution: Use `False` in Python (capital F)

3. **Incorrect field names**
   - The Quote type doesn't have fields like `subtotal`, `total`, or `status`
   - Use `quoteStatus` instead of `status`
   - Calculate totals from line items

## Working Example

```python
create_quote_mutation = {
    "query": """mutation...""",
    "variables": {
        "attributes": {
            "clientId": client_id,
            "propertyId": property_id,
            "title": f"Quote Title - {datetime.now().strftime('%m/%d/%Y')}",
            "message": "Quote message here",
            "lineItems": [
                {
                    "name": "Service Name",
                    "description": "Service description",
                    "quantity": 1.0,
                    "unitPrice": 750.00,
                    "saveToProductsAndServices": False
                }
            ]
        }
    }
}
```

## Quote Created

- **Quote #:** 1157
- **Client:** Kathleen Ohm (Green World Property Services)
- **Total:** $1,500.00
- **Line Items:**
  1. MCP Integration Setup & Configuration - $750.00
  2. API Testing & Validation (3 units) - $450.00
  3. Documentation & Training - $300.00

## Files Created During Testing

- `/tmp/create-jobber-quote-final.py` - Working quote creation script
- `/tmp/jobber-quote-summary.md` - Detailed summary of the created quote