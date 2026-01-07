# 🔐 API Keys Setup Guide

## ⚠️ Your API Key Was Leaked!

Your Gemini API key has been flagged as leaked. Follow these steps immediately:

## Step 1: Revoke the Old Key

1. Go to [Google AI Studio API Keys](https://aistudio.google.com/app/apikey)
2. Find your old API key: `AIzaSyBHHiDQ549Mp9P2HuZog323GR9p_rLFO5Q`
3. Click **Delete** or **Revoke** to disable it

## Step 2: Generate a New API Key

1. On the same page, click **"Create API Key"**
2. Select your Google Cloud project (or create a new one)
3. Copy the new API key that's generated

## Step 3: Update Your App

1. Open the file: `lib/config/api_keys.dart`
2. Replace `'YOUR_NEW_API_KEY_HERE'` with your new API key
3. Save the file

**Example:**
```dart
class ApiKeys {
  static const String geminiApiKey = 'AIzaSyC_YOUR_ACTUAL_NEW_KEY_HERE';
}
```

## Step 4: Test the AI Chat

1. Run your app: `flutter run`
2. Navigate to the AI Chat screen
3. Send a test message to verify it works

## 🛡️ Security Best Practices

✅ **DO:**
- Keep `api_keys.dart` in `.gitignore` (already done)
- Never share your API key publicly
- Regenerate keys if you suspect they're compromised
- Use environment variables for production apps

❌ **DON'T:**
- Commit API keys to Git
- Share API keys in screenshots or videos
- Hardcode API keys directly in source files
- Use the same API key across multiple projects

## 📝 Note

The file `lib/config/api_keys.dart` is now in `.gitignore`, so it won't be committed to Git. The template file `api_keys.dart.template` can be safely committed and shared with other developers.

---

**Need Help?** 
- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
