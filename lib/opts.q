\d .u
.u.args: .z.x
/Drop all at indices
opts.dropAll:{.[x;();_/;desc y]} 

/ Pass 1b or 0b as typ to affirm/disaffirm that a param is used
/ For instance, we might have verbosity turned off by seeing if the quiet flag is present:
/ .opts.addOpt["quiet,silent";0b;`verbose]
/ q script.q --quiet
/ q) verbose
/ 0b
addOpt:{[flags;typ;handler];
 isBool:-1h ~ type typ;
 val: first $[isBool;opts.getBoolOpt;opts.getRegOpt] each "--" ,/: "," vs (),flags;
 if[count val;
  $[isBool;opts.setBoolOpt;opts.setRegOpt][typ;handler;val]];
 }

opts.getRegOpt:{
 l:where .u.args like x,"*";
 / Options where the param values are separate from the param flag (value is at next index)
 separated: x ~/: .u.args l;
 r:$[count separated;
  ?[separated;.u.args 1 + l;(count x,"=") _' .u.args l];
  ()];
 opts.dropAll[`.u.args;l,1 + (l where separated)];
 first r
 }

opts.setRegOpt:{[typ;handler;val];
 val: (first typ)$$[10h ~ type typ;" " vs val;val];
 $[-11h ~ type handler;
  handler set val;
  (1 = count handler);
  handler val;
  (handler 0) set (handler 1) val];
 }

opts.getBoolOpt:{
 opts.dropAll[`.u.args;l:where .u.args ~\: x];
 0 < count l
 }

opts.setBoolOpt:{[b;handler;val];
 bval:b ~ val;
 $[-11h ~ type handler;
  handler set bval;
  (1 = count handler);
  if[val;handler[bval]];
  (handler 0) set (handler 1) bval];
 }

opts.finalize:{
 if[any .u.args like "-*";
  '"Unhandled options: \n\t", "\n\t" sv .u.args where .u.args like "-*"];
 }

