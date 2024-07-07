---
canonical_url: https://grencez.dev/2022/sxproto-20220122
date: 2022-01-22
last_modified_at: 2024-07-07
description: A file extension and format for S-expressions representing protobuf messages.
---

# Sxproto: An S-expression format for protocol buffer messages

Date: 2022-01-22

Update: 2024-07-07 (new array syntax)

Code: [https://github.com/rendezqueue/rules_sxproto](https://github.com/rendezqueue/rules_sxproto)

## Motivation

I just want to populate some protocol buffers using a Lisp-like syntax.

Protocol Buffer text and JSON formats can make it hard to write complicated protobufs directly, which is often a good exercise when writing tests or designing a new schema.
This is especially true when the protobuf's messages represent a domain-specific language's syntax tree
(like [CEL](https://github.com/googleapis/googleapis/blob/master/google/api/expr/v1alpha1/syntax.proto)).
We're essentially talking about treating [code as data](https://en.wikipedia.org/wiki/Homoiconicity) now,
which make S-expressions a pretty natural fit if you're comfortable with them.
So here we are, about to embark on a fairly easy quest to write protobufs like Lisp.

Don't get me wrong, the text format of protocol buffers is fantastic.
It is made specifically easy to diff, has great parsers, and is generally well-supported.
You should use it.
In fact, we will be using it here as a translation target!

## Format

**How should these S-expression protobuf data files look?**
They should have the `.sxpb` extension, which follows the pattern of the text (`.txtpb`) and binary (`.binpb`) protobuf formats.

**How is sxpb pronounced?**
We can call it Sxproto data (pronounced "ess ex proto data") or just Sxpb (pronounced "ess ex pee bee").
Avoid just saying "Sxproto" because "proto" typically refers to the schema in a `.proto` file.

**How do comments look?**
In Lisp, they're semicolons.
We don't want to bother writing custom syntax rules, so a semicolon sounds great.
In fact, we can put the following comment at the end of a sxproto file to tell Vim that it should have Lisp indentation.
```lisp
; vim: ft=lisp lw=nil
```

**What about scalar fields?**
These are fields that contain a number or a string.
Fields all have names, so the name should begin the S-expression and the value comes after it.
```lisp
; An integer.
(x 5)  ;  x: 5
; A float.
(y 5.5)  ;  y: 5.5
; A string.
(greeting "hello")  ;  greeting: "hello"
; Concatenate strings like in txtpb.
(greeting "hello" " world")  ;  greeting: "hello" " world"
```

**What about message-typed fields?**
This is basically the same.
The field name comes first in the S-expression, and everything after it represents the fields of the message.
Since each field of that message is an S-expression itself, there's no ambiguity.
```lisp
; A message holding a single integer.
(m (x 5))  ;  m {x: 5}

; An empty message.
(m)  ;  m {}

; A message holding the first 3 fields of the previous example.
(m (x 5) (y 5.5) (greeting "hello"))  ;  m {a: 5  y: 5.5  greeting: "hello"}
```

**What about repeated fields (aka arrays)?**
Rather than holding just one value of a certain type, a repeated field holds an array of such values.
Conceptually, this is like a message with unnamed fields and where order matters, so it should use a similar but obviously different syntax.
We can write arrays just like messages but with `(())` as the first field, hinting to our eyes or a parser that what follows are the array's elements.
```lisp
; An array of integers.
(my_integers (()) 1 2 3)  ;  my_integers: [1, 2, 3]

; An array of strings.
(my_greetings (()) "yo" "howdy" "sup")  ;  my_greetings: ["yo", "howdy", "sup"]

; An array of the previous example's message.
(my_messages (())                       ;  my_messages: [
 (() (x 5))                             ;    {x: 5},
 ()                                     ;    {},
 (() (x 5) (y 5.5) (greeting "hello"))  ;    {a: 5  y: 5.5  greeting: "hello"}
)                                       ;  ]

; An empty array.
(my_empty_array (()))  ;  my_empty_array: []
```

**What about the other repeated field syntax?**
Like JSON, where you have to specify arrays between square brackets (like above),
a sxproto file may not always have a schema, so we should keep one array syntax.

This differs from txtpb format, which lets you specify the field as if it were not repeated at all.
For txtpb, there's no type ambiguity because the associated protobuf schema defines the actual field types.
```lisp
; An array of integers.
(my_integers (())
 1                 ;  my_integers: 1
 2                 ;  my_integers: 2
 3)                ;  my_integers: 3

; An array of strings.
(my_greetings (())
 "yo"               ;  my_greetings: "yo"
 "howdy"            ;  my_greetings: "howdy"
 "sup")             ;  my_greetings: "sup"

; An array of messages.
(my_messages (())
 (() (x 5))           ;  my_messages {x: 5}
 ()                   ;  my_messages {}
 (()                  ;  my_messages {
  (x 5)               ;    x: 5
  (y 5.5)             ;    y: 5.5
  (greeting "hello")  ;    greeting: "hello"
))                    ;  }
```

## Example

You're basically an sxpb expert at this point; there's really not much to it!
But just for fun, let's have a larger example that populates some `GroceryList` messages.

```protobuf
syntax = "proto3";

message GroceryListItem {
  string name = 1;
  int32 amount = 2;
  bool variety = 3;
  float budget = 4;
  oneof expected_cost {
    float expected_cost_each = 5;
    float expected_cost_total = 6;
  }
  repeated string favorites = 7;
}

message GroceryList {
  repeated GroceryListItem items = 1;
}
```

Scenario: I'm only running low on dips and sauces, so my grocery list is pretty short today.
I only need 1 dip, but it would be great to find some hummus or garlic dip.
And for some mild heat, it would be great to find some
[Yuzu sauce](https://www.traderjoesgroceryreviews.com/yuzu-hot-sauce-trader-joes-hot-sauce/),
[Jump Up and Kiss Me](https://jumpupandkissme.wordpress.com/2013/02/06/the-best-valentines-gift/),
[Ray's Polish Fire](https://www.polishfire.com),
[BeeBOMB](https://pexpeppers.com/products/beebomb-hot-sauce), or
[Yucatan Sunshine](https://reilyproducts.com/products/try-me-yucatan-sunshine-habanero-sauce-5-oz/).
Hmm, I'm getting carried away.
I only need 3 sauces and should limit the cost to 20 USD.

Using the explicit array style for repeated fields, we can specify the grocery list as:

```lisp
(items (())                           ;  items: [{
 (()
  (name "dip")                        ;    name: "dip"
  (amount 1)                          ;    amount: 1
  (expected_cost_total 6.50)          ;    expected_cost_total: 6.50
  (budget 20)                         ;    budget: 10
  (favorites (()) "hummus" "garlic")  ;    favorites: ["hummus", "garlic"]
 )                                    ;  }, {
 (()
  (name "hot sauce")                  ;    name: "hot sauce"
  (amount 3)                          ;    amount: 3
  (variety true)                      ;    variety: true
  (expected_cost_each 6.50)           ;    expected_cost_each: 6.50
  (budget 20)                         ;    budget: 20
  (favorites (())                     ;    favorites: [
   "yuzu" "kiss" "fire"               ;      "yuzu", "kiss", "fire",
   "bee" "sunshine"                   ;      "bee", "sunshine"
  )                                   ;    ]
))                                    ;  }]
```
