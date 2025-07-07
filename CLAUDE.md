# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MinCenter** is a web platform for a Korean disability support center (민들레장애인자립생활센터). It's a multi-service application with separate frontend and backend components.

## Architecture

### Technology Stack
- **Backend**: Rust with Axum framework, PostgreSQL, Redis, JWT authentication
- **Frontend**: Two SvelteKit 5.0 applications (site and admin) with TypeScript, Tailwind CSS 4.0
- **Infrastructure**: Docker Compose, Nginx, PostgreSQL, Redis

### Project Structure
```
/
├── backends/api/          # Rust API server
├── frontends/site/        # Public website (SvelteKit)
├── frontends/admin/       # Admin panel (SvelteKit)
├── database/             # Database schema and migrations
├── nginx/                # Nginx configuration
├── scripts/              # Deployment scripts
└── docker-compose.yml    # Multi-service orchestration
```

## Development Commands

### Critical: Directory-specific Commands
**🚨 IMPORTANT**: This is a monorepo. Always run commands from the appropriate directory:

#### Rust API (backends/api)
```bash
# Development
cd backends/api && cargo run
cd backends/api && cargo watch -x run

# Build and test
cd backends/api && cargo build --release
cd backends/api && cargo test
cd backends/api && cargo clippy
cd backends/api && cargo fmt
```

#### Frontend Site (frontends/site)
```bash
# Development
cd frontends/site && npm run dev
cd frontends/site && npm run build
cd frontends/site && npm run preview

# Code quality
cd frontends/site && npm run lint
cd frontends/site && npm run format
cd frontends/site && npm run check
```

#### Frontend Admin (frontends/admin)
```bash
# Development
cd frontends/admin && npm run dev
cd frontends/admin && npm run build
cd frontends/admin && npm run preview

# Code quality
cd frontends/admin && npm run lint
cd frontends/admin && npm run format
cd frontends/admin && npm run check
```

#### Docker Development
```bash
# Full stack
docker-compose up -d

# Individual services
docker-compose up -d postgres redis
docker-compose up -d api site admin
```

## Backend Architecture (Rust/Axum)

### Core Patterns
- **Error Handling**: Use `Result<T, E>` pattern, never `unwrap()`
- **API Responses**: Consistent `ApiResponse<T>` structure with success/error states
- **Database**: SQLx with prepared statements, UUID primary keys
- **Authentication**: JWT tokens with refresh token system
- **File Storage**: Local filesystem with organized upload structure

### Key Components
- **Handlers**: HTTP request handlers in `/handlers/`
- **Models**: Database models and response DTOs in `/models/`
- **Services**: Business logic layer in `/services/`
- **Middleware**: Authentication, CORS, logging in `/middleware/`
- **Utils**: JWT utilities, validation, image processing in `/utils/`

### Database
- **PostgreSQL**: Korean locale support, UUID primary keys
- **Migrations**: Manual updates to `database/init.sql` and `database/seed.sql`
- **Schema**: 20+ tables with proper relationships, full-text search with pg_trgm

## Frontend Architecture (SvelteKit 5.0)

### Key Features
- **SvelteKit 5.0**: Latest version with modern syntax
- **TypeScript**: Full type safety
- **Tailwind CSS 4.0**: Latest utility-first CSS framework
- **Rich Text Editor**: TipTap integration (site only)
- **Calendar**: FullCalendar integration
- **UI Components**: Custom components with bits-ui and lucide-svelte

### Code Conventions
- **Components**: Reusable UI components in `/lib/components/`
- **API Integration**: Centralized API clients in `/lib/api/`
- **State Management**: Svelte stores in `/lib/stores/`
- **Types**: TypeScript interfaces in `/lib/types/`

## Database Management

### Development Database Updates
When making schema changes during development:
1. Update `database/init.sql` with schema changes
2. Update `database/seed.sql` with test data
3. Rebuild containers: `docker-compose down && docker-compose up -d`

### Database Features
- **Korean Support**: Full Korean text search capabilities
- **File Management**: Sophisticated file entity relationships
- **User System**: Social login support, points system, notifications
- **Audit Trail**: Created/updated timestamps with triggers

## Security & Performance

### Security
- **JWT Authentication**: Secure token-based authentication
- **Role-based Access Control**: Admin and user roles
- **Input Validation**: Comprehensive request validation
- **File Upload Security**: Type validation, size limits, EXIF removal

### Performance
- **Database Indexing**: Comprehensive index strategy
- **Redis Caching**: Session and data caching
- **Asset Optimization**: Vite build optimizations
- **Connection Pooling**: Efficient database connections

## Code Quality Standards

### Rust Backend
- **No unwrap()**: Always use proper error handling
- **Clippy compliance**: Fix all clippy warnings
- **Documentation**: Doc comments for public functions
- **Type safety**: Compile-time error checking
- **Korean responses**: All user-facing messages in Korean

### Frontend
- **TypeScript**: Full type safety
- **ESLint compliance**: Fix all linting errors
- **Prettier formatting**: Consistent code formatting
- **Component reusability**: Build reusable UI components

## Common Development Workflow

1. **Start Development Environment**:
   ```bash
   # Terminal 1: API server
   cd backends/api && cargo watch -x run
   
   # Terminal 2: Main site
   cd frontends/site && npm run dev
   
   # Terminal 3: Admin (if needed)
   cd frontends/admin && npm run dev
   ```

2. **Code Quality Checks**:
   ```bash
   # Backend checks
   cd backends/api && cargo clippy && cargo fmt
   
   # Frontend checks
   cd frontends/site && npm run lint && npm run check
   cd frontends/admin && npm run lint && npm run check
   ```

3. **Database Changes**:
   - Update `database/init.sql` for schema changes
   - Update `database/seed.sql` for test data
   - Restart containers to apply changes

## Deployment

- **Target**: CentOS 7 compatible
- **Process Management**: PM2 for Node.js applications
- **SSL**: Let's Encrypt with automated certificate management
- **Docker**: Multi-stage builds for production efficiency
- **Memory Optimization**: Specialized build scripts for resource-constrained environments