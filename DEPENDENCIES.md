# Dependencies and Licensing

This document explains the licensing architecture of `dartwing-frappe` and how it manages dependencies while maintaining Apache 2.0 licensing.

## Overview

`dartwing-frappe` is licensed under **Apache License 2.0** and integrates with two major components:

1. **Frappe Framework** (MIT License) - Used as a core library
2. **ERPNext** (GPL-3.0 License) - Accessed via API as a separate service

This document explains how we maintain Apache 2.0 licensing while respecting the licenses of both dependencies.

---

## License Compatibility Matrix

| Component | License | Integration Type | Code Inclusion | License Impact |
|-----------|---------|------------------|-----------------|----------------|
| dartwing-frappe | Apache 2.0 | N/A | This repo | Primary license |
| Frappe Framework | MIT | Library import | No | MIT is compatible with Apache 2.0 |
| ERPNext | GPL-3.0 | HTTP/RPC API | No | No GPL contamination |

---

## Frappe Framework (MIT License)

### License Details

The Frappe Framework is licensed under the MIT License. MIT is a permissive open source license that:

- Allows commercial use
- Allows modification
- Allows distribution
- Allows private use
- Requires License and Copyright Notice
- Provides no warranty or liability

**MIT License Text**: https://github.com/frappe/frappe/blob/develop/LICENSE

### Why Apache 2.0 Works with MIT

Our application can be licensed under Apache 2.0 when using the Frappe Framework because:

1. **MIT is permissive**: MIT allows code to be used in projects with different licenses
2. **No GPL requirements**: MIT does not impose copyleft requirements (unlike GPL)
3. **Apache 2.0 is compatible**: Apache 2.0 is also a permissive license
4. **Library usage**: We use Frappe as a library, not as derivative work

### How We Use Frappe

- Import Frappe Framework as a Python package
- Build custom applications on top of Frappe
- Do NOT modify Frappe framework source code
- Do NOT redistribute Frappe code

**Result**: Custom applications built on Frappe are not restricted by MIT license terms

---

## ERPNext (GPL-3.0 License)

### License Details

ERPNext is licensed under the GNU General Public License v3.0 (GPL-3.0). GPL-3.0 is a **copyleft** license that:

- Allows commercial use
- Allows modification
- Allows distribution
- Requires source code disclosure
- **Requires derivative works to use the same GPL-3.0 license** (copyleft)
- Requires License and Copyright Notice
- Provides no warranty or liability

**GPL-3.0 License Text**: https://www.gnu.org/licenses/gpl-3.0.html

### Why GPL-3.0 Does NOT Affect Our License

Our application remains Apache 2.0 licensed because:

1. **No code embedding**: We do NOT include, modify, or redistribute ERPNext source code
2. **API-only integration**: All communication with ERPNext happens via REST API/RPC calls
3. **Separate deployment**: ERPNext runs as an independent service with its own GPL-3.0 licensing
4. **No derivative work**: We do not create derivative works of ERPNext code
5. **Proxy pattern**: We act as a client/proxy to ERPNext, not as a modification of it

### Architectural Separation

```
dartwing-frappe (Apache 2.0)
        ↓ (HTTP/RPC API calls)
ERPNext Service (GPL-3.0)
```

The separation is:
- **Network boundary**: ERPNext is accessed over HTTP/RPC
- **Process boundary**: ERPNext runs in separate process(es)
- **Code boundary**: No ERPNext source code is included in this repository
- **License boundary**: GPL-3.0 terms apply to ERPNext deployment only

### GPL-3.0 and Service Usage

GPL-3.0 is primarily concerned with:
- Modifying GPL-licensed software
- Redistributing GPL-licensed software
- Creating derivative works from GPL-licensed software

GPL-3.0 is **NOT** concerned with:
- Using GPL-licensed software as a service
- Communicating with GPL-licensed software via APIs
- Building applications that call into GPL-licensed services

