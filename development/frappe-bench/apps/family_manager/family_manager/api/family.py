# Copyright (c) 2025, Brett and contributors
# For license information, please see license.txt

import frappe
from frappe import _


@frappe.whitelist()
def create_family(organization_name, organization_type="Family", description=None, status="Active"):
	"""
	Create a new Family organization
	
	Args:
		organization_name (str): Name of the organization
		organization_type (str): Type of organization (Family, Business, Non-Profit, Other)
		description (str): Optional description
		status (str): Status of the organization (Active, Inactive, Archived)
	
	Returns:
		dict: Created Family document
	"""
	if not organization_name:
		frappe.throw(_("Organization Name is required"))
	
	# Check if family already exists
	if frappe.db.exists("Family", organization_name):
		frappe.throw(_("Family organization '{0}' already exists").format(organization_name))
	
	try:
		family = frappe.get_doc({
			"doctype": "Family",
			"organization_name": organization_name,
			"organization_type": organization_type,
			"description": description,
			"status": status
		})
		family.insert()
		frappe.db.commit()
		
		return {
			"success": True,
			"message": _("Family organization created successfully"),
			"data": family.as_dict()
		}
	except Exception as e:
		frappe.db.rollback()
		frappe.log_error(f"Error creating family: {str(e)}")
		frappe.throw(_("Failed to create family organization: {0}").format(str(e)))


@frappe.whitelist()
def get_family(name):
	"""
	Get a Family organization by name
	
	Args:
		name (str): Name of the family organization
	
	Returns:
		dict: Family document
	"""
	if not name:
		frappe.throw(_("Family name is required"))
	
	if not frappe.db.exists("Family", name):
		frappe.throw(_("Family organization '{0}' not found").format(name))
	
	try:
		family = frappe.get_doc("Family", name)
		return {
			"success": True,
			"data": family.as_dict()
		}
	except Exception as e:
		frappe.log_error(f"Error getting family: {str(e)}")
		frappe.throw(_("Failed to get family organization: {0}").format(str(e)))


@frappe.whitelist()
def get_all_families(filters=None, fields=None, limit_start=0, limit_page_length=20):
	"""
	Get all Family organizations with optional filters
	
	Args:
		filters (dict): Optional filters
		fields (list): Fields to return
		limit_start (int): Pagination start
		limit_page_length (int): Number of records per page
	
	Returns:
		dict: List of Family documents
	"""
	try:
		if isinstance(filters, str):
			import json
			filters = json.loads(filters)
		
		if isinstance(fields, str):
			import json
			fields = json.loads(fields)
		
		families = frappe.get_all(
			"Family",
			filters=filters or {},
			fields=fields or ["name", "organization_name", "organization_type", "status", "created_date"],
			limit_start=int(limit_start),
			limit_page_length=int(limit_page_length),
			order_by="created_date desc"
		)
		
		return {
			"success": True,
			"count": len(families),
			"data": families
		}
	except Exception as e:
		frappe.log_error(f"Error getting families: {str(e)}")
		frappe.throw(_("Failed to get family organizations: {0}").format(str(e)))


@frappe.whitelist()
def update_family(name, **kwargs):
	"""
	Update a Family organization
	
	Args:
		name (str): Name of the family organization
		**kwargs: Fields to update
	
	Returns:
		dict: Updated Family document
	"""
	if not name:
		frappe.throw(_("Family name is required"))
	
	if not frappe.db.exists("Family", name):
		frappe.throw(_("Family organization '{0}' not found").format(name))
	
	try:
		family = frappe.get_doc("Family", name)
		
		# Update allowed fields
		allowed_fields = ["organization_type", "description", "status"]
		for field in allowed_fields:
			if field in kwargs:
				setattr(family, field, kwargs[field])
		
		family.save()
		frappe.db.commit()
		
		return {
			"success": True,
			"message": _("Family organization updated successfully"),
			"data": family.as_dict()
		}
	except Exception as e:
		frappe.db.rollback()
		frappe.log_error(f"Error updating family: {str(e)}")
		frappe.throw(_("Failed to update family organization: {0}").format(str(e)))


@frappe.whitelist()
def delete_family(name):
	"""
	Delete a Family organization
	
	Args:
		name (str): Name of the family organization
	
	Returns:
		dict: Success message
	"""
	if not name:
		frappe.throw(_("Family name is required"))
	
	if not frappe.db.exists("Family", name):
		frappe.throw(_("Family organization '{0}' not found").format(name))
	
	try:
		frappe.delete_doc("Family", name)
		frappe.db.commit()
		
		return {
			"success": True,
			"message": _("Family organization deleted successfully")
		}
	except Exception as e:
		frappe.db.rollback()
		frappe.log_error(f"Error deleting family: {str(e)}")
		frappe.throw(_("Failed to delete family organization: {0}").format(str(e)))


@frappe.whitelist()
def search_families(query, limit=20):
	"""
	Search for Family organizations by name or description
	
	Args:
		query (str): Search query
		limit (int): Maximum number of results
	
	Returns:
		dict: List of matching Family documents
	"""
	if not query:
		frappe.throw(_("Search query is required"))
	
	try:
		families = frappe.get_all(
			"Family",
			filters=[
				["organization_name", "like", f"%{query}%"]
			],
			or_filters=[
				["description", "like", f"%{query}%"]
			],
			fields=["name", "organization_name", "organization_type", "status", "description"],
			limit=int(limit)
		)
		
		return {
			"success": True,
			"count": len(families),
			"data": families
		}
	except Exception as e:
		frappe.log_error(f"Error searching families: {str(e)}")
		frappe.throw(_("Failed to search family organizations: {0}").format(str(e)))


@frappe.whitelist()
def get_family_stats():
	"""
	Get statistics about Family organizations
	
	Returns:
		dict: Statistics about families
	"""
	try:
		total = frappe.db.count("Family")
		active = frappe.db.count("Family", {"status": "Active"})
		inactive = frappe.db.count("Family", {"status": "Inactive"})
		archived = frappe.db.count("Family", {"status": "Archived"})
		
		by_type = {}
		types = frappe.get_all("Family", fields=["organization_type", "count(*) as count"], group_by="organization_type")
		for t in types:
			by_type[t.organization_type] = t.count
		
		return {
			"success": True,
			"data": {
				"total": total,
				"by_status": {
					"active": active,
					"inactive": inactive,
					"archived": archived
				},
				"by_type": by_type
			}
		}
	except Exception as e:
		frappe.log_error(f"Error getting family stats: {str(e)}")
		frappe.throw(_("Failed to get family statistics: {0}").format(str(e)))
