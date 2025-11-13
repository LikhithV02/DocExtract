import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { CopyableField } from "@/components/CopyableField";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

interface DocumentDetailsViewProps {
  data: any;
  documentType: "invoice" | "government_id";
}

export const DocumentDetailsView = ({ data, documentType }: DocumentDetailsViewProps) => {
  // Normalize data structure - handle both direct and nested extracted_data
  const normalizedData = data?.extracted_data ? data.extracted_data : data;

  if (documentType === "invoice") {
    return (
      <div className="space-y-6">
        {/* Seller Info */}
        <Card className="border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-transparent">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-primary">
              <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              Seller Information
            </CardTitle>
          </CardHeader>
          <CardContent className="grid md:grid-cols-2 gap-4">
            <CopyableField
              label="Business Name"
              value={normalizedData.seller_info?.name || "N/A"}
            />
            <CopyableField
              label="GSTIN"
              value={normalizedData.seller_info?.gstin || "N/A"}
            />
            <CopyableField
              label="Contact Numbers"
              value={normalizedData.seller_info?.contact_numbers?.join(", ") || "N/A"}
              className="md:col-span-2"
            />
          </CardContent>
        </Card>

        {/* Customer Info */}
        <Card className="border-2 border-secondary/20 bg-gradient-to-br from-secondary/5 to-transparent">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-secondary">
              <div className="w-2 h-2 rounded-full bg-secondary animate-pulse" />
              Customer Information
            </CardTitle>
          </CardHeader>
          <CardContent className="grid md:grid-cols-2 gap-4">
            <CopyableField
              label="Customer Name"
              value={normalizedData.customer_info?.name || "N/A"}
            />
            <CopyableField
              label="Contact"
              value={normalizedData.customer_info?.contact || "N/A"}
            />
            <CopyableField
              label="Address"
              value={normalizedData.customer_info?.address || "N/A"}
              className="md:col-span-2"
            />
            <CopyableField
              label="Customer GSTIN"
              value={normalizedData.customer_info?.gstin || "N/A"}
            />
          </CardContent>
        </Card>

        {/* Invoice Details */}
        <Card className="border-2 border-accent/20 bg-gradient-to-br from-accent/5 to-transparent">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-accent">
              <div className="w-2 h-2 rounded-full bg-accent animate-pulse" />
              Invoice Details
            </CardTitle>
          </CardHeader>
          <CardContent className="grid md:grid-cols-3 gap-4">
            <CopyableField
              label="Date"
              value={normalizedData.invoice_details?.date || "N/A"}
            />
            <CopyableField
              label="Bill Number"
              value={normalizedData.invoice_details?.bill_no || "N/A"}
            />
            <CopyableField
              label="Gold Price/Unit"
              value={normalizedData.invoice_details?.gold_price_per_unit || "N/A"}
            />
          </CardContent>
        </Card>

        {/* Line Items */}
        {normalizedData.line_items && normalizedData.line_items.length > 0 && (
          <Card className="border-2 border-purple-500/20 bg-gradient-to-br from-purple-500/5 to-transparent">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-purple-600">
                <div className="w-2 h-2 rounded-full bg-purple-600 animate-pulse" />
                Line Items
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Description</TableHead>
                      <TableHead>HSN Code</TableHead>
                      <TableHead className="text-right">Weight</TableHead>
                      <TableHead className="text-right">Wastage %</TableHead>
                      <TableHead className="text-right">Rate</TableHead>
                      <TableHead className="text-right">Making %</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {normalizedData.line_items.map((item: any, index: number) => (
                      <TableRow key={index}>
                        <TableCell className="font-medium">{item.description}</TableCell>
                        <TableCell>{item.hsn_code}</TableCell>
                        <TableCell className="text-right">{item.weight}</TableCell>
                        <TableCell className="text-right">{item.wastage_allowance_percentage}%</TableCell>
                        <TableCell className="text-right">₹{item.rate}</TableCell>
                        <TableCell className="text-right">{item.making_charges_percentage}%</TableCell>
                        <TableCell className="text-right font-semibold">₹{item.amount}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Payment Details */}
        {normalizedData.payment_details && (
          <Card className="border-2 border-blue-500/20 bg-gradient-to-br from-blue-500/5 to-transparent">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-blue-600">
                <div className="w-2 h-2 rounded-full bg-blue-600 animate-pulse" />
                Payment Details
              </CardTitle>
            </CardHeader>
            <CardContent className="grid md:grid-cols-3 gap-4">
              <CopyableField
                label="Cash Payment"
                value={`₹${normalizedData.payment_details.cash || 0}`}
              />
              <CopyableField
                label="UPI Payment"
                value={`₹${normalizedData.payment_details.upi || 0}`}
              />
              <CopyableField
                label="Card Payment"
                value={`₹${normalizedData.payment_details.card || 0}`}
              />
            </CardContent>
          </Card>
        )}

        {/* Summary */}
        <Card className="border-2 border-success/20 bg-gradient-to-br from-success/5 to-transparent">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-success">
              <div className="w-2 h-2 rounded-full bg-success animate-pulse" />
              Summary
            </CardTitle>
          </CardHeader>
          <CardContent className="grid md:grid-cols-2 gap-4">
            <CopyableField
              label="Subtotal"
              value={`₹${normalizedData.summary?.sub_total || "N/A"}`}
            />
            <CopyableField
              label="Discount"
              value={`₹${normalizedData.summary?.discount || "N/A"}`}
            />
            <CopyableField
              label="Taxable Amount"
              value={`₹${normalizedData.summary?.taxable_amount || "N/A"}`}
            />
            <CopyableField
              label="Grand Total"
              value={`₹${normalizedData.summary?.grand_total || "N/A"}`}
            />
          </CardContent>
        </Card>
      </div>
    );
  }

  // Government ID view
  return (
    <Card className="border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-transparent">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-primary">
          <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
          Personal Information
        </CardTitle>
      </CardHeader>
      <CardContent className="grid md:grid-cols-2 gap-4">
        <CopyableField
          label="Full Name"
          value={normalizedData.full_name || "N/A"}
        />
        <CopyableField
          label="ID Number"
          value={normalizedData.id_number || "N/A"}
        />
        <CopyableField
          label="Date of Birth"
          value={normalizedData.date_of_birth || "N/A"}
        />
        <CopyableField
          label="Gender"
          value={normalizedData.gender || "N/A"}
        />
        <CopyableField
          label="Address"
          value={normalizedData.address || "N/A"}
          className="md:col-span-2"
        />
        <CopyableField
          label="Nationality"
          value={normalizedData.nationality || "N/A"}
        />
        <CopyableField
          label="Document Type"
          value={normalizedData.document_type || "N/A"}
        />
      </CardContent>
    </Card>
  );
};
