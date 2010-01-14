\d .utl
arg.args: .z.x
/Drop all at indices
arg.outHandle:-1;
arg.dropAll:{.[x;();_/;desc y]} 
arg.boolOpts:()
arg.regOpts:()
arg.regDefOpts:()
arg.posArgs:()
arg.typeDict:typeDict:(("*";0b;1b),"BXHIJEFCSMDZUVT")!("\"String Literal\"";"Disable Flag";"Enable Flag";"BOOL";"BYTE";"SHORT";"INT";"LONG";"REAL";"FLOAT";"CHARACTER";"SYMBOL";"YYYY.MM";"YYYY.MM.DD";"YYYY.MM.DDTHH:MM:SS.mmm";"HH:MM";"HH:MM:SS";"HH:MM:SS.mmm")

/ Pass 1b or 0b as typ to affirm/disaffirm that a param is used
/ For instance, we might have verbosity turned off by seeing if the quiet flag is present:
/ .utl.addOpt["quiet,silent";0b;`verbose]
/ q script.q --quiet
/ q) verbose
/ 0b
addArg:{[typ;default;num;handler];
  arg.posArgs,:enlist (typ;default;num;handler);
  }

/ Regular options are only invoked when there is a value available
addOpt:{[flags;typ;handler];
  isBool:-1h ~ type typ;
  arg:enlist (flags;typ;handler);
  $[isBool;
    arg.boolOpts,:arg;
    arg.regOpts,:arg
    ];
  }

/ Default value options are always invoked
addOptDef:{[flags;typ;default;handler];
  if[-1h ~ type typ; '"Default value options cannot be boolean"];
  arg.regDefOpts,:enlist (flags;typ;default;handler);
  }

arg.processReg:{[flags;typ;handler];
  / Get all candidate options from the arguments
  val:arg.filterVals arg.getRegOpt each arg.filterFlags flags;
  if[count val;arg.setReg[typ;handler;1b;val];];
  }

arg.processDefReg:{[flags;typ;default;handler];
  val:arg.filterVals arg.getRegOpt each arg.filterFlags flags;
  $[count val;
    arg.setReg[typ;handler;1b;val];
    arg.setReg[typ;handler;0b;default]
    ];
  }

arg.processBool:{[flags;typ;handler];
  / Get all candidate options from the arguments
  val:arg.filterVals arg.getBoolOpt each arg.filterFlags flags;
  if[count val;arg.setBool[typ;handler;val];];
  }

arg.processArg:{[typ;default;num;handler];
  val:typ$$[count[arg.args] < first num;
    '"Insufficient arguments";
    0h < type num; / If num is a list (eg (),3), we consume all remaining values
    arg.args;
    first[$[(num~0) and count arg.args;num:1;num]]#arg.args / If a zero is used as the num, it's treated as a single optional argument (just don't wanna do 1#()
    ];
  $[(0 <> first num) and 0h < type num;
    arg.setReg["";handler;0b;val];
    arg.setReg["";handler;0b;$[1 ~ num;first;::] $[0 = count val;default;val]]
    ];
  arg.dropAll[`.utl.arg.args;til count val];
  }

arg.filterFlags:{"--" ,/: "," vs (),x}
arg.filterVals:{first x where not () ~/: x}

