"""
JSON Schema for Invoice (Indian GST Format) document extraction
"""


def get_invoice_schema() -> dict:
    """
    Returns JSON Schema for Invoice documents (Indian GST Format)
    Matches the InvoiceData Pydantic model
    """
    return {
        "type": "object",
        "additionalProperties": False,
        "required": [
            "seller_info",
            "customer_info",
            "invoice_details",
            "line_items",
            "summary",
            "payment_details",
        ],
        "properties": {
            "seller_info": {
                "type": "object",
                "required": ["name", "gstin"],
                "properties": {
                    "name": {"type": "string", "description": "Seller business name"},
                    "gstin": {
                        "type": "string",
                        "description": "Seller GST Identification Number",
                    },
                    "contact_numbers": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Seller contact phone numbers",
                    },
                },
            },
            "customer_info": {
                "type": "object",
                "required": ["name"],
                "properties": {
                    "name": {"type": "string", "description": "Customer name"},
                    "address": {
                        "type": ["string", "null"],
                        "description": "Customer address",
                    },
                    "contact": {
                        "type": ["string", "null"],
                        "description": "Customer contact number",
                    },
                    "gstin": {
                        "type": ["string", "null"],
                        "description": "Customer GST Identification Number",
                    },
                },
            },
            "invoice_details": {
                "type": "object",
                "required": ["date", "bill_no"],
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Invoice date in YYYY-MM-DD format",
                    },
                    "bill_no": {
                        "type": "string",
                        "description": "Invoice/Bill number",
                    },
                    "gold_price_per_unit": {
                        "type": ["number", "null"],
                        "description": "Gold price per unit (for jewelry invoices)",
                    },
                },
            },
            "line_items": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["description", "weight", "rate", "amount"],
                    "properties": {
                        "description": {
                            "type": "string",
                            "description": "Item description",
                        },
                        "hsn_code": {
                            "type": ["string", "null"],
                            "description": "HSN code for the item",
                        },
                        "weight": {
                            "type": "number",
                            "description": "Item weight in grams",
                        },
                        "wastage_allowance_percentage": {
                            "type": ["number", "null"],
                            "description": "Wastage allowance percentage",
                        },
                        "rate": {"type": "number", "description": "Rate per unit"},
                        "making_charges_percentage": {
                            "type": ["number", "null"],
                            "description": "Making charges as percentage",
                        },
                        "amount": {"type": "number", "description": "Line item total"},
                    },
                },
            },
            "summary": {
                "type": "object",
                "required": ["sub_total", "taxable_amount", "grand_total"],
                "properties": {
                    "sub_total": {"type": "number", "description": "Subtotal amount"},
                    "discount": {
                        "type": ["number", "null"],
                        "description": "Discount amount",
                    },
                    "taxable_amount": {
                        "type": "number",
                        "description": "Taxable amount",
                    },
                    "sgst_percentage": {
                        "type": ["number", "null"],
                        "description": "SGST percentage",
                    },
                    "sgst_amount": {
                        "type": ["number", "null"],
                        "description": "SGST amount",
                    },
                    "cgst_percentage": {
                        "type": ["number", "null"],
                        "description": "CGST percentage",
                    },
                    "cgst_amount": {
                        "type": ["number", "null"],
                        "description": "CGST amount",
                    },
                    "grand_total": {
                        "type": "number",
                        "description": "Grand total amount",
                    },
                },
            },
            "payment_details": {
                "type": "object",
                "properties": {
                    "cash": {"type": "number", "description": "Cash payment amount"},
                    "upi": {"type": "number", "description": "UPI payment amount"},
                    "card": {"type": "number", "description": "Card payment amount"},
                },
            },
            "total_amount_in_words": {
                "type": ["string", "null"],
                "description": "Total amount in words",
            },
        },
    }
