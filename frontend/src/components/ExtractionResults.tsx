import { CheckCircle2, FileText, Download } from "lucide-react";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";

interface ExtractionResultsProps {
  data: any;
  fileName: string;
  documentType: "invoice" | "government_id";
  onReset: () => void;
}

export const ExtractionResults = ({
  data,
  fileName,
  documentType,
  onReset,
}: ExtractionResultsProps) => {
  // Normalize data structure - handle both direct and nested extracted_data
  const normalizedData = data?.extracted_data ? data.extracted_data : data;

  const downloadJSON = () => {
    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${fileName.split(".")[0]}_extracted.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const renderInvoiceData = (invoiceData: any) => (
    <div className="space-y-6">
      {invoiceData.seller_info && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Seller Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Name</p>
                <p className="font-medium">{invoiceData.seller_info.name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">GSTIN</p>
                <p className="font-medium">{invoiceData.seller_info.gstin}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {invoiceData.invoice_details && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Invoice Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Date</p>
                <p className="font-medium">{invoiceData.invoice_details.date}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Bill No</p>
                <p className="font-medium">{invoiceData.invoice_details.bill_no}</p>
              </div>
              {invoiceData.invoice_details.gold_price_per_unit && (
                <div>
                  <p className="text-sm text-muted-foreground">Gold Price/Unit</p>
                  <p className="font-medium">₹{invoiceData.invoice_details.gold_price_per_unit}</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {invoiceData.line_items && invoiceData.line_items.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Line Items</CardTitle>
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
                  {invoiceData.line_items.map((item: any, index: number) => (
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

      {invoiceData.payment_details && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Payment Details</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Cash</p>
                <p className="font-medium text-lg">₹{invoiceData.payment_details.cash || 0}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">UPI</p>
                <p className="font-medium text-lg">₹{invoiceData.payment_details.upi || 0}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Card</p>
                <p className="font-medium text-lg">₹{invoiceData.payment_details.card || 0}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {invoiceData.summary && (
        <Card className="border-2 border-primary/20 bg-gradient-to-br from-card to-accent/10">
          <CardHeader>
            <CardTitle className="text-lg">Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between items-center py-2 border-b">
              <span className="text-muted-foreground">Subtotal</span>
              <span className="font-medium">₹{invoiceData.summary.sub_total}</span>
            </div>
            {invoiceData.summary.discount > 0 && (
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-muted-foreground">Discount</span>
                <span className="font-medium text-destructive">-₹{invoiceData.summary.discount}</span>
              </div>
            )}
            <div className="flex justify-between items-center py-2 border-b">
              <span className="text-muted-foreground">Taxable Amount</span>
              <span className="font-medium">₹{invoiceData.summary.taxable_amount}</span>
            </div>
            {invoiceData.summary.sgst_amount > 0 && (
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-muted-foreground">SGST ({invoiceData.summary.sgst_percentage}%)</span>
                <span className="font-medium">₹{invoiceData.summary.sgst_amount}</span>
              </div>
            )}
            {invoiceData.summary.cgst_amount > 0 && (
              <div className="flex justify-between items-center py-2 border-b">
                <span className="text-muted-foreground">CGST ({invoiceData.summary.cgst_percentage}%)</span>
                <span className="font-medium">₹{invoiceData.summary.cgst_amount}</span>
              </div>
            )}
            <div className="flex justify-between items-center py-3 text-lg font-bold border-t-2">
              <span>Grand Total</span>
              <span className="text-primary">₹{invoiceData.summary.grand_total}</span>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );

  const renderGovernmentIdData = (idData: any) => (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Document Information</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {Object.entries(idData).map(([key, value]) => (
            <div key={key}>
              <p className="text-sm text-muted-foreground capitalize">
                {key.replace(/_/g, " ")}
              </p>
              <p className="font-medium">{String(value)}</p>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between p-6 rounded-2xl bg-gradient-to-r from-success/10 to-success/5 border-2 border-success/20">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-success flex items-center justify-center">
            <CheckCircle2 className="w-7 h-7 text-success-foreground" />
          </div>
          <div>
            <h3 className="text-lg font-bold">Extraction Successful!</h3>
            <p className="text-sm text-muted-foreground">{fileName}</p>
          </div>
        </div>
        <Badge variant="outline" className="border-success/50 text-success">
          {documentType === "invoice" ? "Invoice" : "Government ID"}
        </Badge>
      </div>

      <div className="flex gap-3">
        <Button
          onClick={downloadJSON}
          variant="outline"
          className="flex-1"
        >
          <Download className="w-4 h-4 mr-2" />
          Download JSON
        </Button>
        <Button
          onClick={onReset}
          variant="default"
          className="flex-1 bg-gradient-to-r from-primary to-accent hover:opacity-90"
        >
          <FileText className="w-4 h-4 mr-2" />
          Extract Another
        </Button>
      </div>

      {documentType === "invoice" ? renderInvoiceData(normalizedData) : renderGovernmentIdData(normalizedData)}
    </div>
  );
};
