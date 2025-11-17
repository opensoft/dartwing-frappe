"""
Run this script using: 
cd /home/brett/projects/frappe/development/frappe-bench
./env/bin/python -m frappe.utils.bench --site site1.localhost console < setup_family.py

Or manually in console:
./env/bin/python -m frappe.utils.bench --site site1.localhost console
Then paste the code below.
"""

import frappe
from frappe.utils.password import get_decrypted_password

print("=" * 60)
print("Family Manager Setup")
print("=" * 60)

# Install the app
print("\n1. Installing family_manager app...")
try:
    apps = frappe.get_installed_apps()
    if "family_manager" not in apps:
        print("   Note: App needs to be installed via bench install-app")
        print("   Run: bench --site site1.localhost install-app family_manager")
    else:
        print("   ✓ App already installed")
except Exception as e:
    print(f"   Note: {str(e)}")

# Migrate to create tables
print("\n2. Running migrations...")
try:
    frappe.db.commit()
    print("   ✓ Database committed")
except Exception as e:
    print(f"   Note: {str(e)}")

# Generate API keys
print("\n3. Generating API keys for Administrator...")
try:
    user = "Administrator"
    user_doc = frappe.get_doc("User", user)
    
    if not user_doc.api_key:
        api_key = frappe.generate_hash(length=15)
        api_secret = frappe.generate_hash(length=15)
        
        user_doc.api_key = api_key
        user_doc.api_secret = api_secret
        user_doc.save(ignore_permissions=True)
        frappe.db.commit()
        
        print(f"   ✓ API Keys generated")
        print(f"   API Key: {api_key}")
        print(f"   API Secret: {api_secret}")
        
        # Save to file
        with open("/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt", "w") as f:
            f.write(f"API Key: {api_key}\n")
            f.write(f"API Secret: {api_secret}\n")
            f.write(f"\nAuthorization Header:\n")
            f.write(f"Authorization: token {api_key}:{api_secret}\n")
        print("   ✓ Credentials saved to api_credentials.txt")
    else:
        api_key = user_doc.api_key
        try:
            api_secret = get_decrypted_password("User", user, fieldname="api_secret")
        except:
            api_secret = "[encrypted]"
        
        print(f"   ✓ API Keys already exist")
        print(f"   API Key: {api_key}")
        print(f"   API Secret: {api_secret}")
        
        # Save to file
        with open("/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt", "w") as f:
            f.write(f"API Key: {api_key}\n")
            f.write(f"API Secret: {api_secret}\n")
            f.write(f"\nAuthorization Header:\n")
            f.write(f"Authorization: token {api_key}:{api_secret}\n")
        print("   ✓ Credentials saved to api_credentials.txt")
        
except Exception as e:
    print(f"   Error: {str(e)}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
print("Setup steps to complete:")
print("=" * 60)
print("1. Add family_manager to apps.txt:")
print("   echo 'family_manager' >> sites/apps.txt")
print("")
print("2. Install the app:")
print("   bench --site site1.localhost install-app family_manager")
print("")  
print("3. Run migrations:")
print("   bench --site site1.localhost migrate")
print("=" * 60)
