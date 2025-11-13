import { useState, useEffect } from "react";
import { Navigation } from "@/components/Navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { api, Document } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";
import { FileText, TrendingUp, Calendar, DollarSign, Loader2 } from "lucide-react";
import { format, startOfMonth, endOfMonth, parseISO } from "date-fns";

const Statistics = () => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    fetchDocuments();
  }, []);

  const fetchDocuments = async () => {
    try {
      setIsLoading(true);
      const response = await api.getDocuments({
        limit: 1000,
        offset: 0,
      });
      setDocuments(response.documents);
    } catch (error) {
      console.error("Error fetching documents:", error);
      toast({
        title: "Error",
        description: "Failed to load statistics",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const stats = {
    totalDocuments: documents.length,
    invoices: documents.filter(d => d.document_type === 'invoice').length,
    governmentIds: documents.filter(d => d.document_type === 'government_id').length,
    thisMonth: documents.filter(d => {
      const docDate = parseISO(d.created_at);
      const now = new Date();
      return docDate >= startOfMonth(now) && docDate <= endOfMonth(now);
    }).length,
    totalRevenue: documents
      .filter(d => d.document_type === 'invoice')
      .reduce((sum, d) => sum + (d.extracted_data?.summary?.grand_total || 0), 0),
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background">
        <Navigation />
        <main className="container mx-auto px-4 py-8">
          <div className="flex flex-col items-center justify-center min-h-[60vh]">
            <Loader2 className="w-16 h-16 text-primary animate-spin mb-4" />
            <h3 className="text-xl font-semibold">Loading Statistics...</h3>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navigation />

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              Statistics Dashboard
            </h1>
            <p className="text-lg text-muted-foreground">
              Overview of your document extraction activity
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 mb-8">
            <Card className="border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-transparent hover:shadow-lg transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total Documents
                </CardTitle>
                <FileText className="w-5 h-5 text-primary" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-primary">{stats.totalDocuments}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  All time
                </p>
              </CardContent>
            </Card>

            <Card className="border-2 border-accent/20 bg-gradient-to-br from-accent/5 to-transparent hover:shadow-lg transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  This Month
                </CardTitle>
                <Calendar className="w-5 h-5 text-accent" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-accent">{stats.thisMonth}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {format(new Date(), 'MMMM yyyy')}
                </p>
              </CardContent>
            </Card>

            <Card className="border-2 border-secondary/20 bg-gradient-to-br from-secondary/5 to-transparent hover:shadow-lg transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Invoices
                </CardTitle>
                <TrendingUp className="w-5 h-5 text-secondary" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-secondary">{stats.invoices}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {stats.governmentIds} Government IDs
                </p>
              </CardContent>
            </Card>

            <Card className="border-2 border-success/20 bg-gradient-to-br from-success/5 to-transparent hover:shadow-lg transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total Revenue
                </CardTitle>
                <DollarSign className="w-5 h-5 text-success" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-success">
                  ₹{stats.totalRevenue.toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  From {stats.invoices} invoices
                </p>
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            <Card className="border-2 border-primary/10">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-primary" />
                  Document Type Distribution
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <div className="flex justify-between mb-2">
                      <span className="text-sm font-medium">Invoices</span>
                      <span className="text-sm text-muted-foreground">
                        {stats.totalDocuments > 0
                          ? Math.round((stats.invoices / stats.totalDocuments) * 100)
                          : 0}%
                      </span>
                    </div>
                    <div className="h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-primary to-accent transition-all"
                        style={{
                          width: `${stats.totalDocuments > 0
                            ? (stats.invoices / stats.totalDocuments) * 100
                            : 0}%`
                        }}
                      />
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between mb-2">
                      <span className="text-sm font-medium">Government IDs</span>
                      <span className="text-sm text-muted-foreground">
                        {stats.totalDocuments > 0
                          ? Math.round((stats.governmentIds / stats.totalDocuments) * 100)
                          : 0}%
                      </span>
                    </div>
                    <div className="h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-secondary to-secondary/80 transition-all"
                        style={{
                          width: `${stats.totalDocuments > 0
                            ? (stats.governmentIds / stats.totalDocuments) * 100
                            : 0}%`
                        }}
                      />
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-2 border-primary/10">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-primary" />
                  Quick Facts
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex justify-between items-center py-2 border-b">
                    <span className="text-sm text-muted-foreground">Average Invoice Value</span>
                    <span className="font-semibold">
                      ₹{stats.invoices > 0
                        ? Math.round(stats.totalRevenue / stats.invoices).toLocaleString()
                        : 0}
                    </span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b">
                    <span className="text-sm text-muted-foreground">Documents This Month</span>
                    <span className="font-semibold">{stats.thisMonth}</span>
                  </div>
                  <div className="flex justify-between items-center py-2">
                    <span className="text-sm text-muted-foreground">Most Common Type</span>
                    <span className="font-semibold">
                      {stats.invoices > stats.governmentIds ? 'Invoice' : 'Government ID'}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Statistics;
