# Performance Optimization Command

Analyze and optimize code performance, identifying bottlenecks and implementing improvements.

## Tasks

1. **Performance Profiling**
   - Run performance benchmarks on current code
   - Identify CPU and memory bottlenecks
   - Analyze time complexity of algorithms
   - Check for memory leaks

2. **Code Optimizations**
   - **Algorithm Optimization**: Replace O(n²) with O(n log n) where possible
   - **Caching**: Implement memoization for expensive computations
   - **Lazy Loading**: Defer loading of non-critical resources
   - **Database Queries**: Optimize N+1 queries, add proper indexes
   - **Async Operations**: Convert blocking operations to async
   - **Bundle Size**: Tree-shake unused code, implement code splitting

3. **Resource Optimization**
   - Optimize images and media files
   - Minify CSS and JavaScript
   - Enable compression (gzip/brotli)
   - Implement browser caching strategies

4. **Frontend Specific** (if applicable)
   - Virtual scrolling for large lists
   - Debounce/throttle event handlers
   - Optimize React re-renders
   - Implement service workers

5. **Backend Specific** (if applicable)
   - Connection pooling
   - Query optimization
   - Implement caching layers (Redis)
   - Load balancing strategies

## Arguments
$arguments - Target file, directory, or specific optimization focus

## Output
- Performance benchmark before/after results
- List of implemented optimizations
- Estimated performance improvements
- Recommendations for further optimizations