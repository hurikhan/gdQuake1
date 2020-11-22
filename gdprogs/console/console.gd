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

var ansi_support = false

var state = CONSOLE_STATE_CLOSED
var busy = false

var thread_count = 0
var thread_count_mutex = Mutex.new()

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
	
	if OS.has_environment("TERM"):
		if OS.get_environment("TERM") == "xterm-256color":
			ansi_support = true

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
		get_tree().set_input_as_handled ()
		return
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("console_up"):
		_history_up()
		get_tree().set_input_as_handled()
		return
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("console_down"):
		_history_down()
		get_tree().set_input_as_handled()
		return
	
	if get_node("LineEdit").has_focus() and event.is_action_pressed("console_clear"):
		_confunc_clear()
		get_tree().set_input_as_handled()
		return
	
	if get_node("LineEdit").get_text() != "" and get_node("LineEdit").has_focus() and Input.is_key_pressed(KEY_TAB):
		_tab_complete_args()
		_tab_complete()
		get_tree().set_input_as_handled()
		return
	
	




# _     _     _                   
#| |__ (_)___| |_ ___  _ __ _   _ 
#| '_ \| / __| __/ _ \| '__| | | |
#| | | | \__ \ || (_) | |  | |_| |
#|_| |_|_|___/\__\___/|_|   \__, |
#                           |___/ 

func _history_up():
	if history_idx < history.size():
		history_idx = history_idx + 1
		get_node("LineEdit").set_text( history[ history_idx-1 ] )
		get_node("LineEdit").set_cursor_position( history[ history_idx-1 ].length()  )



func _history_down():
	if history_idx > 0:
		history_idx = history_idx - 1
		
		if history_idx == 0:
			get_node("LineEdit").clear()
		else:
			get_node("LineEdit").set_text( history[ history_idx - 1] )
			get_node("LineEdit").set_cursor_position( history[ history_idx -1 ].length() )



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
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# Signal handles the hiding at the end of the animation
	# Open the console
	elif opened == false:
		get_node("AnimationPlayer").play_backwards("fade")
		get_node("LineEdit").grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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


const _ANSI_RGB = char(0x1B) + "[38;2;%d;%d;%dm"
const _ANSI_BOLD = char(0x1B) + "[1m"
const _ANSI_RESET = char(0x1B) + "[0m"

const _ansi_debug = false
func _ansi_print(text: String, echo : bool):
	var ansi = text
	var offset = 0
	
	while true:
		offset = ansi.findn('[color=', offset)
		
		if offset == -1:
			break
		
		var end = ansi.findn(']', offset)
		var sub = ansi.substr(offset, end-offset+1)
		
		# html color e.g.: "[color=#FFFFFF]"
		if sub[7] == '#':
			var _colorhtml = ansi.substr(offset + 7, end-offset-7)
			if ansi_support:
				var _c = Color(_colorhtml)
				var _ansi_color = _ANSI_RGB % [_c.r8, _c.g8, _c.b8]
				ansi = ansi.replace(sub, _ansi_color)
				
				if _ansi_debug:
					print("sub[%d..%d]: %s" % [offset, end, sub])
					print("colorhtml: %s" % [_colorhtml])
					print("color: %02x%02x%02x" % [_c.r8, _c.g8, _c.b8])
			else:
				ansi = ansi.replace(sub, "")
			
		# named color e.g.: "[color=white]"
		else:
			var _colorname = ansi.substr(offset + 7, end-offset-7)
			if ansi_support:
				var _c = ColorN(_colorname)
				var _ansi_color = _ANSI_RGB % [_c.r8, _c.g8, _c.b8]
				ansi = ansi.replace(sub, _ansi_color)
				
				if _ansi_debug:
					print("sub[%d..%d]: %s" % [offset, end, sub])
					print("colorname: %s" % [_colorname])
					print("color: %02x%02x%02x" % [_c.r8, _c.g8, _c.b8])
			else:
				ansi = ansi.replace(sub, "")
		
		offset +=1
	
	if ansi_support:
		ansi = ansi.replace("[b]", _ANSI_BOLD)
		ansi = ansi.replace("[/b]", _ANSI_RESET)
		ansi = ansi.replace("[/color]", _ANSI_RESET)
	else:
		ansi = ansi.replace("[b]", "")
		ansi = ansi.replace("[/b]", "")
		ansi = ansi.replace("[/color]", "")
	
	print(ansi)


func con_print_image(image):
	var size = image.get_size()
	var cvar_scale = get_cvar("console_print_image_scale")
	size.x = int(size.x * cvar_scale)
	size.y = int(size.y * cvar_scale)
	image.resize(size.x, size.y)
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	$ConsoleText.add_image(tex)
	$ConsoleText.newline()


