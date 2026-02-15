# Database Configuration Guide

## Supabase Connection String

### ⚠️ Important: URL Encoding Special Characters

If your Supabase password contains special characters, you **must** URL-encode them:

| Character | Encoded |
|-----------|---------|
| `/`       | `%2F`   |
| `*`       | `%2A`   |
| `+`       | `%2B`   |
| `#`       | `%23`   |
| `?`       | `%3F`   |
| `@`       | `%40`   |
| `:`       | `%3A`   |
| ` ` (space) | `%20` |

### Example

**❌ Wrong (will cause errors):**
```
postgresql://postgres.xxx:3y/*Kq+d26AAd#?@host.supabase.com:5432/postgres
```

**✅ Correct:**
```
postgresql://postgres.xxx:3y%2F%2AKq%2Bd26AAd%23%3F@host.supabase.com:5432/postgres
```

### How to Set in Azure App Service

1. Azure Portal → App Service → Configuration → Application settings
2. Add/Edit: `DATABASE_URL`
3. Value: Your properly encoded connection string
4. Save and restart

### Alternative: Use Connection Pooler

Supabase provides two connection modes:

1. **Direct Connection** (port 5432)
   ```
   postgresql://postgres.xxx:password@aws-xxx.pooler.supabase.com:5432/postgres
   ```

2. **Session Pooler** (port 6543) - Recommended for serverless
   ```
   postgresql://postgres.xxx:password@aws-xxx.pooler.supabase.com:6543/postgres
   ```

3. **Transaction Pooler** (port 6543 with `?pgbouncer=true`)
   ```
   postgresql://postgres.xxx:password@aws-xxx.pooler.supabase.com:6543/postgres?pgbouncer=true
   ```

For Azure App Service, **Session Pooler (port 6543)** is recommended.

## Fallback Behavior

If `DATABASE_URL` is not set or is invalid, the app will automatically fall back to SQLite:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

## Testing Locally

Add to your `.env` file:
```bash
DATABASE_URL=postgresql://postgres.xxx:password@host:5432/postgres
```

Then run:
```bash
python manage.py migrate
python manage.py runserver
```
