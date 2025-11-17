# Copyright (c) 2025, Brett and contributors
# For license information, please see license.txt

import frappe
from frappe.model.document import Document


class Family(Document):
	"""Family Organization Document"""
	
	def validate(self):
		"""Validate the Family document before saving"""
		if not self.organization_name:
			frappe.throw("Organization Name is required")
		
		if not self.organization_type:
			self.organization_type = "Family"
		
		if not self.status:
			self.status = "Active"
	
	def before_insert(self):
		"""Called before inserting a new Family document"""
		if not self.created_date:
			self.created_date = frappe.utils.today()
	
	def on_update(self):
		"""Called after updating the Family document"""
		pass
	
	def on_trash(self):
		"""Called before deleting the Family document"""
		pass
