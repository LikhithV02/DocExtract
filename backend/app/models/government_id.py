"""
Government ID document data model
"""
from pydantic import BaseModel, Field
from typing import Optional


class GovernmentIdData(BaseModel):
    """Government ID document data model matching Flutter schema"""

    full_name: str = Field(..., description="Full name on the document")
    id_number: str = Field(..., description="ID number")
    date_of_birth: str = Field(..., description="Date of birth")
    gender: str = Field(..., description="Gender")
    address: str = Field(..., description="Address")
    issue_date: str = Field(..., description="Issue date")
    expiry_date: Optional[str] = Field(None, description="Expiry date if applicable")
    nationality: str = Field(..., description="Nationality")
    document_type: str = Field(..., description="Type of government ID")

    class Config:
        json_schema_extra = {
            "example": {
                "full_name": "John Doe",
                "id_number": "ABC123456",
                "date_of_birth": "1990-01-01",
                "gender": "Male",
                "address": "123 Main St, City, State 12345",
                "issue_date": "2020-01-01",
                "expiry_date": "2030-01-01",
                "nationality": "Indian",
                "document_type": "Aadhaar Card",
            }
        }
