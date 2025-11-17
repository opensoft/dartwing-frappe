# Family Manager - Installation & API Guide

This guide will help you set up the Family Manager app and use its CRUD API endpoints.

## Installation Steps

### 1. Add App to Frappe Site

```bash
cd /home/brett/projects/frappe/development/frappe-bench

# Add the app to sites/apps.txt
echo 'family_manager' >> sites/apps.txt

# Install the app on your site
bench --site site1.localhost install-app family_manager

# Run migrations to create database tables
bench --site site1.localhost migrate
```

### 2. Generate API Keys

Run the Frappe console:
```bash
bench --site site1.localhost console
```

Then execute this Python code:
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
print(f"Authorization: token {api_key}:{api_secret}")

# Save to file
with open("/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt", "w") as f:
    f.write(f"API Key: {api_key}\n")
    f.write(f"API Secret: {api_secret}\n")
    f.write(f"\nAuthorization Header:\n")
    f.write(f"Authorization: token {api_key}:{api_secret}\n")
```

## API Endpoints

### Built-in Frappe REST API

These endpoints are automatically available for the Family doctype:

#### List All Families
```bash
GET /api/resource/Family
```

**Example:**
```bash
curl -X GET "http://localhost:8000/api/resource/Family" \
  -H "Authorization: token {api_key}:{api_secret}"
```

**Query Parameters:**
- `fields`: JSON array of fields to return, e.g., `["name","organization_name","status"]`
- `filters`: JSON array of filters, e.g., `[["status","=","Active"]]`
- `limit_page_length`: Number of records per page (default: 20)
- `limit_start`: Pagination offset

#### Get Single Family
```bash
GET /api/resource/Family/{name}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/api/resource/Family/Smith%20Family" \
  -H "Authorization: token {api_key}:{api_secret}"
```

#### Create Family
```bash
POST /api/resource/Family
```

**Example:**
```bash
curl -X POST "http://localhost:8000/api/resource/Family" \
  -H "Authorization: token {api_key}:{api_secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_name": "Smith Family",
    "organization_type": "Family",
    "description": "The Smith family organization",
    "status": "Active"
  }'
```

#### Update Family
```bash
PUT /api/resource/Family/{name}
```

**Example:**
```bash
curl -X PUT "http://localhost:8000/api/resource/Family/Smith%20Family" \
  -H "Authorization: token {api_key}:{api_secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description",
    "status": "Active"
  }'
```

#### Delete Family
```bash
DELETE /api/resource/Family/{name}
```

**Example:**
```bash
curl -X DELETE "http://localhost:8000/api/resource/Family/Smith%20Family" \
  -H "Authorization: token {api_key}:{api_secret}"
```

---

### Custom API Endpoints

Additional endpoints with business logic:

#### Create Family (Custom)
```bash
POST /api/method/family_manager.api.family.create_family
```

**Parameters:**
- `organization_name` (required): Name of the organization
- `organization_type` (optional): Type (Family, Business, Non-Profit, Other)
- `description` (optional): Description text
- `status` (optional): Status (Active, Inactive, Archived)

**Example:**
```bash
curl -X POST "http://localhost:8000/api/method/family_manager.api.family.create_family" \
  -H "Authorization: token {api_key}:{api_secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_name": "Johnson Family",
    "organization_type": "Family",
    "description": "The Johnson family organization"
  }'
```

#### Get Family (Custom)
```bash
GET /api/method/family_manager.api.family.get_family?name={name}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.get_family?name=Johnson%20Family" \
  -H "Authorization: token {api_key}:{api_secret}"
```

#### Get All Families (Custom)
```bash
GET /api/method/family_manager.api.family.get_all_families
```

**Parameters:**
- `filters` (optional): JSON filters
- `fields` (optional): JSON array of fields
- `limit_start` (optional): Pagination start
- `limit_page_length` (optional): Page size

**Example:**
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.get_all_families?limit_page_length=10" \
  -H "Authorization: token {api_key}:{api_secret}"
```

#### Update Family (Custom)
```bash
POST /api/method/family_manager.api.family.update_family
```

**Parameters:**
- `name` (required): Family name
- `organization_type` (optional): New type
- `description` (optional): New description
- `status` (optional): New status

**Example:**
```bash
curl -X POST "http://localhost:8000/api/method/family_manager.api.family.update_family" \
  -H "Authorization: token {api_key}:{api_secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Johnson Family",
    "description": "Updated Johnson family",
    "status": "Active"
  }'
```

#### Delete Family (Custom)
```bash
POST /api/method/family_manager.api.family.delete_family
```

**Parameters:**
- `name` (required): Family name

**Example:**
```bash
curl -X POST "http://localhost:8000/api/method/family_manager.api.family.delete_family" \
  -H "Authorization: token {api_key}:{api_secret}" \
  -H "Content-Type: application/json" \
  -d '{"name": "Johnson Family"}'
```

#### Search Families
```bash
GET /api/method/family_manager.api.family.search_families?query={search_term}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.search_families?query=Smith" \
  -H "Authorization: token {api_key}:{api_secret}"
```

#### Get Family Statistics
```bash
GET /api/method/family_manager.api.family.get_family_stats
```

**Example:**
```bash
curl -X GET "http://localhost:8000/api/method/family_manager.api.family.get_family_stats" \
  -H "Authorization: token {api_key}:{api_secret}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 10,
    "by_status": {
      "active": 8,
      "inactive": 1,
      "archived": 1
    },
    "by_type": {
      "Family": 7,
      "Business": 2,
      "Non-Profit": 1
    }
  }
}
```

---

## Family DocType Fields

- **organization_name**: (Data, Required, Unique) - The name of the family organization
- **organization_type**: (Select, Required) - Type: Family, Business, Non-Profit, Other
- **description**: (Text, Optional) - Description of the organization
- **status**: (Select) - Status: Active, Inactive, Archived
- **created_date**: (Date, Read-only) - Auto-set to today's date

---

## Testing

Run the test script:
```bash
cd /home/brett/projects/frappe/development/frappe-bench
./test_family_api.sh
```

This will test all CRUD operations on both the built-in and custom API endpoints.

---

## File Structure

```
apps/family_manager/
├── family_manager/
│   ├── __init__.py
│   ├── hooks.py
│   ├── api/
│   │   ├── __init__.py
│   │   └── family.py          # Custom API endpoints
│   └── doctype/
│       ├── __init__.py
│       └── family/
│           ├── __init__.py
│           ├── family.json     # DocType definition
│           └── family.py       # DocType controller
├── pyproject.toml
└── README.md
```

---

## Notes

- All API endpoints require authentication using API keys
- The Family doctype uses `organization_name` as the primary key (auto-naming)
- Both built-in REST API and custom endpoints are available
- Custom endpoints include additional validation and error handling
- All endpoints support JSON request/response format
