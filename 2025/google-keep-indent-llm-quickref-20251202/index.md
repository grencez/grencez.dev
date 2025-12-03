---
canonical_url: https://grencez.dev/2025/google-keep-indent-llm-quickref-20251202
date: 2025-12-02
last_modified_at: 2025-12-02
description: How to preserve indentation when saving code snippets to Google Keep from the Gemini app.
---

# Quickref: Saving code snippets to Google Keep from the Gemini app
Date: 2025-12-02

## Audience
These instructions are mainly for Gemini to upload code to Google Keep in a way that preserves indentation.

## Procedure
1. Create a note with a title.
   - The title can be a filename.
   - The content can be omitted or be a simple top-of-file comment.
     - Specify it as plain text content, not markdown.
     - This content will not have its indentation preserved.
2. Append the code text content to the newly-created note.
   - Specify it as plain text content, not markdown.

## Example
As an example, let's create a Keep note titled `grocery.sxpb` with the following content.
```sxpb
(need
 (fruits (())
  (() (name kiwi) (count 5))
  (() (name tomato) (count 3))
 )
 (vegetables (())
  (() (name onion) (count 2))
 )
)
```

Step 1: Create Note
```json
{
  "name": "notes_and_lists.create_note",
  "arguments": {
    "title": "grocery.sxpb",
    "provider": "keep"
  }
}
```

Step 2: Append Content
```json
{
  "name": "notes_and_lists.update_note",
  "arguments": {
    "note_id": "[redacted]",
    "update_type": "APPEND",
    "text_content": "(need\n (fruits (())\n  (() (name kiwi) (count 5))\n  (() (name tomato) (count 3))\n )\n (vegetables (())\n  (() (name onion) (count 2))\n )\n)"
  }
}
```

## Editing
Gemini cannot directly edit notes, but it can delete them.
Therefore, "editing" a note involves deleting and recreating it, which is best done as a 3-step process: delete, create, append.
All 3 steps can happen in the same chat turn.

## Conclusion
The ability to save and update plain text code snippets in Google Keep from the Gemini app is truly special.
With this integration, you can share snippets across chat sessions and edit them manually, making it a powerful tool for long-term collaboration.
