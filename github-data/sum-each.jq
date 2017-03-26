# For a list of objects, sum each field
# From http://stackoverflow.com/questions/28484534/
# Be sure to run with
#   --null-input   because we get the inputs with 'inputs[]'
#   --slurp        because we've used 'inputs[]' not 'inputs',
#                  unless it's already an array
reduce (inputs[] | to_entries[]) as $i ({}; .[$i.key] += $i.value)