func con_print(text : String, echo=true):
	_ansi_print(text, echo)
	
	if not text.ends_with('\n'):
		text += '\n'
		
	$ConsoleText.append_bbcode(text)

var last_completion = 0

func con_print_completion(lines : PoolStringArray):
	
	for i in range(0, last_completion):
		$ConsoleText.remove_line($ConsoleText.get_line_count() - 1)
	
	$ConsoleText.update()
	
	for line in lines:
		con_print(line)
	
	last_completion = lines.size()


func con_print_ok(text : String):
	# lime text
	con_print("[color=lime][OK]    -- %s[/color]" % text)


func con_print_warn(text : String):
	# yellow text
	con_print("[color=yellow][WARN]  -- %s[/color]" % text)


func con_print_error(text):
	# red text
	con_print("[color=red][ERROR] -- %s[/color]" % str(text))


func con_thread(text, _node, _func, _args):
	
	while(true):
		if thread_count >= cvars["mt_num"].value:
			OS.delay_msec(10)
		else:
			thread_count_mutex.lock()
			thread_count += 1
			thread_count_mutex.unlock()
			break
	
	var userdata = Array()
	
	userdata.insert(0, text)
	userdata.insert(1, _node)
	userdata.insert(2, _func)
	userdata.insert(3, _args)
	
	var _thread = Thread.new()
	_thread.start(self, "_con_thread_func", userdata)
	con_print("[color=aqua][THREAD -- STARTED] -- %s [/color]" % str(text))
	
	return _thread
	
	
	
func con_thread_wait(_thread):
	return _thread.wait_to_finish()
	
	
func _con_thread_func(userdata):
	
	var _text = userdata[0]
	var _node = userdata[1]
	var _func = userdata[2]
	var _args = userdata[3]
	
	var start = OS.get_ticks_msec()
	var ret = _node.callv(_func, _args)
	var end = OS.get_ticks_msec()
	con_print("[color=blue][THREAD -- DONE] -- %s %d ms[/color]" % [str(_text), end-start])
	
	thread_count_mutex.lock()
	thread_count -= 1
	thread_count_mutex.unlock()
	
	return ret



func con_print_array(arr):
	for entry in arr:
		con_print(str(entry))


var _progress_thread
var _progress_timer
var _progress_status_node
var _progress_status_func
var _progress_status_firstcall = false
var _progress_status_text = ""

enum {STATUS_INIT, STATUS_PROGRESS, STATUS_FINISHED}

func _con_progress_status():
	
	var ret = _progress_status_node.call(_progress_status_func)
	var status = ret[0]
	var msg = ret[1]
	
	match status:
		STATUS_INIT:
			if _progress_status_firstcall == true:
				con_print(msg)
				_progress_status_firstcall = false
		
		STATUS_PROGRESS:
			console_text.remove_line(console_text.get_line_count() - 1)
			console_text.update()
			con_print(msg)
			console_text.update()
		
		STATUS_FINISHED:
			_progress_timer.autostart = false
			_progress_timer.stop()
			_progress_thread.wait_to_finish()
			
			if typeof(msg) == TYPE_ARRAY:
				console_text.remove_line(console_text.get_line_count() - 1)
				console_text.update()
				con_print(msg[0])
				console_text.update()
				con_print_ok(msg[1])
			else:
				console.con_print_ok(msg)


func con_progress(thread_node, thread_func, thread_parameter, status_func):
		_progress_thread = Thread.new()
		
		var err = _progress_thread.start(thread_node, thread_func, thread_parameter)
		
		if err == 0:
			_progress_status_node = thread_node
			_progress_status_func = status_func
			_progress_status_firstcall = true
			_progress_timer = Timer.new()
			_progress_timer.set_wait_time(0.5)
			_progress_timer.connect("timeout", self, "_con_progress_status")
			_progress_timer.autostart = true
			add_child(_progress_timer)


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


func _tab_complete_args():
	var text = $LineEdit.get_text()
	var args = text.split(' ')
	
	if commands.has(args[0]):
		var command = commands[args[0]]
		if command.node.has_method("_confunc_%s_autocompletion" % args[0]):
			command.node.call("_confunc_%s_autocompletion" % args[0], args)


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
		con_print_error("Unknown command or cvar: " + cmd[0])
		
	get_node("LineEdit").clear()
	history_idx = 0


