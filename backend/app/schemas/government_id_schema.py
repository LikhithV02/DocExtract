"""
JSON Schema for Government ID document extraction
"""


def get_government_id_schema() -> dict:
    """
    Returns JSON Schema for Government ID documents
    Matches the GovernmentIdData Pydantic model
    """
    return {
        "type": "object",
        "additionalProperties": False,
        "required": [
            "full_name",
            "id_number",
            "date_of_birth",
            "gender",
            "address",
            "issue_date",
            "nationality",
            "document_type",
        ],
        "properties": {
            "full_name": {
                "type": "string",
                "description": "Full name as it appears on the document",
            },
            "id_number": {
                "type": "string",
                "description": "Unique identification number",
            },
            "date_of_birth": {
                "type": "string",
                "description": "Date of birth in YYYY-MM-DD format",
            },
            "gender": {
                "type": "string",
                "description": "Gender (Male/Female/Other)",
            },
            "address": {
                "type": "string",
                "description": "Full address as shown on the document",
            },
            "issue_date": {
                "type": "string",
                "description": "Date of issue in YYYY-MM-DD format",
            },
            "expiry_date": {
                "type": ["string", "null"],
                "description": "Expiry date in YYYY-MM-DD format if applicable",
            },
            "nationality": {
                "type": "string",
                "description": "Nationality of the document holder",
            },
            "document_type": {
                "type": "string",
                "description": "Type of government ID (e.g., Aadhaar, Passport, Driver's License)",
            },
        },
    }
