import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
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
            <div>
              <Label className="text-muted-foreground">Business Name</Label>
              <p className="font-medium mt-1">{data.seller_info?.name || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">GSTIN</Label>
              <p className="font-medium mt-1">{data.seller_info?.gstin || "N/A"}</p>
            </div>
            <div className="md:col-span-2">
              <Label className="text-muted-foreground">Contact Numbers</Label>
              <p className="font-medium mt-1">{data.seller_info?.contact_numbers?.join(", ") || "N/A"}</p>
            </div>
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
            <div>
              <Label className="text-muted-foreground">Customer Name</Label>
              <p className="font-medium mt-1">{data.customer_info?.name || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Contact</Label>
              <p className="font-medium mt-1">{data.customer_info?.contact || "N/A"}</p>
            </div>
            <div className="md:col-span-2">
              <Label className="text-muted-foreground">Address</Label>
              <p className="font-medium mt-1">{data.customer_info?.address || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Customer GSTIN</Label>
              <p className="font-medium mt-1">{data.customer_info?.gstin || "N/A"}</p>
            </div>
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
            <div>
              <Label className="text-muted-foreground">Date</Label>
              <p className="font-medium mt-1">{data.invoice_details?.date || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Bill Number</Label>
              <p className="font-medium mt-1">{data.invoice_details?.bill_no || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Gold Price/Unit</Label>
              <p className="font-medium mt-1">{data.invoice_details?.gold_price_per_unit || "N/A"}</p>
            </div>
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
            <div>
              <Label className="text-muted-foreground">Subtotal</Label>
              <p className="font-medium mt-1">₹{data.summary?.sub_total || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Discount</Label>
              <p className="font-medium mt-1">₹{data.summary?.discount || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Taxable Amount</Label>
              <p className="font-medium mt-1">₹{data.summary?.taxable_amount || "N/A"}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Grand Total</Label>
              <p className="font-bold text-lg mt-1">₹{data.summary?.grand_total || "N/A"}</p>
            </div>
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
        <div>
          <Label className="text-muted-foreground">Full Name</Label>
          <p className="font-medium mt-1">{data.full_name || "N/A"}</p>
        </div>
        <div>
          <Label className="text-muted-foreground">ID Number</Label>
          <p className="font-medium mt-1">{data.id_number || "N/A"}</p>
        </div>
        <div>
          <Label className="text-muted-foreground">Date of Birth</Label>
          <p className="font-medium mt-1">{data.date_of_birth || "N/A"}</p>
        </div>
        <div>
          <Label className="text-muted-foreground">Gender</Label>
          <p className="font-medium mt-1">{data.gender || "N/A"}</p>
        </div>
        <div className="md:col-span-2">
          <Label className="text-muted-foreground">Address</Label>
          <p className="font-medium mt-1">{data.address || "N/A"}</p>
        </div>
        <div>
          <Label className="text-muted-foreground">Nationality</Label>
          <p className="font-medium mt-1">{data.nationality || "N/A"}</p>
        </div>
        <div>
          <Label className="text-muted-foreground">Document Type</Label>
          <p className="font-medium mt-1">{data.document_type || "N/A"}</p>
        </div>
      </CardContent>
    </Card>
  );
};
