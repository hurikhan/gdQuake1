# Godot Console main script
# Copyright (c) 2016 Hugo Locurcio and contributors - MIT license
# Enhanced by: Mario Schlack (hurikhan)
#	* Tab completion
#	* History
#	* Other nodes can register commands and cvars
#	* Clear function (CTRL+L)
#	* Alphabetical sorting of commands + cvars
#	* Persistent config (config_save, config_load)
#	* Multiple commands in one line, seperated by ";"
#	* Added basic macro functionality
#	* Save and load history to user://history.txt
#	* String detection in arguments e.g: echo "hello world" 

extends Panel

onready var console_text = get_node("ConsoleText")

var commands = {}							# All recognized commands
var cvars = {}								# All recognized cvars
var history = PoolStringArray()				# Stores all executed commands or changed cvars
var history_idx = 0							# Current history index pointer
var tab_bbcode = ""							# Backups the whole bbcode from the output to restore after tab completion
var macros = {}								# All macros are saved here
var cfg_filename = "user://config.txt"		# Where to save the cvars. Must be set at startup --> Console.set_configfile()

const CONSOLE_FUNC_PREFIX = "_confunc_"
const CONSOLE_VAR_PREFIX = "_convar_"

const CONSOLE_STATE_OPENED = 0
const CONSOLE_STATE_FADING = 1
const CONSOLE_STATE_CLOSED = 2

var state = CONSOLE_STATE_CLOSED

#                    _       
# _ __ ___  __ _  __| |_   _ 
#| '__/ _ \/ _` |/ _` | | | |
#| | |  __/ (_| | (_| | |_| |
#|_|  \___|\__,_|\__,_|\__, |
#                      |___/ 

func _ready():
	_convar_console_font_size(0)
	# Set the console size to 40%
	_convar_console_size(0)
	
	# Allow selecting console text
	console_text.set_selection_enabled(true)
	# Follow console output (for scrolling)
	console_text.set_scroll_follow(true)
	# Don't allow focusing on the console text itself
	console_text.set_focus_mode(FOCUS_NONE)
	
	set_process_input(true)
	
	#ConsoleCommands.register_all()
	_register_commands()
	_register_cvars()



#      _                   _   
#     (_)_ __  _ __  _   _| |_ 
#     | | '_ \| '_ \| | | | __|
#     | | | | | |_) | |_| | |_ 
# ____|_|_| |_| .__/ \__,_|\__|
#|_____|      |_|              

func _input(event):
	
	if state == CONSOLE_STATE_FADING:
		return false
	
	if event.is_action_pressed("console_toggle"):
		if not is_console_opened():
			set_console_opened(false)
		else:
			set_console_opened(true)
		
		state = CONSOLE_STATE_FADING
		

	
	if get_node("LineEdit").get_text() != "" and get_node("LineEdit").has_focus() and event.is_action_pressed("console_clear"):
		get_node("LineEdit").clear()
		history_idx = 0
		
		if not tab_bbcode == "":
			get_node("ConsoleText").parse_bbcode(tab_bbcode)
			tab_bbcode = ""
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("ui_up"):
		_history_up()
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("ui_down"):
		_history_down()
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("console_clear"):
		_confunc_clear()
	
	if get_node("LineEdit").get_text() != "" and get_node("LineEdit").has_focus() and Input.is_key_pressed(KEY_TAB):
		_tab_complete()



# _     _     _                   
#| |__ (_)___| |_ ___  _ __ _   _ 
#| '_ \| / __| __/ _ \| '__| | | |
#| | | | \__ \ || (_) | |  | |_| |
#|_| |_|_|___/\__\___/|_|   \__, |
#                           |___/ 

func _history_up():
	
	#print(history)
	
	if history_idx < history.size():
		history_idx = history_idx + 1
		get_node("LineEdit").set_text( history[ history_idx-1 ] )
		get_node("LineEdit").set_cursor_position( history[ history_idx-1 ].length()  )
		#print(history_idx)



