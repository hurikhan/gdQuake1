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
		_get_globals()
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
	
	##debug##
	var timer := console.con_timer_create(console.DEBUG_LOW)
	
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_globaldefs + struct_size
	var num = progs.dprograms.num_globaldefs
	
	# ------------------------------------
	# globaldefs
	# ------------------------------------
	var globaldefs := Array()
	
	globaldefs.resize(num)
	globaldefs[0] = {"type": EV_FLOAT, "offset":0, "s_name":"pad[28]"}
	
	for i in range(1, num-1):
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
			
		globaldefs[i] = def
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
#		i += 1
	
	# ------------------------------------
	# Add globaldefs to progs
	# ------------------------------------
	progs.globaldefs = globaldefs
	
	
	# ------------------------------------
	# debug print DEBUG_LOW
	# ------------------------------------
	##debug##
	if console.debug_level >= console.DEBUG_LOW:
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		console.con_print_debug(console.DEBUG_LOW, "globaldefs")
		console.con_print_debug(console.DEBUG_LOW, "----------------------------------")
		
		# ------------------------------------
		# debug print DEBUG_HIGH
		# ------------------------------------
		if console.debug_level >= console.DEBUG_HIGH:

			for index in range(1, progs.dprograms.num_globaldefs-1):
				var name = progs.globaldefs[index].s_name
				console.con_print_debug(console.DEBUG_HIGH, "%6d: %s" % [index, name])
		
		timer.print("%d globaldefs loaded." % num)
		
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_globals
# -----------------------------------------------------
func _get_globals():
	
	##debug##
	var timer := console.con_timer_create(console.DEBUG_LOW)
	
	var globals := Array()
	var globals_name := Array()	##debug
	
	globals.resize(progs.dprograms.num_globals)
	globals_name.resize(progs.dprograms.num_globals)	##debug
	
	# ------------------------------------
	# set names for Reserved Offsets
	# ------------------------------------
	globals_name[0] = "OFS_NULL"
	globals_name[1] = "OFS_RETURN"
	globals_name[4] = "OFS_PARM0"
	globals_name[7] = "OFS_PARM1"
	globals_name[10] = "OFS_PARM2"
	globals_name[13] = "OFS_PARM3"
	globals_name[16] = "OFS_PARM4"
	globals_name[19] = "OFS_PARM5"
	globals_name[22] = "OFS_PARM6"
	globals_name[25] = "OFS_PARM7"
		
	# ------------------------------------
	# globals
	# ------------------------------------
	var data = parser_v3.buffer.data_array
	var start = progs.dprograms.ofs_globals
	var end = progs.dprograms.ofs_globals + progs.dprograms.num_globals * 4 - 1
	
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = data.subarray(start, end)
	
	
	for i in range(28):
		globals[i] = 0
	
	for def in progs.globaldefs:
		
		if def == null:
			continue
		
		
		buffer.seek(def.offset * 4)
		
		match def.type:
			EV_FLOAT:
				globals[def.offset] = buffer.get_float()
			EV_ENTITY:
				globals[def.offset] = buffer.get_32()
			EV_FIELD:
				globals[def.offset] = buffer.get_32()
			EV_FUNCTION:
				globals[def.offset] = buffer.get_32()
			EV_STRING:
				globals[def.offset] = buffer.get_32()
			EV_VECTOR:
				globals[def.offset] = buffer.get_float()
				globals[def.offset+1] = buffer.get_float()
				globals[def.offset+2] = buffer.get_float()
		
		globals_name[def.offset] = def.s_name
	
	progs.globals = globals
	progs.globals_name = globals_name
	
	
	# ------------------------------------
	# debug print DEBUG_HIGH
	# ------------------------------------
	if console.debug_level >= console.DEBUG_LOW:
		
		if console.debug_level >= console.DEBUG_HIGH:
			
			for def in progs.globaldefs:
				
				if def == null:
					continue
				
				var value_str := ""
				
				match def.type:
					EV_VECTOR:
						value_str += "["
						value_str += str(globals[def.offset]) + ", "
						value_str += str(globals[def.offset+1]) + ", "
						value_str += str(globals[def.offset+2])
						value_str += "]"
					_:
						value_str = str(globals[def.offset])
				
				console.con_print_debug(console.DEBUG_HIGH, "offset: %6d type: %12s s_name: %-24s -- value: %s" % [def.offset, _get_type_string(def.type), def.s_name, value_str])
		
		timer.print("%d globals loaded." % progs.dprograms.num_globals)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_fielddefs
