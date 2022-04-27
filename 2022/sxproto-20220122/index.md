---
canonical_url: https://grencez.dev/2022/sxproto-20220122
date: 2022-01-22
last_modified_at: 2022-04-26
description: A file extension and format for S-expressions representing protobuf messages.
---

# Sxproto: An S-expression format for protocol buffer messages

Date: 2022-01-22

Code: [https://github.com/fantasma/rules_sxproto](https://github.com/fantasma/rules_sxproto)

## Motivation

I just want to populate some protocol buffers using a Lisp-like syntax.

Textproto and JSON syntax can make it hard to write complicated protobufs directly, which is often a good exercise when writing tests or designing a new schema.
This is especially true when the protobuf's messages represent a domain-specific language's syntax tree
(like [CEL](https://github.com/googleapis/googleapis/blob/master/google/api/expr/v1alpha1/syntax.proto)).
We're essentially talking about treating [code as data](https://en.wikipedia.org/wiki/Homoiconicity) now,
which make S-expressions a pretty natural fit if you're comfortable with them.
So here we are, about to embark on a fairly easy quest to write protobufs like Lisp.

Don't get me wrong, the text format of protocol buffers is fantastic.
It is made specifically easy to diff, has great parsers, and is generally well supported.
You should use it.
In fact, we will be using it here as a translation target!

## Format

**How should these S-expression protobuf files look?**
Or more urgently, how should we name them?
Luckily, applying some wordplay to the existing "textproto" and "binaryproto" naming scheme gives us an easy answer:
"S-expression proto" files should have an `.sxproto` file extension (pronounced "ess ex proto").

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
; Textproto will concatenate strings for us!
(greeting "hello" "world")  ;  greeting: "hello" "world"
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
Conceptually, this is just a funny message with no field names, right?
It's not encoded like that on the wire of course, but this way of thinking can help us find an appropriate S-expression representation.
We can make these "funny messages" fill in the last gap of our syntax: S-expressions that start with S-expressions!
```lisp
; An array of integers.
((my_integers) 1 2 3)  ;  my_integers: [1, 2, 3]

; An array of strings.
((my_greetings) "yo" "howdy" "sup")  ;  my_greetings: ["yo", "howdy", "sup"]

; An array of the previous example's message.
((my_messages)                        ;  my_messages [
 (() (x 5))                           ;      {x: 5},
 (())                                 ;      {},
 (()                                  ;      {a: 5  y: 5.5  greeting: "hello"},
  (x 5) (y 5.5) (greeting "hello")))  ;  ]
```

At this point, you're probably thinking:
"Typical Lisp user; you can't solve your syntax problems with more parentheses".
It's a valid criticism, though I don't really qualify as a Lisp user anymore.
Anyway, if you find this style too obtuse, you can use the other repeated field syntax.

**What about the other repeated field syntax?**
Unlike JSON, where you have to specify arrays between square brackets (like above),
the textproto format lets you specify the field as if it were not repeated at all.
Indeed, you can just specify it more times to add more values to the array.
Likewise, there's no new sxproto syntax here, but it's worth mentioning that this style is valid.
There's no type ambiguity because the associated protobuf schema defines our actual field types.
```lisp
; An array of integers.
(my_integers 1)  ;  my_integers: 1
(my_integers 2)  ;  my_integers: 2
(my_integers 3)  ;  my_integers: 3

; An array of strings.
(my_greetings "yo")     ;  my_greetings: "yo"
(my_greetings "howdy")  ;  my_greetings: "howdy"
(my_greetings "sup")    ;  my_greetings: "sup"

; An array of messages.
(my_messages (x 5))    ;  my_messages: {x: 5}
(my_messages)          ;  my_messages: {}
(my_messages           ;  my_messages: {
  (x 5)                ;      x: 5
  (y 5.5)              ;      y: 5.5
  (greeting "hello"))  ;      greeting: "hello"
                       ;  }
```

## Example

You're basically an sxproto expert at this point; there's really not much to it!
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
((items)                            ;  items: [{
 (()                                ;
  (name "dip")                      ;      name: "dip"
  (amount 1)                        ;      amount: 1
  (expected_cost_total 6.50)        ;      expected_cost_total: 6.50
  (budget 20)                       ;      budget: 10
  ((favorites) "hummus" "garlic"))  ;      favorites: ["hummus", "garlic"]
 (()                                ;  }, {
  (name "hot sauce")                ;      name: "hot sauce"
  (amount 3)                        ;      amount: 3
  (variety true)                    ;      variety: true
  (expected_cost_each 6.50)         ;      expected_cost_each: 6.50
  (budget 20)                       ;      budget: 20
  ((favorites)                      ;      favorites: [
   "yuzu" "kiss" "fire"             ;          "yuzu", "kiss", "fire",
   "bee" "sunshine")))              ;          "bee", "sunshine"
                                    ;      ]
; vim: ft=lisp lw=nil               ;  }]
```

Contrast that the "repeated" style below.

```lisp
(items                          ;  items {
  (name "dip")                  ;    name: "dip"
  (amount 1)                    ;    amount: 1
  (expected_cost_total 6.50)    ;    expected_cost_total: 6.50
  (budget 10)                   ;    budget: 10
  (favorites "hummus")          ;    favorites: "hummus"
  (favorites "garlic"))         ;    favorites: "garlic"
                                ;  }
(items                          ;  items {
  (name "hot sauce")            ;    name: "hot sauce"
  (amount 3)                    ;    amount: 3
  (variety true)                ;    variety: true
  (expected_cost_each 6.50)     ;    expected_cost_each: 6.50
  (budget 20)                   ;    budget: 20
  (favorites "yuzu")            ;    favorites: "yuzu"
  (favorites "kiss")            ;    favorites: "kiss"
  (favorites "fire")            ;    favorites: "fire"
  (favorites "bee")             ;    favorites: "bee"
  (favorites "sunshine"))       ;    favorites: "sunshine"
; vim: ft=lisp lw=nil           ;  }
```

Notice how the sxproto indentation hasn't really changed?
Even though we had more S-expression nesting before, Vim's Lisp indentation rules work out to the same amount of horizontal space.
Pretty neat!