func _history_down():
	if history_idx > 0:
		history_idx = history_idx - 1
		
		if history_idx == 0:
			get_node("LineEdit").clear()
		else:
			get_node("LineEdit").set_text( history[ history_idx - 1] )
			get_node("LineEdit").set_cursor_position( history[ history_idx -1 ].length() )
		#print(history_idx)



#           _          
# _ __ ___ (_)___  ___ 
#| '_ ` _ \| / __|/ __|
#| | | | | | \__ \ (__ 
#|_| |_| |_|_|___/\___|
#                      

func set_config_filename(filename):
	cfg_filename = filename


func get_config_filename():
	return cfg_filename


func set_console_opened(opened):
	_convar_console_size( cvars["console_size"].value )
	# Close the console
	if opened == true:
		get_node("AnimationPlayer").play("fade")
		# Signal handles the hiding at the end of the animation
	# Open the console
	elif opened == false:
		get_node("AnimationPlayer").play_backwards("fade")
		get_node("LineEdit").grab_focus()
		show()



# This signal handles the hiding of the console at the end of the fade-out animation
func _on_AnimationPlayer_animation_finished(anim_name):
	if get_node("AnimationPlayer").get_current_animation_position() == 0.0:
		state = CONSOLE_STATE_OPENED
	else:
		state = CONSOLE_STATE_CLOSED
		hide()


# Is the console fully opened?
func is_console_opened():
	if state == CONSOLE_STATE_OPENED:
		return true
	else:
		return false



# Called when the user presses Enter in the console
func _on_LineEdit_text_entered(text):
	var text_splitted = text.split(" ", true)
	# Don't do anything if the LineEdit contains only spaces
	if not text.empty() and text_splitted[0]:
		execute(text)
	else:
		# Clear the LineEdit but do nothing
		get_node("LineEdit").clear()



#                                 _       _   
#  ___ ___  _ __       _ __  _ __(_)_ __ | |_ 
# / __/ _ \| '_ \     | '_ \| '__| | '_ \| __|
#| (_| (_) | | | |    | |_) | |  | | | | | |_ 
# \___\___/|_| |_|____| .__/|_|  |_|_| |_|\__|
#               |_____|_|                     

func con_print(text, echo=true):
	console_text.append_bbcode(str(text) + "\n")
	if echo:
		print(text)


func con_print_ok(text):
	# green text
	console_text.append_bbcode("[color=green][OK]    -- " + str(text) + "[/color]\n")
	print(text)


func con_print_warn(text):
	# yellow text
	console_text.append_bbcode("[color=yellow][WARN]  -- " + str(text) + "[/color]\n")
	print(text)


func con_print_error(text):
	# red text
	console_text.append_bbcode("[color=#ff4444][ERROR] -- " + str(text) + "[/color]\n")
	print(text)


func con_print_array(arr):
	for entry in arr:
		console_text.append_bbcode(str(entry) + "\n")
		print(entry)



#                _     _            
# _ __ ___  __ _(_)___| |_ ___ _ __ 
#| '__/ _ \/ _` | / __| __/ _ \ '__|
#| | |  __/ (_| | \__ \ ||  __/ |   
#|_|  \___|\__, |_|___/\__\___|_|   
#          |___/                    

# Registers a new command
func register_command(name, args):
	commands[name] = args


# Registers a new cvar (control variable)
func register_cvar(name, args):
	cvars[name] = args
	cvars[name].value = cvars[name].default_value



#     _                     _ _          
#  __| | ___  ___  ___ _ __(_) |__   ___ 
# / _` |/ _ \/ __|/ __| '__| | '_ \ / _ \
#| (_| |  __/\__ \ (__| |  | | |_) |  __/
# \__,_|\___||___/\___|_|  |_|_.__/ \___|
#                                       

# Describes a command, user by the "cmdlist" command and when the user enters a command name without any arguments (if it requires at least 1 argument)
func _describe_command(cmd, echo=true):
	var command = commands[cmd]
	var description = command.description
	var args = command.args
	var num_args = command.num_args
	if num_args >= 1:
		con_print("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + " " + args + ")[/color]", echo)
	else:
		con_print("[color=#ffff66]" + cmd + ":[/color] " + description + " [color=#88ffff](usage: " + cmd + ")[/color]", echo)


