---
canonical_url: https://grencez.dev/2023/llama-chatbot-20230404
date: 2023-04-04
last_modified_at: 2023-04-04
description: Making an infinite chatbot with llama.cpp.
---

# Infinite chatbot with llama.cpp

## Abstract
We walk through some techniques of using llama.cpp as a chatbot.

Jump to the [Setup](#setup) section if you don't have llama.cpp set up already or if you're trying to copy/paste commands.

## Guiding the Autocomplete
The first thing you'll notice when running [llama.cpp](https://github.com/ggerganov/llama.cpp)'s main example is that the text after your prompt just keeps going as if completing a story.
To use it as a chatbot, we have to guide the glorified autocomplete tool to expect & fill in the correct structure by providing it a good prompt that consists of 2 parts:
1. Priming prompt.
   - Describes the rest of the document.
     - "Transcript of a dialogue between User and a fancy AI named Bot."
     - "Every line of dialogue begins with a name followed by a colon."
   - Describes the characters chatting.
     - Bad: "Bot definitely doesn't want to destroy humanity."
     - Good: "Bot is friendly and it tries to help User with their concerns."
2. Few-shot example prompt.
   - A handful of example dialogue lines.

For a chat, llama.cpp's `main` example is run with flags that indicate that you're requesting an interactive session (`-i`) and a reverse prompt (`-r "User:"`) that lets you fill in the user dialogue.

For an infinite chat, llama.cpp's `main` example can reinitialize its prompt with your original primer prompt followed by only the newest half(ish) of chat dialogue.
You need to use flags that tell it to run forever (`-n -1`), have no exit token (`--ignore-eos`), keep as many tokens as exist in the primer prompt (`--keep 123`), and you probably want max context size (`-c 2048`).

## Constraining Structure
Infinite chat has some issues:
- Bad text patterns develop and worsen. (e.g., User gets a poorly-tokenized nickname like "Userrrrrrrrr".)
  - No easy fix. Must rewrite/regenerate.
- Dialogue lines get too long.
- Line that is not dialogue. (e.g., `\end{code}`)
- Too many consecutive dialogue lines.

A hacky but effective workaround for the last 3 issues is to let the user decide whether they want to speak whenever the Bot writes a punctuation or newline.
And, in the case of a newline, force it to start with `User: ` or `Bot: ` depending on either user input or alternating pattern (because sometimes it's fun to let the LLM write the user's dialogue).

A better general solution is to regenerate the last line if it looks bad (user-driven) or goes on for too long (automatic).
This idea is tracked by [Issue #604](https://github.com/ggerganov/llama.cpp/issues/604) for llama.cpp and is already implemented in a fork named [koboldcpp](https://github.com/LostRuins/koboldcpp).
My [rendezllama](https://github.com/rendezqueue/rendezllama) project will eventually do the same via llama.cpp, koboldcpp, or some other library.

[Allen Roush et al. explore](https://paperswithcode.com/paper/most-language-models-can-be-poets-too-an-ai) some other more direct ways of enforcing structure.
See their [Constrained-Text-Generation-Studio](https://github.com/Hellisotherpeople/Constrained-Text-Generation-Studio) project on GitHub for an implementation and the list of constraints.
I like this idea, and it could definitely complement the ability to regenerate lines, but it's impossible to guard against all bad text patterns.

## Quality vs Structure
When the structure LLM-generated text is unconstrained, it's difficult to use some common techniques that improve chatbot quality.

I observed the trade-offs for the 7B and 13B LLaMA checkpoints.
The larger one usually behaves better, so I suspect that the 30B and 65B checkpoints continue that trend.
It would explain why some people are able to use these techniques.

### Inner Monologue
Some people give the chatbot a `/think` command to reason about the world without affecting conversation.
The [Google robotics team shows](https://innermonologue.github.io) that inner monologue  can improve LLM quality by providing space to narrate and re-contextualize information before committing to an idea (e.g., by "speaking" it).

Structural problems:
- The chatbot seems to normalize thinking a lot, then goes on thinking tangents and has trouble staying on topic.
- The conversation seems more likely to break with an `\end{code}`.
- The chatbot sometimes assumes that the user can read its mind.

The last problem can be mitigated with a different encoding that makes the chatbot's speech lines look less similar to its inner monologue lines.
A narrator (below) works well for this, but introduces different structural problems.

### Narrator
If you're using the chatbot for a "choose your own adventure" experience where actions can take place, a narrator can help.
The narrator can also reiterate important medium-term contextual information that would otherwise be lost in the normal flow of conversation.
Just add lines starting with `Narrator: ` or `> `.

Structural problems:
- Using `Narrator: ` can inadvertently introduce a 3rd character named `Narrator` that starts conversing with you.
- Using `> ` can trigger text like `<` and `>>>`  to occur.
- Will make the user perform actions that they may not have chosen.
- Sometimes takes over completely as if it's the text of a book that is continuing after a brief character dialogue.

A narrator gives great results in terms of writing quality but needs to be actively corrected when it makes the wrong choice for the user.

### Actions in square brackets
Characters can perform actions on their own dialogue lines fairly naturally without hinting much at an unwanted document structure.
However, there's still a trade-off because denoting actions with brackets like `[points here]` seems to produce better quality than asterisks like `*points here*` do.

Structural problems:
- Bracketed actions are sometimes put on their own lines, leading to problems similar to the narrator.

I got the idea to use brackets after reading [Simon Wilson's rant](https://www.ermlikeyeah.com/please-god-make-this-pain-go-away/) about how brackets are more proper.
This syntax seems to behave really well as long as it only appears in the speech lines.

### Starting Indicator
Some people add a line like `### Conversation Start` to separate the priming prompt from the chat dialogue.

Structural problems:
- Very likely to add `### Conversation End` to cut the conversation short.

A blank line seems to work well enough as a way to separate the priming prompt from the start of the dialogue.

## Setup
### Parameters
The instructions assume you're running as the correct user (e.g., via `doas`) and have the following environment variables set.
```shell
doas -u gendeux bash -l
delegate_user=${USER}
llama_cpp_dir=/home/${delegate_user}/code/llama.cpp
models_dir=/mnt/llama_model_data/llama_cpp_models
model_subdir=13B
```

### Get llama.cpp
```shell
mkdir -p $(dirname "${llama_cpp_dir}")
cd $(dirname "${llama_cpp_dir}")
git clone https://github.com/ggerganov/llama.cpp $(basename "${llama_cpp_dir}")
cd llama.cpp
make
# Prepare pipenv for later.
pipenv install numpy==1.24.2
pipenv install sentencepiece
```

### Download LLaMA checkpoints
Request the checkpoints from Facebook directly [here](https://github.com/facebookresearch/llama) or see [this comment](https://github.com/facebookresearch/llama/pull/73#issuecomment-1468084739).
The command to get everything but the 65B checkpoint might look like:
```shell
cd $(dirname "${models_dir})
# Omit 65B model, only port 49184, and name the result directory how our commands expect.
aria2c --select-file 1-4,21-23,25,26  --listen-port=49184 --dht-listen-port=49184 "magnet:?xt=urn:btih:...&dn=$(basename ${models_dir})"
```

### Updating and Quantizing
The llama.cpp project moves fast and sometimes breaks stuff.
Check its commits to see if there's something new.
```shell
cd "${llama_cpp_dir}"
# Remember where we were in case results are bad.
# If it is, use `git checkout THE_HASH`.
git rev-parse HEAD | tee "/tmp/${delegate_user}_llama_version.txt"
# No-op if you were at the latest commit before.
git checkout master
# Update and build.
git pull origin master
make
# Convert from checkpoints and quantize. You don't always have to do this.
pipenv run python convert-pth-to-ggml.py "${models_dir}/${model_subdir}/" 1
./quantize "${models_dir}/${model_subdir}/ggml-model-f16.bin" "${models_dir}/${model_subdir}/ggml-model-q4_0.bin" 2
```