**Reference**: [GNU FAQ on GPL and Web Services](https://www.gnu.org/licenses/gpl-faq.html#AGPLProxy)

---

## Detailed Licensing Breakdown

### dartwing-frappe Application Code

**License**: Apache License 2.0

**What's Included**:
- Custom business logic
- Frappe integration layer
- ERPNext proxy/connector classes
- REST API endpoints
- Database models (DocTypes)
- Custom views and templates
- Tests and documentation

**License File**: [LICENSE](./LICENSE)

### Frappe Framework

**License**: MIT License

**Installation**: `pip install frappe` (external dependency)

**Included in Repo**: No (installed as external package)

**Usage**:
- Imported as Python package
- Used through Frappe's public API
- NOT modified or redistributed

**License Acknowledgment**: When using Frappe, ensure you:
- Include Frappe's MIT license notice in your documentation
- Acknowledge MIT license in your project

**See**: https://github.com/frappe/frappe/blob/develop/LICENSE

### ERPNext Service

**License**: GNU General Public License v3.0

**Installation**: Deployed as separate service (not in this repository)

**Included in Repo**: No (accessed via API only)

**Usage**:
- Accessed via REST API/RPC
- No source code included
- No source code modified
- No source code redistributed

**License Acknowledgment**: When deploying ERPNext:
- Deploy ERPNext under GPL-3.0 terms
- Provide source code access for your ERPNext deployment if modified
- Use the ERPNext license when distributing modified ERPNext versions

**See**: https://github.com/frappe/erpnext/blob/develop/LICENSE

---

## User Obligations

When using `dartwing-frappe`:

### For dartwing-frappe Code

✅ You must:
- Provide license notice (Apache 2.0)
- Include copy of Apache 2.0 license
- State significant changes made

❌ You cannot:
- Remove Apache 2.0 license notice
- Hold maintainers liable
- Claim trademark rights to Dartwing

### For Frappe Framework

✅ You must:
- Include Frappe's MIT license notice
- Include copy of MIT license

❌ You cannot:
- Remove MIT license notice
- Hold maintainers liable

### For ERPNext

✅ When deploying ERPNext:
- Follow ERPNext's GPL-3.0 license
- Provide source code if you modify ERPNext
- Include GPL-3.0 license notice

❌ You cannot:
- Remove GPL-3.0 license notice
- Hold maintainers liable
- Use ERPNext code outside GPL-3.0 terms (in your own derivative works)

---

## FAQ

### Q: Can I use this under a different license?

A: No. This application is licensed under Apache 2.0. However, you can:
- Use the application according to Apache 2.0 terms
- Fork it and propose changes
- Use it in commercial projects (with proper attribution)

### Q: Do I need to open-source my code if I use this?

A: **No**. Apache 2.0 is a permissive license that does not require you to open-source your code. You can:
- Use it in proprietary applications
- Modify it for internal use
- Distribute it without releasing your source code

You must:
- Include the Apache 2.0 license
- Include copyright notice
- State any significant changes

### Q: Can I remove the ERPNext proxy and use a different accounting system?

A: Yes. The ERPNext connector is modular. You can:
- Replace the ERPNext proxy with your own connector
- Create connectors for other accounting systems
- Use the rest of the application independently

### Q: What if I modify ERPNext?

A: If you modify ERPNext:
- Your modifications fall under GPL-3.0
- You must provide source code for modifications
- You CANNOT use modified ERPNext code outside GPL-3.0
- The `dartwing-frappe` application itself remains Apache 2.0

### Q: Can I use this with a proprietary Frappe extension?

A: Frappe and ERPNext are both open source. However, if you use proprietary extensions:
- Check the license of the extension
- Ensure compatibility with Apache 2.0 + MIT + GPL-3.0
- Consult the extension's license terms

### Q: How do I properly attribute licenses?

A: Include in your project:
- Copy of Apache 2.0 license (this app)
- Copy of MIT license (Frappe)
- Copy of GPL-3.0 license (ERPNext, in ERPNext deployment)
- Attribution notice for each component

Example:
```
Licenses:
- dartwing-frappe: Apache License 2.0
- Frappe Framework: MIT License
- ERPNext: GNU General Public License v3.0

See LICENSES/ directory for full license texts.
```

---

## References

### Licenses

- [Apache License 2.0](./LICENSE)
- [MIT License](https://opensource.org/licenses/MIT)
- [GPL-3.0 License](https://www.gnu.org/licenses/gpl-3.0.html)

### Documentation

- [Frappe Framework](https://github.com/frappe/frappe)
- [ERPNext](https://github.com/frappe/erpnext)
- [OSI License Compatibility](https://www.blackducksoftware.com/blog/open-source-licenses-compatibility)
- [GPL and Services](https://www.gnu.org/licenses/gpl-faq.html)

### Related

- [README.md](./README.md) - Main documentation
- [LICENSE](./LICENSE) - Apache 2.0 license text

---

**Last Updated**: November 2025

**Note**: This document is provided for informational purposes. It is not legal advice. Consult legal counsel if you have questions about license compliance.
