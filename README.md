# DocExtract

A Flutter mobile and web application for extracting information from documents using LlamaParse AI. This app specializes in processing government IDs and invoices, making it easy to digitize and store document information.

## Features

- 📸 **Capture photos** directly from your device camera (Android only)
- 📁 **Upload images** (JPG, PNG) or PDF documents
- 🆔 **Government ID extraction** - Extract information from passports, driver's licenses, national IDs, etc.
- 🧾 **Invoice extraction** - Extract details from bills, receipts, and purchase orders
- ✏️ **Edit before saving** - Review and edit all extracted data before saving to database
- 🔄 **Real-time sync** - Data extracted on mobile appears instantly on web app (and vice versa)
- 💾 **Supabase integration** - Securely store all extracted documents in the cloud
- 📱 **Cross-platform** - Runs on Android and as a web application
- 📜 **History view** - Browse and manage all previously extracted documents

## Technology Stack

- **Flutter/Dart** - Cross-platform UI framework
- **LlamaParse** - AI-powered document parsing and extraction
- **Supabase** - Backend database and authentication
- **Provider** - State management
- **Image Picker** - Camera and gallery access
- **File Picker** - File upload functionality

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- A [Supabase](https://supabase.com) account
- A [LlamaCloud](https://cloud.llamaindex.ai) API key

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/DocExtract.git
cd DocExtract
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Supabase

1. Go to [Supabase](https://supabase.com) and create a new project
2. Once your project is created, go to **Settings** > **API**
3. Copy your **Project URL** and **anon public** key
4. In your Supabase project, create the following table:

```sql
-- Create the extracted_documents table
CREATE TABLE extracted_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type TEXT NOT NULL,
  file_name TEXT NOT NULL,
  extracted_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index for faster queries
CREATE INDEX idx_document_type ON extracted_documents(document_type);
CREATE INDEX idx_created_at ON extracted_documents(created_at DESC);

-- Enable Realtime for the table (for real-time sync across devices)
ALTER PUBLICATION supabase_realtime ADD TABLE extracted_documents;
```

5. **Enable Realtime** in your Supabase project:
   - Go to **Database** > **Replication** in your Supabase dashboard
   - Find the `extracted_documents` table
   - Enable replication for the table to allow real-time updates

### 4. Set Up LlamaParse

1. Go to [LlamaCloud](https://cloud.llamaindex.ai)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key and copy it

### 5. Configure Environment Variables

You have two options to configure your API keys:

#### Option A: Using Dart Define (Recommended)

Run the app with your API keys as command-line arguments:

```bash
flutter run --dart-define=SUPABASE_URL=your_supabase_url \
            --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key \
            --dart-define=LLAMA_CLOUD_API_KEY=your_llama_api_key
```

#### Option B: Direct Code Modification (For Testing Only)

Edit `lib/main.dart` and `lib/services/llama_parse_service.dart` to replace placeholder values:

**In `lib/main.dart`:**
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

**In `lib/screens/document_type_selection_screen.dart`:**
```dart
const apiKey = 'YOUR_LLAMA_CLOUD_API_KEY';
```

> ⚠️ **Warning:** Never commit API keys directly in your code. Use environment variables or a secure configuration management solution.

## Running the Application

### Android

1. Connect an Android device or start an emulator
2. Run the following command:

```bash
flutter run
```

Or with environment variables:

```bash
flutter run --dart-define=SUPABASE_URL=your_url \
            --dart-define=SUPABASE_ANON_KEY=your_key \
            --dart-define=LLAMA_CLOUD_API_KEY=your_key
```

### Web

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=your_url \
                      --dart-define=SUPABASE_ANON_KEY=your_key \
                      --dart-define=LLAMA_CLOUD_API_KEY=your_key
```

Or to build for web deployment:

```bash
flutter build web --release --dart-define=SUPABASE_URL=your_url \
                            --dart-define=SUPABASE_ANON_KEY=your_key \
                            --dart-define=LLAMA_CLOUD_API_KEY=your_key
```

The built files will be in the `build/web` directory.

## Building for Production

### Android APK

```bash
flutter build apk --release --dart-define=SUPABASE_URL=your_url \
                             --dart-define=SUPABASE_ANON_KEY=your_key \
                             --dart-define=LLAMA_CLOUD_API_KEY=your_key
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release --dart-define=SUPABASE_URL=your_url \
                                  --dart-define=SUPABASE_ANON_KEY=your_key \
                                  --dart-define=LLAMA_CLOUD_API_KEY=your_key
```

## Project Structure

```
DocExtract/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   └── extracted_document.dart        # Document data model
│   ├── providers/
│   │   └── document_provider.dart         # State management with real-time sync
│   ├── screens/
│   │   ├── home_screen.dart               # Main screen
│   │   ├── document_type_selection_screen.dart
│   │   ├── edit_extraction_screen.dart    # Edit extracted data before saving
│   │   ├── extraction_result_screen.dart  # Results display
│   │   └── history_screen.dart            # Document history
│   └── services/
│       ├── llama_parse_service.dart       # LlamaParse API integration
│       └── supabase_service.dart          # Supabase database operations
├── android/                               # Android platform files
├── web/                                   # Web platform files
└── pubspec.yaml                          # Dependencies
```

## How to Use

1. **Launch the app** on your Android device or web browser
2. **Choose an input method:**
   - Take a photo (Android only)
   - Choose from gallery
   - Upload a PDF or image file
3. **Select document type:**
   - Government ID
   - Invoice
4. **Wait for extraction** - The app will process your document using LlamaParse
5. **Review and edit** - Check the extracted data and make any necessary corrections
6. **Save to database** - Confirm to save the document (will sync in real-time across all devices)
7. **Access history** - Tap the history icon to view all previously extracted documents

### Real-time Sync

Once you save a document on one device (e.g., mobile), it will **instantly appear** on all other devices running the app (e.g., web browser) thanks to Supabase Realtime. No need to refresh!

## Extracted Data

### Government ID
- Full Name
- ID Number
- Date of Birth
- Gender
- Address
- Issue Date
- Expiry Date
- Nationality
- Document Type

### Invoice (Detailed Indian GST Invoice)
**Seller Information:**
- Seller Name
- GSTIN (Goods and Services Tax Identification Number)
- Contact Numbers

**Customer Information:**
- Customer Name
- Billing Address
- Contact Number
- GSTIN

**Invoice Details:**
- Invoice Date
- Bill Number
- Gold Price per Unit (for jewelry invoices)

**Line Items:** (For each item)
- Description
- HSN Code (Harmonized System of Nomenclature)
- Weight
- Wastage Allowance Percentage
- Rate
- Making Charges Percentage
- Amount

**Financial Summary:**
- Subtotal
- Discount
- Taxable Amount
- SGST (State GST) Percentage & Amount
- CGST (Central GST) Percentage & Amount
- Grand Total

**Payment Details:**
- Cash Amount
- UPI Amount
- Card Amount

**Additional:**
- Total Amount in Words

## Troubleshooting

### Camera not working on Android

Make sure you have granted camera permissions:
1. Go to Settings > Apps > DocExtract > Permissions
2. Enable Camera permission

### Supabase connection errors

- Verify your Supabase URL and anon key are correct
- Check that your Supabase project is active
- Ensure the `extracted_documents` table exists

### LlamaParse API errors

- Verify your LlamaCloud API key is valid
- Check your API usage limits
- Ensure you have an active subscription if required

### Web version not loading files

- Check browser console for errors
- Ensure you're using a modern browser (Chrome, Firefox, Safari, Edge)
- Clear browser cache and try again

## API Costs

- **LlamaParse**: Check [LlamaCloud pricing](https://cloud.llamaindex.ai) for current rates
- **Supabase**: Free tier includes 500MB database storage and 2GB bandwidth

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See the LICENSE file for details.

## Support

For issues, questions, or contributions, please open an issue on GitHub.

## Acknowledgments

- [Flutter](https://flutter.dev) - The UI framework
- [LlamaIndex](https://www.llamaindex.ai) - For the LlamaParse extraction service
- [Supabase](https://supabase.com) - For the backend infrastructure
