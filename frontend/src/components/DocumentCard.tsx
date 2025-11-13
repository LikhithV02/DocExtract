import { FileText, Calendar, Trash2, Eye } from "lucide-react";
import { Card, CardContent } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { Document } from "@/lib/api";
import { format } from "date-fns";

interface DocumentCardProps {
  document: Document;
  onView: (document: Document) => void;
  onDelete: (id: string) => void;
}

export const DocumentCard = ({ document, onView, onDelete }: DocumentCardProps) => {
  return (
    <Card className="overflow-hidden hover:shadow-lg transition-all duration-300 hover:scale-[1.02] bg-gradient-to-br from-card to-accent/5">
      <CardContent className="p-6">
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-primary to-accent flex items-center justify-center">
              <FileText className="w-6 h-6 text-primary-foreground" />
            </div>
            <div>
              <h3 className="font-semibold truncate max-w-[200px]" title={document.file_name}>
                {document.file_name}
              </h3>
              <div className="flex items-center gap-2 mt-1">
                <Calendar className="w-3 h-3 text-muted-foreground" />
                <span className="text-xs text-muted-foreground">
                  {format(new Date(document.created_at), "MMM dd, yyyy")}
                </span>
              </div>
            </div>
          </div>
          <Badge variant={document.document_type === "invoice" ? "default" : "secondary"}>
            {document.document_type === "invoice" ? "Invoice" : "ID"}
          </Badge>
        </div>

        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            className="flex-1"
            onClick={() => onView(document)}
          >
            <Eye className="w-4 h-4 mr-2" />
            View
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onDelete(document.id)}
            className="text-destructive hover:bg-destructive/10"
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};
