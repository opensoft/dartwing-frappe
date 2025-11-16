# dartwing-frappe

Frappe framework integration layer for Dartwing with ERPNext accounting module proxy.

## Overview

`dartwing-frappe` is a custom application layer built on top of the Frappe framework. It provides:

- **Custom business logic** using Frappe's powerful framework
- **ERPNext accounting integration** via a proxy/connector pattern
- **Clean architectural separation** between custom code and third-party services
- **Apache 2.0 licensing** for the application while respecting dependencies

## Architecture

This application follows a service-oriented architecture:

```
┌─────────────────────────────────────────┐
│   dartwing-frappe Application           │
│   (Apache 2.0 Licensed)                 │
├─────────────────────────────────────────┤
│  Custom Features & Business Logic       │
│  Frappe Integration Layer               │
│  ERPNext Proxy/Connector                │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  Frappe Framework (MIT Licensed)        │
│  - Core application framework           │
│  - Database models                      │
│  - User interface & API                 │
└────────────┬────────────────────────────┘
             │
             ▼ (HTTP/RPC Calls)
┌─────────────────────────────────────────┐
│  ERPNext Service (GPL-3.0 Licensed)     │
│  - Accounting Module                    │
│  - Financial Reports                    │
│  - Separate Deployment                  │
└─────────────────────────────────────────┘
```

### Key Architectural Principles

1. **No ERPNext Code Embedding**: This application does not include, modify, or redistribute ERPNext source code
2. **API-Based Integration**: Communication with ERPNext happens exclusively via HTTP/RPC API calls
3. **Service Separation**: ERPNext runs as an independent service with its own GPL-3.0 deployment
4. **Proxy Pattern**: The application acts as a proxy/connector forwarding accounting requests to ERPNext

## License

This application is licensed under the **Apache License 2.0**.

### Dependency Licensing

This project depends on and integrates with:

- **Frappe Framework**: MIT License
  - Used as a library for application development
  - Custom applications built on Frappe are not restricted by the MIT license

- **ERPNext**: GNU General Public License v3.0 (GPL-3.0)
  - Runs as a separate service
  - This application does NOT include or modify ERPNext code
  - Communication is via REST API/RPC only
  - See [DEPENDENCIES.md](./DEPENDENCIES.md) for detailed licensing information

For more details, see the [LICENSE](./LICENSE) file and [DEPENDENCIES.md](./DEPENDENCIES.md).

## Getting Started

### Prerequisites

- Frappe Framework installed and running
- ERPNext service available and configured (for accounting features)
- Python 3.8+
- Docker (optional, for containerized deployment)

### Installation

```bash
# Clone the repository
git clone https://github.com/opensoft/dartwing-frappe.git
cd dartwing-frappe

# Install dependencies
bench install-app dartwing-frappe

# Run migrations
bench migrate
```

### Configuration

Configure ERPNext connection in your Frappe site configuration:

```python
# site_config.json
{
  "erpnext_url": "http://erpnext-service:8000",
  "erpnext_api_key": "your-api-key",
  "erpnext_api_secret": "your-api-secret"
}
```

## Usage

### Accounting Module Access

When users access accounting features through this application:

1. The application receives the request
2. The ERPNext Proxy validates and transforms the request
3. The request is forwarded to the ERPNext service via API
4. ERPNext processes the accounting logic
5. Results are returned to the user through this application

### Example: Creating an Invoice

```python
# In your custom Frappe app
from dartwing_frappe.connectors.erpnext_proxy import ERPNextProxy

proxy = ERPNextProxy()
invoice_data = {
    'customer': 'CUST-001',
    'items': [...],
    'due_date': '2025-12-31'
}

result = proxy.create_invoice(invoice_data)
```

## Development

### Structure

```
dartwing-frappe/
├── dartwing_frappe/
│   ├── __init__.py
│   ├── hooks.py
│   ├── connectors/
│   │   ├── erpnext_proxy.py      # ERPNext integration
│   │   └── frappe_helpers.py     # Frappe utilities
│   ├── doctype/
│   │   └── [...custom doctypes]
│   └── api.py                    # REST endpoints
├── tests/
├── LICENSE                        # Apache 2.0
└── README.md
```

### Contributing

Contributions are welcome! Please ensure:

- Code follows the Apache 2.0 license terms
- ERPNext integration remains as a pure proxy (no code modifications)
- Tests are included for new features

## Support

For issues and questions:

- GitHub Issues: https://github.com/opensoft/dartwing-frappe/issues
- Documentation: Check [DEPENDENCIES.md](./DEPENDENCIES.md) for licensing details

## License Summary

| Component | License | Notes |
|-----------|---------|-------|
| dartwing-frappe | Apache 2.0 | This application |
| Frappe Framework | MIT | Used as library |
| ERPNext | GPL-3.0 | Separate service, API integration only |

---

**Note**: For a detailed explanation of the licensing architecture and how ERPNext integration works, please see [DEPENDENCIES.md](./DEPENDENCIES.md).