arg.getRegOpt:{
  l:where arg.args like x,"*";
  / Options where the param values are separate from the param flag (value is at next index)
  separated: x ~/: arg.args l;
  r:$[count separated;
    ?[separated;arg.args 1 + l;(count x,"=") _' arg.args l];
    ()
    ];
  arg.dropAll[`.utl.arg.args;l,1 + (l where separated)];
  first r
  }

/ The typ is really only expected to be a char list or a single char
/ If it is a char list, it is assumed that the value will be a space separated list of arguments
/ .utl.addOpt["ints";enlist "I";`intList]
/ q script.q --ints "20 30 40"
/ q) intList
/ 20 30 40
/ Only the first character from a char list is used
arg.setReg:{[typ;handler;parseVal;val];
  if[parseVal;
    val: (first typ)$$[10h ~ type typ;" " vs val;val];
    ];
  $[-11h ~ type handler;
    handler set val;
    (1 = count handler);
    handler val;
    (handler 0) set (handler 1) val
    ];
  }

/ Boolean options are always invoked
arg.getBoolOpt:{
  arg.dropAll[`.utl.arg.args;l:where arg.args ~\: x];
  0 < count l
  }

/ Boolean options affirm or disaffirm that an option was set.
/ NOTE:If a function is the handler, it is *ONLY* called  when the flag 
/ is present (the bval is passed simply because a function *always* has at least one argument)
/ If a symbol/function pair is the handler, it is *ALWAYS* called with the bval
/ The reasoning is that any boolean variables mentioned should be set
arg.setBool:{[b;handler;val];
  bval:b ~ val;  / This is basically not XOR.  The boolean value is true when both are the same
  $[-11h ~ type handler;
    handler set bval;
    (1 = count handler);
    if[val;handler[bval]];
    (handler 0) set (handler 1) bval];
  }

parseArgs:{
  output:("";());
  output[0],: raze arg.argMessage .' arg.posArgs;
  if[count arg.regDefOpts;
    output: output,'raze each flip arg.optDefMessage .' arg.regDefOpts;
    ];
  if[count arg.boolOpts,arg.regOpts;
    output: output,'raze each flip arg.optMessage .' arg.boolOpts,arg.regOpts;
    ];
  r:@[;::;::]{
    arg.processBool .' arg.boolOpts;
    arg.processReg .' arg.regOpts;
    arg.processDefReg .' arg.regDefOpts;
    arg.processArg .' arg.posArgs;
    arg.handleUnrecognized[];
    };
  if[(10h ~ type r) or not 0 = count arg.args;
    if[10h ~ type r; arg.outHandle "error: ", r];
    arg.outHandle "usage: ",ssr[$[(::) ~ x;"q ",string[.z.f]," %cmd%";x];"%cmd%";1 _ output[0]]; / There will be one extra line of padding at the front of the command line string
    if[count output 1;arg.outHandle ` sv output 1;];
    arg.exit 1; / Explicitly name exit function to allow test override
    ];
  }

arg.exit:{if[not .utl.DEBUG;exit x];}

arg.optMessage:{[flags;typ;handler];
  cmdLine: " [ ",first[arg.filterFlags flags],$[-11h ~ type first handler;
    " ",string first handler;
    10h ~ type typ;
    " \"",arg.typeDict[first typ]," ...\"";
    -1h ~ type typ;
    "";
    " ",arg.typeDict[first typ]
    ]," ]";
  explainLine: ("," sv arg.filterFlags[flags]),"     ",$[-11h ~ type first handler;string[first handler]," - ";""],arg.typeDict first typ;
  (cmdLine;enlist "\t",explainLine)
  }

arg.optDefMessage:{[flags;typ;default;handler];
  defText:":(",$[10h ~ type default;"\"",default,"\"";" " sv string (),default],")";
  cmdLine: " [ ",first[arg.filterFlags flags]," ",$[-11h ~ type first handler;
    string first handler;
    10h ~ type typ;
    "\"",arg.typeDict[first typ]," ...\"";
    arg.typeDict[first typ]
    ],defText," ]";
  explainLine: ("," sv arg.filterFlags[flags]),"     ",$[-11h ~ type first handler;string[first handler]," - ";""],arg.typeDict first typ, defText;
  (cmdLine;enlist "\t",explainLine)
  }

arg.argMessage:{[typ;default;num;handler];
  defText:$[10h ~ type default;":(\"",default,"\")";() ~ default;"";":(",(" " sv string (),default),")"];
  cmdLine: " ", " " sv first[max (num;1)]#enlist $[-11h ~ type first handler;
    string first handler;
    arg.typeDict[first typ]
    ],defText;
  {[num;cmdLine] $[first[num] ~ 0;" [",cmdLine," ]";cmdLine]}[num] cmdLine,$[0h < type num;"...";""]
  }

arg.handleUnrecognized:{[messageGiven];
  msg:"Unrecognized options: \n\t", "\n\t" sv arg.args where arg.args like "-*";
  if[any arg.args like "-*";
    'msg
    ];
  }