# Describes a cvar, used by the "cvarlist" command and when the user enters a cvar name without any arguments
func _describe_cvar(cvar, echo=true):
	var cvariable = cvars[cvar]
	var description = cvariable.description
	var type = cvariable.type
	var default_value = cvariable.default_value
	var value = cvariable.value
	if type == "str":
		con_print("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]\"" + str(value) + "\"[/color]  " + str(description) + " [color=#ff88ff](default: \"" + str(default_value) + "\")[/color]", echo)
	else:
		var min_value = cvariable.min_value
		var max_value = cvariable.max_value
		con_print("[color=#88ff88]" + str(cvar) + ":[/color] [color=#9999ff]" + str(value) + "[/color]  " + str(description) + " [color=#ff88ff](" + str(min_value) + ".." + str(max_value) + ", default: " + str(default_value) + ")[/color]", echo)



# _        _                                 _      _   _             
#| |_ __ _| |__     ___ ___  _ __ ___  _ __ | | ___| |_(_) ___  _ __  
#| __/ _` | '_ \   / __/ _ \| '_ ` _ \| '_ \| |/ _ \ __| |/ _ \| '_ \ 
#| || (_| | |_) | | (_| (_) | | | | | | |_) | |  __/ |_| | (_) | | | |
# \__\__,_|_.__/   \___\___/|_| |_| |_| .__/|_|\___|\__|_|\___/|_| |_|
#                                     |_|                             

func _tab_complete():
	var text = get_node("LineEdit").get_text()
	var cmd_matches = 0
	var cmd_found = ""
	var cvar_matches = 0
	var cvar_found = ""
	var tab_matches = []
	var tab_complete_line
	var tab_min = 100
	
	if tab_bbcode == "":
		tab_bbcode = get_node("ConsoleText").get_bbcode()
	else:
		get_node("ConsoleText").parse_bbcode(tab_bbcode)
	
	var command_keys = commands.keys()	# alphabetically sorting
	command_keys.sort()					#
	
	for command in command_keys:
		if command.begins_with(text):
			_describe_command(command, false)
			cmd_matches += 1
			cmd_found = command
			tab_matches.append(command)
			tab_min = min(tab_min, command.length())
	
	var cvar_keys = cvars.keys()		# alphabetically sorting
	cvar_keys.sort()					#
	
	for cvar in cvar_keys:
		if cvar.begins_with(text):
			_describe_cvar(cvar, false)
			cvar_matches += 1
			cvar_found = cvar
			tab_matches.append(cvar)
			tab_min = min(tab_min, cvar.length())
	
	if cmd_matches == 1 and cvar_matches == 0:
		cmd_found = cmd_found + " "
		get_node("LineEdit").set_text(cmd_found)
		get_node("LineEdit").set_cursor_position(cmd_found.length())
		return
		
	if cmd_matches == 0 and cvar_matches == 1:
		cvar_found = cvar_found + " "
		get_node("LineEdit").set_text(cvar_found)
		get_node("LineEdit").set_cursor_position(cvar_found.length())
		return
	
	if cmd_matches != 0 or cvar_matches != 0:
		#con_print("\n")
		
		var tab_done = false
		
		tab_complete_line = text
		for i in range(text.length(), int(tab_min)):
			tab_complete_line = tab_complete_line + tab_matches[0][i]
			#print(tab_complete_line)
			
			for tab_match in tab_matches:
				if not tab_match.begins_with(tab_complete_line):
					tab_complete_line = tab_complete_line.substr(0,i)
					tab_done = true
					break
					
			if tab_done:
				break
		
		get_node("LineEdit").set_text(tab_complete_line)
		get_node("LineEdit").set_cursor_position(tab_complete_line.length())



#                          _       
#  _____  _____  ___ _   _| |_ ___ 
# / _ \ \/ / _ \/ __| | | | __/ _ \
#|  __/>  <  __/ (__| |_| | ||  __/
# \___/_/\_\___|\___|\__,_|\__\___|
#                                  

