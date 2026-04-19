# OCR.space API Setup Guide (SIMPLEST OPTION!)

## Why OCR.space?

OCR.space provides:
- **25,000 free requests/month** (way more than enough!)
- **No credit card required** for free tier
- **Simple API key** (no complex setup)
- **High accuracy** OCR for documents
- **Fast processing** (usually < 5 seconds)

## Setup Steps (5 minutes!):

### 1. Create OCR.space Account
1. Go to [OCR.space](https://ocr.space/OCRAPI)
2. Click "Register" (top right)
3. Fill in your details and verify email
4. **Done!** You now have 25,000 free API calls/month

### 2. Get Your API Key
1. Log into your OCR.space account
2. Go to "My Account" or check your email
3. Copy your API key (it looks like: `helloworld123456789`)

### 3. Configure Environment Variables
Update your `.env` file in the backend folder:

```env
OCR_SPACE_API_KEY=helloworld123456789
```

### 4. Install Dependencies
```bash
cd backend
npm install
```

### 5. Test the Setup
The system will automatically:
- Extract text from uploaded documents
- Parse structured data using regex patterns
- Handle both NID and Driver's License formats

## Benefits:

✅ **Completely FREE** - 25,000 requests/month
✅ **No credit card** required
✅ **Super simple** - Just one API key
✅ **Fast setup** - 5 minutes total
✅ **Reliable** - Been around for years

## Cost:
- **Free tier**: 25,000 requests/month
- **Paid plans**: From $9.99/month for 250,000 requests

## How It Works:
1. User uploads document image
2. Backend sends image to OCR.space API
3. OCR.space extracts all text from the image
4. Backend uses regex to parse the text into structured data
5. Admin sees extracted information (name, ID number, dates, etc.)

This is the **easiest and most cost-effective** solution for your verification system!