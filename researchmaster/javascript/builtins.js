
function TLH_builtins () { }

TLH_builtins.prototype.preg_replace = function (fromregstring, to, string) {
	var reg = new RegExp(fromregstring, "g")
	return string.replace(reg, to);
}

TLH_builtins.prototype.preg_match = function (regstring, string) {
	var reg  = new RegExp(regstring);
	return string.match(reg);
}

