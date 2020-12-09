extends Node


#05. signals
#06. enums
enum {EV_VOID, EV_STRING, EV_FLOAT, EV_VECTOR, EV_ENTITY, EV_FIELD, EV_FUNCTION, EV_POINTER }	# etype_t
#07. constants
#08. exported variables
#09. public variables
var progs = Dictionary()
#10. private variables
#11. onready variables


#	 _ __   __ _ _ __ ___  ___ 
#	| '_ \ / _` | '__/ __|/ _ \
#	| |_) | (_| | |  \__ \  __/
#	| .__/ \__,_|_|  |___/\___|
#	|_|                        


# -----------------------------------------------------
# load_progs
# -----------------------------------------------------
func load_progs(filename):
	var dir = Directory.new()
	var path = console.cvars["path_prefix"].value + "cache/" + filename + ".res"
	
	if dir.file_exists(path) and console.cvars["cache"].value == 1:
		var cache_file = File.new()
		cache_file.open(path, File.READ)
		progs = cache_file.get_var(true)
		cache_file.close()
	
	else:
		
		parser_v3.open_file(console.cvars["path_prefix"].value + "id1-x/" + filename)
		
		# -----------------------------------------------------
		# dprograms_t
		# -----------------------------------------------------
		var dprograms_t = parser_v3.create("dprograms_t")
		dprograms_t.add("version",			parser_v3.T_U32		)
		dprograms_t.add("crc",				parser_v3.T_U32		)
		dprograms_t.add("ofs_statements",	parser_v3.T_U32		)
		dprograms_t.add("num_statements",	parser_v3.T_U32		)
		dprograms_t.add("ofs_globaldefs",	parser_v3.T_U32		)
		dprograms_t.add("num_globaldefs",	parser_v3.T_U32		)
		dprograms_t.add("ofs_fielddefs",	parser_v3.T_U32		)
		dprograms_t.add("num_fielddefs",	parser_v3.T_U32		)
		dprograms_t.add("ofs_functions",	parser_v3.T_U32		)
		dprograms_t.add("num_functions",	parser_v3.T_U32		)
		dprograms_t.add("ofs_strings",		parser_v3.T_U32		)		# Character strings, separated by '\0'. First one is \0
		dprograms_t.add("size_strings",		parser_v3.T_U32		)		# total size of string data
		dprograms_t.add("ofs_globals",		parser_v3.T_U32		)
		dprograms_t.add("num_globals",		parser_v3.T_U32		)
		dprograms_t.add("entityfields",		parser_v3.T_I16		)
		
		# -----------------------------------------------------
		# statement_t
		# -----------------------------------------------------
		var statement_t = parser_v3.create("statement_t")
		statement_t.add("op",	parser_v3.T_U16		)
		statement_t.add("a",	parser_v3.T_U16		)
		statement_t.add("b",	parser_v3.T_U16		)
		statement_t.add("c",	parser_v3.T_U16		)
		
		# -----------------------------------------------------
		# def_t
		# -----------------------------------------------------
		var def_t = parser_v3.create("def_t")
		def_t.add("type",		parser_v3.T_U16		)
		def_t.add("offset",		parser_v3.T_U16		)
		def_t.add("s_name",		parser_v3.T_U32		)
		
		# -----------------------------------------------------
		# function_t
		# -----------------------------------------------------
		var function_t = parser_v3.create("function_t")
		function_t.add("first_statement",	parser_v3.T_I32			)
		function_t.add("parm_start",		parser_v3.T_I32			)
		function_t.add("locals",			parser_v3.T_I32			)
		function_t.add("profile",			parser_v3.T_I32			)
		function_t.add("s_name",			parser_v3.T_I32			)
		function_t.add("s_file",			parser_v3.T_I32			)
		function_t.add("numparms",			parser_v3.T_I32			)
		function_t.add("parm_size",			parser_v3.T_U8,		8	)
		
		# -----------------------------------------------------
		# Eval
		# -----------------------------------------------------
		_get_dprograms(dprograms_t)
		_get_strings()
		_get_globaldefs(def_t)
		_get_fielddefs(def_t)
		_get_functions(function_t)
		_get_statements(statement_t)
		
		parser_v3.close_file()
		
		
		if console.cvars["cache"].value == 1:
			dir.make_dir_recursive( path.get_base_dir() )
			
			var cache_file = File.new()
			var err = cache_file.open(path, File.WRITE)
			cache_file.store_var(progs, true)
			cache_file.close()
	
	_generate_entvars_script()
	
	console.con_print_ok("%s loaded." % filename)



# -----------------------------------------------------
# _get_dprograms
# -----------------------------------------------------
func _get_dprograms(struct):
	progs.dprograms = struct.eval(0)
	
	# -----------------------------------------------------
	# debug print DEBUG_LOW
	# -----------------------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, ".dat")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		for k in progs.dprograms:
			var line = "%s -- %s" % [k, progs.dprograms[k]]
			console.con_print_debug(console.DEBUG_LOW, line)
		
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_strings
# -----------------------------------------------------
func _get_strings():
	var offset = progs.dprograms.ofs_strings
	var end = progs.dprograms.ofs_strings + progs.dprograms.size_strings
	
	var sdict = Dictionary()
	
	parser_v3.set_offset(offset)
	
	while parser_v3.get_offset() < end:
		var key = parser_v3.get_offset() - offset
		var s = parser_v3.get_string()
		
		sdict[key] = s
	
	progs.strings = sdict
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "strings")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		# ------------------------------------
		# debug print DEBUG_HIGH
		# ------------------------------------
		if console.debug_level >= console.DEBUG_HIGH:
			for k in sdict:
				var line = "%s -- %s" % [k, sdict[k]]
				console.con_print_debug(console.DEBUG_HIGH, line)
			
			var s_max = 0
			for v in sdict.values():
				var length = v.length()
				if length > s_max:
					s_max = length
			console.con_print_debug(console.DEBUG_HIGH,"Biggest string length: %d" % s_max)
		
		console.con_print_debug(console.DEBUG_LOW, "%d strings loaded." % sdict.size())
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_globaldefs
# -----------------------------------------------------
func _get_globaldefs(struct):
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_globaldefs + struct_size
	var num = progs.dprograms.num_globaldefs
	
	var globaldefs = Dictionary()
	var globals_by_name = Dictionary()
	var globals = StreamPeerBuffer.new()
	
	var i = 1
	
	while i < num - 1:
		# ------------------------------------
		# Get def entry
		# ------------------------------------
		var def = struct.eval(offset)
		
		# ------------------------------------
		# Get s_name
		# ------------------------------------
		def.s_name = progs.strings[def.s_name]
		
		# ------------------------------------
		# Eval savegame bit
		# ------------------------------------
		def.savegame = (def.type >= 0x8000)
		
		if def.savegame:
			def.type -= 0x8000
		
		# ------------------------------------
		# Add dict entry
		# ------------------------------------
		var key = def.offset
		
		if def.type == EV_VECTOR:
			key = str(key) + "_vec"
		
		if globaldefs.has(key):
			key = str(key) + "_" + str(def.offset)
			var type = def.type
			var s_name = def.s_name
			var _offset = def.offset
			console.con_print_warn("[%d] [%s] Redefinition of: %s" % [ _offset, _get_type_sting(type), key, def.s_name ])
			
		globaldefs[key] = def
		if not def.s_name.begins_with("IMM"):
			globals_by_name[def.s_name] = key
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		i += 1
	
	# ------------------------------------
	# Add globaldefs to progs
	# ------------------------------------
	progs.globaldefs = globaldefs
	progs.globals_by_name = globals_by_name
	
	# ------------------------------------
	# Add globals to progs
	# ------------------------------------
	var arr = parser_v3.buffer.data_array
	var start = progs.dprograms.ofs_globals
	var end = progs.dprograms.ofs_globals + progs.dprograms.num_globals * 4 - 1
	
	globals.data_array = arr.subarray(start, end)
	
	progs.globals = globals
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "globaldefs")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		# ------------------------------------
		# debug print DEBUG_HIGH
		# ------------------------------------
		if console.debug_level >= console.DEBUG_HIGH:
			
			i = 0
			
			for k in progs.globaldefs:
				var type = progs.globaldefs[k].type
				var s_name = progs.globaldefs[k].s_name
				var line = ""
				
				line = "%s -- %s -- %s" % [ str(k), _get_type_sting(type), s_name  ]
				
				console.con_print_debug(console.DEBUG_HIGH, line)
				i += 1
				
