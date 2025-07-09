# {PROJECT_NAME} - Python Project Memory

## Project Overview
**Project Name**: {PROJECT_NAME}  
**Type**: Python Application  
**Created**: {DATE}  
**Directory**: {PROJECT_PATH}

## Architecture & Tech Stack
- **Python Version**: {PYTHON_VERSION}
- **Framework**: [Django/FastAPI/Flask/None]
- **Database**: [PostgreSQL/SQLite/MongoDB]
- **ORM**: [Django ORM/SQLAlchemy/Tortoise]
- **Testing**: pytest + coverage
- **Package Manager**: pip/poetry/pipenv
- **Virtual Environment**: venv/conda

## Project Structure
```
{PROJECT_NAME}/
├── {PROJECT_NAME}/      # Main package
├── tests/              # Test files
├── docs/               # Documentation
├── requirements.txt    # Dependencies
├── setup.py           # Package setup
├── .env.example       # Environment template
└── README.md          # Project documentation
```

## Coding Standards
- Follow PEP 8 style guidelines
- Use type hints for function parameters and returns
- Write docstrings for all functions and classes
- Use descriptive variable and function names
- Implement proper exception handling
- Use list/dict comprehensions where appropriate
- Follow the DRY principle

## Python Best Practices
- Use virtual environments for dependency isolation
- Pin dependency versions in requirements.txt
- Use f-strings for string formatting
- Prefer pathlib over os.path for file operations
- Use context managers for resource management
- Implement proper logging instead of print statements
- Use dataclasses or Pydantic for data models

## Development Workflow
1. Always start with plan mode for new features
2. Create feature branches for development
3. Write tests before implementing functionality (TDD)
4. Use black for code formatting
5. Run flake8/pylint for linting
6. Use mypy for type checking
7. Run pytest before committing

## Testing Strategy
- Unit tests for individual functions/methods
- Integration tests for API endpoints (if applicable)
- Use fixtures for test data setup
- Mock external dependencies
- Aim for high test coverage (>90%)
- Use parametrized tests for multiple scenarios

## Dependencies Management
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Freeze dependencies
pip freeze > requirements.txt
```

## Environment Variables
```
ENVIRONMENT=development
DEBUG=True
DATABASE_URL=
SECRET_KEY=
API_KEY=
LOG_LEVEL=INFO
```

## Error Handling & Logging
- Use specific exception types
- Implement proper logging configuration
- Use try/except blocks appropriately
- Log errors with context information
- Use logging levels appropriately (DEBUG, INFO, WARNING, ERROR)

## Performance Considerations
- Use generators for large data processing
- Implement database connection pooling
- Use caching for expensive operations
- Profile code for bottlenecks
- Use async/await for I/O operations (if applicable)

## Security Best Practices
- Validate and sanitize all inputs
- Use secrets module for sensitive data generation
- Implement proper authentication and authorization
- Keep dependencies updated
- Use HTTPS in production
- Store secrets in environment variables

## Dependencies & External APIs
[Document external services, APIs, and their documentation URLs]

## Common Commands
```bash
# Run tests
pytest

# Run with coverage
pytest --cov={PROJECT_NAME}

# Format code
black .

# Lint code
flake8 .

# Type checking
mypy {PROJECT_NAME}

# Run application
python -m {PROJECT_NAME}
```

## Known Issues & Technical Debt
[Track known problems and areas for improvement]

## Recent Context & Instructions
[This section will be updated with recent instructions and context]