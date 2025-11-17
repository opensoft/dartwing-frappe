#!/bin/bash

echo "=========================================="
echo "Family Manager Installation"
echo "=========================================="
echo ""

cd /home/brett/projects/frappe/development/frappe-bench

# Check if bench command exists
if ! command -v bench &> /dev/null; then
    echo "Error: bench command not found."
    echo "Please make sure Frappe Bench is installed properly."
    echo ""
    echo "You can manually run these commands:"
    echo "1. Add app to sites: echo 'family_manager' >> sites/apps.txt"
    echo "2. Install app: bench --site site1.localhost install-app family_manager"
    echo "3. Migrate: bench --site site1.localhost migrate"
    exit 1
fi

echo "Step 1: Adding family_manager to apps.txt..."
if ! grep -q "family_manager" sites/apps.txt 2>/dev/null; then
    echo 'family_manager' >> sites/apps.txt
    echo "✓ Added to apps.txt"
else
    echo "✓ Already in apps.txt"
fi
echo ""

echo "Step 2: Installing app on site1.localhost..."
bench --site site1.localhost install-app family_manager
echo ""

echo "Step 3: Running migrations..."
bench --site site1.localhost migrate
echo ""

echo "Step 4: Generating API keys..."
echo "Run this in Frappe console:"
echo ""
echo "bench --site site1.localhost console"
echo ""
echo "Then paste this code:"
echo "-----------------------------------"
cat << 'EOF'
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
EOF
echo "-----------------------------------"
echo ""

echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Generate API keys using the console command above"
echo "2. Read FAMILY_MANAGER_README.md for API documentation"
echo "3. Run ./test_family_api.sh to test the endpoints"
echo ""
