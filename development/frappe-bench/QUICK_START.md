# Family Manager - Quick Start Guide

## What Has Been Created

I've created a complete **Family Manager** Frappe app with CRUD API endpoints for managing family organizations.

### Files Created:

```
apps/family_manager/
├── family_manager/
│   ├── __init__.py
│   ├── hooks.py                          # App configuration
│   ├── api/
│   │   ├── __init__.py
│   │   └── family.py                     # Custom API endpoints (7 endpoints)
│   └── doctype/
│       ├── __init__.py
│       └── family/
│           ├── __init__.py
│           ├── family.json               # DocType definition
│           └── family.py                 # DocType controller
├── pyproject.toml                        # App metadata
└── README.md

Helper Scripts:
├── install_family_manager.sh             # Installation script
├── test_family_api.sh                    # API testing script
├── FAMILY_MANAGER_README.md              # Complete API documentation
└── QUICK_START.md                        # This file
```

## Installation (3 Steps)

### Step 1: Install the App

```bash
cd /home/brett/projects/frappe/development/frappe-bench

# Option A: Run the install script
./install_family_manager.sh

# Option B: Manual installation
echo 'family_manager' >> sites/apps.txt
bench --site site1.localhost install-app family_manager
bench --site site1.localhost migrate
```

### Step 2: Generate API Keys

```bash
bench --site site1.localhost console
```

Paste this in the console:

```python
import frappe
from frappe.utils.password import get_decrypted_password

user = "Administrator"
user_doc = frappe.get_doc("User", user)

if not user_doc.api_key:
    api_key = frappe.generate_hash(length=15)
    api_secret = frappe.generate_hash(length=15)
    user_doc.api_key = api_key
    user_doc.api_secret = api_secret
    user_doc.save(ignore_permissions=True)
    frappe.db.commit()
else:
    api_key = user_doc.api_key
    api_secret = get_decrypted_password("User", user, fieldname="api_secret")

print(f"API Key: {api_key}")
print(f"API Secret: {api_secret}")

with open("/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt", "w") as f:
    f.write(f"API Key: {api_key}\n")
    f.write(f"API Secret: {api_secret}\n")
    f.write(f"\nAuthorization Header:\n")
    f.write(f"Authorization: token {api_key}:{api_secret}\n")

print("\nCredentials saved to api_credentials.txt")
```

### Step 3: Test the API

```bash
# Make sure Frappe server is running
bench start

# In another terminal, run tests
./test_family_api.sh
```

## Available API Endpoints

### Built-in Frappe REST API (5 endpoints)
- `GET /api/resource/Family` - List all families
- `GET /api/resource/Family/{name}` - Get single family
- `POST /api/resource/Family` - Create family
- `PUT /api/resource/Family/{name}` - Update family
- `DELETE /api/resource/Family/{name}` - Delete family

### Custom API Endpoints (7 endpoints)
- `POST /api/method/family_manager.api.family.create_family` - Create with validation
- `GET /api/method/family_manager.api.family.get_family` - Get single
- `GET /api/method/family_manager.api.family.get_all_families` - List with filters
- `POST /api/method/family_manager.api.family.update_family` - Update with validation
- `POST /api/method/family_manager.api.family.delete_family` - Delete with validation
- `GET /api/method/family_manager.api.family.search_families` - Search by name/description
- `GET /api/method/family_manager.api.family.get_family_stats` - Get statistics

## Quick Test Examples

### Create a Family (Built-in API)
```bash
curl -X POST "http://localhost:8000/api/resource/Family" \
  -H "Authorization: token YOUR_KEY:YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_name": "Smith Family",
    "organization_type": "Family",
    "description": "The Smith family organization"
  }'
```

### Get All Families (Custom API)
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.get_all_families" \
  -H "Authorization: token YOUR_KEY:YOUR_SECRET"
```

### Search Families
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.search_families?query=Smith" \
  -H "Authorization: token YOUR_KEY:YOUR_SECRET"
```

### Get Statistics
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.get_family_stats" \
  -H "Authorization: token YOUR_KEY:YOUR_SECRET"
```

## Family DocType Schema

| Field              | Type   | Required | Description                           |
|--------------------|--------|----------|---------------------------------------|
| organization_name  | Data   | Yes      | Unique name (used as primary key)     |
| organization_type  | Select | Yes      | Family/Business/Non-Profit/Other      |
| description        | Text   | No       | Description of the organization       |
| status             | Select | No       | Active/Inactive/Archived (default: Active) |
| created_date       | Date   | No       | Auto-set to today (read-only)         |

## Features

✅ Complete CRUD operations
✅ RESTful API endpoints (built-in + custom)
✅ API authentication with tokens
✅ Input validation and error handling
✅ Search functionality
✅ Statistics/analytics endpoint
✅ Automatic timestamping
✅ Field-level permissions
✅ Change tracking enabled

## Next Steps

1. **Read Full Documentation**: See `FAMILY_MANAGER_README.md` for detailed API docs
2. **Test All Endpoints**: Run `./test_family_api.sh`
3. **Customize**: Modify `apps/family_manager/family_manager/doctype/family/family.py` for custom logic
4. **Add More Fields**: Edit `family.json` and run `bench migrate`
5. **Create UI**: Add custom pages or use Frappe's auto-generated forms

## Troubleshooting

### bench command not found
Make sure you're in the frappe-bench directory and bench is installed.

### App not installing
Check that `family_manager` is in `sites/apps.txt` and run migrations.

### API returns 403 Forbidden
Verify your API keys are correct. Check `api_credentials.txt`.

### DocType not found
Run `bench --site site1.localhost migrate` to create database tables.

## Documentation Files

- **QUICK_START.md** (this file) - Quick overview and setup
- **FAMILY_MANAGER_README.md** - Complete API documentation with examples
- **install_family_manager.sh** - Automated installation script
- **test_family_api.sh** - API testing script

---

**Created**: All CRUD functionality for Family organizations
**Status**: Ready to install and test
**Time to Setup**: ~5 minutes
