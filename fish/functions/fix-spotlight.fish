# https://github.com/yarnpkg/yarn/issues/6453#issuecomment-476048618
function fix-spotlight
	find . -type d -name "node_modules" -exec touch "{}/.metadata_never_index" \;
end
