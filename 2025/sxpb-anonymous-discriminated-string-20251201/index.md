---
canonical_url: https://grencez.dev/2025/sxpb-anonymous-discriminated-string-20251201
date: 2025-12-01
last_modified_at: 2025-12-01
description: How to write multi-word strings in SxPB arrays without wrapping them in quotation marks.
---

# Listing bare multi-word strings in SxPB
Date: 2025-12-01

## Abstract
The *anonymous discriminated string* syntax is introduced to write multi-word strings in SxPB arrays without wrapping them in double quotes.

## Motivation
In SxPB, most string fields can be written without quotation marks.
These so-called [bare strings](../../2024/sxpb-string-grammar-20240717/index.md) like `(my_string A B C)` were introduced to yield an efficient and predictable tokenization.
For example, an LLM like LLaMA or most others will tokenize the quoted version of `(my_string "A B C")` with `A` as the first token, then `B` and `C` paired with their preceding spaces as the next 2 tokens.
In contrast, with the bare version of `my_string`, the first token of string content is `A` with the space preceding it, making it predictably like the `B` and `C` tokens that follow.
Including the space in the string's first token can [yield higher accuracy](https://arxiv.org/abs/2212.09912) when an LLM is asked to output the string with a preceding space like in a sentence.

## Problem
But how do we employ the same trick when our multi-word string is in an array like `(my_array (()) "A B C" "D E F")`?
Omitting quotes like `(my_array (()) A B C D E F)` changes the meaning entirely!

## Derivation
We can derive a good syntax naturally.
First, we'll definitely have to group the words in parentheses.
Second, we need to give it an empty field name to be consistent with how [messages in arrays](../../2022/sxproto-20220122/index.md) put `()` where a field name would be.
That's about it.
We can put `""` where a field name would be, making our desired array look like `(my_array (()) ("" A B C) ("" D E F))`.

The string is parsed as if it came after a field name.
While `""` acts as a type discriminator, it is also valid string content.
That is, even though we wrote `(my_string A B C)` in an example earlier, it would also be valid to write `(my_string "" A B C)`.
Therefore, we can parse `""` as part of the string, concatenate it with `A`, and finally append `B` and `C` with spaces between the bare words to get `"A B C"`.

## Example
To recap, this means we have 3 basic ways to write strings in an array:
```sxpb
(my_strings (())
 bare
 "quoted string"
 ("" anonymous discriminated string)
)
```
