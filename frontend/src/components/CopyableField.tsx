import { useState } from "react";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Copy, Check } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface CopyableFieldProps {
  label: string;
  value: string | number;
  className?: string;
}

export const CopyableField = ({ label, value, className = "" }: CopyableFieldProps) => {
  const [copied, setCopied] = useState(false);
  const { toast } = useToast();

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(String(value));
      setCopied(true);
      toast({
        title: "Copied!",
        description: `${label} copied to clipboard`,
      });
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      toast({
        title: "Copy failed",
        description: "Could not copy to clipboard",
        variant: "destructive",
      });
    }
  };

  return (
    <div className={className}>
      <div className="flex items-center justify-between mb-1">
        <Label className="text-muted-foreground">{label}</Label>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleCopy}
          className="h-6 px-2 text-xs"
        >
          {copied ? (
            <Check className="w-3 h-3 text-success" />
          ) : (
            <Copy className="w-3 h-3" />
          )}
        </Button>
      </div>
      <p className="font-medium">{value || "N/A"}</p>
    </div>
  );
};
