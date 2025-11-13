import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { CopyableField } from "@/components/CopyableField";
import { Separator } from "@/components/ui/separator";

interface DocumentDetailsViewProps {
  data: any;
  documentType: "invoice" | "government_id";
}

export const DocumentDetailsView = ({ data, documentType }: DocumentDetailsViewProps) => {
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
              value={data.seller_info?.name || "N/A"}
            />
            <CopyableField
              label="GSTIN"
              value={data.seller_info?.gstin || "N/A"}
            />
            <CopyableField
              label="Contact Numbers"
              value={data.seller_info?.contact_numbers?.join(", ") || "N/A"}
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
              value={data.customer_info?.name || "N/A"}
            />
            <CopyableField
              label="Contact"
              value={data.customer_info?.contact || "N/A"}
            />
            <CopyableField
              label="Address"
              value={data.customer_info?.address || "N/A"}
              className="md:col-span-2"
            />
            <CopyableField
              label="Customer GSTIN"
              value={data.customer_info?.gstin || "N/A"}
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
              value={data.invoice_details?.date || "N/A"}
            />
            <CopyableField
              label="Bill Number"
              value={data.invoice_details?.bill_no || "N/A"}
            />
            <CopyableField
              label="Gold Price/Unit"
              value={data.invoice_details?.gold_price_per_unit || "N/A"}
            />
          </CardContent>
        </Card>

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
              value={`₹${data.summary?.sub_total || "N/A"}`}
            />
            <CopyableField
              label="Discount"
              value={`₹${data.summary?.discount || "N/A"}`}
            />
            <CopyableField
              label="Taxable Amount"
              value={`₹${data.summary?.taxable_amount || "N/A"}`}
            />
            <CopyableField
              label="Grand Total"
              value={`₹${data.summary?.grand_total || "N/A"}`}
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
          value={data.full_name || "N/A"}
        />
        <CopyableField
          label="ID Number"
          value={data.id_number || "N/A"}
        />
        <CopyableField
          label="Date of Birth"
          value={data.date_of_birth || "N/A"}
        />
        <CopyableField
          label="Gender"
          value={data.gender || "N/A"}
        />
        <CopyableField
          label="Address"
          value={data.address || "N/A"}
          className="md:col-span-2"
        />
        <CopyableField
          label="Nationality"
          value={data.nationality || "N/A"}
        />
        <CopyableField
          label="Document Type"
          value={data.document_type || "N/A"}
        />
      </CardContent>
    </Card>
  );
};
