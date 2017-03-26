[
  .[] |
  .reactions |
  del(.url) |
  . + {thumbsup: ."+1", thumbsdown: ."-1", comments: 1} |
  del(."+1") |
  del(."-1")
]
