package luahscript.exprs;

enum StringLiteralKind {
	DoubleQuotes;
	SingleQuotes;
	SquareBracket(count:Int);
}