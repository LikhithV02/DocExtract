"""
Invoice document data model
"""
from pydantic import BaseModel, Field
from typing import List, Optional


class SellerInfo(BaseModel):
    """Seller information from invoice"""

    name: str
    gstin: str
    contact_numbers: List[str] = Field(default_factory=list)


class CustomerInfo(BaseModel):
    """Customer information from invoice"""

    name: str
    address: Optional[str] = None
    contact: Optional[str] = None
    gstin: Optional[str] = None


class InvoiceDetails(BaseModel):
    """Invoice metadata"""

    date: str = Field(..., description="Invoice date in YYYY-MM-DD format")
    bill_no: str
    gold_price_per_unit: Optional[float] = None


class LineItem(BaseModel):
    """Individual line item in invoice"""

    description: str
    hsn_code: Optional[str] = None
    weight: float
    wastage_allowance_percentage: Optional[float] = None
    rate: float
    making_charges_percentage: Optional[float] = None
    amount: float


class InvoiceSummary(BaseModel):
    """Invoice totals and tax summary"""

    sub_total: float
    discount: Optional[float] = None
    taxable_amount: float
    sgst_percentage: Optional[float] = None
    sgst_amount: Optional[float] = None
    cgst_percentage: Optional[float] = None
    cgst_amount: Optional[float] = None
    grand_total: float


class PaymentDetails(BaseModel):
    """Payment breakdown"""

    cash: float = 0.0
    upi: float = 0.0
    card: float = 0.0


class InvoiceData(BaseModel):
    """Complete invoice document data model matching Flutter schema"""

    seller_info: SellerInfo
    customer_info: CustomerInfo
    invoice_details: InvoiceDetails
    line_items: List[LineItem]
    summary: InvoiceSummary
    payment_details: PaymentDetails
    total_amount_in_words: Optional[str] = None

    class Config:
        json_schema_extra = {
            "example": {
                "seller_info": {
                    "name": "ABC Jewellers",
                    "gstin": "29ABCDE1234F1Z5",
                    "contact_numbers": ["+91-1234567890"],
                },
                "customer_info": {
                    "name": "John Doe",
                    "address": "123 Main St",
                    "contact": "+91-9876543210",
                    "gstin": None,
                },
                "invoice_details": {
                    "date": "2024-01-15",
                    "bill_no": "INV-001",
                    "gold_price_per_unit": 6000.0,
                },
                "line_items": [
                    {
                        "description": "Gold Ring",
                        "hsn_code": "7113",
                        "weight": 10.5,
                        "wastage_allowance_percentage": 8.0,
                        "rate": 6000.0,
                        "making_charges_percentage": 15.0,
                        "amount": 72765.0,
                    }
                ],
                "summary": {
                    "sub_total": 72765.0,
                    "discount": 0.0,
                    "taxable_amount": 72765.0,
                    "sgst_percentage": 1.5,
                    "sgst_amount": 1091.48,
                    "cgst_percentage": 1.5,
                    "cgst_amount": 1091.48,
                    "grand_total": 74947.96,
                },
                "payment_details": {"cash": 74947.96, "upi": 0.0, "card": 0.0},
                "total_amount_in_words": "Seventy Four Thousand Nine Hundred Forty Seven Rupees and Ninety Six Paise Only",
            }
        }