func execute(text):
	var cmds = text.split(";")

	for cmd in cmds:
		for i in range(cmd.length()):
			if cmd.begins_with(" "):
				cmd.erase(0,1)
			else:
				break
		
		if not cmd == "":
			_handle_command(cmd)
		else:
			return
	
	#history.append(text)
	history.insert(0, text)


#                 _                        
#  _____   ____ _| |    __ _ _ __ __ _ ___ 
# / _ \ \ / / _` | |   / _` | '__/ _` / __|
#|  __/\ V / (_| | |  | (_| | | | (_| \__ \
# \___| \_/ \__,_|_|___\__,_|_|  \__, |___/
#                 |_____|        |___/  

func _eval_args(args):
	# Cleanup the args input
	# iterate over all cmd elements to find strings with leading and tailing ""
	# store them in new_args and hand it over to the function call
	var string_detected = false
	var string_arg = ""
	var new_args = []
	
	for arg in args:
		
		if arg.begins_with("\"") and arg.ends_with("\"") and not string_detected:
			arg.erase(0,1)						# remove the leading "
			arg.erase( arg.length() -1, 1)		# remove the tailing "
			new_args.append( arg )
			continue
		
		if arg.begins_with("\"") and not string_detected:
			string_detected = true
			arg.erase(0,1)						# remove the leading "
			string_arg = arg
			continue
		
		if arg.ends_with("\"") and string_detected:
			string_detected = false
			arg.erase( arg.length() -1, 1)		# remove the tailing "
			string_arg = string_arg + " " + arg
			new_args.append(string_arg)
			string_arg = ""
			continue
		
		if string_detected:
			string_arg = string_arg + " " + arg
			continue
		
		new_args.append(arg)
	
	if new_args.size() == 1:
		return [ args[0], "" ]
	else:
		return new_args

# _                     _ _      
#| |__   __ _ _ __   __| | | ___ 
#| '_ \ / _` | '_ \ / _` | |/ _ \
#| | | | (_| | | | | (_| | |  __/
#|_| |_|\__,_|_| |_|\__,_|_|\___|
#                                
#                                               _ 
#  ___ ___  _ __ ___  _ __ ___   __ _ _ __   __| |
# / __/ _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` |
#| (_| (_) | | | | | | | | | | | (_| | | | | (_| |
# \___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|
#                                                 

func _handle_command(text):
	
	if not tab_bbcode == "":
		get_node("ConsoleText").parse_bbcode(tab_bbcode)
		tab_bbcode = ""
	
	# The current console text, splitted by spaces (for arguments)
	var cmd = text.split(" ", true)
	# Check if the first word is a valid command
	if commands.has(cmd[0]):
		var command = commands[cmd[0]]
		print("] " + text)
		con_print("[b]] " + text + "[/b]", false)
		# If no argument is supplied, then show command description and usage, but only if command has at least 1 argument required
		if cmd.size() == 1 and not command.num_args == 0:
			_describe_command(cmd[0])
		else:
			# Run the command! If there are no arguments, don't pass any to the other script.
			if command.num_args == 0:
				command.node.call(CONSOLE_FUNC_PREFIX + cmd[0])
			else:
				command.node.call(CONSOLE_FUNC_PREFIX + cmd[0], _eval_args(cmd))
				
				
	# Check if the first word is a valid cvar
	elif cvars.has(cmd[0]):
		_handle_cvar(text, cmd)
	else:
		# Treat unknown commands as unknown
		con_print("[b]] " + text + "[/b]")
		#con_print("[i][color=#ff8888]Unknown command or cvar: " + cmd[0] + "[/color][/i]")
		con_print_error("[i]Unknown command or cvar: " + cmd[0] + "[/i]")
	get_node("LineEdit").clear()
	history_idx = 0


