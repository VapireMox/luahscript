package luahscript.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;
using StringTools;
using Lambda;

class LuaLibMacro {
	public static inline var LUALIB_PREFFIX:String = "lualib_";
	public static var keyIndex:Map<String, String> = [];

	static var sbFields:Array<Field>;

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		sbFields = [];
		makeLibsFunction(fields);
		return fields;
	}

	static inline function makeMultiReturn():Field {
		return {
			name: "multiReturn",
			access: [AStatic],
			kind: FFun({
				args: [{
					name: "args",
					type: macro:haxe.Rest<Dynamic>,
				}],
				expr: macro {
					return luahscript.LuaAndParams.fromArray(args);
				},
				ret: Context.toComplexType(Context.getType("luahscript.LuaAndParams")),
			}),
			pos: Context.currentPos()
		}
	}

	static inline function makeImplements():Field {
		var sb:Array<ObjectField> = [for(f in sbFields) {field: f.name.substr(LUALIB_PREFFIX.length), expr: if(f.kind.match(FFun(_)) && f.meta.find(m -> m.name == ":multiArgs") != null) macro Reflect.makeVarArgs($i{f.name})
		else macro $i{f.name}}];
		return {
			name: "implement",
			access: [APublic, AStatic, AInline],
			kind: FFun({
				args: [],
				expr: macro {
					var obj:Dynamic = ${{expr: EObjectDecl(sb), pos: Context.currentPos()}};
					return luahscript.LuaTable.fromObject(obj);
				},
				ret: macro: luahscript.LuaTable<Dynamic>
			}),
			pos: Context.currentPos()
		};
	}

	static function makeLibsFunction(fields:Array<Field>):Array<Field> {
		for(i=>field in fields) {
			if(field.name.startsWith(LUALIB_PREFFIX)) {
				var newField:Field = {
					name: field.name,
					access: field.access,
					doc: field.doc,
					kind: null,
					pos: field.pos,
					meta: field.meta
				};
				if(field.meta.find(m -> m.name == ":multiReturn") != null) {
					switch(field.kind) {
						case FFun(func):
							func.ret = Context.toComplexType(Context.getType("luahscript.LuaAndParams"));
							Reflect.setProperty(newField, "kind", FFun(func));
						case _:
							Reflect.setProperty(newField, "kind", field.kind);
					}
				} else Reflect.setProperty(newField, "kind", field.kind);
				fields.remove(field);
				fields.insert(i, newField);
				sbFields.push(newField);
			}
		}

		fields.push(makeMultiReturn());
		fields.push(makeImplements());

		return fields;
	}
}