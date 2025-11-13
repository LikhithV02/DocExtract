import { useCallback, useState } from "react";
import { Upload, Camera, FileText } from "lucide-react";
import { Button } from "./ui/button";
import { cn } from "@/lib/utils";

interface UploadZoneProps {
  onFileSelect: (file: File) => void;
  isProcessing: boolean;
}

export const UploadZone = ({ onFileSelect, isProcessing }: UploadZoneProps) => {
  const [isDragging, setIsDragging] = useState(false);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);

      const file = e.dataTransfer.files[0];
      if (file) {
        onFileSelect(file);
      }
    },
    [onFileSelect]
  );

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      onFileSelect(file);
    }
  };

  const handleCameraCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      onFileSelect(file);
    }
  };

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      className={cn(
        "relative border-2 border-dashed rounded-2xl p-12 transition-all duration-300 shadow-soft hover:shadow-medium",
        isDragging
          ? "border-primary bg-gradient-secondary/20 scale-[1.02] shadow-glow"
          : "border-primary/30 bg-gradient-card hover:border-primary/60",
        isProcessing && "opacity-50 pointer-events-none"
      )}
    >
      <div className="flex flex-col items-center gap-6 text-center">
        <div className="w-20 h-20 rounded-full bg-gradient-primary flex items-center justify-center shadow-soft">
          <FileText className="w-10 h-10 text-white" />
        </div>

        <div>
          <h3 className="text-2xl font-bold mb-2">Upload Document</h3>
          <p className="text-muted-foreground">
            Drag and drop or choose a file to extract data
          </p>
          <p className="text-sm text-muted-foreground mt-1">
            Supports PDF, PNG, JPG (Max 20MB)
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 w-full max-w-md">
          <Button
            variant="default"
            size="lg"
            className="flex-1 bg-gradient-primary hover:opacity-90 transition-opacity text-white shadow-soft hover:shadow-medium"
            onClick={() => document.getElementById("file-upload")?.click()}
            disabled={isProcessing}
          >
            <Upload className="w-5 h-5 mr-2" />
            Choose File
          </Button>

          <Button
            variant="outline"
            size="lg"
            className="flex-1 border-2 border-secondary text-secondary hover:bg-secondary hover:text-secondary-foreground transition-all"
            onClick={() => document.getElementById("camera-capture")?.click()}
            disabled={isProcessing}
          >
            <Camera className="w-5 h-5 mr-2" />
            Take Photo
          </Button>
        </div>

        <input
          id="file-upload"
          type="file"
          className="hidden"
          accept="image/*,.pdf"
          onChange={handleFileInput}
          disabled={isProcessing}
        />

        <input
          id="camera-capture"
          type="file"
          className="hidden"
          accept="image/*"
          capture="environment"
          onChange={handleCameraCapture}
          disabled={isProcessing}
        />
      </div>
    </div>
  );
};