func _handle_cvar(text, cmd):
	var cvar = cvars[cmd[0]]
	print("] " + text)
	con_print("[b]] " + text + "[/b]")
	# If no argument is supplied, then show cvar description and usage
	if cmd.size() == 1:
		_describe_cvar(cmd[0])
	else:
		# Let the cvar change values!
		if cvar.type == "str":
			for word in range(1, cmd.size()):
				if word == 1:
					cvar.value = str(cmd[word])
				else:
					cvar.value += str(" " + cmd[word])
		elif cvar.type == "int":
			cvar.value = int(cmd[1])
		elif cvar.type == "float":
			cvar.value = float(cmd[1])

		# Call setter code
		if cvar.node.has_method(CONSOLE_VAR_PREFIX + cmd[0]):
			cvar.node.call(CONSOLE_VAR_PREFIX + cmd[0], cvar.value)


func get_cvar(name):
	# TODO: Implement type check
	return cvars[name].value


func set_cvar(name, value):
	# TODO: Implement type check
	cvars[name].value = value
	cvars[name].node.call(CONSOLE_VAR_PREFIX + name, value)



# _                 _                     __ _       
#| | ___   __ _  __| |    ___ ___  _ __  / _(_) __ _ 
#| |/ _ \ / _` |/ _` |   / __/ _ \| '_ \| |_| |/ _` |
#| | (_) | (_| | (_| |  | (_| (_) | | | |  _| | (_| |
#|_|\___/ \__,_|\__,_|___\___\___/|_| |_|_| |_|\__, |
#                   |_____|                    |___/ 

func load_config():
	_confunc_config_load()
	
		# Load history
	if get_cvar("console_history_autoload") == 1:
		_confunc_console_history_load()



#                _     _            
# _ __ ___  __ _(_)___| |_ ___ _ __ 
#| '__/ _ \/ _` | / __| __/ _ \ '__|
#| | |  __/ (_| | \__ \ ||  __/ |   
#|_|  \___|\__, |_|___/\__\___|_|   
#          |___/                    
#                                               _ 
#  ___ ___  _ __ ___  _ __ ___   __ _ _ __   __| |
# / __/ _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` |
#| (_| (_) | | | | | | | | | | | (_| | | | | (_| |
# \___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|
#                                                 
# Register functions
func _register_commands():
	register_command("echo", {
		node = self,
	description = "Prints a string in console.",
		args = "<string>",
		num_args = 1
	})
	
	register_command("cmdlist", {
		node = self,
		description = "Lists all available commands.",
		args = "",
		num_args = 0
	})
	
	register_command("cvarlist", {
		node = self,
		description = "Lists all available cvars.",
		args = "",
		num_args = 0
	})
	
	register_command("help", {
		node = self,
		description = "Outputs usage instructions.",
		args = "",
		num_args = 0
	})
	
	register_command("quit", {
		node = self,
		description = "Exits the application.",
		args = "",
		num_args = 0
	})
	
	register_command("clear", {
		node = self,
		description = "Clears the console output.",
		args = "",
		num_args = 0
	})
	
	register_command("config_save", {
		node = self,
		description = "Saves the current config into user://config.txt.",
		args = "",
		num_args = 0
	})
	
	register_command("config_load", {
		node = self,
		description = "Loads the config from user://config.txt.",
		args = "",
		num_args = 0
	})
	
	register_command("macro_create", {
		node = self,
		description = "Creates a macro.",
		args = "<Macroname> <Macro>",
		num_args = 2
	})
	
	register_command("macro_delete", {
		node = self,
		description = "Deletes a macro.",
		args = "<Macroname>",
		num_args = 1
	})
	
	register_command("macro_exec", {
		node = self,
		description = "Executes a macro.",
		args = "<Macroname>",
		num_args = 1
	})
	
	register_command("macro_list", {
		node = self,
		description = "Lists all macros.",
		args = "",
		num_args = 0
	})
	
	register_command("console_history_save", {
		node = self,
		description = "Saves the history to user://history.txt",
		args = "",
		num_args = 0
	})
	
	register_command("console_history_load", {
		node = self,
		description = "Loads the history from user://history.txt",
		args = "",
		num_args = 0
	})



#  ___ ___  _ __ ___  _ __ ___   __ _ _ __   __| |
# / __/ _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` |
#| (_| (_) | | | | | | | | | | | (_| | | | | (_| |
# \___\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|
#                                                 
#  __                  _   _                 
# / _|_   _ _ __   ___| |_(_) ___  _ __  ___ 
#| |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
#|  _| |_| | | | | (__| |_| | (_) | | | \__ \
#|_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#     

