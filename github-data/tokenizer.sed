# tokenizer for GitHub comment bodies
# Preserves these as word chars: # $ % & @ _
# Strips all other characters out
# Combine with `tr ' ' '\n'` to split words onto their own line

# Strip non-word punctuation
s_[]!"()*+,/:;<=>?[\^`{|}~]_ _g

# Strip _ if at beginning or end of word (Markdown italic)
s/[[:<:]]_//g
s/_[[:>:]]//g

# Strip _ again (Markdown bold)
s/[[:<:]]_//g
s/_[[:>:]]//g

# Convert ' . - to _ if in the middle of a word
s/([[:alnum:]_])['.-]([[:alnum:]_])/\1_\2/g

# Convert ' . - to Spc otherwise
s/['.-]/ /g

# Tokenize based on whitespace
s/[[:space:]]+/ /g
