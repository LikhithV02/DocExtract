import { useState } from "react";
import { Navigation } from "@/components/Navigation";
import { UploadZone } from "@/components/UploadZone";
import { ReviewEdit } from "@/components/ReviewEdit";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useToast } from "@/hooks/use-toast";
import { api, fileToBase64 } from "@/lib/api";
import { Loader2, Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { sampleInvoices } from "@/lib/sampleData";

const Extract = () => {
  const [documentType, setDocumentType] = useState<"invoice" | "government_id">("invoice");
  const [isProcessing, setIsProcessing] = useState(false);
  const [extractedData, setExtractedData] = useState<any>(null);
  const [fileName, setFileName] = useState("");
  const { toast } = useToast();

  const handleFileSelect = async (file: File) => {
    setIsProcessing(true);

    try {
      const base64Data = await fileToBase64(file);

      const response = await api.extract({
        file_data: base64Data,
        file_name: file.name,
        document_type: documentType,
      });

      setExtractedData(response.extracted_data);
      setFileName(response.file_name);

      toast({
        title: "Extraction Complete!",
        description: "Review the data and save when ready",
      });
    } catch (error) {
      console.error("Extraction error:", error);
      toast({
        title: "Extraction Failed",
        description: "Failed to extract document data. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSave = async (editedData: any) => {
    try {
      await api.createDocument({
        document_type: documentType,
        file_name: fileName,
        extracted_data: editedData,
      });

      toast({
        title: "Saved Successfully!",
        description: "Document has been saved to the database",
      });

      // Reset after a short delay
      setTimeout(() => {
        handleReset();
      }, 1500);
    } catch (error) {
      console.error("Save error:", error);
      toast({
        title: "Save Failed",
        description: "Failed to save document. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleReset = () => {
    setExtractedData(null);
    setFileName("");
  };

  const loadSampleExtraction = () => {
    // Load first invoice sample for demo
    const sample = sampleInvoices[0];
    setExtractedData(sample.extracted_data);
    setFileName(sample.file_name);
    setDocumentType(sample.document_type as "invoice" | "government_id");
    
    toast({
      title: "Sample Data Loaded!",
      description: "Review and edit the sample extraction",
    });
  };

  return (
    <div className="min-h-screen bg-background">
      <Navigation />

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              Extract Document Data
            </h1>
            <p className="text-lg text-muted-foreground">
              Upload invoices or government IDs to extract structured information
            </p>
          </div>

          {!extractedData ? (
            <div className="space-y-6">
              <div className="bg-card rounded-2xl p-6 shadow-sm">
                <Label className="text-base font-semibold mb-3 block">
                  Document Type
                </Label>
                <RadioGroup
                  value={documentType}
                  onValueChange={(value) => setDocumentType(value as "invoice" | "government_id")}
                  className="flex gap-4"
                  disabled={isProcessing}
                >
                  <div className="flex items-center space-x-2 flex-1">
                    <RadioGroupItem value="invoice" id="invoice" />
                    <Label
                      htmlFor="invoice"
                      className="flex-1 cursor-pointer p-4 rounded-lg border-2 border-border hover:border-primary transition-colors"
                    >
                      <span className="font-semibold">Invoice</span>
                      <p className="text-sm text-muted-foreground mt-1">
                        Bills, receipts, and invoices
                      </p>
                    </Label>
                  </div>
                  <div className="flex items-center space-x-2 flex-1">
                    <RadioGroupItem value="government_id" id="government_id" />
                    <Label
                      htmlFor="government_id"
                      className="flex-1 cursor-pointer p-4 rounded-lg border-2 border-border hover:border-primary transition-colors"
                    >
                      <span className="font-semibold">Government ID</span>
                      <p className="text-sm text-muted-foreground mt-1">
                        Aadhaar, passport, license
                      </p>
                    </Label>
                  </div>
                </RadioGroup>
              </div>

              {isProcessing ? (
                <div className="bg-card rounded-2xl p-16 text-center">
                  <div className="flex flex-col items-center gap-4">
                    <Loader2 className="w-16 h-16 text-primary animate-spin" />
                    <h3 className="text-xl font-semibold">Processing Document...</h3>
                    <p className="text-muted-foreground">
                      Extracting data from your document
                    </p>
                  </div>
                </div>
              ) : (
                <>
                  <UploadZone onFileSelect={handleFileSelect} isProcessing={isProcessing} />
                  
                  <div className="text-center mt-4">
                    <Button
                      onClick={loadSampleExtraction}
                      variant="outline"
                      className="border-2 border-primary/30 hover:border-primary"
                    >
                      <Eye className="w-4 h-4 mr-2" />
                      View Sample Extraction
                    </Button>
                  </div>
                </>
              )}
            </div>
          ) : (
            <ReviewEdit
              data={extractedData}
              fileName={fileName}
              documentType={documentType}
              onSave={handleSave}
              onCancel={handleReset}
            />
          )}
        </div>
      </main>
    </div>
  );
};

export default Extract;
