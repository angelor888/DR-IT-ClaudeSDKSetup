# {PROJECT_NAME} - React Project Memory

## Project Overview
**Project Name**: {PROJECT_NAME}  
**Type**: React Application  
**Created**: {DATE}  
**Directory**: {PROJECT_PATH}

## Architecture & Tech Stack
- **Frontend**: React {REACT_VERSION}
- **Language**: TypeScript
- **Build Tool**: Vite / Create React App
- **State Management**: [Redux/Zustand/Context API]
- **Styling**: [Tailwind CSS/Styled Components/CSS Modules]
- **Testing**: Jest + React Testing Library
- **Package Manager**: npm/yarn

## Coding Standards
- Use TypeScript for all new components
- Prefer functional components with hooks
- Use explicit return types for functions
- Follow React best practices (memoization, proper deps)
- Use descriptive component and prop names
- Implement proper error boundaries
- Write unit tests for complex logic

## Component Structure
```
src/
├── components/          # Reusable UI components
├── pages/              # Route-level components
├── hooks/              # Custom React hooks
├── utils/              # Pure utility functions
├── types/              # TypeScript type definitions
├── services/           # API calls and external services
└── __tests__/          # Test files
```

## Development Workflow
1. Always start with plan mode for new features
2. Create feature branches for significant changes
3. Write tests before implementing complex logic
4. Use Storybook for component development (if applicable)
5. Run linting and type checking before commits
6. Update documentation for new components

## Styling Guidelines
- Use consistent spacing units (4px, 8px, 16px, 24px)
- Follow mobile-first responsive design
- Use semantic HTML elements
- Implement consistent color scheme
- Ensure accessibility (ARIA labels, keyboard navigation)

## State Management Patterns
- Keep state as local as possible
- Use custom hooks for complex state logic
- Implement proper loading and error states
- Use optimistic updates for better UX
- Cache API responses appropriately

## Performance Considerations
- Use React.memo for expensive components
- Implement proper key props for lists
- Lazy load routes and heavy components
- Optimize images and assets
- Monitor bundle size

## Dependencies & External APIs
[Document external services, APIs, and their documentation URLs]

## Environment Variables
```
REACT_APP_API_URL=
REACT_APP_AUTH_DOMAIN=
REACT_APP_ANALYTICS_ID=
```

## Testing Strategy
- Unit tests for hooks and utilities
- Component tests for UI behavior
- Integration tests for user flows
- E2E tests for critical paths
- Visual regression tests (if applicable)

## Known Issues & Technical Debt
[Track known problems and areas for improvement]

## Recent Context & Instructions
[This section will be updated with recent instructions and context]