#				if i > 100:
#					break
		
		console.con_print_debug(console.DEBUG_LOW, "%d globaldefs loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_fielddefs
# -----------------------------------------------------
func _get_fielddefs(struct):
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_fielddefs + struct_size
	var num = progs.dprograms.num_fielddefs
	
	var fielddefs = Dictionary()
	
	var i = 1
	
	while i < num:
		# ------------------------------------
		# Get def entry
		# ------------------------------------
		var def = struct.eval(offset)
		
		# ------------------------------------
		# Get s_name
		# ------------------------------------
		def.s_name = progs.strings[def.s_name]
		
		# ------------------------------------
		# Eval savegame bit
		# ------------------------------------
		def.savegame = (def.type >= 0x8000)
		
		if def.savegame:
			def.type -= 0x8000
		
		# ------------------------------------
		# Cleanup + add dict entry
		# ------------------------------------
		var key = def.offset
		
		if def.type == EV_VECTOR:
			key = str(key) + "_vec"
		
		if fielddefs.has(key):
			key = str(key) + "_" + str(def.offset)
			var type = def.type
			var s_name = def.s_name
			var _offset = def.offset
			console.con_print_warn("[%d] [%s] Redefinition of: %s" % [ _offset, _get_type_sting(type), key, def.s_name ])
			
		fielddefs[key] = def
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		i += 1
	
	# ------------------------------------
	# Add fielddefs entry to progs
	# ------------------------------------
	progs.fielddefs = fielddefs
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "fielddefs")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		# ------------------------------------
		# debug print DEBUG_HIGH
		# ------------------------------------
		if console.debug_level >= console.DEBUG_HIGH:
			
			i = 0
			
			for k in progs.fielddefs:
				var type = progs.fielddefs[k].type
				var s_name = progs.fielddefs[k].s_name
				var line = ""
				
				line = "%s -- %s -- %s" % [ str(k), _get_type_sting(type), s_name  ]
				
				console.con_print_debug(console.DEBUG_HIGH, line)
				i += 1
				
#				if i > 100:
#					break
	
	console.con_print_debug(console.DEBUG_LOW, "%d fielddefs loaded." % num)
	console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_functions
# -----------------------------------------------------
func _get_functions(struct):
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_functions + struct_size
	var num = progs.dprograms.num_functions
	
	var functions = Dictionary()
	
	var i = 1
	
	while i < num - 1:
		# ------------------------------------
		# Get function entry
		# ------------------------------------
		var function = struct.eval(offset)
		
		# ------------------------------------
		# Get s_name
		# ------------------------------------
		function.s_name = progs.strings[ function.s_name ]
		
		# ------------------------------------
		# Get source file string
		# ------------------------------------
		function.s_file = progs.strings[ function.s_file ]
		
		# ------------------------------------
		# Cleanup + add dict entry
		# ------------------------------------
		functions[i] = function
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		i += 1
	
	# ------------------------------------
	# Add fielddefs entry to progs
	# ------------------------------------
	progs.functions = functions
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "functions")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		# ------------------------------------
		# debug print DEBUG_HIGH
		# ------------------------------------
		if console.debug_level >= console.DEBUG_HIGH:
			
			i = 0
			
			for k in progs.functions:
				
				var line = "%d:\t(%d) %s -- statement: %d -- param: %d -- locals: %d -- profile: %d -- source: %s" % [
					k,
					progs.functions[k].numparms,
					progs.functions[k].s_name,
					progs.functions[k].first_statement,
					progs.functions[k].parm_start,
					progs.functions[k].locals,
					progs.functions[k].profile,
					progs.functions[k].s_file,
					]
				
				console.con_print_debug(console.DEBUG_HIGH, line)
				i += 1
				
#				if i > 100:
#					break
		
		console.con_print_debug(console.DEBUG_LOW, "%d functions loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_statements
# -----------------------------------------------------
func _get_statements(struct):
	var offset = progs.dprograms.ofs_statements + 8
	var num = progs.dprograms.num_statements
	
	var statements = Dictionary()
	
	var struct_size = struct.get_size()
	var i = 1
	
	while i < num - 1:
		# ------------------------------------
		# Get statement
		# ------------------------------------
		var statement = struct.eval(offset)
		
		statements[i] = statement
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		i += 1
		
	
	# ------------------------------------
	# Add statements to progs
	# ------------------------------------
	progs.statements = statements
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "statements")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "%d statements loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")

#	__   ___ __ ___  
#	\ \ / / '_ ` _ \ 
#	 \ V /| | | | | |
#	  \_/ |_| |_| |_|

enum opcode {
	OP_DONE,
	OP_MUL_F,
	OP_MUL_V,
	OP_MUL_FV,
	OP_MUL_VF,
	OP_DIV_F,
	OP_ADD_F,
	OP_ADD_V,
	OP_SUB_F,
	OP_SUB_V,
	
