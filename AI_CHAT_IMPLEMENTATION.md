# AI Chat History Implementation

## Overview
Implemented a complete AI chat feature with conversation history stored by date. The AI assistant uses Groq's LLaMA 3.3 70B model and provides medical guidance in Romanian.

## Features Implemented

### 1. AI Chat Screen (`lib/screens/ai_chat_screen.dart`)
- Real-time chat interface with AI assistant
- User messages displayed on the right (using theme primary color)
- AI responses displayed on the left (using theme secondaryContainer color)
- Auto-scroll to latest message
- Loading indicator while AI is responding
- History button in AppBar to access conversation history
- Empty state with helpful message

### 2. AI History Screen (`lib/screens/ai_history_screen.dart`)
- Conversations grouped by date (Astăzi, Ieri, or full date)
- Expandable date sections showing conversation count
- Each conversation shows:
  - Time of conversation
  - User message with person icon
  - AI response with robot icon
  - Delete button for individual conversations
- Delete all conversations for a specific date
- Pull-to-refresh functionality
- Empty state when no history exists

### 3. Database Schema (`supabase_ai_chat_schema.sql`)
```sql
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  conversation_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. AI Service (`lib/services/ai_service.dart`)
- Integration with Groq API
- Uses LLaMA 3.3 70B Versatile model
- System prompt configured for medical assistance in Romanian
- Error handling for API failures

### 5. AI Chat Service (`lib/services/ai_chat_service.dart`)
- `sendMessage()` - Send user message and get AI response
- `getConversations()` - Retrieve all conversations
- `getConversationsByDate()` - Group conversations by date
- `deleteConversation()` - Delete single conversation
- `deleteConversationsForDate()` - Delete all conversations for a date

### 6. Data Model (`lib/models/ai_conversation.dart`)
- `AIConversation` - Single conversation model
- `ConversationsByDate` - Grouped conversations model
- JSON serialization/deserialization

### 7. Home Screen Integration (`lib/screens/home_screen.dart`)
- AI chat button (robot face) uses theme colors
- Gradient background adapts to app theme
- Shadow color matches primary color
- Opens AI chat screen on tap

## Theme Integration

All UI elements use the app's theme colors:
- **Primary color**: User messages, AI button gradient
- **Secondary container**: AI responses background
- **Primary container**: AppBar background, date group icons
- **Outline**: Borders and dividers
- **Surface**: Card backgrounds

## Database Setup

To enable the AI chat feature, run this SQL in your Supabase SQL Editor:

```sql
-- Create ai_conversations table
CREATE TABLE IF NOT EXISTS ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  conversation_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_date 
ON ai_conversations(user_id, conversation_date DESC);

-- Enable Row Level Security
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own conversations"
ON ai_conversations FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conversations"
ON ai_conversations FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
ON ai_conversations FOR DELETE
USING (auth.uid() = user_id);
```

## Dependencies Added

- `http: ^1.2.0` - For Groq API calls

## Usage

1. **Start a conversation**: Tap the AI robot button on the home screen
2. **Send messages**: Type your health question and tap send
3. **View history**: Tap the history icon in the AI chat screen
4. **Delete conversations**: 
   - Tap delete icon on individual conversation
   - Tap delete sweep icon to remove all conversations for a date

## API Configuration

The app uses:
- **Groq API Key**: `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`
- **Model**: `llama-3.3-70b-versatile`
- **Temperature**: 0.7
- **Max Tokens**: 500 per response

## Romanian Language Support

All UI text is in Romanian:
- "Asistent AI" - AI Assistant
- "Istoric Conversații" - Conversation History
- "Astăzi" - Today
- "Ieri" - Yesterday
- "Scrie mesajul tău..." - Write your message...
- "Începe o conversație" - Start a conversation
- "Nicio conversație" - No conversations

## Next Steps

1. Run the SQL schema in Supabase
2. Test the chat functionality
3. Verify conversations are saved correctly
4. Test history viewing and deletion
5. Ensure theme colors match throughout the app
