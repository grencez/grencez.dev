---
canonical_url: https://grencez.dev/2024/sxpb-string-grammar-20240717
date: 2024-07-17
last_modified_at: 2024-07-17
description: How to unambiguously parse string literals in .sxpb format.
---

# Parsing strings from SxPB files
Date: 2024-07-17

## Abstract
In the initial design of [SxPB, an S-expression format for protobuf data](../../2022/sxproto-20220122/index.md), we only considered the basic double-quoted string.
Since then, SxPB has been extended to support multiline and bare strings.
Multiline strings make it easy to embed file content, which is particularly useful in Ansible playbooks.
Bare strings only have blank space between the field name and first word, which yields an efficient tokenization when fed to Large Language Models.
The absence of double quotes makes bare strings easier to type, but this design might include confusing edge cases without proper care.

To alleviate confusion or ambiguity, we define a regular grammar for SxPB strings.
In doing so, we also show that bare strings remain simple enough to be recognized by their first one or two bytes.

## Motivation
SxPB aims to be convenient while remaining simple enough to have predictable limits on its flexibility.
To this end, literal values and the fields that hold them should be trivial to parse:
```sxpb
; Booleans are named literals, which begin with a plus.
(my_bool +false) (my_other_bool +true)
; Integers can also begin with a minus or digit.
(my_int -2) (my_other_int 3)
; Floating point numbers can also begin with a period.
(my_float .4e+1)
; Arrays begin with empty nested parentheses.
(my_int_array (()) 0 +1 -2 3)
(my_float_array (()) 0.0 +.1e1 -2. 30e-1 .4e+1)
; Strings can begin with double quotes, but we usually write field names bare.
(my_bare_string a b c)
(my_quoted_string "a b c")
("my_quoted_field" "a b c")
```

As for structure, SxPB adheres to three basic rules:
- Field names and literal values are delimited by blank space, which includes semicolon-prefixed line comments.
- Structural elements are wrapped by parentheses, which do not require blank space for separation.
- Strings can be surrounded by double quotes and can then contain backslash-escaped double quotes.

Aside from some edge-case strings, the rules for literals and structure given above are enough to parse any valid `.sxpb` file.
Let's tackle those strings, first by exploring how we want to write them conveniently in an example, and finally by defining an grammar to parse them unambiguously.

## Example
Consider the following SxPB-formatted Ansible playbook that updates a host's `/etc/motd`:
```sxpb
; file: motd_ansible_playbook.sxpb
(())
(()
 (name Set up a motivational Message of the Day.)
 (hosts all)
 (tasks (())
  (()
   (name "1 " task to configure 10 times more motivation in the motd!)
   (ansible.builtin.copy
    (dest /etc/motd)
    (owner root) (group root) (mode "0644")
    (content If you're tired of starting over, stop giving up. """
Yesterday, you said "tomorrow".
Will you push even further beyond today?
""")))
))
```

A few things to note:
- File mode `"0644"` has to be quoted.
  - This avoids being being an integer 644.
- Task name starts with a `"1 "`, which makes sense to be quoted.
  - Otherwise, a parser would have to look too far ahead to realize it's not a number.
- Task name starts with a `"1 "`, which makes sense to need a space at the end.
  - Quoted string segments concatenate with neighboring segments without a space (like in C or Python).
  - Unquoted string segments are implicitly concatenated with a space character between them (like in YAML).
- Task name includes a plain number `10`, which is interpreted as a string.
  - This is expected because we already know the field is a string at this point.
- File content begins with several unquoted strings containing a single quote, comma, and period.
  - This is fine because those characters have no special meaning in SxPB.
- File content includes double quotes within a multiline string.
  - This matches Python's behavior.

## Definition
Since bare strings should be allowed to contain digits in the middle, their initial unquoted segment follows different rules.
We call the initial segment a bare word (ref: [BARE](#bare)) and the later segments plain words (ref: [PLAIN](#plain)).
String segments that are surrounded by double quotes or triple double quotes (ref: [QUOTED](#quoted)) are treated the same as the unquoted variants in that blank space (ref: [BLANK]{#blank}) must separate them.
This yields a simple high-level grammar for string literals.
```
STRING = ( QUOTED | BARE ) ( BLANK ( QUOTED | PLAIN ) )* ;
```

### Blank
Blank space is any combination of whitespace characters (`[ \t\n\v\f\r]`) and line comments (`[;][^\n]*[\n]`).
```
BLANK = ( [ \t\n\v\f\r] | [;][^\n]*[\n] )+ ;
```

### Plain
Plain words are consecutive characters that have no syntactic meaning (i.e., no space, comment, double quotes, or parentheses).
If we're already parsing a string, it's safe to assume that any plain words that follow should also be part of the string.
```
PLAIN = [^ \t\n\v\f\r;"()]+ ;
```

### Bare
Bare words are plain words that can unambiguously begin an unquoted string (aka bare string).
To avoid ambiguity with numbers and special values, bare strings cannot begin with a digit or plus, and they can only begin with a minus or period under certain conditions.
Specifically, a bare word must satisfy the following constraints:
- Does not begin with a digit or plus.
- Does not begin with a minus followed by a digit, plus, or period.
- Does not begin with a period followed by a digit, plus, or minus.

Therefore, only the first two characters need to be considered to detect a bare string.
This allows common strings like ".", "-", or anything with a prefix of ".." or "--" to be written without quotes but excludes other combinations like "-.", ".-", and ".+".
```
BARE_PREFIX
= [-.]? [^-+.0123456789 \t\n\v\f\r;"()]
| [-][-]
| [.][.]
;
BARE = BARE_PREFIX PLAIN? | [-.] ;
```

### Quoted
Quoted strings are enclosed by a pair of double quotes "like this" or a pair of three double quotes """like this""".
While the latter variant can contain one or two consecutive unescaped double quotes, an escaped double quote `\"` affects the grammar of both variants.
```
QUOTED
= ["] ( [^"\\]+ | [\\]. )* ["]
| ["]["]["] ( ["]?["]?[^"\\]+ | ["]?["]?[\\]. )* ["]["]["]
;
```
