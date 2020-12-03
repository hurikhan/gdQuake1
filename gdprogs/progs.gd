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



# -----------------------------------------------------
# _get_dprograms
# -----------------------------------------------------
func _get_dprograms(struct):
	progs.dprograms = struct.eval(0)
	
	console.con_print("----------------------------------")
	console.con_print(".dat")
	console.con_print("----------------------------------")
	
	for k in progs.dprograms:
		var line = "%s -- %s" % [k, progs.dprograms[k]]
		console.con_print(line)
	
	console.con_print("")



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
	
	console.con_print("----------------------------------")
	console.con_print("strings")
	console.con_print("----------------------------------")
	
#	# ------------------------------------
#	# debug print
#	# ------------------------------------
#	for k in sdict:
#		var line = "%s -- %s" % [k, sdict[k]]
#		console.con_print(line)
#
#	var s_max = 0
#	for v in sdict.values():
#		var length = v.length()
#		if length > s_max:
#			s_max = length
#	console.con_print("Biggest string length: %d" % s_max)
	
	console.con_print("%d strings loaded." % sdict.size())
	console.con_print("")



# -----------------------------------------------------
# _get_globaldefs
# -----------------------------------------------------
func _get_globaldefs(struct):
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_globaldefs + struct_size
	var num = progs.dprograms.num_globaldefs
	
	
	var globaldefs = Dictionary()
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
		
#		# ------------------------------------
#		# Get value
#		# ------------------------------------
#		var value_offset = progs.dprograms.ofs_globals + (def.offset * 4)
#
#		var value
#
#		match def.type:
#			EV_FLOAT:
#				value = _raw.get_f32(data, value_offset)
#			EV_VECTOR:
#				var x = _raw.get_f32(data, value_offset)
#				var y = _raw.get_f32(data, value_offset + 4)
#				var z = _raw.get_f32(data, value_offset + 8)
#				value = Vector3(x, y, z)
#			EV_STRING:
#				var first_char = _raw.get_u8(data, value_offset)
#				if first_char == 0:
#					value = ""
#				else:
#					value = _raw.get_string(data, value_offset, 256)
#			_:
#				value = _raw.get_u32(data, value_offset)
#
#		def.value = value
		
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
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		i += 1
	
	# ------------------------------------
	# Add globaldefs to progs
	# ------------------------------------
	progs.globaldefs = globaldefs
	
	# ------------------------------------
	# Add globals to progs
	# ------------------------------------
	var arr = parser_v3.buffer.data_array
	var start = progs.dprograms.ofs_globals
	var end = progs.dprograms.ofs_globals + progs.dprograms.num_globals * 4 - 1
	
	globals.data_array = arr.subarray(start, end)
	
	progs.globals = globals
	
	console.con_print("----------------------------------")
	console.con_print("globaldefs")
	console.con_print("----------------------------------")
	
#	# ------------------------------------
#	# debug print
#	# ------------------------------------
#	i = 0
#
#	for k in progs.globaldefs:
#		var type = progs.globaldefs[k].type
#		var s_name = progs.globaldefs[k].s_name
#		var line = ""
#
#		line = "%s -- %s -- %s" % [ str(k), _get_type_sting(type), s_name  ]
#
#		console.con_print(line)
#		i += 1
#
#		if i > 100:
#			break
	
	console.con_print("%d globaldefs loaded." % num)
	console.con_print("")




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
		
#		# ------------------------------------
#		# Get value
#		# ------------------------------------
#		var value_offset = progs.dprograms.ofs_fielddefs + (def.offset * 4)
#
#		var value
#
#		match def.type:
#			EV_FLOAT:
#				value = _raw.get_f32(data, value_offset)
#			EV_VECTOR:
#				var x = _raw.get_f32(data, value_offset)
#				var y = _raw.get_f32(data, value_offset + 4)
#				var z = _raw.get_f32(data, value_offset + 8)
#				value = Vector3(x, y, z)
#			EV_STRING:
#				value = ""
#			_:
#				value = _raw.get_u32(data, value_offset)
#
#		def.value = value
		
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
	
	console.con_print("----------------------------------")
	console.con_print("fielddefs")
	console.con_print("----------------------------------")
	
#	# ------------------------------------
#	# debug print
#	# ------------------------------------
#	i = 0
#
#	for k in progs.fielddefs:
#		var type = progs.fielddefs[k].type
#		var s_name = progs.fielddefs[k].s_name
#		var line = ""
#
#		line = "%s -- %s -- %s" % [ str(k), _get_type_sting(type), s_name  ]
#
#		console.con_print(line)
#		i += 1
#
##		if i > 100:
##			break
	
	console.con_print("%d fielddefs loaded." % num)
	console.con_print("")



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
	
	console.con_print("----------------------------------")
	console.con_print("functions")
	console.con_print("----------------------------------")
	
#	# ------------------------------------
#	# debug print
#	# ------------------------------------
#	i = 0
#
#	for k in progs.functions:
#
#		var line = "%d:\t(%d) %s -- statement: %d -- param: %d -- locals: %d -- profile: %d -- source: %s" % [
#			k,
#			progs.functions[k].numparms,
#			progs.functions[k].s_name,
#			progs.functions[k].first_statement,
#			progs.functions[k].parm_start,
#			progs.functions[k].locals,
#			progs.functions[k].profile,
#			progs.functions[k].s_file,
#			]
#
#		console.con_print(line)
#		i += 1
#
##		if i > 100:
##			break
	
	console.con_print("%d functions loaded." % num)
	console.con_print("")


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
	
	console.con_print("----------------------------------")
	console.con_print("statements")
	console.con_print("----------------------------------")
	console.con_print("%d statements loaded." % num)
	console.con_print("")

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


# -----------------------------------------------------
# _get_opcode_name
# -----------------------------------------------------
func _get_opcode_name(op):
	var keys = opcode.keys()
	return keys[op]



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



func _ready():
	
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



func _confunc_progs_load(args):
	load_progs(args[1])



func _confunc_progs_disassemble(args):
	_disassemble(args[1])



func _confunc_progs_info_global(args):
	console.con_print( _get_global_name( int(args[1]) ) )



func _confunc_progs_info_field(args):
	console.con_print( _get_field_name( int(args[1]) ) )



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
	if progs.globals.has(num):
		return progs.globals[num].s_name
	else:
		""



func _get_field_name(num):
	if progs.fielddefs.has(num):
		return progs.fielddefs[num].s_name
	else:
		""
