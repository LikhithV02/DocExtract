const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api/v1";

export interface ExtractRequest {
  file_data: string;
  file_name: string;
  document_type: "invoice" | "government_id";
}

export interface ExtractResponse {
  extracted_data: any;
  file_name: string;
}

export interface Document {
  id: string;
  document_type: "invoice" | "government_id";
  file_name: string;
  extracted_data: any;
  created_at: string;
}

export interface DocumentsResponse {
  documents: Document[];
  total: number;
}

export const api = {
  async extract(data: ExtractRequest): Promise<ExtractResponse> {
    const response = await fetch(`${API_BASE_URL}/extract`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("Extraction failed");
    }

    return response.json();
  },

  async createDocument(data: {
    document_type: string;
    file_name: string;
    extracted_data: any;
  }): Promise<Document> {
    const response = await fetch(`${API_BASE_URL}/documents`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("Failed to save document");
    }

    return response.json();
  },

  async getDocuments(params?: {
    document_type?: string;
    limit?: number;
    offset?: number;
  }): Promise<DocumentsResponse> {
    const queryParams = new URLSearchParams();
    if (params?.document_type) queryParams.set("document_type", params.document_type);
    if (params?.limit) queryParams.set("limit", params.limit.toString());
    if (params?.offset) queryParams.set("offset", params.offset.toString());

    const response = await fetch(
      `${API_BASE_URL}/documents?${queryParams.toString()}`
    );

    if (!response.ok) {
      throw new Error("Failed to fetch documents");
    }

    return response.json();
  },

  async getDocument(id: string): Promise<Document> {
    const response = await fetch(`${API_BASE_URL}/documents/${id}`);

    if (!response.ok) {
      throw new Error("Document not found");
    }

    return response.json();
  },

  async deleteDocument(id: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/documents/${id}`, {
      method: "DELETE",
    });

    if (!response.ok) {
      throw new Error("Failed to delete document");
    }
  },

  async updateDocument(id: string, data: {
    extracted_data: any;
  }): Promise<Document> {
    const response = await fetch(`${API_BASE_URL}/documents/${id}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("Failed to update document");
    }

    return response.json();
  },
};

export const fileToBase64 = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      const result = reader.result as string;
      // Remove the data:image/xxx;base64, prefix
      const base64 = result.split(",")[1];
      resolve(base64);
    };
    reader.onerror = (error) => reject(error);
  });
};
