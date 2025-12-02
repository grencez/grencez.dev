---
canonical_url: https://grencez.dev/2025/google-keep-indent-llm-quickref-20251202
date: 2025-12-02
last_modified_at: 2025-12-02
description: Protocol for preserving indentation in Google Keep.
---

# Protocol for preserving indentation in Google Keep

First create a note with a title and no content.
You can add text content at this step, but it won't be indented.
Something like a top-of-file comment would be appropriate though.

Next, append to that newly-created note.
Specify only plain text content, not markdown.

As an example, let's create a Keep note titled grocery.sxpb with the following days field.

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

--- API Call Log (grocery.sxpb) ---

Step 1: Create Container
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
