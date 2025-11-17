#!/usr/bin/env python3
"""
Setup script for Family Manager app
This script will:
1. Install the family_manager app
2. Create the Family doctype
3. Generate API keys for testing
"""

import os
import sys
import subprocess

# Add the Frappe app to Python path
frappe_path = "/home/brett/projects/frappe/development/frappe-bench/apps/frappe"
sys.path.insert(0, frappe_path)

os.chdir("/home/brett/projects/frappe/development/frappe-bench")

# Set environment variable for Frappe site
os.environ["FRAPPE_SITE"] = "site1.localhost"

import frappe
from frappe.utils.password import get_decrypted_password


def setup_family_manager():
	"""Setup the Family Manager app"""
	print("=" * 60)
	print("Family Manager Setup")
	print("=" * 60)
	
	# Connect to site
	frappe.init(site="site1.localhost")
	frappe.connect()
	
	print("\n1. Installing family_manager app...")
	try:
		# Check if app is already installed
		if "family_manager" not in frappe.get_installed_apps():
			print("   Adding app to site...")
			frappe.commands.install_app("family_manager", site="site1.localhost")
			print("   ✓ App installed successfully")
		else:
			print("   ✓ App already installed")
	except Exception as e:
		print(f"   Note: {str(e)}")
	
	print("\n2. Creating/Updating Family doctype...")
	try:
		# The doctype should be automatically created when the app is installed
		# We can verify it exists
		if frappe.db.exists("DocType", "Family"):
			print("   ✓ Family doctype exists")
		else:
			print("   Creating Family doctype...")
			# Import and sync the doctype
			frappe.reload_doctype("Family", force=True)
			print("   ✓ Family doctype created")
	except Exception as e:
		print(f"   Note: {str(e)}")
	
	print("\n3. Generating API keys...")
	try:
		# Create API keys for Administrator user
		user = "Administrator"
		
		# Check if API keys already exist
		api_secret = frappe.get_doc("User", user)
		
		if not api_secret.api_key:
			# Generate new API key
			api_key = frappe.generate_hash(length=15)
			api_secret_key = frappe.generate_hash(length=15)
			
			frappe.db.set_value("User", user, "api_key", api_key)
			frappe.db.set_value("User", user, "api_secret", api_secret_key)
			frappe.db.commit()
			
			print(f"   ✓ API Keys generated for user: {user}")
			print(f"   API Key: {api_key}")
			print(f"   API Secret: {api_secret_key}")
		else:
			api_key = api_secret.api_key
			api_secret_key = get_decrypted_password("User", user, fieldname="api_secret")
			
			print(f"   ✓ API Keys already exist for user: {user}")
			print(f"   API Key: {api_key}")
			print(f"   API Secret: {api_secret_key}")
		
		# Save credentials to file
		with open("/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt", "w") as f:
			f.write(f"API Key: {api_key}\n")
			f.write(f"API Secret: {api_secret_key}\n")
			f.write(f"\nAuthorization Header:\n")
			f.write(f'Authorization: token {api_key}:{api_secret_key}\n')
		
		print(f"\n   ✓ Credentials saved to: api_credentials.txt")
		
	except Exception as e:
		print(f"   Error generating API keys: {str(e)}")
	
	print("\n4. API Endpoints Available:")
	print("   " + "=" * 56)
	print("   Built-in REST API (Frappe standard):")
	print("   - GET    /api/resource/Family                  (List all)")
	print("   - POST   /api/resource/Family                  (Create)")
	print("   - GET    /api/resource/Family/{name}           (Read)")
	print("   - PUT    /api/resource/Family/{name}           (Update)")
	print("   - DELETE /api/resource/Family/{name}           (Delete)")
	print()
	print("   Custom API Endpoints:")
	print("   - POST   /api/method/family_manager.api.family.create_family")
	print("   - GET    /api/method/family_manager.api.family.get_family")
	print("   - GET    /api/method/family_manager.api.family.get_all_families")
	print("   - POST   /api/method/family_manager.api.family.update_family")
	print("   - POST   /api/method/family_manager.api.family.delete_family")
	print("   - GET    /api/method/family_manager.api.family.search_families")
	print("   - GET    /api/method/family_manager.api.family.get_family_stats")
	
	print("\n" + "=" * 60)
	print("Setup Complete!")
	print("=" * 60)
	
	frappe.destroy()


if __name__ == "__main__":
	setup_family_manager()
