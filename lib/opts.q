\d .utl
.utl.args: .z.x
/Drop all at indices
opts.dropAll:{.[x;();_/;desc y]} 

/ Pass 1b or 0b as typ to affirm/disaffirm that a param is used
/ For instance, we might have verbosity turned off by seeing if the quiet flag is present:
/ .utl.addOpt["quiet,silent";0b;`verbose]
/ q script.q --quiet
/ q) verbose
/ 0b
addOpt:{[flags;typ;handler];
 isBool:-1h ~ type typ;
 / Get all candidate options from the arguments
 val: $[isBool;opts.getBoolOpt;opts.getRegOpt] each "--" ,/: "," vs (),flags;
 / If the option was absent, an empty list is returned, filter these out
 val: first val where not () ~/: val;
 if[count val;
  $[isBool;opts.setBoolOpt;opts.setRegOpt][typ;handler;val]];
 }

/ Regular options are only invoked when there is a value available
/ Providing default values was considered to be overkill
opts.getRegOpt:{
 l:where .utl.args like x,"*";
 / Options where the param values are separate from the param flag (value is at next index)
 separated: x ~/: .utl.args l;
 r:$[count separated;
  ?[separated;.utl.args 1 + l;(count x,"=") _' .utl.args l];
  ()];
 opts.dropAll[`.utl.args;l,1 + (l where separated)];
 first r
 }

/ The typ is really only expected to be a char list or a single char
/ If it is a char list, it is assumed that the value will be a space separated list of arguments
/ .utl.addOpt["ints";enlist "I";`intList]
/ q script.q --ints "20 30 40"
/ q) intList
/ 20 30 40
/ Only the first character from a char list is used
opts.setRegOpt:{[typ;handler;val];
 val: (first typ)$$[10h ~ type typ;" " vs val;val];
 $[-11h ~ type handler;
  handler set val;
  (1 = count handler);
  handler val;
  (handler 0) set (handler 1) val];
 }

/ Boolean options are always invoked
opts.getBoolOpt:{
 opts.dropAll[`.utl.args;l:where .utl.args ~\: x];
 0 < count l
 }

/ Boolean options affirm or disaffirm that an option was set.
/ NOTE:If a function is the handler, it is *ONLY* called  when the flag 
/ is present (the bval is passed simply because a function *always* has at least one argument)
/ If a symbol/function pair is the handler, it is *ALWAYS* called with the bval
/ The reasoning is that any boolean variables mentioned should be set
opts.setBoolOpt:{[b;handler;val];
 bval:b ~ val;  / This is basically not XOR.  The boolean value is true when both are the same
 $[-11h ~ type handler;
  handler set bval;
  (1 = count handler);
  if[val;handler[bval]];
  (handler 0) set (handler 1) bval];
 }

opts.finalize:{
 if[any .utl.args like "-*";
  '"Unhandled options: \n\t", "\n\t" sv .utl.args where .utl.args like "-*"];
 }