func _handle_cvar(text, cmd):
	var cvar = cvars[cmd[0]]
	#$ConsoleText.push_color(Color.blueviolet)
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
	
	register_command("ls", {
		node = self,
		description = "Lists the files in the current directory.",
		args = "<directory>",
		num_args = 1
	})
	
	register_command("cache_clear", {
		node = self,
		description = "Clear the cache.",
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


# [Autocompletion] Lists the files in the current directory.
func _confunc_ls_autocompletion(args):
	
	var s1 = ""
	var s2 = ""
	
	if args.size() == 1:
		return
	
	s1 = args[1].get_base_dir()
	s2 = args[1].get_file()
	
	if s1 != "":
		s1 += '/'
	
	if args.size() > 1:
		if not shell_has_dir("user://%s" % s1):
			s1 = ""
	
	var dirs = shell_ls("user://%s" % s1)[0]
	var found = []

	for d in dirs:
		if d.begins_with(s2):
			found.push_back(d)
	
	if found.size() == 1:
		var line = "%s %s/" % [args[0], s1 + found[0]]
		$LineEdit.set_text(line)
		$LineEdit.caret_position = line.length()
		con_print_completion([""])
	else:
		var completion_text = []
		for f in found:
			completion_text.push_back("[color=#4040FF]%s[/color]/" % f)
		con_print_completion(completion_text)


# Lists the files in the current directory.
func _confunc_ls(args):
	var dir = Directory.new()
	
	var path = "user://"
	
	if args.size() > 1:
		path = path + args[1]
	
	var ret = shell_ls(path)
	var dirs = ret[0]
	var files = ret[1]
	
	for d in dirs:
		console.con_print("[color=#4040FF]%s[/color]/" % d)
	
	for f in files:
		console.con_print(f)


# Removes the whole cache directory.
func _confunc_cache_clear():
	var path = "user://cache/"
	
	var dir = Directory.new()
	
	if dir.dir_exists(path):
		_remove_dir(path)
		dir.remove(path)


# [Helper] Removes a complete directory recursivly
func _remove_dir(path):
	
	var dir = Directory.new()	
	var ret = shell_ls(path)
	var dirs = ret[0]
	var files = ret[1]
	
	for d in dirs:
		_remove_dir(path+d+"/")
		dir.remove(path+d)
	
	for f in files:
		dir.remove(path+f)

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
	
	register_cvar("console_ansi_color", {
		node = self,
		description = "Activates/Deactivates ANSI color support for the terminal output.",
		type = "int",
		default_value = 1,
		min_value = 0,
		max_value = 1
	})
	
	register_cvar("console_print_image_scale", {
		node = self,
		description = "Sets the scale for images, which are printed trought con_print_image().",
		type = "float",
		default_value = 2.0,
		min_value = 0.0,
		max_value = 100.0
	})
	
	register_cvar("cache", {
		node = self,
		description = "Activates/Deactivates the cache functionality.",
		type = "int",
		default_value = 1,
		min_value = 0,
		max_value = 1
	})
	
	register_cvar("mt", {
		node = self,
		description = "Activates/Deactivates the multitreading functionality.",
		type = "int",
		default_value = 1,
		min_value = 0,
		max_value = 1
	})
	
	register_cvar("mt_num", {
		node = self,
		description = "Maximum number of parallel threads",
		type = "int",
		default_value = 4,
		min_value = 0,
		max_value = 128
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

# Console -- ansi terminal color support
func _convar_console_ansi_color(value):
	if value == 1:
		if OS.has_environment("TERM"):
			if OS.get_environment("TERM") == "xterm-256color":
				ansi_support = true
	else:
		ansi_support = false


# Console -- con_print_image() scale factor
func _convar_console_print_image_scale(value):
	pass


# Cache On/Off
func _convar_cache(value):
	pass


# MultiThreading On/Off
func _convar_mt(value):
	pass


# MultiThreading max num of threads
func _convar_mt_num(value):
	pass
#     _          _ _                      _     
# ___| |__   ___| | |   ___ _ __ ___   __| |___ 
#/ __| '_ \ / _ \ | |  / __| '_ ` _ \ / _` / __|
#\__ \ | | |  __/ | | | (__| | | | | | (_| \__ \
#|___/_| |_|\___|_|_|  \___|_| |_| |_|\__,_|___/
											   

func shell_ls(path):
	var dir = Directory.new()
	
	var dirs = []
	var files = []
	
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var filename = dir.get_next()
		
		while filename != "":
			#console.con_print(filename)

			if dir.current_is_dir():
				if filename != "." and filename != "..":
					dirs.push_back(filename)
			else:
					files.push_back(filename)
				
			filename = dir.get_next()
		
		dirs.sort()
		files.sort()
		
		return [dirs, files]
		
	else:
		console.con_print_error("Could not open %s directory." % path)


func shell_has_dir(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		return true
	else:
		return false