	OP_EQ_F,
	OP_EQ_V,
	OP_EQ_S,
	OP_EQ_E,
	OP_EQ_FNC,
	
	OP_NE_F,
	OP_NE_V,
	OP_NE_S,
	OP_NE_E,
	OP_NE_FNC,
	
	OP_LE,
	OP_GE,
	OP_LT,
	OP_GT,

	OP_LOAD_F,
	OP_LOAD_V,
	OP_LOAD_S,
	OP_LOAD_ENT,
	OP_LOAD_FLD,
	OP_LOAD_FNC,

	OP_ADDRESS,

	OP_STORE_F,
	OP_STORE_V,
	OP_STORE_S,
	OP_STORE_ENT,
	OP_STORE_FLD,
	OP_STORE_FNC,

	OP_STOREP_F,
	OP_STOREP_V,
	OP_STOREP_S,
	OP_STOREP_ENT,
	OP_STOREP_FLD,
	OP_STOREP_FNC,

	OP_RETURN,
	OP_NOT_F,
	OP_NOT_V,
	OP_NOT_S,
	OP_NOT_ENT,
	OP_NOT_FNC,
	OP_IF,
	OP_IFNOT,
	OP_CALL0,
	OP_CALL1,
	OP_CALL2,
	OP_CALL3,
	OP_CALL4,
	OP_CALL5,
	OP_CALL6,
	OP_CALL7,
	OP_CALL8,
	OP_STATE,
	OP_GOTO,
	OP_AND,
	OP_OR,
	
	OP_BITAND,
	OP_BITOR
}

var _q1_2_godot_types = {
	EV_ENTITY : "Spatial",
	EV_FLOAT : "float",
	EV_FUNCTION : "int",
	EV_STRING : "String",
	EV_VECTOR : "Vector3"
}



# -----------------------------------------------------
# _get_opcode_name
# -----------------------------------------------------
func _get_opcode_name(op):
	var keys = opcode.keys()
	return keys[op]



# -----------------------------------------------------
# _generate_entvars_script
# -----------------------------------------------------
func _generate_entvars_script():
	var script = ""
	script += "extends Object\n\n"
	
	var vector_component = []
	var index_dict = "\nvar index = {\n"
	
	for key in progs.fielddefs:
		var _name = progs.fielddefs[key].s_name
		var _type = _q1_2_godot_types[progs.fielddefs[key].type]
		
		if _type != "Vector3":
			index_dict += "\t%d: \"%s\",\n" % [key, _name]
		
		if _type == "float":
			if vector_component.has(_name):
				continue
		
		script += "var %s : %s\n" % [_name, _type]
		
		if _type == "Vector3":
			vector_component.append(_name + "_x")
			vector_component.append(_name + "_y")
			vector_component.append(_name + "_z")
	
	script += index_dict + "}\n"
	
	var fields_file = File.new()
	var err = fields_file.open(console.cvars["path_prefix"].value + "/cache/entvars.gd", File.WRITE)
	fields_file.store_string(script)
	fields_file.close()



# -----------------------------------------------------
# _disassemble
# -----------------------------------------------------
func _disassemble(p_function):
#	if funcname == "":
#		console.con_print_error("Parameter <funcname> needed.")
#		return
	
	var func_num : int = -1
	
	if not progs.has("functions"):
		console.con_print_error("No .dat file loaded.")
		return
	
	if p_function.is_valid_integer():
		func_num = int(p_function)
	else:
		for k in progs.functions.keys():
			if progs.functions[k].s_name == p_function:
				func_num = k
	
	
	
	if not progs.functions.has(func_num):
		console.con_print_error("Function <%d> not found." % func_num)
		return
	
	var function = progs.functions[func_num]
	var builtin = false
	
	if function.first_statement < 1:
		builtin = true
	
	var first_statement_str : String
	
	if builtin:
		first_statement_str = "builtin #%d" % func_num
	else:
		first_statement_str = str(function.first_statement)
	
	console.con_print("----------------------------------")
	console.con_print("function[%d]: %s" % [func_num, function.s_name] )
	console.con_print("----------------------------------")
	console.con_print("first_statement: %s" % first_statement_str)
	console.con_print("parm_start: %d" % function.parm_start)
	console.con_print("locals: %d" % function.locals)
	console.con_print("profile: %d" % function.profile)
	console.con_print("s_file: %s" % function.s_file)
	console.con_print("numparms: %d" % function.numparms)
	console.con_print("parm_size[8]: [%d %d %d %d -- %d %d %d %d]" % function.parm_size)
	console.con_print("----------------------------------")
	
	if not builtin:
	
		var i = 0
		
		while i < 10:
			var st = function.first_statement + i
			var statement = progs.statements[ st ]
			var op = statement.op
			var a = statement.a
			var b = statement.b
			var c = statement.c
			
			var info_a = ""
			var info_b = ""
			var info_c = ""
			
#			if op == opcode.OP_LOAD_F:
#				info_a = progs.globaldefs[a].s_name
#
#				progs.globals.seek(b*4)
#				var _b = progs.globals.get_u32()
#				info_b = progs.fielddefs[_b].s_name
			
			console.con_print("%d:\t [%d]\t%s " % [st, op, _get_opcode_name(op)])
			console.con_print("\t\t\t a:\t%d\t%s" % [a, info_a])
			console.con_print("\t\t\t b:\t%d\t%s" % [b, info_b])
			console.con_print("\t\t\t c:\t%d\t%s" % [c, info_c])
		
			#console.con_print("%d: %s\n\ta: %d\n\tb: %d\n\tc: %d\n" % [ i, _get_opcode_name(op), a, b, c ] )
			i += 1

const OFS_NULL = 0
const OFS_RETURN = 1
const OFS_PARM0 = 4
const OFS_PARM1 = 7
const OFS_PARM2 = 10
const OFS_PARM3 = 13
const OFS_PARM4 = 16
const OFS_PARM5 = 19
const OFS_PARM6 = 22
const OFS_PARM7 = 25
const RESERVED_OFS = 28
const OFS_SELF = 28
const OFS_OTHER = 29
const OFS_WORLD = 30

const MAX_STACK_DEPTH = 32
const LOCALSTACK_SIZE = 2048

var pr_stack = []
var pr_xstatement : int = 0
var pr_xfunction : int = 0
var pr_depth : int = 0
var exitdepth : int = 0

var localstack = []
var localstack_used : int

var pr_pointer : Dictionary
var pr_strings : Dictionary
var pr_string_num : int = -1

# Game Data
var cached_sounds : Dictionary
var cached_models : Dictionary
var lightstyles : Dictionary