# -----------------------------------------------------
func _get_fielddefs(struct):
	
	##debug##
	var timer := console.con_timer_create(console.DEBUG_LOW)
	
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_fielddefs + struct_size
	var num = progs.dprograms.num_fielddefs
	
	var fielddefs = Array()
	fielddefs.resize(num+1)
	
	
	for i in range(1,num):
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
		# add dict entry
		# ------------------------------------
		
		fielddefs[i] = def
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
	
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
			
			for i in range(1,num):
				var type = progs.fielddefs[i].type
				var s_name = progs.fielddefs[i].s_name
				var _offset = progs.fielddefs[i].offset
				var line = ""
				
				line = "%s -- %s -- %s -- %d" % [ str(i), _get_type_string(type), s_name, _offset  ]
				
				console.con_print_debug(console.DEBUG_HIGH, line)
	
		timer.print("%d fielddefs loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_functions
# -----------------------------------------------------
func _get_functions(struct):
	
	##debug##
	var timer := console.con_timer_create(console.DEBUG_LOW)
	
	var struct_size = struct.get_size()
	var offset = progs.dprograms.ofs_functions + struct_size
	var num = progs.dprograms.num_functions
	
	var functions = Array()
	functions.resize(num)
	
	for i in range(1,num):
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
			
			for i in range(1,num):
				
				var line = "%d:\t(%d) %s -- statement: %d -- param: %d -- locals: %d -- profile: %d -- source: %s" % [
					i,
					progs.functions[i].numparms,
					progs.functions[i].s_name,
					progs.functions[i].first_statement,
					progs.functions[i].parm_start,
					progs.functions[i].locals,
					progs.functions[i].profile,
					progs.functions[i].s_file,
					]
				
				console.con_print_debug(console.DEBUG_HIGH, line)
				
#				if i > 100:
#					break
		
		timer.print("%d functions loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _get_statements
# -----------------------------------------------------
func _get_statements(struct):
	
	##debug##
	var timer := console.con_timer_create(console.DEBUG_LOW)
	
	var offset = progs.dprograms.ofs_statements + 8
	var num = progs.dprograms.num_statements
	
	var statements = Array()
	statements.resize(num)
	
	var struct_size = struct.get_size()
	
	for i in range(1,num-1):
		# ------------------------------------
		# Get statement
		# ------------------------------------
		var statement = struct.eval(offset)
		
		statements[i] = statement
		
		# ------------------------------------
		# Inc offset + counter i
		# ------------------------------------
		offset += struct_size
		
	
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
		
		timer.print("%d functions loaded." % num)
		console.con_print_debug(console.DEBUG_LOW, "")



# -----------------------------------------------------
# _generate_entvars_script
# -----------------------------------------------------
func _generate_entvars_script():
	var script = ""
	script += "extends Object\n\n"
	
	var fields = ""
	var last_vector = "__none__"
	
	for i in range(1, progs.fielddefs.size()-2):
		var _name : String = progs.fielddefs[i].s_name
		var _type : int = progs.fielddefs[i].type
		
		match _type:
			EV_ENTITY:
				fields += "var %s : Spatial = null\n" % _name
			EV_FUNCTION:
				fields += "var %s : int = 0\n" % _name
			EV_STRING:
				fields += "var %s : String = \"\"\n" % _name
			EV_FLOAT:
				if not _name.begins_with(last_vector):
					fields += "var %s : float = 0.0\n" % _name
			EV_VECTOR:
				fields += "var %s := Vector3(0.0, 0.0, 0.0)\n" % _name
				last_vector = _name
	
	script += fields + "\n"
	
	var offset = "var offset = {\n"
	var offset_vec = "var offset_vec = {\n"
	
	for i in range(1, progs.fielddefs.size()-2):
		var _name : String = progs.fielddefs[i].s_name
		var _type : int = progs.fielddefs[i].type
		var _offset : int = progs.fielddefs[i].offset
		
		match _type:
			EV_VECTOR:
				offset_vec += "\t%d: \"%s\",\n" % [_offset, _name]
			_:
				offset += "\t%d: \"%s\",\n" % [_offset, _name]
		
	offset += "}\n\n"
	offset_vec += "}\n\n"
	
	script += offset
	script += offset_vec
		
	var fields_file = File.new()
	var err = fields_file.open(console.cvars["path_prefix"].value + "/cache/entvars.gd", File.WRITE)
	fields_file.store_string(script)
	fields_file.close()



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
	
	var ret = _print_func_info(p_function)
	
	var function = ret[0]
	var builtin = ret[1]
	
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
			
			console.con_print("%7d:   %s " % [st, _get_opcode_name(op)])
			console.con_print("\t\t\t a:%7d     %s" % [a, info_a])
			console.con_print("\t\t\t b:%7d     %s" % [b, info_b])
			console.con_print("\t\t\t c:%7d     %s" % [c, info_c])
		
			#console.con_print("%d: %s\n\ta: %d\n\tb: %d\n\tc: %d\n" % [ i, _get_opcode_name(op), a, b, c ] )
			i += 1



func _print_func_info(p_function, debug_level=0):
	var func_num : int = -1
	
	if not progs.has("functions"):
		console.con_print_error("No .dat file loaded.")
		return
	
	##Fixme
	p_function = str(p_function)
	
	if p_function.is_valid_integer():
		func_num = int(p_function)
	else:
		for i in range(1,progs.functions.size()):
			if progs.functions[i].s_name == p_function:
				func_num = i
	
	if func_num == -1:
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
	
	var lines := PoolStringArray()
	
	lines.push_back("----------------------------------")
	lines.push_back("function[%d]: %s" % [func_num, function.s_name])
	lines.push_back("----------------------------------")
	lines.push_back("first_statement: %s" % first_statement_str)
	lines.push_back("parm_start: %d" % function.parm_start)
	lines.push_back("locals: %d" % function.locals)
	lines.push_back("profile: %d" % function.profile)
	lines.push_back("s_file: %s" % function.s_file)
	lines.push_back("numparms: %d" % function.numparms)
	lines.push_back("parm_size[8]: [%d %d %d %d -- %d %d %d %d]" % function.parm_size)
	lines.push_back("----------------------------------")
	
	if debug_level == 0:
		for line in lines:
			console.con_print(line)
	else:
		for line in lines:
			console.con_print_debug(debug_level, line)
	
	
	
#	console.con_print("----------------------------------")
#	console.con_print("function[%d]: %s" % [func_num, function.s_name] )
#	console.con_print("----------------------------------")
#	console.con_print("first_statement: %s" % first_statement_str)
#	console.con_print("parm_start: %d" % function.parm_start)
#	console.con_print("locals: %d" % function.locals)
#	console.con_print("profile: %d" % function.profile)
#	console.con_print("s_file: %s" % function.s_file)
#	console.con_print("numparms: %d" % function.numparms)
#	console.con_print("parm_size[8]: [%d %d %d %d -- %d %d %d %d]" % function.parm_size)
#	console.con_print("----------------------------------")
	
	return [function, builtin]



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
	
	if console.debug_level >= console.DEBUG_MEDIUM:
		
		console.con_print_debug(console.DEBUG_MEDIUM,
				"_PR_EnterFunction: %s",
				[ progs.functions[funcnum].s_name] )
				
		_print_func_info(funcnum, console.DEBUG_MEDIUM)
	
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
	
	for i in range(locals):
		localstack.push_back(progs.globals[parm_start+i])
		
	localstack_used += locals
	
	# -----------------------------------------------------
	# copy parameters
	# -----------------------------------------------------
	var numparms : int = progs.functions[funcnum].numparms
	var parm_size  = progs.functions[funcnum].parm_size
	var o : int = parm_start
	
	for i in range(numparms):
		for j in range(parm_size[i]):
			
			var value = progs.globals[OFS_PARM0 + i * 3 + j]
			
			progs.globals[o] = value
			
			o += 1
	
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
	
	for i in range(c):
		progs.globals[progs.functions[pr_xfunction].parm_start] = localstack.pop_back()
	
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
		for i in range(1, progs.functions.size()):
			if progs.functions[i].s_name == p_function:
				func_num = i
				break
	
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
		
		##debug-begin##
		if console.debug_level >= console.DEBUG_HIGH:
			console.con_print_debug(console.DEBUG_HIGH, "%5d:   %-15s %7d %7d %7d", [s, _get_opcode_name( st.op ), a, b, c])
		##debug-end##
		
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
			
			opcode.OP_IF:
				s = _OP_IF(st, s)
			
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
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	_set_global_float(st.c, va + vb)


func _OP_ADD_V(st):
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	_set_global_vector(st.c, va + vb)



func _OP_SUB_F(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	_set_global_float(st.c, va - vb)



func _OP_SUB_V(st):
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	_set_global_vector(st.c, va - vb)



func _OP_MUL_F(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	_set_global_float(st.c, va * vb)



func _OP_MUL_V(st):
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	_set_global_float(st.c, va.dot(vb) )




func _OP_MUL_VF(st):
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	_set_global_vector(st.c, va * vb)



func _OP_DIV_F(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	_set_global_float(st.c, va / vb)



func _OP_BITAND(st):
	var va := int(_get_global_float(st.a))
	var vb := int(_get_global_float(st.b))
	
	var vc = va & vb
	vc = vc & 0xFFFFFFFF
	
	_set_global_float(st.c, float(vc))



func _OP_GE(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	if va >= vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_LE(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	if va <= vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_GT(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	if va > vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_NOT_F(st):
	var va := _get_global_float(st.a)
	
	if va == 0.0:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_OR(st):
	var va := int(_get_global_float(st.a))
	var vb := int(_get_global_float(st.b))
	
	_set_global_float(st.c, float( va | vb) )



func _OP_NOT_S(st):
	var va := _get_global_string(st.a)
	
	if not va == "":
		_set_global_float(st.c, 0.0)
	else:
		_set_global_float(st.c, 1.0)



func _OP_EQ_F(st):
	var va := _get_global_float(st.a)
	var vb := _get_global_float(st.b)
	
	if va == vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_EQ_V(st):
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	if va == vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_EQ_S(st):
	var va := _get_global_string(st.a)
	var vb := _get_global_string(st.b)
	
	if va == vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_NE_V(st):
	
	var va := _get_global_vector(st.a)
	var vb := _get_global_vector(st.b)
	
	if va != vb:
		_set_global_float(st.c, 1.0)
	else:
		_set_global_float(st.c, 0.0)



func _OP_STORE(st):
	progs.globals[st.b] = progs.globals[st.a]



func _OP_STORE_V(st):
	progs.globals[st.b] = progs.globals[st.a]
	progs.globals[st.b+1] = progs.globals[st.a+1]
	progs.globals[st.b+2] = progs.globals[st.a+2]



func _OP_STOREP(st):
	
	var vb = progs.globals[st.b]
	
	var ent = instance_from_id( vb[0] )
	var entvars = ent.get_meta("entvars")
	var name = entvars.offset[vb[1]]
	
	match st.op:
		opcode.OP_STOREP_S:
			entvars[name] = _get_global_string(st.a)
			
		opcode.OP_STOREP_ENT:
			entvars[name] = _get_global_ent(st.a)
		
		opcode.OP_STOREP_F:
			var f := _get_global_float(st.a)
			
			if name.ends_with("_x"):
				name = entvars.offset_vec[vb[1]]
				entvars[name].x = f
				
			elif name.ends_with("_y"):
				name = entvars.offset_vec[vb[1]-1]
				entvars[name].y = f
				
			elif name.ends_with("_z"):
				name = entvars.offset_vec[vb[1]-2]
				entvars[name].z = f
			else:
				entvars[name] = f
		
		opcode.OP_STOREP_V:
			name = entvars.offset_vec[vb[1]]
			entvars[name] = _get_global_vector(vb[1])
		
		opcode.OP_STOREP_FNC:
			entvars[name] = _get_global_int(st.a)
		_:
			console.con_print_warn("[PROGS] _OP_STOREP: Type not implementet")



func _OP_ADDRESS(st):
	var va = progs.globals[st.a]
	var vb = progs.globals[st.b]
	
	progs.globals[st.c] = [va, vb]



func _OP_LOAD(st):
	var va = progs.globals[st.a]
	var vb = progs.globals[st.b]
	
	var ent = instance_from_id(va)
	var entvars = ent.get_meta("entvars")
	var name = entvars.offset[vb]
	
	var evar
	
	match st.op:
		opcode.OP_LOAD_F:
			if name.ends_with("_x"):
				name = entvars.offset_vec[vb]
				evar = entvars[name].x
				
			elif name.ends_with("_y"):
				name = entvars.offset_vec[vb-1]
				evar = entvars[name].y
				
			elif name.ends_with("_z"):
				name = entvars.offset_vec[vb-2]
				evar = entvars[name].z
			
			else:
				evar = entvars[name]
		
		opcode.OP_LOAD_V:
			name = entvars.offset_vec[vb]
			evar = entvars[name]
		
		_:
			evar = entvars[name]
	
	match st.op:
		opcode.OP_LOAD_ENT:
			progs.globals[st.c] = evar.get_instance_id() 
		opcode.OP_LOAD_S:
			progs.strings[-st.c] = evar
			progs.globals[st.c] = -st.c
		opcode.OP_LOAD_F:
			progs.globals[st.c] = evar
		opcode.OP_LOAD_V:
			progs.globals[st.c] = evar.x
			progs.globals[st.c+1] = evar.y
			progs.globals[st.c+2] = evar.z
		_:
			console.con_print_warn("[PROGS] _OP_LOAD: Type not implementet")



func _OP_IF(st, s):
	
	var va = _get_global_float(st.a)
	
	if va == 1.0:
		s += st.b - 1
	
	return s



func _OP_IFNOT(st, s):
	
	var va = _get_global_float(st.a)
	
	if va == 0.0:
		s += st.b - 1
	
	return s



func _OP_GOTO(st, s):
	
	return s + st.a - 1



func _OP_CALL(st, s):
#	var pr_argc = st.op - opcode.OP_CALL0
	
	var va = progs.globals[st.a]
	
	if progs.functions[va].first_statement < 0:
		# call builtin funtion
		_call_builtin(st, -progs.functions[va].first_statement)
		return s
	else:
		# call quakec function
		return _PR_EnterFunction(va)



func _call_builtin(st, bfunc):
	match bfunc:
		1:	_builtin_1_makevectors(st)
		2:	_builtin_2_setorigin(st)
		3:	_builtin_3_setmodel(st)
		4:	_builtin_4_setsize(st)
		7:	_builtin_7_random(st)
		14: _builtin_14_spawn(st)
		15: _builtin_15_remove(st)
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
##inline##
func _builtin_3_setmodel(st) -> void:
	
	var ent = _get_global_ent(OFS_PARM0)
	var path = _get_global_string(OFS_PARM1)
	
	
	var entvars = ent.get_meta("entvars")
#	entvars["model"] = path
#	entvars["modelindex"] = 1234
	
#	add_child(bsp.bsp_meshes[int(entvars.model)])
	
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
##inline##
func _builtin_4_setsize(st):
	
	var e := _get_global_ent(OFS_PARM0)
	var mins := _get_global_vector(OFS_PARM1)
	var maxs := _get_global_vector(OFS_PARM2)
	
	var entvars = e.get_meta("entvars")
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
##inline##
func _builtin_7_random(st):
	
	var random = randf()
	
	_set_global_float(OFS_RETURN, random)
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_7_random: %f" %  random)



##inline##
func _builtin_14_spawn(st) -> void:
	
	var ent = entities.spawn()
	
	progs.globals[OFS_RETURN] = ent.get_instance_id()
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_14_spawn: %d" %  ent.get_instance_id())


##inline##
func _builtin_15_remove(st) -> void:
	
	var ent = _get_global_ent(OFS_PARM0)
	
	entities.remove(ent)
	
	##debug##
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_15_remove: %d" %  ent.get_instance_id())



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
#	if not cached_models.has(filename):
#		cached_models[filename] = ""
	
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
##inline##
func _builtin_34_droptofloor(st):
	
	var e := _get_global_ent(OFS_SELF)
	
	_set_global_float(OFS_RETURN, 1.0)
	
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
##inline##
func _builtin_43_fabs(st):
	
	var f = _get_global_float(OFS_PARM0)
	
	progs.globals[OFS_RETURN] = abs(f)
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_43_fabs: %f" % abs(f) )



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
##inline##
func _builtin_74_ambientsound(st):
	
	var pos : Vector3 = _get_global_vector(OFS_PARM0)
	var sample : String = _get_global_string(OFS_PARM1)
	var volume : float = _get_global_float(OFS_PARM2)
	var attenuation : float = _get_global_float(OFS_PARM3)
	
	console.con_print_debug(console.DEBUG_MEDIUM, "_builtin_74_ambientsound: [%f %f %f], %s, %f, %f" % [pos.x, pos.y, pos.z, sample, volume, attenuation] )



##inline##
func _get_global_string(num : int) -> String:
	
	var ret : String
	
	var str_num = progs.globals[num]
	
	if str_num == null:
		ret = ""
	else:
		ret = progs.strings[str_num]
	
	return ret



##inline##
func _get_global_int(num : int) -> int:
	
	var ret : int
	
	ret = progs.globals[num]
	
	return ret



##inline##
func _set_global_int(num : int, value : int) -> void:
	
	progs.globals[num] = int(value)



##inline##
func _get_global_float(num : int) -> float:
	
	var ret : float
	
	var value = progs.globals[num]
	
	if value == null:
		ret = 0.0
	else:
		ret = value
	
	return ret



##inline##
func _set_global_float(num : int, value : float) -> void:
	
	progs.globals[num] = value



##inline##
func _get_global_vector(num : int) -> Vector3:
	
	var ret : Vector3
	
	var x = _get_global_float(num)
	var y = _get_global_float(num+1)
	var z = _get_global_float(num+2)
	
	ret = Vector3(x, y, z)
	
	return ret



##inline##
func _set_global_vector(num : int, value : Vector3) -> void:
	_set_global_float(num, value.x)
	_set_global_float(num+1, value.y)
	_set_global_float(num+2, value.z)



##inline##
func _get_global_ent(num : int) -> Spatial:
	
	var ret
	
	var ent_num = progs.globals[num]
	
	ret = instance_from_id(ent_num)
	
	return ret



##inline##
func _set_global_ent(num : int, value : Spatial) -> void:
	
	progs.globals.seek(num * 4)
	progs.globals.put_u32(value.get_instance_id())




func set_global_by_name(name : String, value) -> void:
	
	var num = progs.dprograms.num_globaldefs
	
	var def
	
	var found := false
	
	for i in range(1, num-1):
		if progs.globaldefs[i].s_name == name:
			def = progs.globaldefs[i]
			found = true
	
	if not found:
		console.con_print_warn("Could not find global definition with the s_name: %s !" % name)
		return
	
	match typeof(value):
		TYPE_INT:
			_set_global_int(def.offset, value)
		TYPE_REAL:
			_set_global_float(def.offset, value)
		TYPE_VECTOR3:
			_set_global_vector(def.offset, value)



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
	var value = progs.globals.get_u32()
	console.con_print(str(value))



func _get_type_string(type):
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
