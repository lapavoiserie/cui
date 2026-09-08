package cui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class StateMacro {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var stateInits:Array<Expr> = [];
        var newFields:Array<Field> = [];

        for (field in fields) {
            var isState = false;
            var stateMeta:Null<MetadataEntry> = null;
            if (field.meta != null) {
                for (m in field.meta) {
                    if (m.name == ":state") {
                        isState = true;
                        stateMeta = m;
                        break;
                    }
                }
            }

            if (!isState) {
                newFields.push(field);
                continue;
            }

            var origType:Null<ComplexType> = null;
            var defaultExpr:Null<Expr> = null;
            switch (field.kind) {
                case FVar(t, e):
                    origType = t;
                    defaultExpr = e;
                default:
            }

            if (origType == null) {
                Context.error("@:state fields must have an explicit type", field.pos);
                continue;
            }

            if (defaultExpr == null) {
                defaultExpr = macro null;
            }

            var fieldName = field.name;

            // `@:state(durable)` -- the cell is born from the store rather than
            // from the default, and writes back to it. Wrapping the default
            // expression keeps this out of the constructor-ordering question
            // entirely; see rui.macros.DurableState.
            var durable = rui.macros.DurableState.requestOf(field, stateMeta, origType);
            if (durable != null)
                defaultExpr = rui.macros.DurableState.hydrate(durable, defaultExpr);

            // Choose specialized State class based on type
            var stateClassName = getStateClassName(origType);
            var stateType:ComplexType = TPath({
                pack: ["cui", "state"],
                name: "State",
                sub: stateClassName,
                params: stateClassName == "State" ? [TPType(origType)] : [],
            });

            
            // The field becomes a property over a cell named `count_` -- see

            
            // rui.macros.StateProperty. The specialised State subclass is the

            
            // cell's type; the registry name stays the field's own.

            
            var cell = rui.macros.StateProperty.cellName(fieldName);

            
            for (f in rui.macros.StateProperty.split(field, origType, stateType))

            
                newFields.push(f);

            
            var nameExpr = macro $v{fieldName};
            var initExpr = switch (stateClassName) {
                case "IntState": macro $i{cell} = new cui.state.State.IntState($defaultExpr, $nameExpr);
                case "BoolState": macro $i{cell} = new cui.state.State.BoolState($defaultExpr, $nameExpr);
                case "FloatState": macro $i{cell} = new cui.state.State.FloatState($defaultExpr, $nameExpr);
                case "StringState": macro $i{cell} = new cui.state.State.StringState($defaultExpr, $nameExpr);
                default: macro $i{cell} = new cui.state.State.State($defaultExpr, $nameExpr);
            };
            stateInits.push(initExpr);
            if (durable != null)
                stateInits.push(rui.macros.DurableState.bindCall(durable, macro this, cell, field.pos));
        }

        if (stateInits.length > 0) {
            var ctorFound = false;
            for (f in newFields) {
                if (f.name == "new") {
                    ctorFound = true;
                    switch (f.kind) {
                        case FFun(func):
                            var existingBody = func.expr;
                            var allExprs:Array<Expr> = stateInits.copy();
                            if (existingBody != null) allExprs.push(existingBody);
                            func.expr = macro $b{allExprs};
                        default:
                    }
                    break;
                }
            }

            if (!ctorFound) {
                var allExprs:Array<Expr> = [macro super()];
                for (e in stateInits) allExprs.push(e);
                newFields.push({
                    name: "new",
                    access: [APublic],
                    kind: FFun({
                        args: [],
                        ret: null,
                        expr: macro $b{allExprs},
                    }),
                    pos: Context.currentPos(),
                });
            }
        }

        return newFields;
    }

    static function getStateClassName(ct:ComplexType):String {
        return switch (ct) {
            case TPath(p):
                if (p.pack.length == 0) {
                    switch (p.name) {
                        case "Int": "IntState";
                        case "Bool": "BoolState";
                        case "Float": "FloatState";
                        case "String": "StringState";
                        default: "State";
                    };
                } else {
                    "State";
                }
            default: "State";
        };
    }
}
#end