# -----------------------------------------------------
# _PR_EnterFunction
# -----------------------------------------------------
func _PR_EnterFunction(funcnum : int):
	
	console.con_print_debug(console.DEBUG_MEDIUM,
			"_PR_EnterFunction: %s",
			[ progs.functions[funcnum].s_name] )
	
	pr_stack.push_back( { "s": pr_xstatement, "f": pr_xfunction} )
	pr_depth += 1
	
	if pr_depth >= MAX_STACK_DEPTH:
		console.con_print_error("Stack overflow")
	
	# -----------------------------------------------------
	# save off any locals that the new function steps on
	# -----------------------------------------------------
	var locals : int = progs.functions[funcnum].locals
	var parm_start : int = progs.functions[funcnum].parm_start
	
	if locals + localstack_used > LOCALSTACK_SIZE:
		console.con_print_error("PR_ExecuteProgram: locals stack overflow")
	
	progs.globals.seek(parm_start * 4 )
	
	for i in range(locals):
		localstack.push_back(progs.globals.get_u32())
		
	localstack_used += locals
	
	# -----------------------------------------------------
	# copy parameters
	# -----------------------------------------------------
	var numparms : int = progs.functions[funcnum].numparms
	var parm_size  = progs.functions[funcnum].parm_size
	var o : int = parm_start
	
	for i in range(numparms):
		for j in range(parm_size[i]):
			progs.globals.seek(OFS_PARM0 + i * 3 + j * 4)
			var value = progs.globals.get_u32()
			
			progs.globals.seek(o)
			progs.globals.put_u32(value)
			o += 4
	
	pr_xfunction = funcnum
	
	return progs.functions[funcnum].first_statement - 1



# -----------------------------------------------------
# _PR_LeaveFunction
# -----------------------------------------------------
func _PR_LeaveFunction():
	
	console.con_print_debug(console.DEBUG_MEDIUM,
			"_PR_LeaveFunction: %s",
			[ progs.functions[pr_xfunction].s_name ] )
	
	if pr_depth < 0:
		console.con_print_error("prog stack underflow")
	
	# -----------------------------------------------------
	# restore locals from the stack
	# -----------------------------------------------------
	var c = progs.functions[pr_xfunction].locals
	
	localstack_used -= c
	
	if c < 0:
		console.con_print_error("PR_ExecuteProgram: locals stack underflow")
	
	progs.globals.seek(progs.functions[pr_xfunction].parm_start)
	
	for i in range(c):
		progs.globals.put_32( localstack.pop_back() )
	
	pr_depth -= 1
	
	var stack = pr_stack.pop_back()
	pr_xfunction = stack.f
	
	return stack.s



# -----------------------------------------------------
# exec
# -----------------------------------------------------
func exec(p_function):
	var func_num : int = -1
	
	if not progs.has("functions"):
		console.con_print_error("No .dat file loaded.")
		return
	
	if p_function.is_valid_integer():
		func_num = int(p_function)
	else:
		for k in progs.functions.keys():
			if progs.functions[k].s_name == p_function:
				func_num = k
	
	exitdepth = pr_depth
	
	var s =_PR_EnterFunction(func_num)
	
	# Test -----------------------
	
	while true:
		s += 1
		
		pr_xstatement = s
		
		var st = progs.statements[s]
		
		var a = st.a
		var b = st.b
		var c = st.c
		
		if console.debug_level >= console.DEBUG_HIGH:
			console.con_print_debug(console.DEBUG_HIGH, "%d:   %s %d %d %d", [s, _get_opcode_name( st.op ), a, b, c])
		
		match st.op:
			
			opcode.OP_ADD_F:
				_OP_ADD_F(st)
			
			opcode.OP_ADD_V:
				_OP_ADD_V(st)
			
			opcode.OP_SUB_F:
				_OP_SUB_F(st)
			
			opcode.OP_SUB_V:
				_OP_SUB_V(st)
			
			opcode.OP_MUL_F:
				_OP_MUL_F(st)
			
			opcode.OP_MUL_V:
				_OP_MUL_V(st)
			
			opcode.OP_MUL_VF:
				_OP_MUL_VF(st)
			
			opcode.OP_DIV_F:
				_OP_DIV_F(st)
			
			opcode.OP_BITAND:
				_OP_BITAND(st)
			
			opcode.OP_GE:
				_OP_GE(st)
			
			opcode.OP_LE:
				_OP_LE(st)
			
			opcode.OP_GT:
				_OP_GT(st)
			
			opcode.OP_OR:
				_OP_OR(st)
			
			opcode.OP_NOT_F:
				_OP_NOT_F(st)
			
			opcode.OP_NOT_S:
				_OP_NOT_S(st)
			
			opcode.OP_EQ_F:
				_OP_EQ_F(st)
			
			opcode.OP_EQ_V:
				_OP_EQ_V(st)
			
			opcode.OP_EQ_S:
				_OP_EQ_S(st)
			
			opcode.OP_NE_V:
				_OP_NE_V(st)
			
			opcode.OP_STORE_F, opcode.OP_STORE_ENT, opcode.OP_STORE_FLD, opcode.OP_STORE_S, opcode.OP_STORE_FNC:
				_OP_STORE(st)
			
			opcode.OP_STORE_V:
				_OP_STORE_V(st)
			
			opcode.OP_STOREP_F, opcode.OP_STOREP_ENT, opcode.OP_STOREP_FLD, opcode.OP_STOREP_S, opcode.OP_STOREP_FNC, opcode.OP_STOREP_V:
				_OP_STOREP(st)
			
			opcode.OP_ADDRESS:
				_OP_ADDRESS(st)
			
			opcode.OP_LOAD_F, opcode.OP_LOAD_FLD, opcode.OP_LOAD_ENT, opcode.OP_LOAD_S, opcode.OP_LOAD_FNC, opcode.OP_LOAD_V:
				_OP_LOAD(st)
			
			opcode.OP_IFNOT:
				s = _OP_IFNOT(st, s)
			
			opcode.OP_GOTO:
				s = _OP_GOTO(st, s)
			
			opcode.OP_CALL0, opcode.OP_CALL1, opcode.OP_CALL2, opcode.OP_CALL3, opcode.OP_CALL4, opcode.OP_CALL5, opcode.OP_CALL6, opcode.OP_CALL7, opcode.OP_CALL8:
				s = _OP_CALL(st, s)
				
			opcode.OP_DONE, opcode.OP_RETURN:
				s = _PR_LeaveFunction()
				
				if pr_depth == exitdepth:
					pr_string_num = -1
					pr_strings.clear()
					pr_stack.clear()
					pr_depth = 0
					localstack.clear()
					localstack_used = 0
					
					console.con_print_debug(console.DEBUG_MEDIUM,
							"function: %d done.",
							[ func_num ] ) 
					
					break
				
			_:
				console.con_print_warn("[PROGS] Unknown: %s" % _get_opcode_name( st.op ))
				break



