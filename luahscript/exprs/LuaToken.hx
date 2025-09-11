package luahscript.exprs;

enum LuaToken {
	TEof;
	TConst(c: LuaConst);
	TId(s: String);
	TOp(s: String);
	TPOpen;
	TPClose;
	TBrOpen;
	TBrClose;
	TDot;
	TColon;
	TComma;
	TSemicolon;
	TBkOpen;
	TBkClose;
	TDoubleDot;
	TQuadrupleDot;
}
