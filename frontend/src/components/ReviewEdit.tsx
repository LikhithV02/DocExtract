import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Check, X, Edit2, Save } from "lucide-react";

interface ReviewEditProps {
  data: any;
  fileName: string;
  documentType: "invoice" | "government_id";
  onSave: (editedData: any) => void;
  onCancel: () => void;
}

export const ReviewEdit = ({ data, fileName, documentType, onSave, onCancel }: ReviewEditProps) => {
  const [editedData, setEditedData] = useState(data);
  const [isEditing, setIsEditing] = useState(false);

  const handleSave = () => {
    onSave(editedData);
  };

  const updateNestedValue = (path: string[], value: any) => {
    const newData = JSON.parse(JSON.stringify(editedData));
    let current = newData;
    
    for (let i = 0; i < path.length - 1; i++) {
      if (!current[path[i]]) current[path[i]] = {};
      current = current[path[i]];
    }
    
    current[path[path.length - 1]] = value;
    setEditedData(newData);
  };

  const renderInvoiceFields = () => (
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
            <Label htmlFor="seller-name">Business Name</Label>
            <Input
              id="seller-name"
              value={editedData.seller_info?.name || ""}
              onChange={(e) => updateNestedValue(["seller_info", "name"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="seller-gstin">GSTIN</Label>
            <Input
              id="seller-gstin"
              value={editedData.seller_info?.gstin || ""}
              onChange={(e) => updateNestedValue(["seller_info", "gstin"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div className="md:col-span-2">
            <Label htmlFor="seller-contact">Contact Numbers</Label>
            <Input
              id="seller-contact"
              value={editedData.seller_info?.contact_numbers?.join(", ") || ""}
              onChange={(e) => updateNestedValue(["seller_info", "contact_numbers"], e.target.value.split(",").map((s: string) => s.trim()))}
              disabled={!isEditing}
              className="bg-background/50"
              placeholder="Comma separated numbers"
            />
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
            <Label htmlFor="customer-name">Customer Name</Label>
            <Input
              id="customer-name"
              value={editedData.customer_info?.name || ""}
              onChange={(e) => updateNestedValue(["customer_info", "name"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="customer-contact">Contact</Label>
            <Input
              id="customer-contact"
              value={editedData.customer_info?.contact || ""}
              onChange={(e) => updateNestedValue(["customer_info", "contact"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div className="md:col-span-2">
            <Label htmlFor="customer-address">Address</Label>
            <Textarea
              id="customer-address"
              value={editedData.customer_info?.address || ""}
              onChange={(e) => updateNestedValue(["customer_info", "address"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="customer-gstin">Customer GSTIN</Label>
            <Input
              id="customer-gstin"
              value={editedData.customer_info?.gstin || ""}
              onChange={(e) => updateNestedValue(["customer_info", "gstin"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
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
            <Label htmlFor="invoice-date">Date</Label>
            <Input
              id="invoice-date"
              type="date"
              value={editedData.invoice_details?.date || ""}
              onChange={(e) => updateNestedValue(["invoice_details", "date"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="invoice-bill-no">Bill Number</Label>
            <Input
              id="invoice-bill-no"
              value={editedData.invoice_details?.bill_no || ""}
              onChange={(e) => updateNestedValue(["invoice_details", "bill_no"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="invoice-gold-price">Gold Price/Unit</Label>
            <Input
              id="invoice-gold-price"
              type="number"
              value={editedData.invoice_details?.gold_price_per_unit || ""}
              onChange={(e) => updateNestedValue(["invoice_details", "gold_price_per_unit"], parseFloat(e.target.value))}
              disabled={!isEditing}
              className="bg-background/50"
            />
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
            <Label htmlFor="subtotal">Subtotal</Label>
            <Input
              id="subtotal"
              type="number"
              value={editedData.summary?.sub_total || ""}
              onChange={(e) => updateNestedValue(["summary", "sub_total"], parseFloat(e.target.value))}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="discount">Discount</Label>
            <Input
              id="discount"
              type="number"
              value={editedData.summary?.discount || ""}
              onChange={(e) => updateNestedValue(["summary", "discount"], parseFloat(e.target.value))}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="taxable">Taxable Amount</Label>
            <Input
              id="taxable"
              type="number"
              value={editedData.summary?.taxable_amount || ""}
              onChange={(e) => updateNestedValue(["summary", "taxable_amount"], parseFloat(e.target.value))}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="grand-total">Grand Total</Label>
            <Input
              id="grand-total"
              type="number"
              value={editedData.summary?.grand_total || ""}
              onChange={(e) => updateNestedValue(["summary", "grand_total"], parseFloat(e.target.value))}
              disabled={!isEditing}
              className="bg-background/50 font-bold text-lg"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );

  const renderGovIdFields = () => (
    <div className="space-y-6">
      <Card className="border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-transparent">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-primary">
            <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
            Personal Information
          </CardTitle>
        </CardHeader>
        <CardContent className="grid md:grid-cols-2 gap-4">
          <div>
            <Label htmlFor="full-name">Full Name</Label>
            <Input
              id="full-name"
              value={editedData.full_name || ""}
              onChange={(e) => updateNestedValue(["full_name"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="id-number">ID Number</Label>
            <Input
              id="id-number"
              value={editedData.id_number || ""}
              onChange={(e) => updateNestedValue(["id_number"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="dob">Date of Birth</Label>
            <Input
              id="dob"
              type="date"
              value={editedData.date_of_birth || ""}
              onChange={(e) => updateNestedValue(["date_of_birth"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="gender">Gender</Label>
            <Input
              id="gender"
              value={editedData.gender || ""}
              onChange={(e) => updateNestedValue(["gender"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div className="md:col-span-2">
            <Label htmlFor="address">Address</Label>
            <Textarea
              id="address"
              value={editedData.address || ""}
              onChange={(e) => updateNestedValue(["address"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="nationality">Nationality</Label>
            <Input
              id="nationality"
              value={editedData.nationality || ""}
              onChange={(e) => updateNestedValue(["nationality"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
          <div>
            <Label htmlFor="doc-type">Document Type</Label>
            <Input
              id="doc-type"
              value={editedData.document_type || ""}
              onChange={(e) => updateNestedValue(["document_type"], e.target.value)}
              disabled={!isEditing}
              className="bg-background/50"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Header */}
      <Card className="bg-gradient-primary border-0 text-primary-foreground shadow-glow">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-3xl flex items-center gap-3">
                <Check className="w-8 h-8" />
                Review & Edit Data
              </CardTitle>
              <CardDescription className="text-primary-foreground/80 mt-2">
                File: {fileName}
              </CardDescription>
            </div>
            <Button
              onClick={() => setIsEditing(!isEditing)}
              variant={isEditing ? "secondary" : "outline"}
              size="lg"
              className={isEditing ? "bg-secondary text-secondary-foreground" : "bg-white/10 hover:bg-white/20 text-white border-white/30"}
            >
              {isEditing ? (
                <>
                  <Save className="w-4 h-4 mr-2" />
                  Editing Mode
                </>
              ) : (
                <>
                  <Edit2 className="w-4 h-4 mr-2" />
                  Enable Editing
                </>
              )}
            </Button>
          </div>
        </CardHeader>
      </Card>

      {/* Fields */}
      {documentType === "invoice" ? renderInvoiceFields() : renderGovIdFields()}

      <Separator className="my-6" />

      {/* Actions */}
      <div className="flex gap-4 justify-end sticky bottom-4 bg-background/80 backdrop-blur-sm p-4 rounded-lg border-2 border-primary/20 shadow-medium">
        <Button
          onClick={onCancel}
          variant="outline"
          size="lg"
          className="border-2"
        >
          <X className="w-4 h-4 mr-2" />
          Cancel
        </Button>
        <Button
          onClick={handleSave}
          size="lg"
          className="bg-gradient-success text-white shadow-soft hover:shadow-medium transition-all"
        >
          <Check className="w-4 h-4 mr-2" />
          Save to Database
        </Button>
      </div>
    </div>
  );
};