func _OP_ADD_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a + b)



func _OP_ADD_V(st):
	progs.globals.seek(st.a * 4)
	var ax = progs.globals.get_float()
	var ay = progs.globals.get_float()
	var az = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var bx = progs.globals.get_float()
	var by = progs.globals.get_float()
	var bz = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(ax + bx)
	progs.globals.put_float(ay + by)
	progs.globals.put_float(az + bz)



func _OP_SUB_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a-b)



func _OP_SUB_V(st):
	progs.globals.seek(st.a * 4)
	var ax = progs.globals.get_float()
	var ay = progs.globals.get_float()
	var az = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var bx = progs.globals.get_float()
	var by = progs.globals.get_float()
	var bz = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(ax * bx + ay * by + az * bz)



func _OP_MUL_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a * b)



func _OP_MUL_V(st):
	progs.globals.seek(st.a * 4)
	var ax = progs.globals.get_float()
	var ay = progs.globals.get_float()
	var az = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var bx = progs.globals.get_float()
	var by = progs.globals.get_float()
	var bz = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(ax - bx)
	progs.globals.put_float(ay - by)
	progs.globals.put_float(az - bz)




func _OP_MUL_VF(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var bx = progs.globals.get_float()
	var by = progs.globals.get_float()
	var bz = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a * bx)
	progs.globals.put_float(a * by)
	progs.globals.put_float(a * bz)



func _OP_DIV_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a / b)