# Prints a string in console
func _confunc_echo(args):
	args.remove(0)
	
	var text = ""
	
	for arg in args:
		text = text + arg + " "
		
	con_print(text)


# Lists all available commands
func _confunc_cmdlist():
	var keys = commands.keys()
	keys.sort()
	
	for key in keys:
		_describe_command(key)


# Lists all available cvars
func _confunc_cvarlist():
	var keys = cvars.keys()
	keys.sort()
	
	for key in keys:
		_describe_cvar(key)


# Prints some help
func _confunc_help():
	var help_text = """Type [color=#ffff66]cmdlist[/color] to get a list of commands.
Type [color=#ffff66]cvarlist[/color] to get a list of variables.
Type [color=#ffff66]quit[/color] to exit the application."""
	con_print(help_text)


# Exits the application
func _confunc_quit():
	
	# Save history
	if get_cvar("console_history_autosave") == 1:
		_confunc_console_history_save()
	
	get_tree().quit()


# Clears the console output
func _confunc_clear():
	tab_bbcode = ""
	console_text.parse_bbcode("[b][/b]")


# Saves the current config to a file.
func _confunc_config_save():
	
	var cfg = ConfigFile.new()
	
	#save cvars
	if not cvars.empty():
		var keys = cvars.keys()
		keys.sort()
		
		for key in keys:
			var cvar = key.split("_")
			
			if cvar.size() >= 2:
				var section = cvar[0]
				cfg.set_value(section, key, cvars[key].value)
	
	#save macros
	if not macros.empty():
		var keys = macros.keys()
		keys.sort()
		
		var section = "macros"
		
		for key in keys:
			cfg.set_value(section, key, macros[key])
	
	
	#save all to a file
	var ret = cfg.save(cfg_filename)
	if ret == OK:
		con_print_ok(cfg_filename + " saved.")
	else:
		con_print_error("Could not save " + cfg_filename + "!")


# Loads the config from a file.
func _confunc_config_load():
	
	var cfg = ConfigFile.new()
	var ret = cfg.load(cfg_filename)
	if ret == OK:
		var sections = cfg.get_sections()
		
		for section in sections:
			
			#load macros
			if section == "macros":
				var macro_keys = cfg.get_section_keys(section)
				
				for macroname in macro_keys:
					macros[macroname] = cfg.get_value(section, macroname)
				
				continue
			
			
			var keys = cfg.get_section_keys(section)
			
			for key in keys:
				if cvars.has(key):
					var value = cfg.get_value(section, key)
					cvars[key].value = value
					cvars[key].node.call(CONSOLE_VAR_PREFIX + key, value)
		
		con_print_ok(cfg_filename + " loaded.")
	else:
		con_print_warn("Could not open " + cfg_filename + "!")


#func _confunc_config_delete(args):
#	Global.delete_file(args[1])


func _confunc_macro_create(args):
	
	var macroname = args[1]
	
	if not macros.has(macroname):
		args.remove(0)
		args.remove(0)
		
		var macro = ""
		
		for element in args:
			macro = macro + element + " "
		
		macros[macroname] = macro
		con_print_ok("Macro " + macroname + " created.")
	else:
		con_print_error("A Macro with the name " + macroname + " already exists!")
	


func _confunc_macro_delete(args):
	
	var macroname = args[1]
	
	if macros.has(macroname):
		macros.erase(macroname)
		con_print_ok("Macro " + macroname + " deleted.")
	else:
		con_print_error("There is no macro named " + macroname + "!")


func _confunc_macro_exec(args):
	
	var macroname = args[1]
	
	if macros.has(macroname):
		execute(macros[macroname])
	else:
		con_print_error("There is no macro named " + macroname + "!")


func _confunc_macro_list():
	for macroname in macros:
		con_print(macroname + " -- " + macros[macroname])


