# SxPB Nests

An **SxPB Nest** is a recursive data structure mapping strings to other Nests. It is designed for describing free-form, hierarchical data with a clean S-expression syntax.

## Structure

Internally, a Nest is a dictionary where:
- Keys are non-empty strings.
- Values are either `None` (representing a leaf node or "string field") or another `SxpbNest` (representing a sub-nest).

## Syntax

### Defining a Nest Field

A field containing a Nest is declared with a `("")` marker after the field name.

```sxpb
(appearance ("")
 (stature short)
)
```

In the example above, `appearance` is a Nest. Inside it, `stature` is also a Nest (by default).

### Fields within a Nest

Every field inside a Nest is treated as a sub-nest by default.

```sxpb
(head
 (hair wild cascade)
)
```

Here, `head` contains `hair`, which contains keys `wild` and `cascade`.

### String Fields

To specify that a field contains a string value (instead of a sub-nest), use the `""` discriminator after the field name. This allows multi-word strings to be written without quotes (bare).

```sxpb
(description "" a tall dark stranger)
```

Here, `description` is a field with the string value `"a tall dark stranger"`.

**Note:** String fields cannot contain sub-nests (nested structures starting with `(`).

### Top-Level Nests

A file can represent a Nest at the top level by starting with the `("")` marker.

```sxpb
("")
key1
(key2 val2)
```

## Rules and Constraints

1.  **Empty Keys Forbidden:** Keys cannot be empty strings (`""`). The empty string literal `""` is reserved as a marker.
2.  **String Field Marker:** The `""` marker discriminates a string field from a sub-nest.
    *   `(key body)` -> `key` maps to a sub-nest defined by `body`.
    *   `(key "" content)` -> `key` maps to the string `content`.
3.  **Bare Strings:** Multi-word strings in a string field can be written as a sequence of bare words (e.g., `quiet confidence`).
4.  **Formatting:**
    *   Nests with 1 to 3 simple string keys (leaves) are typically formatted on a single line: `(w a b)`.
    *   Larger nests or those containing sub-nests use multi-line formatting.

## Examples

### The Handsome Goblin

This example demonstrates sub-nests, string fields, and mixed content.

```sxpb
(appearance ("")
 (stature
  short
  ; Multi-word strings in a nest (as keys) need quoting if they contain spaces?
  ; No, keys must be single tokens (bare or quoted).
  ; But values (string fields) can be bare multi-word.

  ; This is a sub-nest with two keys "quiet" and "confidence" (which are leaves/None).
  ("" quiet confidence)

  ; This is a string field "posture" with value "regal poise".
  (posture "" regal poise)

  ; Keys with spaces must be quoted.
  ("relative height" "" up to a human's chest)
 )
 (skin
  smooth
  (luminous "" in the dark)
  (green deep velvety ("" like moss))
 )
 (head
  (hair wild cascade (tied "" with a strip of leather) (black midnight))
  (eyes (color "" polished amber))
  (ears long tapered (pierced "" thin silver rings))
  (cheekbones high sharp)
  (smile sly crooked ("" hint of pointy teeth) soft)
  (jaw angular strong)
 )
)
```

### Parsing Result (Python)

The parser converts the above structure into an `SxpbNest` object (inheriting from `dict`):

```python
{
    "appearance": {
        "stature": {
            "short": None,
            "quiet confidence": None,  # Parsed from ("" quiet confidence)
            "posture": "regal poise",  # Parsed from (posture "" regal poise) - represented as Nest with 1 key -> None internally?
                                       # Actually, string fields are parsed as: {"posture": {"regal poise": None}}
            "relative height": {"up to a human's chest": None}
        },
        "skin": {
            "smooth": None,
            "luminous": {"in the dark": None},
            "green": {
                "deep": None,
                "velvety": None,
                "like moss": None
            }
        },
        # ...
    }
}
```

*Note: In the Python object model, a string field `(key "" value)` is represented as a Nest containing `{value: None}`. A "leaf" key in a Nest maps to `None`.*
