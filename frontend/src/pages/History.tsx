import { useState, useEffect } from "react";
import { Navigation } from "@/components/Navigation";
import { DocumentDetailsView } from "@/components/DocumentDetailsView";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { api, Document } from "@/lib/api";
import { sampleInvoices } from "@/lib/sampleData";
import { Search, FileText, Loader2, Sparkles, Eye, Trash2 } from "lucide-react";
import { format } from "date-fns";

const History = () => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [filteredDocuments, setFilteredDocuments] = useState<Document[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingSamples, setIsLoadingSamples] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [filterType, setFilterType] = useState<string>("invoice");
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const { toast } = useToast();

  const fetchDocuments = async () => {
    try {
      setIsLoading(true);
      const response = await api.getDocuments({
        limit: 100,
        offset: 0,
      });
      setDocuments(response.documents);
      setFilteredDocuments(response.documents);
    } catch (error) {
      console.error("Error fetching documents:", error);
      toast({
        title: "Error",
        description: "Failed to load documents",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    // Load sample data directly for demo purposes
    const sampleDocs: Document[] = sampleInvoices.map((sample, index) => ({
      id: `sample-${index}`,
      document_type: sample.document_type as "invoice" | "government_id",
      file_name: sample.file_name,
      extracted_data: sample.extracted_data,
      created_at: new Date(Date.now() - index * 86400000).toISOString(),
    }));
    setDocuments(sampleDocs);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    let filtered = documents.filter((doc) => doc.document_type === filterType);

    if (searchQuery) {
      filtered = filtered.filter((doc) =>
        doc.file_name.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    setFilteredDocuments(filtered);
  }, [searchQuery, filterType, documents]);

  const handleDelete = async (id: string) => {
    // Delete from local state for demo
    setDocuments(documents.filter((doc) => doc.id !== id));
    toast({
      title: "Document Deleted",
      description: "Document removed successfully",
    });
  };

  const loadSampleData = async () => {
    setIsLoadingSamples(true);
    
    // Add more sample data for demo
    const newSampleDocs: Document[] = sampleInvoices.map((sample, index) => ({
      id: `additional-sample-${Date.now()}-${index}`,
      document_type: sample.document_type as "invoice" | "government_id",
      file_name: sample.file_name,
      extracted_data: sample.extracted_data,
      created_at: new Date(Date.now() - index * 3600000).toISOString(),
    }));

    setDocuments([...documents, ...newSampleDocs]);
    
    toast({
      title: "Sample Data Loaded!",
      description: `Added ${sampleInvoices.length} sample documents`,
    });
    
    setIsLoadingSamples(false);
  };

  return (
    <div className="min-h-screen bg-background">
      <Navigation />

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              Document History
            </h1>
            <p className="text-lg text-muted-foreground">
              View and manage your extracted documents
            </p>
          </div>

          <div className="bg-card rounded-2xl p-6 shadow-sm mb-6 space-y-6">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                placeholder="Search documents by filename..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>

            <div>
              <Label className="text-base font-semibold mb-3 block">Document Type</Label>
              <RadioGroup
                value={filterType}
                onValueChange={setFilterType}
                className="flex gap-3"
              >
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="invoice" id="filter-invoice" />
                  <Label htmlFor="filter-invoice" className="cursor-pointer">Invoices</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="government_id" id="filter-id" />
                  <Label htmlFor="filter-id" className="cursor-pointer">Government IDs</Label>
                </div>
              </RadioGroup>
            </div>
          </div>

          {isLoading ? (
            <div className="bg-card rounded-2xl p-16 text-center">
              <div className="flex flex-col items-center gap-4">
                <Loader2 className="w-16 h-16 text-primary animate-spin" />
                <h3 className="text-xl font-semibold">Loading Documents...</h3>
              </div>
            </div>
          ) : filteredDocuments.length === 0 ? (
            <div className="bg-card rounded-2xl p-16 text-center">
              <div className="flex flex-col items-center gap-6">
                <div className="w-20 h-20 rounded-full bg-muted flex items-center justify-center">
                  <FileText className="w-10 h-10 text-muted-foreground" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">No Documents Found</h3>
                  <p className="text-muted-foreground mb-6">
                    {searchQuery
                      ? "Try adjusting your search"
                      : "Start by extracting your first document or load sample data"}
                  </p>
                </div>
                {!searchQuery && documents.length === 0 && (
                  <Button
                    onClick={loadSampleData}
                    disabled={isLoadingSamples}
                    className="bg-gradient-to-r from-primary to-accent hover:opacity-90"
                    size="lg"
                  >
                    {isLoadingSamples ? (
                      <>
                        <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                        Loading Samples...
                      </>
                    ) : (
                      <>
                        <Sparkles className="w-5 h-5 mr-2" />
                        Load Sample Documents
                      </>
                    )}
                  </Button>
                )}
              </div>
            </div>
          ) : (
            <div>
              <div className="flex items-center justify-between mb-6">
                <p className="text-sm text-muted-foreground">
                  Showing {filteredDocuments.length} document(s)
                </p>
                <Button
                  onClick={loadSampleData}
                  disabled={isLoadingSamples}
                  variant="outline"
                  size="sm"
                >
                  {isLoadingSamples ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Loading...
                    </>
                  ) : (
                    <>
                      <Sparkles className="w-4 h-4 mr-2" />
                      Add More Samples
                    </>
                  )}
                </Button>
              </div>
              
              <div className="bg-card rounded-2xl border-2 border-primary/10 overflow-hidden shadow-soft">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-gradient-to-r from-primary/5 to-accent/5 hover:from-primary/10 hover:to-accent/10">
                      <TableHead className="font-bold">File Name</TableHead>
                      <TableHead className="font-bold">Type</TableHead>
                      <TableHead className="font-bold">Date</TableHead>
                      {filterType === "invoice" && <TableHead className="font-bold">Amount</TableHead>}
                      <TableHead className="font-bold text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredDocuments.map((document) => (
                      <TableRow key={document.id} className="hover:bg-muted/50">
                        <TableCell className="font-medium">{document.file_name}</TableCell>
                        <TableCell>
                          <Badge 
                            variant={document.document_type === "invoice" ? "default" : "secondary"}
                            className={document.document_type === "invoice" 
                              ? "bg-gradient-to-r from-primary to-accent text-white" 
                              : "bg-gradient-to-r from-secondary to-secondary/80 text-secondary-foreground"
                            }
                          >
                            {document.document_type === "invoice" ? "Invoice" : "Government ID"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {format(new Date(document.created_at), "MMM dd, yyyy")}
                        </TableCell>
                        {filterType === "invoice" && (
                          <TableCell className="font-semibold text-success">
                            ₹{document.extracted_data?.summary?.grand_total || "N/A"}
                          </TableCell>
                        )}
                        <TableCell className="text-right">
                          <div className="flex gap-2 justify-end">
                            <Button
                              onClick={() => setSelectedDocument(document)}
                              variant="outline"
                              size="sm"
                              className="border-primary/30 hover:border-primary hover:bg-primary/5"
                            >
                              <Eye className="w-4 h-4 mr-1" />
                              View
                            </Button>
                            <Button
                              onClick={() => handleDelete(document.id)}
                              variant="outline"
                              size="sm"
                              className="border-destructive/30 hover:border-destructive hover:bg-destructive/5 hover:text-destructive"
                            >
                              <Trash2 className="w-4 h-4 mr-1" />
                              Delete
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>
          )}
        </div>
      </main>

      <Dialog open={!!selectedDocument} onOpenChange={() => setSelectedDocument(null)}>
        <DialogContent className="max-w-4xl max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-2xl flex items-center gap-2">
              <FileText className="w-6 h-6 text-primary" />
              {selectedDocument?.file_name}
            </DialogTitle>
          </DialogHeader>
          <div className="mt-6">
            {selectedDocument && (
              <DocumentDetailsView 
                data={selectedDocument.extracted_data} 
                documentType={selectedDocument.document_type}
              />
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default History;