func _confunc_console_history_save():
	# save history
	var file = File.new()
	var ret = file.open("user://history.txt", file.WRITE)
	if ret == OK:
		for i in history:
			file.store_string(i+"\n")
		file.close()
		con_print_ok("user://history.txt saved.")
	else:
		con_print_error("Could not create file: user://history.txt!")


func _confunc_console_history_load():
	# loads history
	
	history = []
	
	var file = File.new()
	var ret = file.open("user://history.txt", file.READ)
	if ret == OK:
		while not file.eof_reached():
			var line = file.get_line()
			if not line == "":
				history.append(line)
		file.close()
		con_print_ok("user://history.txt loaded.")



#                _     _                                       
# _ __ ___  __ _(_)___| |_ ___ _ __    _____   ____ _ _ __ ___ 
#| '__/ _ \/ _` | / __| __/ _ \ '__|  / __\ \ / / _` | '__/ __|
#| | |  __/ (_| | \__ \ ||  __/ |    | (__ \ V / (_| | |  \__ \
#|_|  \___|\__, |_|___/\__\___|_|     \___| \_/ \__,_|_|  |___/
#          |___/                                               

func _register_cvars():
	register_cvar("console_font_size", {
		node = self,
		description = "Console font size (0=automatic dpi detection).",
		type = "int",
		default_value = 0,
		min_value = 0,
		max_value = 32
	})
	
	register_cvar("console_size", {
		node = self,
		description = "Console size.",
		type = "float",
		default_value = 0.4,
		min_value = 0.0,
		max_value = 1.0
	})
	
	register_cvar("console_alpha", {
		node = self,
		description = "Sets the alpha for the console.",
		type = "float",
		default_value = 0.9,
		min_value = 0.0,
		max_value = 1.0
	})
	
	register_cvar("console_show", {
		node = self,
		description = "Show or hide the console on startup.",
		type = "int",
		default_value = 0,
		min_value = 0,
		max_value = 1
	})
	
	register_cvar("console_history_autosave", {
		node = self,
		description = "Saves the history to user://history.txt on quit",
		type = "int",
		default_value = 1,
		min_value = 0,
		max_value = 1
	})
	
	register_cvar("console_history_autoload", {
		node = self,
		description = "Loads the history from user://history.txt on startup",
		type = "int",
		default_value = 1,
		min_value = 0,
		max_value = 1
	})



#                             __                  _   _                 
#  _____   ____ _ _ __ ___   / _|_   _ _ __   ___| |_(_) ___  _ __  ___ 
# / __\ \ / / _` | '__/ __| | |_| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
#| (__ \ V / (_| | |  \__ \ |  _| |_| | | | | (__| |_| | (_) | | | \__ \
# \___| \_/ \__,_|_|  |___/ |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#                                                                       

# Console -- font size
func _convar_console_font_size(value):
	
	if value == 0:
		# Set font size depending on the dpi resolution
		var dpi = OS.get_screen_dpi()
		if dpi <= 200:
			value = 14
		elif dpi <= 400:
			value = 20
		else:
			value = 26
	
	get_node("ConsoleText").get_font("bold_italics_font").set_size(value)
	get_node("ConsoleText").get_font("italics_font").set_size(value)
	get_node("ConsoleText").get_font("bold_font").set_size(value)
	get_node("ConsoleText").get_font("normal_font").set_size(value)
	get_node("LineEdit").get_font("font").set_size(value)


# Console -- size
func _convar_console_size(value):
	if value == 0:
		if OS.get_name() == "Android":
			value = 0.4
		else:
			value = 0.7
	
	var screen_size = Vector2()
	
	if OS.is_window_fullscreen():
		screen_size = OS.get_screen_size()
	else:
		screen_size = OS.get_window_size()
	
	var console_size = get_size()
	set_size( Vector2(console_size.x, screen_size.y * value))


# Console -- set alpha
func _convar_console_alpha(value):
	self_modulate.a = value


# Console -- show
func _convar_console_show(value):
	if value == 1:
		set_console_opened(false)
	else:
		set_console_opened(true)
		


# Console -- history autosave
func _convar_console_history_autosave(value):
	pass


# Console -- history autosave
func _convar_console_history_autoload(value):
	pass


