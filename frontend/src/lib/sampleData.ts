export const sampleInvoices = [
  {
    document_type: "invoice",
    file_name: "ABC_Jewellers_Invoice_001.pdf",
    extracted_data: {
      seller_info: {
        name: "ABC Jewellers",
        gstin: "29AABCU9603R1ZX",
        contact_numbers: ["9876543210", "9876543211"]
      },
      customer_info: {
        name: "Priya Sharma",
        address: "123 MG Road, Bangalore, Karnataka 560001",
        contact: "9988776655",
        gstin: "29AABCU9603R1ZY"
      },
      invoice_details: {
        date: "2024-01-15",
        bill_no: "INV-2024-001",
        gold_price_per_unit: 6500.00
      },
      line_items: [
        {
          description: "Gold Necklace 22K",
          weight: 25.5,
          rate: 6500.00,
          wastage_allowance_percentage: 8.0,
          making_charges_percentage: 12.0,
          amount: 198900.00,
          hsn_code: "7113"
        },
        {
          description: "Gold Earrings Pair",
          weight: 8.2,
          rate: 6500.00,
          wastage_allowance_percentage: 10.0,
          making_charges_percentage: 15.0,
          amount: 66625.00,
          hsn_code: "7113"
        }
      ],
      summary: {
        sub_total: 265525.00,
        discount: 5000.00,
        taxable_amount: 260525.00,
        sgst_percentage: 1.5,
        sgst_amount: 3907.88,
        cgst_percentage: 1.5,
        cgst_amount: 3907.88,
        grand_total: 268340.76
      },
      payment_details: {
        cash: 200000.00,
        upi: 68340.76,
        card: 0
      },
      total_amount_in_words: "Two Lakh Sixty Eight Thousand Three Hundred Forty Rupees and Seventy Six Paise Only"
    }
  },
  {
    document_type: "invoice",
    file_name: "Diamond_Palace_Receipt_045.pdf",
    extracted_data: {
      seller_info: {
        name: "Diamond Palace",
        gstin: "27AADCD1234E1Z5",
        contact_numbers: ["8765432109"]
      },
      customer_info: {
        name: "Rajesh Kumar",
        address: "456 Park Street, Mumbai, Maharashtra 400012",
        contact: "9123456789",
        gstin: null
      },
      invoice_details: {
        date: "2024-02-20",
        bill_no: "DP-045",
        gold_price_per_unit: 6750.00
      },
      line_items: [
        {
          description: "Diamond Ring 18K Gold",
          weight: 5.3,
          rate: 6750.00,
          wastage_allowance_percentage: 12.0,
          making_charges_percentage: 18.0,
          amount: 46462.50,
          hsn_code: "7113"
        }
      ],
      summary: {
        sub_total: 46462.50,
        discount: 0,
        taxable_amount: 46462.50,
        sgst_percentage: 1.5,
        sgst_amount: 696.94,
        cgst_percentage: 1.5,
        cgst_amount: 696.94,
        grand_total: 47856.38
      },
      payment_details: {
        cash: 0,
        upi: 47856.38,
        card: 0
      },
      total_amount_in_words: "Forty Seven Thousand Eight Hundred Fifty Six Rupees and Thirty Eight Paise Only"
    }
  },
  {
    document_type: "invoice",
    file_name: "Tanishq_Bill_2024_0892.pdf",
    extracted_data: {
      seller_info: {
        name: "Tanishq Jewellery",
        gstin: "29AAACT2727Q1ZV",
        contact_numbers: ["1800-266-0123"]
      },
      customer_info: {
        name: "Anita Desai",
        address: "789 Brigade Road, Bangalore, Karnataka 560025",
        contact: "9876012345",
        gstin: null
      },
      invoice_details: {
        date: "2024-03-10",
        bill_no: "TAN-0892",
        gold_price_per_unit: 6600.00
      },
      line_items: [
        {
          description: "Gold Bangle Set (2 pcs)",
          weight: 45.8,
          rate: 6600.00,
          wastage_allowance_percentage: 6.0,
          making_charges_percentage: 10.0,
          amount: 350388.00,
          hsn_code: "7113"
        },
        {
          description: "Gold Chain 22K",
          weight: 12.4,
          rate: 6600.00,
          wastage_allowance_percentage: 8.0,
          making_charges_percentage: 12.0,
          amount: 98208.00,
          hsn_code: "7113"
        }
      ],
      summary: {
        sub_total: 448596.00,
        discount: 10000.00,
        taxable_amount: 438596.00,
        sgst_percentage: 1.5,
        sgst_amount: 6578.94,
        cgst_percentage: 1.5,
        cgst_amount: 6578.94,
        grand_total: 451753.88
      },
      payment_details: {
        cash: 0,
        upi: 0,
        card: 451753.88
      },
      total_amount_in_words: "Four Lakh Fifty One Thousand Seven Hundred Fifty Three Rupees and Eighty Eight Paise Only"
    }
  },
  {
    document_type: "invoice",
    file_name: "Quick_Service_Invoice_156.pdf",
    extracted_data: {
      seller_info: {
        name: "Quick Electronics & Services",
        gstin: "27AABCS1234F1Z6",
        contact_numbers: ["9988112233"]
      },
      customer_info: {
        name: "Vikram Singh",
        address: "321 Linking Road, Mumbai, Maharashtra 400050",
        contact: "9876543210",
        gstin: null
      },
      invoice_details: {
        date: "2024-03-25",
        bill_no: "QES-156",
        gold_price_per_unit: null
      },
      line_items: [
        {
          description: "Laptop Repair Service",
          weight: null,
          rate: 3500.00,
          wastage_allowance_percentage: null,
          making_charges_percentage: null,
          amount: 3500.00,
          hsn_code: "9983"
        },
        {
          description: "Screen Replacement",
          weight: null,
          rate: 8500.00,
          wastage_allowance_percentage: null,
          making_charges_percentage: null,
          amount: 8500.00,
          hsn_code: "8471"
        }
      ],
      summary: {
        sub_total: 12000.00,
        discount: 500.00,
        taxable_amount: 11500.00,
        sgst_percentage: 9.0,
        sgst_amount: 1035.00,
        cgst_percentage: 9.0,
        cgst_amount: 1035.00,
        grand_total: 13570.00
      },
      payment_details: {
        cash: 13570.00,
        upi: 0,
        card: 0
      },
      total_amount_in_words: "Thirteen Thousand Five Hundred Seventy Rupees Only"
    }
  },
  {
    document_type: "government_id",
    file_name: "Aadhaar_Scan_001.pdf",
    extracted_data: {
      full_name: "Amit Kumar Patel",
      id_number: "1234-5678-9012",
      date_of_birth: "1990-05-15",
      gender: "Male",
      address: "House No 45, Sector 12, Gandhinagar, Gujarat 382012",
      issue_date: "2018-03-20",
      expiry_date: null,
      nationality: "Indian",
      document_type: "Aadhaar"
    }
  },
  {
    document_type: "government_id",
    file_name: "Passport_Meera_Shah.pdf",
    extracted_data: {
      full_name: "Meera Shah",
      id_number: "K1234567",
      date_of_birth: "1988-11-22",
      gender: "Female",
      address: "Flat 301, Ashoka Apartments, Pune, Maharashtra 411001",
      issue_date: "2020-01-10",
      expiry_date: "2030-01-09",
      nationality: "Indian",
      document_type: "Passport"
    }
  },
  {
    document_type: "government_id",
    file_name: "Drivers_License_RJ.pdf",
    extracted_data: {
      full_name: "Suresh Kumar Sharma",
      id_number: "RJ0620190012345",
      date_of_birth: "1985-07-08",
      gender: "Male",
      address: "123 Civil Lines, Jaipur, Rajasthan 302006",
      issue_date: "2019-06-15",
      expiry_date: "2039-06-14",
      nationality: "Indian",
      document_type: "Driver's License"
    }
  }
];
