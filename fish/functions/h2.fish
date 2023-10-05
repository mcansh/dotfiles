
function h2 --wraps='shopify hydrogen' --description 'Shortcut for the Hydrogen CLI'
   set npmPrefix (npm prefix -s)
   $npmPrefix/node_modules/.bin/shopify hydrogen $argv
end
