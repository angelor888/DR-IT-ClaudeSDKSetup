# {PROJECT_NAME} - Node.js Project Memory

## Project Overview
**Project Name**: {PROJECT_NAME}  
**Type**: Node.js Application  
**Created**: {DATE}  
**Directory**: {PROJECT_PATH}

## Architecture & Tech Stack
- **Runtime**: Node.js {NODE_VERSION}
- **Language**: TypeScript/JavaScript
- **Framework**: [Express/Fastify/NestJS/None]
- **Database**: [PostgreSQL/MongoDB/Redis]
- **ORM/ODM**: [Prisma/Mongoose/TypeORM]
- **Testing**: Jest + Supertest
- **Package Manager**: npm/yarn/pnpm

## Project Structure
```
src/
├── controllers/         # Route handlers
├── services/           # Business logic
├── models/             # Data models
├── middleware/         # Express middleware
├── utils/              # Utility functions
├── config/             # Configuration files
├── types/              # TypeScript definitions
└── __tests__/          # Test files
```

## Coding Standards
- Use TypeScript for type safety
- Implement proper error handling with try/catch
- Use async/await instead of callbacks
- Follow RESTful API conventions
- Implement proper input validation
- Use environment variables for configuration
- Write comprehensive unit and integration tests

## API Design Principles
- Use clear, consistent endpoint naming
- Implement proper HTTP status codes
- Use standard HTTP methods appropriately
- Implement proper pagination for list endpoints
- Use JSON for request/response bodies
- Implement proper authentication and authorization

## Database Patterns
- Use database transactions for complex operations
- Implement proper indexing for performance
- Use connection pooling
- Implement database migrations
- Use prepared statements to prevent SQL injection
- Follow database naming conventions

## Development Workflow
1. Always start with plan mode for new features
2. Create feature branches for development
3. Write tests before implementing endpoints
4. Use database migrations for schema changes
5. Run linting and type checking before commits
6. Use API documentation tools (Swagger/OpenAPI)

## Security Considerations
- Implement proper authentication (JWT/OAuth)
- Use HTTPS in production
- Implement rate limiting
- Validate and sanitize all inputs
- Use CORS appropriately
- Keep dependencies updated
- Implement proper logging (avoid sensitive data)

## Environment Variables
```
NODE_ENV=development
PORT=3000
DATABASE_URL=
JWT_SECRET=
API_KEY=
```

## Dependencies & External APIs
[Document external services, APIs, and their documentation URLs]

## Error Handling Strategy
- Use consistent error response format
- Implement global error handler
- Log errors appropriately
- Return appropriate HTTP status codes
- Don't expose internal error details to clients

## Performance Considerations
- Use database connection pooling
- Implement caching where appropriate
- Use compression middleware
- Optimize database queries
- Monitor application performance

## Testing Strategy
- Unit tests for services and utilities
- Integration tests for API endpoints
- Database tests with test database
- Load testing for performance critical endpoints
- Security testing for authentication

## Known Issues & Technical Debt
[Track known problems and areas for improvement]

## Recent Context & Instructions
[This section will be updated with recent instructions and context]