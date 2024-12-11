# PostgreSQL Setup and Configuration

This document outlines the PostgreSQL setup, configuration, and best practices for the TmpPhx project.

## Setup

### Prerequisites
- PostgreSQL 14.0 or higher
- Valid database user with creation privileges

### Local Development Setup
```bash
# Install PostgreSQL (macOS)
brew install postgresql@14

# Start PostgreSQL service
brew services start postgresql@14
```

## Database Configuration

### Database User
Create a new database user as `postgres` user:
```bash
# -P: prompt for password, you have to match the password with the one in config/dev.exs
# -d: new role can create DB
createuser -P -d postgres
```

### Environment Variables
The following environment variables should be set in your `.env` file:
```
DATABASE_URL=postgresql://username:password@localhost:5432/tmp_phx_dev
TEST_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/tmp_phx_test
```

### Database Creation

You can skip this step if you're using the `mix setup` command.

```bash
# Create development database
mix ecto.create

# Create and run migrations
mix ecto.migrate
```

## Connection Pool Configuration

In `config/dev.exs`:
```elixir
config :tmp_phx, TmpPhx.Repo,
  pool_size: 10,
  queue_target: 5000,
  queue_interval: 1000
```

## Migrations

### Creating Migrations
```bash
# Generate a new migration
mix ecto.gen.migration create_users

# Run pending migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback
```

### Migration Best Practices
- Always provide both `up` and `down` functions
- Use constraints for data integrity
- Add appropriate indices for frequently queried columns
- Use transactions for complex migrations

## Backup and Restore

### Backup
```bash
pg_dump -U username -d tmp_phx_dev -F c -b -v -f backup.dump
```

### Restore
```bash
pg_restore -U username -d tmp_phx_dev -v backup.dump
```

## Performance Optimization

### Indexing Strategy
- Use B-tree indices for equality and range queries
- Consider GiST indices for geometric data
- Use partial indices for filtered queries
- Regular VACUUM and ANALYZE operations

### Query Optimization
- Use `EXPLAIN ANALYZE` for query performance analysis
- Implement pagination for large result sets
- Use materialized views for complex, frequently-accessed data

## Monitoring

### Key Metrics to Monitor
- Connection pool utilization
- Query execution time
- Cache hit ratio
- Index usage
- Table and index sizes

### Common Queries for Monitoring
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Find slow queries
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active';
```

## Troubleshooting

### Common Issues
1. Connection timeout
   - Check max_connections setting
   - Verify connection pool configuration
   
2. Slow queries
   - Review and update indices
   - Analyze query plans
   - Consider query optimization

3. Database locks
   - Monitor long-running transactions
   - Check for deadlocks

## Security Best Practices

1. Access Control
   - Use least privilege principle
   - Implement row-level security where needed
   - Regular audit of user permissions

2. Connection Security
   - Use SSL for connections
   - Implement connection encryption
   - Regular password rotation

## Development Guidelines

1. Schema Changes
   - All changes must go through migrations
   - Document significant schema changes
   - Maintain backward compatibility when possible

2. Query Guidelines
   - Use Ecto queries when possible
   - Document complex raw SQL queries
   - Implement proper error handling

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [Ecto Documentation](https://hexdocs.pm/ecto/Ecto.html)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