func _OP_BITAND(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_u32()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_u32()
	
	var c = a and b
	progs.globals.seek(st.c * 4)
	progs.globals.put_u32(c)



func _OP_GE(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a >= b)



func _OP_LE(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a <= b)



func _OP_GT(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a > b)



func _OP_NOT_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(-a)



func _OP_OR(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(a || b)



func _OP_NOT_S(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_32()
	
	progs.globals.seek(st.c * 4)
	
	if a < 0:
		progs.globals.put_float(0)
		return
	
	if a != 0:
		progs.globals.put_float(0)
		return
		
	if !progs.strings[a]:
		progs.globals.put_float(0)
		return
		
	progs.globals.put_float(1)
	return	



func _OP_EQ_F(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	
	if a == b:
		progs.globals.put_float(1)
	else:
		progs.globals.put_float(0)



func _OP_EQ_V(st):
	for i in range(3):
		progs.globals.seek(st.a * 4 + i * 4)
		var a = progs.globals.get_float()
		
		progs.globals.seek(st.b * 4 + i * 4)
		var b = progs.globals.get_float()
		
		if a != b:
			progs.globals.seek(st.c * 4)
			progs.globals.put_float(0)
			return
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float(0)



func _OP_EQ_S(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_32()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_32()
	
	var str_a : String = ""
	var str_b : String = ""
	
	if a < 0:
		str_a = pr_strings[a]
	else:
		str_a = progs.strings[a]
	
	if b < 0:
		str_b = pr_strings[b]
	else:
		str_b = progs.strings[b]
	
	
	progs.globals.seek(st.c * 4)
	
	if str_a == str_b:
		progs.globals.put_float(1)
	else:
		progs.globals.put_float(0)



func _OP_NE_V(st):
	progs.globals.seek(st.a * 4)
	var ax = progs.globals.get_float()
	var ay = progs.globals.get_float()
	var az = progs.globals.get_float()
	
	progs.globals.seek(st.b * 4)
	var bx = progs.globals.get_float()
	var by = progs.globals.get_float()
	var bz = progs.globals.get_float()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_float( ax != bx || ay != by || az != bz )



func _OP_STORE(st):
	progs.globals.seek(st.a * 4)
	var value = progs.globals.get_u32()
	progs.globals.seek(st.b * 4)
	progs.globals.put_u32(value)
#	console.con_print("[PROGS] _OP_STORE: %d" % value)



func _OP_STORE_V(st):
	progs.globals.seek(st.a * 4)
	var x = progs.globals.get_u32()
	var y = progs.globals.get_u32()
	var z = progs.globals.get_u32()
	
	progs.globals.seek(st.b * 4)
	progs.globals.put_u32(x)
	progs.globals.put_u32(y)
	progs.globals.put_u32(z)



func _OP_STOREP(st):
	progs.globals.seek(st.b * 4)
	var offset = progs.globals.get_u32()
	
	var ent = entities.entities[pr_pointer[st.b]]
	var entvars = ent.get_meta("entvars")
	var key = entvars.index[offset]
	
	if key.ends_with("_x"):
		key.erase(key.length() -2, 2)
	

	
	match st.op:
		opcode.OP_STOREP_S:
			progs.globals.seek(st.a * 4)
			var source = progs.globals.get_u32()
			entvars[key] = progs.strings[source]
			
		opcode.OP_STOREP_ENT:
			progs.globals.seek(st.a * 4)
			var source = progs.globals.get_u32()
			entvars[key] = entities.entities[source]
		
		opcode.OP_STOREP_F:
			progs.globals.seek(st.a * 4)
			
			var f = progs.globals.get_float()
			
			if key.ends_with("_x"):
				key.erase(key.length() -2, 2)
				entvars[key].x = f
				
			elif key.ends_with("_y"):
				key.erase(key.length() -2, 2)
				entvars[key].y = f
				
			elif key.ends_with("_z"):
				key.erase(key.length() -2, 2)
				entvars[key].z = f
			else:
				entvars[key] = f
		
		opcode.OP_STOREP_V:
			progs.globals.seek(st.a * 4)
			var x = progs.globals.get_u32()
			var y = progs.globals.get_u32()
			var z = progs.globals.get_u32()
			entvars[key] = Vector3(x,y,z)
		
		opcode.OP_STOREP_FNC:
			progs.globals.seek(st.a * 4)
			var fnc = progs.globals.get_32()
			entvars[key] = fnc
		_:
			console.con_print_warn("[PROGS] _OP_STOREP: Type not implementet")
	
#
#	progs.globals.seek(st.a * 4)
#	progs.globals.get_u32(value)
	
#	console.con_print("[PROGS] _OP_STORE: %d" % value)


func _OP_ADDRESS(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_u32()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_u32()
	
	progs.globals.seek(st.c * 4)
	progs.globals.put_32(b)
	pr_pointer[st.c] = a
	
	#console.con_print("[PROGS] _OP_ADDRESS: %d -- %d" % [a, b])



func _OP_LOAD(st):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_u32()
	
	progs.globals.seek(st.b * 4)
	var b = progs.globals.get_u32()
	
	var ent = entities.entities[a]
	var entvars = ent.get_meta("entvars")
	var key = entvars.index[b]
	
	if st.op == opcode.OP_LOAD_V and key.ends_with("_x"):
		key.erase(key.length() -2, 2)
	
	var evar
	
	if st.op == opcode.OP_LOAD_F:
		if key.ends_with("_x"):
			key.erase(key.length() -2, 2)
			evar = entvars[key].x
			
		elif key.ends_with("_y"):
			key.erase(key.length() -2, 2)
			evar = entvars[key].y
			
		elif key.ends_with("_z"):
			key.erase(key.length() -2, 2)
			evar = entvars[key].z
		else:
			evar = entvars[key]

	else:
		evar = entvars[key]
	
	progs.globals.seek(st.c * 4)
	
	match st.op:
		opcode.OP_LOAD_ENT:
			progs.globals.put_32( evar.get_instance_id() )
		opcode.OP_LOAD_S:
			progs.globals.put_32( pr_string_num )
			pr_strings[pr_string_num] = evar
			pr_string_num -= 1
		opcode.OP_LOAD_F:
			progs.globals.put_float( evar )
		opcode.OP_LOAD_V:
			progs.globals.put_float( evar.x )
			progs.globals.put_float( evar.y )
			progs.globals.put_float( evar.z )
		_:
			console.con_print_warn("[PROGS] _OP_LOAD: Type not implementet")



func _OP_IFNOT(st, s):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_u32()
	
	if a == 0:
		s += st.b - 1
	
	return s



func _OP_GOTO(st, s):
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_u32()
	
	return s + st.a - 1



func _OP_CALL(st, s):
	var pr_argc = st.op - opcode.OP_CALL0
	
	progs.globals.seek(st.a * 4)
	var a = progs.globals.get_32()
	
	if not progs.functions.has(a):
		console.con_print_error("[PROGS] _OP_CALL: funcnum %d not found!"% a)
	
	if progs.functions[a].first_statement < 0:
		_call_builtin(st, -progs.functions[a].first_statement)
		return s
	
	#console.con_print("[PROGS] _OP_CALL: args %d -- funcnum: %d" % [pr_argc, a])
	
	return _PR_EnterFunction(a)



func _call_builtin(st, bfunc):
	match bfunc:
		1:	_builtin_1_makevectors(st)
		2:	_builtin_2_setorigin(st)
		3:	_builtin_3_setmodel(st)
		4:	_builtin_4_setsize(st)
		7:	_builtin_7_random(st)
		14: _builtin_14_spawn(st)
		19: _builtin_19_precache_sound(st)
		20: _builtin_20_precache_model(st)
		34: _builtin_34_droptofloor(st)
		35: _builtin_35_lightstyle(st)
		43: _builtin_43_fabs(st)
		72: _builtin_72_cvar_set(st)
		74: _builtin_74_ambientsound(st)
		_: console.con_print_error("[PROGS] _call_builtin: %s not implemented" % bfunc)



# -----------------------------------------------------------------------------
# void makevectors(vector angles)
# -----------------------------------------------------------------------------
# Creates relative forward, right and up vectors with length 1 from angles.
# These 3 directional vectors are stored in the global variables 
# v_forward, v_right and v_up respectively. Note that because these are 
# global variables, running makevectors on another set of angles will destroy
# the previously calculated vectors. 
#
# Parameters:
#
#     angles - The angles that will be used to generate the vectors
#
# -----------------------------------------------------------------------------
##inline##
func _builtin_1_makevectors(st) -> void:
	
	var vec = _get_global_vector(OFS_PARM0)
	var pitch = vec.x		# up / down
	var yaw = vec.y			# left / right
	var roll = vec.z		# fall over
	
	var pi_2_div_360 : float = PI * 2 / 360.0
	
	var angle : float = yaw * pi_2_div_360
	var sy : float = sin(angle)
	var cy : float = cos(angle)
	
	angle = pitch * pi_2_div_360
	var sp : float = sin(angle)
	var cp : float = cos(angle)
	
	angle = roll * pi_2_div_360
	var sr = sin(angle)
	var cr = cos(angle)
	
	var forward := Vector3()
	forward.x = cp * cy;
	forward.y = cp * sy;
	forward.z = -sp;
	
	var right := Vector3()
	right.x = -1 * sr * sp * cy + -1 * cr * sy
	right.y = -1 * sr * sp * sy + -1 * cr * cy
	right.z = -1 * sr * cp
	
	var up := Vector3()
	up.x = cr * sp * cy + -sr * -sy
	up.y = cr * sp * sy + -sr * cy
	up.z = cr * cp
	
	set_global_by_name("v_forward", forward)
	set_global_by_name("v_right", right)
	set_global_by_name("v_up", up)
	
	##debug##
	if console.debug_level >= console.DEBUG_MEDIUM:
		console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_1_makevectors: ")
		console.con_print_debug(console.DEBUG_MEDIUM, "    v_forward: [%f %f %f] " % [forward.x, forward.y, forward.z])
		console.con_print_debug(console.DEBUG_MEDIUM, "    v_right:   [%f %f %f] " % [right.x, right.y, right.z])
		console.con_print_debug(console.DEBUG_MEDIUM, "    v_up:      [%f %f %f] " % [up.x, up.y, up.z])


# -----------------------------------------------------------------------------
# void setorigin (entity e, vector position)
# -----------------------------------------------------------------------------
# Moves an entity to a given location. That function is to be used when spawning
# an entity or when teleporting it. This is the only valid way to move an object
# without using the physics of the world (setting velocity and waiting).
# DO NOT change directly e.origin, otherwise internal links would be screwed,
# and entity clipping would be messed up. 
#
# Parameters:
#
# e = entity to be moved
#
# position = new position for the entity
# -----------------------------------------------------------------------------
##inline##
func _builtin_2_setorigin(st) -> void:
	
	var ent = _get_global_ent(OFS_PARM0)
	var vec = _get_global_vector(OFS_PARM1)
	
	ent.translation = vec
	var entvars = ent.get_meta("entvars")
	entvars["origin"] = vec
	
	##debug##
	if console.debug_level >= console.DEBUG_MEDIUM:
		console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_2_setorigin: " )
		console.con_print_debug(console.DEBUG_MEDIUM, "    origin: [%f %f %f] " % [vec.x, vec.y, vec.z])



# -----------------------------------------------------------------------------
# void setmodel(entity e, string path)
# -----------------------------------------------------------------------------
# Parameters:
#
#    e - The entity who's model is being set
#    path - The path to the model file to set.
#           Can be a model (.mdl), sprite (.spr) or map (.bsp)
# -----------------------------------------------------------------------------
func _builtin_3_setmodel(st) -> void:
	
	var ent = _get_global_ent(OFS_PARM0)
	var path = _get_global_string(OFS_PARM1)
	
	
	var entvars = ent.get_meta("entvars")
#	entvars["model"] = path
#	entvars["modelindex"] = 1234
	
	add_child(bsp.bsp_meshes[int(entvars.model)])
	
	if console.debug_level >= console.DEBUG_MEDIUM:
		console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_3_setmodel: " )
		console.con_print_debug(console.DEBUG_MEDIUM, "    ent:  [%s] " % entvars.classname)
		console.con_print_debug(console.DEBUG_MEDIUM, "    path: [%s] " % path)



# -----------------------------------------------------------------------------
# void setsize(entity e, vector mins, vector maxs)
# -----------------------------------------------------------------------------
#	Sets the size of the entity's bounding box, relative to the entity origin.
#	The size box is rotated by the current angle of the entity. 
#
# Parameters:
#
#    e - The entity who's model is being set
#    mins - The coordinates of the minimum corner of the bounding box (ex: VEC_HULL2_MIN)
#    maxs - The coordinates of the maximum corner of the bounding box (must be larger than mins) (ex: VEC_HULL2_MIN)
# -----------------------------------------------------------------------------
func _builtin_4_setsize(st):
	progs.globals.seek(OFS_PARM0 * 4)
	var parm0 = progs.globals.get_32()
	
	progs.globals.seek(OFS_PARM1 * 4)
	var parm1 = progs.globals.get_32()
	
	progs.globals.seek(OFS_PARM2 * 4)
	var parm2 = progs.globals.get_32()
	
	var ent = entities.entities[parm0]

	progs.globals.seek(parm1 * 4)
	var mins : Vector3 = Vector3()
	mins.x = progs.globals.get_float()
	mins.y = progs.globals.get_float()
	mins.z = progs.globals.get_float()
	
	progs.globals.seek(parm1 * 4)
	var maxs : Vector3 = Vector3()
	maxs.x = progs.globals.get_float()
	maxs.y = progs.globals.get_float()
	maxs.z = progs.globals.get_float()
	
	var entvars = ent.get_meta("entvars")
	entvars["mins"] = mins
	entvars["maxs"] = maxs
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_4_setsize: " )



# -----------------------------------------------------------------------------
# float random()
# -----------------------------------------------------------------------------
#
#	Returns a floating point value greater than or equal to 0 and less than 1.
#
# -----------------------------------------------------------------------------
func _builtin_7_random(st):
	var random = randf()
	progs.globals.seek(OFS_RETURN * 4)
	progs.globals.put_float(random)
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_7_random: %f" %  random)



##inline##
func _builtin_14_spawn(st) -> void:
	
	var ent = entities.spawn()
	
	_set_global_int(OFS_RETURN, ent.get_instance_id())
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_14_spawn: %d" %  ent.get_instance_id())



##inline##
func _builtin_19_precache_sound(st) -> void:
	
	var parm0 := _get_global_int(OFS_PARM0)
	var filename := _get_global_string(OFS_PARM0)
	
	if not cached_sounds.has(filename):
		cached_sounds[filename] = load(console.cvars["path_prefix"].value + "id1-x/" + "sound/" + filename )
	
	_set_global_int(OFS_RETURN, parm0)
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_19_precache_sound: %s" % [filename] )



##inline##
func _builtin_20_precache_model(st) -> void:
	
	var parm0 := _get_global_int(OFS_PARM0)
	var filename := _get_global_string(OFS_PARM0)
	
	##FIXME##
	if not cached_models.has(filename):
		cached_models[filename] = ""
	
	_set_global_int(OFS_RETURN, parm0)
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_20_precache_model: %s" % [filename] )



# -----------------------------------------------------------------------------
# float droptofloor(float yaw, float dist)
# -----------------------------------------------------------------------------
#
# Tries to "drop" an entity down up to 256 units in a single frame, as if it had fallen due to physics. 
#
#	Parameters:
#
#	    yaw - Unused?
#	    dist - Unused?
#
#	Returns:
#
#	    Returns TRUE if the entity landed on the ground and FALSE if it was still in the air.
#
# -----------------------------------------------------------------------------
func _builtin_34_droptofloor(st):
	progs.globals.seek(OFS_SELF * 4)
	var _self = progs.globals.get_32()
	var ent = entities.entities[_self]
	
	progs.globals.seek(OFS_RETURN * 4)
	progs.globals.put_float(1)
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_34_droptofloor: ")



##inline##
func _builtin_35_lightstyle(st) -> void:
	
	var parm0 := _get_global_float(OFS_PARM0)
	var lightstyle := _get_global_string(OFS_PARM1)
	
	lightstyles[int(parm0)] = lightstyle
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_35_lightstyle: %s, %s" % [parm0, lightstyle] )



# -----------------------------------------------------------------------------
# float fabs(float val)
# -----------------------------------------------------------------------------
#
# Returns absolute value of val (like the equivalent function in C).
#
# -----------------------------------------------------------------------------
func _builtin_43_fabs(st):
	progs.globals.seek(OFS_PARM0 * 4)
	var f = progs.globals.get_float()
	
	progs.globals.seek(OFS_RETURN * 4)
	progs.globals.put_float(abs(f))
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_43_fabs: %f" % f )



##inline##
func _builtin_72_cvar_set(st):
	
	var cvar_name = _get_global_string(OFS_PARM0)
	var value = _get_global_string(OFS_PARM1)
	
	console.cvars[cvar_name].value = value
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM,"_builtin_72_cvar_set: %s, %s" % [cvar_name, value] )



# -----------------------------------------------------------------------------
# void ambientsound(vector pos, string sample, float volume, float attenuation)
# -----------------------------------------------------------------------------
#  Starts a sound as an ambient sound. Unlike normal sounds started from the sound function,
#  an ambient sound will never stop playing, even if the player moves out of audible range.
#  It will also be properly registered by the engine if it is started outside of hearing range of the player. 
#
# Parameters:
#
#    pos - The coordinates for the origin of the sound.
#    sample - The path to the sound file. Unlike models, sounds have /sound/ already present,
#             so do not include that directory in the pathname.
#             This sound MUST be looped by placing markers in the .wav file.
#    volume - A value between 0.0 and 1.0 that controls the volume of the sound.
#             0.0 is silent, 1.0 is full volume.
#    attenuation - A value greater than or equal to 0 and less than 4 that controls how fast the sound's volume attenuated from distance.
#                  0 can be heard everywhere in the level, 1 can be heard up to 1000 units and 3.999 has a radius of about 250 units.
# -----------------------------------------------------------------------------
func _builtin_74_ambientsound(st):
	# vector -- pos
	progs.globals.seek(OFS_PARM0 * 4)
	var pos : Vector3 = Vector3()
	pos.x = progs.globals.get_float()
	pos.y = progs.globals.get_float()
	pos.z = progs.globals.get_float()
	
	# string -- sample
	progs.globals.seek(OFS_PARM1 * 4)
	var parm1 = progs.globals.get_32()
	var sample : String = ""
	if parm1 < 0:
		sample = pr_strings[parm1]
	else:
		sample = progs.strings[parm1]
		
	# float -- volume
	progs.globals.seek(OFS_PARM2 * 4)
	var volume = progs.globals.get_float()
	
	# float -- attenuation
	progs.globals.seek(OFS_PARM3 * 4)
	var attenuation = progs.globals.get_float()
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_74_ambientsound: [%f %f %f], %s, %f, %f" % [pos.x, pos.y, pos.z, sample, volume, attenuation] )



##inline##
func _get_global_string(num : int) -> String:
	
	var ret : String = ""
	
	progs.globals.seek(num * 4)
	var str_num = progs.globals.get_32()
	
	if str_num < 0:
		ret = pr_strings[str_num]
	else:
		ret = progs.strings[str_num]
	
	return ret



##inline##
func _get_global_int(num : int) -> int:
	
	var ret : int
	
	progs.globals.seek(num * 4)
	ret = progs.globals.get_32()
	
	return ret



##inline##
func _set_global_int(num : int, value : int) -> void:
	
	progs.globals.seek(num * 4)
	progs.globals.put_32(value)



##inline##
func _get_global_float(num : int) -> float:
	
	var ret : float
	
	progs.globals.seek(num * 4)
	ret = progs.globals.get_float()
	
	return ret



##inline##
func _set_global_float(num : int, value : float) -> void:
	
	progs.globals.seek(num * 4)
	progs.globals.put_float(value)



##inline##
func _get_global_vector(num : int) -> Vector3:
	
	var ret : Vector3
	
	progs.globals.seek(num * 4)
	ret.x = progs.globals.get_float()
	ret.y = progs.globals.get_float()
	ret.z = progs.globals.get_float()
	
	return ret



##inline##
func _set_global_vector(num : int, value : Vector3) -> void:
	
	progs.globals.seek(num * 4)
	progs.globals.put_float(value.x)
	progs.globals.put_float(value.y)
	progs.globals.put_float(value.z)



##inline##
func _get_global_ent(num : int):
	
	var ret
	
	progs.globals.seek(num * 4)
	var ent_num = progs.globals.get_u32()
	
	ret = entities.entities[ent_num]
	
	return ret



##inline##
func _set_global_ent(num : int, value) -> void:
	
	progs.globals.seek(num * 4)
	progs.globals.put_u32(value.get_instance_id())




func set_global_by_name(name, value):
	var key = progs.globals_by_name[name]
	var def = progs.globaldefs[key]
	
	match typeof(value):
		TYPE_INT:
			progs.globals.seek(def.offset * 4)
			progs.globals.put_32(value)
		TYPE_REAL:
			progs.globals.seek(def.offset * 4)
			progs.globals.put_float(value)
		TYPE_VECTOR3:
			progs.globals.seek(def.offset * 4)
			progs.globals.put_float(value.x)
			progs.globals.put_float(value.y)
			progs.globals.put_float(value.z)



func get_global_by_name(name):
	var key = progs.globals_by_name[name]
	var def = progs.globaldefs[key]
	
	match typeof(def.type):
		EV_FLOAT:
			progs.globals.seek(def.offset * 4)
			return progs.globals.get_32()



func set_global_by_offset(offset, value):
	progs.globals.seek(offset * 4)
	progs.globals.put_32(value)

# -----------------------------------------------------
# _ready
# -----------------------------------------------------
func _ready():
	localstack.resize(LOCALSTACK_SIZE)
	
	console.register_command("progs_load", {
		node = self,
		description = "Loads the progs.dat code lump.",
		args = "<filename>",
		num_args = 1
	})
	
	console.register_command("progs_disassemble", {
		node = self,
		description = "Disassembles a quakec vm function.",
		args = "<funcname>",
		num_args = 1
	})
	
	console.register_command("progs_exec", {
		node = self,
		description = "Executes a function.",
		args = "<funcname>",
		num_args = 1
	})
	
	console.register_command("progs_info_global", {
		node = self,
		description = "Prints the <global>.",
		args = "<global>",
		num_args = 1
	})
	
	console.register_command("progs_info_field", {
		node = self,
		description = "Prints the <field>.",
		args = "<field>",
		num_args = 1
	})
	
	console.register_command("progs_generate_entvars_script", {
		node = self,
		description = "Generates the entvars.gd script.",
		args = "",
		num_args = 0
	})
	
	console.register_command("progs_global", {
		node = self,
		description = "Prints the global at <offset>.",
		args = "<offset>",
		num_args = 1
	})



func _confunc_progs_load(args):
	load_progs(args[1])



func _confunc_progs_disassemble(args):
	_disassemble(args[1])



func _confunc_progs_exec(args):
	exec(args[1])



func _confunc_progs_info_global(args):
	console.con_print( _get_global_name( int(args[1]) ) )



func _confunc_progs_info_field(args):
	console.con_print( _get_field_name( int(args[1]) ) )



func _confunc_progs_generate_entvars_script():
	_generate_entvars_script()

func _confunc_progs_global(args):
	progs.globals.seek(int(args[1]) * 4)
	var value = progs.globals.get_32()
	console.con_print(str(value))



func _get_type_sting(type):
	# enum {EV_VOID, EV_STRING, EV_FLOAT, EV_VECTOR, EV_ENTITY, EV_FIELD, EV_FUNCTION, EV_POINTER }
	match type:
		EV_VOID:
			return "EV_VOID"
		EV_STRING:
			return "EV_STRING"
		EV_FLOAT:
			return "EV_FLOAT"
		EV_VECTOR:
			return "EV_VECTOR"
		EV_ENTITY:
			return "EV_ENTITY"
		EV_FIELD:
			return "EV_FIELD"
		EV_FUNCTION:
			return "EV_FUNCTION"
		EV_POINTER:
			return "EV_POINTER"
		_:
			return "EV_UNKNOWN"



func _get_global_name(num):
	if progs.globaldefs.has(num):
		return progs.globaldefs[num].s_name
	else:
		""



func _get_field_name(num):
	if progs.fielddefs.has(num):
		return progs.fielddefs[num].s_name
	else:
		""
