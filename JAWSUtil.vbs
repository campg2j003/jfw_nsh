' JAWSUtil - JAWS utility command processor.
' Purpose: Provide various JAWS utility functions via command line for installers, scripts, etc.
' Run without arguments for usage information.
'
' Copyright (c) 2009-2017 Doug Lee.
'
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
'
' * Redistributions of source code must retain the above copyright notice,
'   this list of conditions and the following disclaimer.
'
' * Redistributions in binary form must reproduce the above copyright notice,
'   this list of conditions and the following disclaimer in the documentation
'   and/or other materials provided with the distribution.
'
' * The names of the copyright holders and contributors may not be used to
'   endorse or promote products derived from this software without specific
'   prior written permission.
'
' THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
' FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
' DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
' SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
' CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
' OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
' USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

option explicit

sub usageExit(msg)
' Print usage instructions and exit with an error code.
	' Get the program name for messages.
	dim name : name = wscript.scriptName
	if lcase(right(name, 4)) = ".vbs" then
		name = left(name, len(name)-4)
	end if
	if msg <> "" then
		msg = msg &VbCrLf
	end if
	errOutput msg &"Usage: " &name &" [-d] [<JAWSVersion>][/<langCode>] <action> [<actionArgs...>" _
	&VbCrLf &"    -d:  Turn debug messages on." _
	&VbCrLf &"<JAWSVersion> is a JAWS version code (e.g., 18.0 or 2018)." _
	&VbCrLf &"<langCode> is a JAWS language code (e.g., enu)." _
	&VbCrLf &"<action> is a recognized action:" _
	&VbCrLf &"	Ver, Lang, Ver/Lang: Report JAWS version, language, or both." _
	&VbCrLf &"	Chain: Update a script chain." _
	&VbCrLf &"	compile: Compile a JSS file or set of files." _
	&VbCrLf &"	Dict: Manipulate a JAWS dictionary (jdf) file." _
	&VbCrLf &"	Paths: Report JAWS paths for testing." _
	&VbCrLf &"<actionArgs> depend on the action; type just the action for further details." _
	&VbCrLf &"Example: " &name &" 2018/enu chain default add bx 8"
	wscript.quit(1)
end sub

' Handle options.
dim argStart : argStart = 0
dim forceCon : forceCon = False
dim arg
for each arg in wscript.arguments
	if arg = "-c" then
		forceCon = True
		argStart = argStart +1
	elseif arg = "-d" then
		debug "*on*"
		argStart = argStart +1
	else
		exit for
	end if
next

' Basic usage check
if wscript.arguments.count -argStart < 1 then
	usageExit ""
end if

' Re-exec in a console if required.
' TODO: Not working (reExecInCon() not defined) and not listed in usage().
if forceCon then
	if not isCon then
		reExecInCon
		wscript.quit
	end if
end if

dim arg1 : arg1 = wscript.arguments(argStart)
dim argParts
dim ver : ver = ""
dim lang : lang = ""
if instr("0123456789", left(arg1, 1)) > 0 then
	' ver and maybe lang given.
	argParts = split(arg1, "/")
	ver = argParts(0)
	if UBound(argParts) > 0 then
		lang = argParts(1)
	end if
	argStart = argStart +1
elseif left(arg1, 1) = "/" then
	' Lang but no ver.
	lang = mid(arg1, 2)
	argStart = argStart +1
end if

' This makes args equal to the command-line arguments after but not including action.
' orgAction is the action from the command line, and action is its lower-case equivalent.
dim orgAction : orgAction = wscript.arguments(argStart)
dim action : action = lcase(orgAction)
dim argcount : argcount = wscript.arguments.count -argStart -1
redim args(argCount-1)
dim i
for i = 0 to argCount -1
	args(i) = wscript.arguments(i+argStart +1)
next

' Globals including the JAWS info object configured for the given JAWS version and language.
dim goFSO : set goFSO = createObject("Scripting.FileSystemObject")
	dim goShell : set goShell = createObject("wscript.shell")
' The program will exit with an error if this init fails.
dim goJAWSInfo : set goJAWSInfo = new JAWSInfo.init(ver, lang)
'errOutput "JAWS " &goJAWSInfo.version &" lang " &goJAWSInfo.lang &" action " &orgAction

' Switch on action.
' All action functions return the null string on success and an error message on failure.
dim result : result = ""
if action = "ver" or action = "lang" or action = "ver/lang" then
	result = do_verLang(action, args)
elseif action = "chain" then
	result = do_chain(args)
elseif action = "compile" then
	result = do_compile(args)
elseif action = "dict" then
	result = do_dict(args)
elseif action = "paths" then
	result = do_paths(args)
else
	usageExit "Unrecognized action: " &cStr(orgAction)
end if
if len(result) > 0 then
	output result
	wscript.quit(1)
end if
wscript.quit(0)

function isCon
' Indicates if this code is running as a console process (as opposed to a GUI process)
dim sName: sName = WScript.fullName
if instr(1, sName, "cscript.exe", 1) then
	isCon = 1
else
	isCon = 0
end if
end function

function do_verLang(action, args)
' Report JAWS version, language, or both.
	dim result
	if action = "ver" then
		result = goJAWSInfo.version
	elseif action = "lang" then
		result = goJAWSInfo.lang
	elseif action = "ver/lang" then
		result = goJAWSInfo.version &"/" &goJAWSInfo.lang
	else
		errOutput "do_verLang: Invalid request: " &action
		wscript.quit 1
	end if
	do_verLang = result
end function

function do_chain(args)
' Update a script chain.
	dim nargs : nargs = UBound(args) +1
	if nargs < 2 then
		do_chain = chain_usage
		exit function
	end if

	dim fileBase : fileBase = args(0)
	dim orgAction : orgAction = args(1)
	dim action : action = lcase(orgAction)
	dim scriptfile, success
	dim oChain : set oChain = new JAWSChain.init(fileBase)

	if action = "add" then
		if nargs < 3 or nargs > 4 then
			do_chain = chain_usage
			exit function
		end if
		scriptfile = args(2)
		if lcase(right(scriptfile, 4)) <> ".jsb" then
			scriptfile = scriptfile &".jsb"
		end if
		dim priority : priority = 0
		if nargs = 4 then
			if len(args(3)) = 1 and instr("123456789", args(3)) > 0 then
				priority = cInt(args(3))
			else
				do_chain = chain_usage
				exit function
			end if
		end if
		success = oChain.addFile(scriptfile, priority)
		if not success then
			do_chain = oChain.errmsg
			exit function
		end if
		success = oChain.write
		if not success then
			do_chain = oChain.errmsg
			exit function
		end if
	elseif action = "remove" or action = "rm" or action = "delete" or action = "del" then
		if nargs <> 3 then
			do_chain = chain_usage
			exit function
		end if
		scriptfile = args(2)
		if lcase(right(scriptfile, 4)) <> ".jsb" then
			scriptfile = scriptfile &".jsb"
		end if
		success = oChain.removeFile(scriptfile)
		if not success then
			do_chain = oChain.errmsg
			exit function
		end if
		success = oChain.write
		if not success then
			do_chain = oChain.errmsg
			exit function
		end if
	elseif action = "list" or action = "ls" then
		oChain.forceRead
		errOutput oChain
		dim files : files = oChain.files
		errOutput oChain
		dim n : n = UBound(files) +1
		dim s : s = cStr(n) +" file(s)"
		if n > 0 then
			s = s +":  " +join(files, ", ")
		end if
		wscript.echo s
	else
		do_chain = "Chain: Unrecognized action: " &orgAction _
		&VbCrLf &do_chain(array(0))  ' trick to display usage.
		exit function
	end if
end function

function chain_usage
	chain_usage = "Syntax: chain <fileBase> add <scriptName> [<priority>]" _
	&VbCrLf &"    <priority>: 1 for first, 9 for last, 2-8 to order between." _
	&VbCrLf &"        WARNING:  Do not use 1 or 9 unless absolutely necessary," _
	&VbCrLf &"        because only one 1 and one 9 are allowed in a chain." _
	&VbCrLf &"        If no <priority> is given, 5 is used." _
	&VbCrLf &"    Example: Chain default add bx 8" _
	&VbCrLf &"chain <fileBase> remove <scriptName> - Remove a file from this chain." _
	&VbCrLf &"chain <fileBase> list - List the files in this chain."
end function

function do_compile(args)
' Compile a JSS file or set of files.
	dim nargs : nargs = UBound(args) +1
	if nargs < 1 then
		do_compile = compile_usage
		exit function
	end if
	do_compile = goJAWSInfo.compile(args)
end function

function compile_usage
	compile_usage = "Syntax: compile <fileName[.jss]> ..." _
	&VbCrLf &"Compilation will take place in the current folder, which" _
	&VbCrLf &"may and may not be a JAWS user folder."
end function

function do_dict(args)
' Manipulate a JAWS dictionary file.
	do_dict = "The Dict command is not yet implemented."
end function

function do_paths(args)
' Report JAWS paths for testing purposes.
	dim nargs : nargs = UBound(args) +1
	dim useShort : useShort = False
	dim skipArg : skipArg = False
	if nargs >= 1 then
		if lcase(args(0)) = "short" then
			skipArg = True
			useShort = True
			nargs = nargs -1
		end if
	end if
	if nargs < 1 then
		if useShort then
			do_paths = "Paths for JAWS version " &goJAWSInfo.version &", language " &goJAWSInfo.lang &":" _
				&VbCrLf &"Program Folder: " &goFSO.getFolder(goJAWSInfo.progDir).shortpath _
				&VbCrLf &"Shared Folder: " &goFSO.getFolder(goJAWSInfo.sharedDir).shortpath _
				&VbCrLf &"User Folder: " &goFSO.getFolder(goJAWSInfo.userDir).shortpath
		else
			do_paths = "Paths for JAWS version " &goJAWSInfo.version &", language " &goJAWSInfo.lang &":" _
				&VbCrLf &"Program Folder: " &goJAWSInfo.progDir _
				&VbCrLf &"Shared Folder: " &goJAWSInfo.sharedDir _
				&VbCrLf &"User Folder: " &goJAWSInfo.userDir
		end if
		exit function
	end if
	dim buf : buf = ""
	dim path
	dim arg
	for each arg in args
		if skipArg then
			skipArg = False
		else
			arg = lcase(left(arg, 1))
			if arg = "p" then
				path = goJAWSInfo.progDir
			elseif arg = "s" then
				path = goJAWSInfo.sharedDir
			elseif arg = "u" then
				path = goJAWSInfo.userDir
			else
				path = "(unrecognized folder identifier)"
			end if
			if useShort then
				path = goFSO.getFolder(path).shortpath
			end if
			buf = buf +path +VbCrLf
		end if
	next
	do_paths = buf
end function

' General utilities.

sub output(msg)
	wscript.echo msg
end sub

sub errOutput(byVal msg)
	' This is not a loop; it's an exitable block.
	do while typeName(msg) <> "String"
		' Allow some object types to be passed instead of a string.
		on error resume next
		msg = "Error " &cStr(msg.number) &": " &msg.description
		if err.number = 0 then
			if msg = "Error 0: " then
				msg = ""
			end if
			exit do
		end if
		err.clear
		msg = msg.errmsg
		if err.number = 0 then
			exit do
		end if
		err.clear
		msg = "<unknown object type " &typeName(msg) &">"
		exit do
	loop
	on error goto 0
	if msg = "" then
		exit sub
	end if
	wscript.stderr.write msg &VbCrLf
end sub

dim gu_debugging : gu_debugging = 0
sub debug(msg)
' Print a debugging message or turn debugging on/off.
	if msg = "*on*" then
		gu_debugging = 1
	elseif msg = "*off*" then
		gu_debugging = 0
	elseif gu_debugging then
		errOutput(msg)
	end if
end sub

function isFalse(item)
	' False items: empty (undefined), null, null string, numeric 0.
	' Warning: Objects that are logically False, like empty collections,
	' still return True here.
	isFalse = False
	if isEmpty(item) then
		isFalse = True
		exit function
	end if
	if isNull(item) then
		isFalse = True
		exit function
	end if
	if isObject(item) then
		if item is Nothing then
			isFalse = True
		end if
		exit function
	end if
	' isNumeric("0") is True!
	if isNumeric(item) and typeName(item) = "Integer" then
		if item = 0 then
			isFalse = True
		end if
		exit function
	end if
	if item = "" then
		isFalse = True
		exit function
	end if
end function

function safeEval(o, s)
	' Evaluate s as an expression in which o is obj.
	' Example: safeEval(oDict, "o.count") where oDict is a Scripting.Dictionary
	' object will return oDict.count.
	' This is called "safe" because it dodges errors in chains of references,
	' such as safeEval(oDict, "o(""xyz"").type") when oDict("xyz") doesn't exist.
	' WARNING: If s does not evaluate to an object, s is evaluated twice.
	' Beware this if s has side effects.
	on error resume next
	set safeEval = eval(s)
	if err.number then
		'wscript.echo "*** Error on set: " &err.description
		err.clear
		safeEval = eval(s)
		if err.number then
			'wscript.echo "*** Error without set: " &err.description
			err.clear
			safeEval = undefined
			exit function
		end if
	end if
	on error goto 0
end function

class JAWSInfo
' A class for getting JAWS paths.
' Construction example: set oJAWSInfo = new JAWSInfo.init("2018", "enu")
' Requires the debug(msg) sub to be defined.

	' The name of the JAWS program (constant).
	public property get progName : progName = "jfw.exe" : end property
	' The version and language codes for this JAWS version (passed to init() or figured out).
	public version, lang
	' The integer portion of version.
	public major
	' Directories of JAWS files.
	public progDir, userDir, sharedDir
	' Full path to the JAWS program.
	public property get progPath : progPath = progDir &"\" &progName : end property
	' True if this JAWS version is (or seems to be) currently running.
	public running

	private sub Class_Initialize
		version = ""
		lang = ""
		running = False
	end sub

	public function init(ver, langCode)
	' Initialize properties given a JAWS version number and language code to work with.
	' Can be chained onto an object creation line--e.g., set JAWS = new JAWSInfo.init(...).
		if len(ver) > 0 then
			debug "Using given JAWS version " &ver
			version = ver
		else
			version = getJFWVersion
		end if
		major = version
		on error resume next
		major = int(left(version, instr(version, ".") -1))
		err.clear
		on error goto 0
		if len(langCode) > 0 then
			debug "Using given language code " &langCode
			lang = langCode
		else
			lang = getJFWLang
		end if
		setDataDirs
		setProgDir
		set init = me
		running = isRunning(progPath)
	end function

	public function getSharedPath(fname)
	' Return the full path to the given shared file.
	' In JAWS 17+, this can involve a search among a few folders.
		if goFSO.fileExists(sharedDir &"\" &fname) then
			getSharedPath = sharedDir &"\" &fname
			exit function
		elseif major < 17 then
			' Before JAWS 17 there were no further options.
			getSharedPath = ""
			exit function
		end if
		dim tmp : tmp = sharedDir
		tmp = replace(tmp, "Settings", "Scripts")
		if goFSO.fileExists(tmp &"\" &fname) then
			getSharedPath = tmp &"\" &fname
			exit function
		end if
		tmp = replace(tmp, "\"&lang, "")
		if goFSO.fileExists(tmp &"\" &fname) then
			getSharedPath = tmp &"\" &fname
			exit function
		end if
		getSharedPath = ""
	end function

	private function getJFWVersionFromProgName(sProg)
	' Get the running JAWS version using sProg as the executable name..
	' Requires WMI.
	' Helper for getJFWVersion().
		dim wmistr : wmistr = "winmgmts:" _
			&"{impersonationLevel=impersonate}!" _
			&"\\." _
			&"\root\cimv2"
		dim wmi : set wmi = Nothing
		on error resume next
		set wmi = getObject(wmistr)
		if wmi is Nothing then
			debug "JAWSInfo.getJFWVersionFromProgName:  WMI is not available."
			getJFWVersionFromProgName = ""
			exit function
		end if
		dim oProcs : set oProcs = Nothing
		set oProcs = wmi.execQuery("SELECT ExecutablePath FROM Win32_Process WHERE name='" &sProg &"'")
		if oProcs is Nothing then
			debug "JAWSInfo.getJFWVersionFromProgName:  WMI query failed"
			getJFWVersionFromProgName = ""
			exit function
		end if
		on error goto 0
		dim oProc
		dim sPath, sVer
		debug "Found " &cStr(oProcs.count) &" instance(s) of " &sProg
		if oProcs.count = 0 then
			getJFWVersionFromProgName = ""
			exit function
		end if
		for each oProc in oProcs
			if sPath then
				' More than one.
				debug "More than one executable path found, not sure which to use."
				getJFWVersionFromProgName = ""
				exit function
			end if
			sPath = oProc.ExecutablePath
			if isNull(sPath) then
				' Seen on Vista with JAWS 11, 2010-02-16.
				debug "The executable path for " &sProg &" is null."
				getJFWVersionFromProgName = ""
				exit function
			end if
			dim aPathParts : aPathParts = split(sPath, "\")
			sVer = aPathParts(UBound(aPathParts)-1)
		next
		debug "JAWSInfo.getJFWVersionFromProgName:  The running JAWS version is " &sVer
		getJFWVersionFromProgName = sVer
	end function

	private function getJFWVersionFromRegistry
	' Get the best JAWS version we can from the Windows registry.
	' Best:
	'	- The only version if only one is found, or
	'	- The only one found to be running if one can be verified as such, or
	'	- The newest version if all else fails.
	' A warning prints if the latter is the case.
	' This routine reads from the registry and must use the 64-bit view where applicable.
	' This should happen by default where applicable.
	' This routine also uses reg.exe.
		dim regpath : regpath = "HKEY_LOCAL_MACHINE\SOFTWARE\Freedom Scientific\JAWS"
		dim oReg : set oReg = Nothing
		on error resume next
		set oReg = goShell.exec("reg query """ &regpath &"""")
		on error goto 0
		if oReg is Nothing then
			debug "JAWSInfo.getJFWVersionFromRegistry: reg.exe exec failed."
			getJFWVersionFromRegistry = ""
			exit function
		end if
		dim results
		results = oReg.StdOut.ReadAll
		debug "Output of reg.exe: " &results
		results = split(results, VbCrLf)
		dim errs : errs = oReg.StdErr.ReadAll
		if len(errs) then
			errOutput "Error running reg.exe:"
			errOutput errs
			getJFWVersionFromRegistry = ""
			exit function
		end if
		do while oReg.status = 0
			wscript.sleep 100
		loop
		if oReg.status = 2 then  ' wshFailed
			debug "reg.exe exec failed."
			getJFWVersionFromRegistry = ""
			exit function
		end if
		dim line, parts, sVer, jpath
		dim found : found = ""
		dim running : running = ""
		for each line in results
			if len(line) then
				if len(found) then
					found = found &"|"
				end if
				found = found &line
				' Convert reg key to file path of jfw.exe.
				jpath = ""
				on error resume next
				jpath = goShell.regRead(line &"\Target")
				on error goto 0
				if len(jpath) then
					if isRunning(jpath &progName) then
						if len(running) then
							running = running &"|"
						end if
						running = running &line
					end if
				end if
			end if  ' len(line)
		next
		found = split(found, "|")
		if UBound(found) = 0 then
			parts = split(found(0), "\")
			sVer = parts(UBound(parts))
			debug "Version " &sVer &" is the only one found."
			getJFWVersionFromRegistry = sVer
			exit function
		end if
		running = split(running, "|")
		if UBound(running) = 0 then
			parts = split(running(0), "\")
			sVer = parts(UBound(parts))
			debug "Version " &sVer &" is the only one running."
			getJFWVersionFromRegistry = sVer
			exit function
		end if
		dim jver : jver = ""
		for each line in found
			parts = split(line, "\")
			sVer = parts(UBound(parts))
			if sVer > jver then
				jver = sVer
			end if
		next
		sVer = jver
		errOutput "Warning: Unable to find a running JAWS version on this machine."
		errOutput "Using the latest version found (" &sVer &")"
		getJFWVersionFromRegistry = sVer
	end function

	private function isRunning(path)
	' Return True if the full path given represents a running JAWS instance.
	' This is done by trying to open it for append (but without writing any data).
	' A "Permission denied" error is assumed to mean the file is open.
	' This trick was discovered by DGL on 2011-03-16 (Vista).
		isRunning = False
		if not goFSO.fileExists(path) then
			exit function
		end if
		on error resume next
		dim oFile : set oFile = goFSO.openTextFile(path, 8) ' ForAppending
		if err.number then
			if err.number = 70 then
				' Permission denied.
				isRunning = True
			end if
		else
			oFile.close
		end if
		on error goto 0
	end function

	public function getJFWVersion
	' Get the running JAWS version.
	' If this fails, get the latest installed JAWS version.
		dim jver
		jver = getJFWVersionFromProgName(progName)
		if jver = "" then
			jver = getJFWVersionFromProgName("FSATProxy.exe")
		end if
		if jver = "" then
			jver = getJFWVersionFromRegistry
		end if
		getJFWVersion = jver
	end function

	public function getJFWLang
	' Get the JAWS language currently in use.
	' TODO:  enu is assumed here.
	' Could look for e.g., JDiction.* minus .exe and use that extension if there's only one.
	' The newest user-folder default.jcf can indicate the language in use.
	' GetWindowModuleName for the first (dialog) descendent of the JFWUI2-class window
	' will return jfw.<langCode>, e.g., jfw.enu.
	' But we can't get to that from VBScript.
		getJFWLang = "enu"
	end function

	private sub setProgDir
	' Set the JAWS program path and verify that JAWS exists there.
	' Exits the program on failure.
	' This routine tries to read from the registry and must use the 64-bit view where applicable.
	' This should happen by default unless a 32-bit process launched this one.
	' To get around that possibility, a guess is made on registry read failure.
	' setDataDirs must run first.
		dim regpath : regpath = "HKEY_LOCAL_MACHINE\SOFTWARE\Freedom Scientific\JAWS\" _
			&version &"\Target"
		progDir = ""
		on error resume next
		progDir = goShell.regRead(regpath)
		on error goto 0
		if progDir <> "" then
			if right(progDir, 1) = "\" then
				progDir = left(progDir, len(progDir)-1)
			end if
			if goFSO.FileExists(progPath) then
				exit sub
			end if
			' If it's in the registry, it should be right, and we don't guess,
			' for fear of getting a different installation.
			errOutput "JAWS not found in listed location " &progDir
			wscript.quit(1)
		end if
		' RegRead failed, we have to guess.
		progDir = ":\Program Files\Freedom Scientific\JAWS\" &version
		if mid(sharedDir, 2, 1) = ":" then
			' Try the drive that contains the shared folder.
			dim drive : drive = left(sharedDir, 1)
			if goFSO.FileExists(drive &progPath) then
				progDir = drive &progDir
				exit sub
			end if
			' Failure above means that path doesn't exist.
		end if
		' Failure here means that or sharedDir does not start with a drive letter.
		progDir = "C" &progDir
		if not goFSO.FileExists(progPath) then
			errOutput "JAWS not found in guessed location " &progDir
			wscript.quit(1)
		end if
	end sub

	sub setDataDirs
	' Set the user and shared directory path properties.
		dim suffix : suffix = "\Freedom Scientific\JAWS\" &version &"\Settings\" &lang
		userDir = appDataPath(False) &suffix
		if not goFSO.FolderExists(userDir) then
			errOutput "JAWS user folder not found or invalid (" &userDir &")."
			wscript.quit(1)
		end if
		sharedDir = appDataPath(True) &suffix
		if not goFSO.FolderExists(sharedDir) then
			errOutput "JAWS shared folder not found or invalid (" &sharedDir &")."
			wscript.quit(1)
		end if
	end sub

	private function appDataPath(bAllUsers)
	' Get the All Users or current user Application Data folder path.
		dim result
		if bAllUsers then
			' Perhaps somewhat expensive but should-be bullet-proof method.
			dim oShellApp : set oShellApp = createObject("Shell.Application")
			' 35 == &H23 == sffCOMMONAPPDATA.
			' namespace returns Folder; self goes to FolderItem where we have a path.
			result = oShellApp.Namespace(35).Self.Path
		else
			result = envVar("appdata")
		end if
		appDataPath = result
	end function

	private function envVar(varname)
	' Expand %varname% via shell.expandEnvironmentStrings,
	' or use alternative means where known and necessary,
	' or quit the program if varname won't expand.
		if not (left(varname, 1) = "%" and right(varname, 1) = "%") then
			varname = "%" &varname &"%"
		end if
		dim expanded : expanded = goShell.expandEnvironmentStrings(varname)
		if expanded <> varname then
			envVar = expanded
			exit function
		end if

		' Standard env vars like APPDATA can be missing (e.g., under Cygwin).
		' This gets those that we know how to find manually.
		dim ev_lc : ev_lc = lcase(mid(varname, 2, len(varname)-2))
		if ev_lc = "appdata" then
			expanded = ""
			on error resume next
			expanded = goShell.regRead("HKEY_CURRENT_USER\Volatile Environment\APPDATA")
			on error goto 0
			if len(expanded) > 0 then
				envVar = expanded
				exit function
			end if
		end if
		errOutput "Error: Unable to expand " &varname &"."
		wscript.quit(1)
	end function

	public function JAWSVersions
	' Return a list of the JAWS versions available.
	' Uses the shared (All Users) folder to determine the version list.
	' We'd use the registry, but I see no way to get a list of keys at a registry level.
		dim root : root = appDataPath(True) &"\Freedom Scientific\JAWS"
		dim oFolders : set oFolders = goFSO.getFolder(root).subfolders
		' TODO: Finish.
	end function

	public function compile(byVal flist())
	' Compile the files in flist, which may include or omit jss extensions.
	' All files in flist are sought in the current folder.
	' Files referenced from or required by compilables will be sought
	' in the current folder, then the JAWS shared folder.
	' Compilation will take place in a temporary folder,
	' and resulting jsb files will be returned to the current folder.
	' For convenience, flist may be a single file (string) rather than an array.
	' Returns null on success and output text on failure.
		compile = ""
		dim compiler : compiler = progdir &"\SCompile.exe"
		dim curdir : curdir = goShell.currentDirectory
		dim cmd : cmd = """" &compiler &""" -d"
		dim exists
		dim oTempFiles : set oTempFiles = new TempFiles.init(me)
		oTempFiles.sharedOnly = True
		oTempFiles.addFile "builtin.jsd"
		oTempFiles.addFile "default.jsd"
		oTempFiles.sharedOnly = False
		oTempFiles.scanFile "default.jss"
		if lcase(typeName(flist)) = "string" then
			flist = array(flist)
		end if
		dim jss, jsd
		for each jss in flist
			if lcase(right(jss, 4)) <> ".jss" _
			and not goFSO.fileExists(curdir &"\" &jss) then
				jss = jss &".jss"
			end if
			exists = goFSO.fileExists(curdir &"\" &jss)
			if not exists then
				compile = "File not found: " &jss
				exit function
			end if
			oTempFiles.addFile jss
			jsd = left(jss, len(jss)-4) &".jsd"
			oTempFiles.addFile jsd
			oTempFiles.scanFile jss
			cmd = cmd &" """ &jss &""""
		next
		oTempFiles.Populate
		dim oCompile : set oCompile = Nothing
		goShell.currentDirectory = oTempFiles.oTempFolder.Path
		on error resume next
		set oCompile = goShell.exec(cmd)
		on error goto 0
		goShell.currentDirectory = curdir
		if oCompile is Nothing then
			compile = "SCompile exec failed"
			oTempFiles.returnResultsTo curdir
			oTempFiles.cleanup
			exit function
		end if
		dim results : results = oCompile.StdOut.ReadAll
		dim errs : errs = oCompile.StdErr.ReadAll
		do while oCompile.status = 0
			wscript.sleep 100
		loop
		if oCompile.status = 2 then  ' wshFailed
			compile = "SCompile exec failed."
			oTempFiles.returnResultsTo curdir
			oTempFiles.cleanup
			exit function
		end if
		dim exitCode : exitCode = oCompile.exitCode
		if exitCode <> 0 then
			if len(errs) > 0 then
				if len(results) > 0 then
					results = results &VbCrLf
				end if
				results = results & errs
			end if
			compile = "SCompile exited with code " &cStr(exitCode) &VbCrLf &results
			results = split(results, VbCrLf)
		end if  ' exitCode <> 0
		oTempFiles.returnResultsTo curdir
		oTempFiles.cleanup
	end function

end class

class TempFiles
' Manager of files required from the current or JAWS shared folder for a compile.
' The files are copied to a temp folder for compilation, then removed.
' Used by JAWSInfo::Compile().

	' The parent JAWSInfo object that created this object.
	public parent
	' A dictionary used as an array of files to copy to and remove from the temp folder.
	private flist
	' The temporary folder used during compilation
	' (only valid between Populate and Cleanup calls).
	public oTempFolder
	' True when adding files that must be from the shared folder and no other.
	public sharedOnly

	private sub class_initialize
		set flist = createObject("Scripting.Dictionary")
		flist.CompareMode = VbTextCompare
		set oTempFolder = Nothing
		sharedOnly = False
	end sub

	public function init(oParent)
		set parent = oParent
		set init = me
	end function

	private function getPath(fname)
	' Get the full path for the given file:
	' If it already includes a path, use that but make it absolute.
	' else if it's in the current direcgtory, use that unless sharedOnly is True;
	' else if it's in the JAWS shared folder, use that;
	' else return the null string.
		dim fpath : fpath = ""
		if instr(fname, "\") > 0 then
			fpath = goFSO.getAbsolutePathName(replace(fname, "\\", "\"))
		elseif not sharedOnly and instr(fname, "\") < 1 and goFSO.fileExists(fname) then
			' Use current folder.
			fpath = goFSO.getAbsolutePathName(fname)
		else
			fpath = parent.getSharedPath(fname)
			' May be null.
		end if
		getPath = fpath
	end function

	public sub addFile(fname)
	' Add a file to the set of files to copy in and remove later.
	' The file is added from the current folder if it exists there,
	' or the shared folder if it exists there,
	' or not at all if it isn't found.
	' Fname must include an extension but not a path.
		if flist.exists(fname) then
			exit sub
		end if
		dim fpath : fpath = getPath(fname)
		if fpath = "" then
			' Can't get from anywhere, so skip it.
			exit sub
		end if
		' Add the file and its full path to the set.
		flist.add fname, fpath
	end sub

	public sub scanFile(fname)
	' Scan the given file and account for any files it references.
		dim fpath
		fpath = getPath(fname)
		dim oFile
		on error resume next
		set oFile = goFSO.openTextFile(fpath, 1)  ' 1 is ForReading
		if err.number then
			' TODO:  Again should report this.
			exit sub
		end if
		on error goto 0
		dim sLine, isInclude, isUse, isImport, inMessages
		inMessages = False
		do while not oFile.atEndOfStream
			sLine = trim(oFile.readLine)
			isInclude = False
			isImport = False
			isUse = False
			if inMessages then
				if lcase(left(sLine, 11)) = "endmessages" then
					inMessages = False
				end if
			elseif lcase(left(sLine, 8)) = "messages" then
			elseif lcase(left(sLine, 7)) = "include" then
				isInclude = True
				sLine = mid(sLine, 8)
			elseif lcase(left(sLine, 3)) = "use" then
				isUse = True
				sLine = mid(sLine, 4)
			elseif lcase(left(sLine, 6)) = "import" then
				isImport = True
				sLine = mid(sLine, 7)
			end if
			if isInclude or isUse or isImport then
				sLine = trim(sLine)
				if left(sLine, 1) = """" then
					sLine = mid(sLine, 2)
					sLine = split(sLine, """", 2)(0)
					sLine = replace(sLine, "\\", "\")
					if isInclude then
						addFile sLine
						scanFile sLine
					elseif isImport then
						addFile sLine
					else  ' isUse
						on error resume next
						sLine = left(sLine, len(sLine)-4)
						if lcase(sLine) = lcase(left(fname, len(fname)-4)) then
							' Example: Use "default.jsb" in JAWS 14+ user-folder default.jss.
							sLine = goJAWSInfo.getSharedPath(sLine)
						end if
						on error goto 0
						scanFile sLine &".jss"
						addFile sLine &".jsd"
					end if
				end if
			end if  ' isInclude or isUse or isImport
		loop
		oFile.close
	end sub

	public sub Populate
	' Create and populate a temporary folder for compilation
	' by copying all required files to it.
		if not (oTempFolder is Nothing) then
			' This should not happen.
			cleanup
		end if
		dim tmpdir , tmpname
		' 2 is TemporaryFolder.
		tmpdir = goFSO.GetSpecialFolder(2)
		if tmpdir = "" then
			errOutput "Can't get temporary folder!"
			exit sub
		end if
		tmpname = goFSO.GetTempName
		if tmpname = "" then
			errOutput "Can't get temporary name!"
			exit sub
		end if
		tmpdir = tmpdir &"\" &tmpname
		debug "Temp path: " &tmpdir
		set oTempFolder = goFSO.CreateFolder(tmpdir)
		dim fname, fpath
		for each fname in flist.keys
			fpath = flist(fname)
			fpath = replace(fpath, "\\", "\")
			on error resume next
			goFSO.copyFile fpath, tmpdir &"\" &fname
			if err.number then
				' TODO:  Output not expected here.
				' errOutput "CopyFile: File not found: " &fname
			end if
			err.clear
			on error goto 0
		next
	end sub

	public sub returnResultsTo(outpath)
	' Return jsb files to the given path from the temporary folder.
		dim oFile, destFile
		for each oFile in oTempFolder.Files
			if lcase(right(oFile.name, 4)) = ".jsb" then
				destFile = outpath &"\" &oFile.Name
				on error resume next
				goFSO.DeleteFile destFile, True
				on error goto 0
				err.clear
				dim moveErr : moveErr = False
				on error resume next
				oFile.move destFile
				if err.number then
					moveErr = True
				end if
				on error goto 0
				if moveErr then
					replaceFile oFile, destFile
				end if
			end if
		next
	end sub

	private sub replaceFile(oFile, destFile)
	' Move by copying then deleting.
	' Sometimes required when working in the JAWS shared folder.
		oFile.copy destFile
		oFile.Delete True
	end sub

	public sub cleanup
	' Remove the files and folder created by Populate().
		oTempFolder.Delete True
		set oTempFolder = Nothing
	end sub

end class
' JAWS chain manager code.
'
' A chain is defined by the "use" lines in its base file.
' A chain must include its FS base file in the shared folder,
' or a copy thereof that is maintained in the user folder.
' Files loaded in a chain can have "priorities" to help sort them:
'	1 - First after the FS file (must be zero or one files with this priority),
'	2-8 - Files between 1 and 9, higher numbers following lower ones, and
'	9 - Last of all files (must be zero or one files with this priority),
' The FS file is considered to have priority 0, so nothing can come before it.
' A chain manager file may contain other code.
'
' Chain operations (see also chain_usage()): init, [force]read, add, remove, list, write.
'
' Design notes:
' The whole file is kept in memory as a hash, lineNumber-to-lineText.
' An arbitrary number of operations can be carried out in memory before a write to disk.
' Two Scripting.Dictionary objects are used.
' Multiline comments are NOT handled properly.
'
' Author:  Doug Lee of Level Access

class JAWSChainLine
' Support class:  One chain file line that references a script (jsb) file.

	' Parent JAWSChain object.
	public parent
	' File name referenced, line number of reference, and priority value.
	' Priority: 0 for chain-starting FS file, 1-9 for others.
	' 1 is first, 9 is last, and there can be at most one of each.
	' 2-8 can repeat.
	public fname, lno, priority
	' File type (see setFType() for a list of types).
	public ftype

	private sub Class_Initialize
		set parent = Nothing
		fname = ""
		lno = 0
		priority = 0
		ftype = ""
	end sub

	public function init(p, file, refline)
		set parent = p
		fname = file
		lno = refline
		priority = 0
		dim line : line = parent.lines(lno)
		dim idx : idx = instr(line, ";")
		if idx > 0 then
			priority = trim(mid(line, idx+1))
			if len(priority) > 0 and instr("0123456789", left(priority, 1)) > 0 then
				priority = cInt(priority)
			else
				priority = 0
			end if
		end if
		setFType
		set init = me
	end function

	private sub setFType
	' Set the file type:
	'	a: Auxiliary (just a script, not a chain base of any sort).
	'	s: A directly loaded JAWS shared-folder script file.
	'	c: A copy of a shared-folder script file in the user folder.
		' Easy cases first.
		if lcase(fname) = lcase(parent.basename &".jsb") then
			' JAWS 14+ Use "default.jsb" style of shared file loading.
			ftype = "s"
			exit sub
		elseif lcase(fname) = lcase(parent.basename &parent.fs_suffix &".jsb") then
			' Use "default_fs.jsb" style.
			ftype = "c"
			exit sub
		end if
		' All other type tests require we read the first line of the jss.
		dim JSSName : JSSName = left(fname, len(fname)-4) &".jss"
		if instr(JSSName, "\") < 1 then
			JSSName = goJAWSInfo.userDir &"\" &JSSName
		end if
		dim oJSSFile
		dim firstLine : firstLine = ""
		on error resume next
		set oJSSFile = goFSO.openTextFile(jssName, 1)  ' 1 is ForReading
		if err.number = 53 then
			' File not found.
			err.clear
			dim JSBName : JSBName = left(JSSName, len(JSSName)-1) &"b"
			dim oJSBFile : set oJSBFile = goFSO.openTextFile(JSBName, 1)  ' 1 is ForReading
			if err.number = 53 then
				' This script really doesn't exist.
				parent.errmsg = "Script file " &JSBName &" not found."
				ftype = "a"
				exit sub
			elseif err.number then
				parent.errmsg = err.description
				exit sub
			else
				' The jsb is there but its jss isn't.
				' Assume this means it's not an FS file.
				err.clear
				oJSBFile.close
				ftype = "a"
				exit sub
			end if
			err.clear
			oJSBFile.close
		elseif err.number then
			parent.errmsg = err.description
			exit sub
		end if
		err.clear
		firstLine = oJSSFile.readLine
		if err.number then
			parent.errmsg = err.description
			oJSSFile.close
			exit sub
		end if
		oJSSFile.close
		on error goto 0
		firstLine = lcase(firstLine)
		if instr(firstLine, "copyright") > 0 and instr(firstLine, "freedom scientific") > 0 then
			' Freedom Scientific file, but where is it?
			' Assume "\" in fname means shared folder.
			if instr(fname, "\") > 0 then
				ftype = "s"
			else
				ftype = "c"
			end if
		else  ' not (obviously at least) a Freedom Scientific script file.
			' Again assume "\" in fname means shared folder.
			if instr(fname, "\") > 0 then
				ftype = "s"
			else
				ftype = "a"
			end if
		end if
	end sub
end class

class JAWSChain
' An object of this class represents a JAWS chain manager file.
' Construction example: set oJAWSChain = new JAWSChain.init("default")

	' Basename of the jss file that is the chain manager (passed to init()).
	public basename
	' Name of the jss file that is the chain manager.
	public jssName
	' Suffix used to form the name of the original Freedom Scientific script file backup that heads this chain.
	' Not used after September 15, 2013 except under JAWS 13 and older.
	public fs_suffix
	' Ordered list of jsb files managed by this chain.
	private flist
	' 0-based index in flist of the FS base script file for the chain.
	' Usually 0 but can be higher (e.g., after a JTools installation).
	public baseIdx
	' Lines from the chain file.
	' Public because JAWSChainLine objects reference this.
	public lines
	' Null string or a byte order mark (BOM) if the file contains one.
	public BOM
	' True if changes were made and False otherwise.
	public modified
	' Error message if the last operation caused an error.
	public errmsg

	private sub Class_Initialize
		basename = ""
		fs_suffix = "_fs"
		BOM = ""
		modified = False
		set flist = createObject("Scripting.Dictionary")
		set lines = createObject("Scripting.Dictionary")
		errmsg = ""
		baseIdx = -1
	end sub

	public function init(base)
		errmsg = ""
		basename = base
		jssName = basename &".jss"
		set init = me
	end function

	private sub buildRefs
	' Collect file reference info from lines.
		dim sLine, sLLine, pos
		dim fname
		flist.removeAll
		baseIdx = -1
		if lines.count = 0 then
			exit sub
		end if
		dim lno
		dim newFile
		for lno = 1 to lines.count
			sLine = lines(lno)
			sLLine = ltrim(lcase(sLine))
			' TODO: We assume no multiline comments here.
			if left(sLLine, 3) = "use" then
				sLine = ltrim(mid(sLine, 4))
				if left(sLine, 1) = """" then
					pos = instrRev(sLine, """")
					if pos > 0 then
						fname = mid(sLine, 2, pos-2)
						dim isShared : isShared = False
						' ToDo: WARNING: Paths are supported here but can crash some JAWS script compilers.
						' Incorrect paths, such as from block copying Settings/enu from one JAWS version to another, are not fixed.
						if instr(fname, "\") > 0 then
							' Un-double backslashes from the Use line.
							fname = replace(fname, "\\", "\")
							' Loading shared files is the only known use of paths here.
							isShared = True
						elseif lcase(fname) = lcase(basename &".jsb") and goJAWSInfo.major >= 14 then
							' JAWS 14+ can load shared-folder code this way.
							fname = goJAWSInfo.getSharedPath(fname)
							isShared = True
						end if
						set newFile = new JAWSChainLine.init(me, fname, lno)
						if isShared then
							' We know the ftype from context in this case.
							newFile.ftype = "s"
						end if
						if newFile.ftype = "" then
							errmsg = "Error: Script file type for " &fname &" not known."
							exit sub
						end if
						flist.add flist.count, newFile
						if instr("sc", newFile.ftype) > 0 then
							if baseIdx >= 0 then
								' Can't have more than one chain base file.
								errmsg = "Error: Multiple chain base files found (indices " &cStr(baseIdx+1) &" and " &cStr(flist.count) &")."
								exit sub
							end if
							baseIdx = flist.count -1
						end if
					end if
				end if
			end if
		next
	end sub

	public sub read
	' Read in the chain file and collect info from it.
		errmsg = ""
		dim oFile
		dim sLine
		dim lno : lno = 0
		dim fname
		if lines.count > 0 then
			' Do nothing; already read.
			exit sub
		end if
		modified = False
		flist.removeAll
		on error resume next
		set oFile = goFSO.openTextFile(goJAWSInfo.userDir &"\" &jssName, 1)  ' 1 is ForReading
		if err.number then
			' TODO: This can't be considered an error because it's legal to have no file and then create it.
			' However, it's also possible that the user mistyped a filename,
			' and without an error being thrown, this will go undetected.
			'errOutput err
			'errmsg = err.description
			exit sub
		end if
		on error goto 0
		do while not oFile.atEndOfStream
			lno = lno +1
			sLine = oFile.readLine
			if lno = 1 then
				dim llen : llen = len(sLine)
				if llen >= 3 then
					if ascB(midB(sLine, 1, 1)) >= 128 _
					and ascB(midB(sLine, 2, 1)) >= 128 _
					and ascB(midB(sLine, 3, 1)) >= 128 then
						BOM = left(sLine, 3)
						sLine = mid(sLine, 4)
					end if
				end if
			end if
			lines.add lno, sLine
		loop
		oFile.close
		buildRefs
	end sub

	public sub forceRead
	' Same as read but forces a rebuild of the data if it was read already.
		flist.removeAll
		lines.removeAll
		read
	end sub

	private function filePriority(fname)
	' Report the priority value for the given file in the managed set.
	' Results: 0-9 for a found file, -1 for a not-found file.
		dim lrec
		for each lrec in flist.items
			if lcase(lrec.fname) = lcase(fname) then
				filePriority = lrec.priority
				exit function
			end if
		next
		filePriority = -1
	end function

	public function removeFile(fname)
	' Remove a jsb file from the set managed by this chain.
	' Does not go to disk until write() is called.
		dim lrec
		read
		if lcase(right(fname, 4)) <> ".jsb" then
			fname = fname &".jsb"
		end if
		for each lrec in flist.items
			if lcase(lrec.fname) = lcase(fname) then
				removeLine lrec.lno
				buildRefs
				removeFile = True
				exit function
			end if
		next
		errmsg = fname &" not found."
		removeFile = False
	end function

	public function addFile(fname, priority)
	' Add a jsb file to the set managed by this chain.
	' Does not go to disk until write() is called.
	' Priority: 1-9:
	'	0:  Default (which is 5).
	'		Note: 0 is used internally for the FS file and files without a number.
	'	1:  Must be first after any FS and unnumbered files.
	'	2-8: After all files of lower or equal number.
	'	9: Last file of all files.
	' It is an error to try to have more than one 1 or 9.
	' Returns True on success and False on failure.
		' Note: For a new chain, two files are added: the given one and the FS file that starts the chain.
		addFile = False
		errmsg = ""
		dim newline : newline = """use """ &fname &".jsb"""
		if priority = 0 then
			priority = 5
		end if
		newline = newline +" ; " +cStr(priority)
		read
		dim n : n = flist.count
		dim nonchain : nonchain = False
		if n = 0 then
			' No files being loaded, so no chain here.
			nonchain = True
		elseif baseIdx < 0 then
			' The chain must include a base file to be valid.
			nonchain = True
		end if
		if nonchain then
			' No chain yet; we have to start one.
			if lines.count <> 0 then
				' ... but this is not a chain file!
				' TODO: Can do better with this condition sometime.
				errmsg = "Error: " &jssName &" is not a script chain manager file."
				exit function
			end if
			' The file doesn't exist yet or is empty.
			addLine "; JAWS Script Chain Manager File - DO NOT EDIT UNLESS YOU KNOW WHAT YOU'RE DOING"
			addLine ""
			dim startname
			if goJAWSInfo.major >= 14 then
				startname = basename &".jsb"
			else
				' The sharedDir approach crashed some JAWS script compilers. [DGL, 2013-10-21]
				' startname = goJAWSInfo.getSharedPath(basename &".jsb")
				startname = basename &fs_suffix &".jsb"
			end if
			addLine "use """ &replace(startname, "\", "\\") &""""
			addLine "use """ &fname &"""  ; " &cStr(priority)
			addLine ""
			addLine "void function filler()"
			addLine "; Filler to make some JAWS versions compile this file successfully."
			addLine "return"
			addLine "endFunction"
			addLine ""
			buildRefs
			addFile = True
			exit function
		end if
		' The file exists and contains references.
		dim curPriority : curPriority = filePriority(fname)
		if curPriority = priority then
			' Return True, but nothing to do.
			addFile = True
			exit function
		elseif curPriority >= 0 then
			if not removeFile(fname) then
				exit function
			end if
			n = n -1
		end if
		dim i, lrec
		for i = n-1 to 0 step -1
			set lrec = flist(i)
			if priority = lrec.priority and (priority = 1 or priority = 9) then
				errmsg = "Error: Position conflict with " &lrec.fname
				exit function
			elseif priority >= lrec.priority then
				exit for
			end if
		next
		' Since we don't allow priority=0 by this point,
		' we established that the FS file is in the chain,
		' and the FS file has priority=0,
		' the above loop should never terminate except via the "exit for" line.
		' lrec will therefore be a line after the FS script's Use line.
		insertLineAfter lrec.lno, "use """ &fname &""" ; " &cStr(priority)
		buildRefs
		addFile = True
	end function

	private sub insertLineAfter(lno, line)
	' Insert a line into lines and update all subsequent keys.
		dim i
		for i = lines.count to lno+1 step -1
			lines.key(i) = i+1
		next
		lines.add lno+1, line
		modified = True
		buildRefs
	end sub

	private sub removeLine(lno)
	' Remove a line from lines and update all subsequent keys.
		dim i
		dim n : n = lines.count
		lines.remove lno
		modified = True
		for i = lno+1 to n
			lines.key(i) = i-1
		next
		buildRefs
	end sub

	private sub addLine(line)
	' Add a line to the line collection.
		lines.add lines.count, line
		modified = True
	end sub

	public function files
	' Return an array of the files managed by this chain.
		dim i
		dim n : n = flist.count
		read
		redim fl(n-1)
		for i = 0 to n-1
			fl(i) = flist(i).fname
		next
		files = fl
	end function

	public function write
	' Write the file to disk if it was changed.
	' This includes the following activities ("base" means the shared-folder version of this file or a copy of it):
	'	- Make sure not to clobber a commercial script set without source that does not support chaining.
	'	- Make sure all referenced non-base jsb files in the chain exist in the JAWS user folder.
	'	- Refresh the *_fs.jsb/jsd files that base the chain, and/or
	'	update the chain base file reference method based on JAWS version if necessary.
	'	- Update the chain manager jss and compile it.
	'	- Reload all JAWS configs if possible, the file being written is default.jss, and the updated JAWS version is the one now running.
	' Nothing is done if no modifications to the chain were made however.
		write = False
		if not modified then
			write = True
			exit function
		end if
		' Upgrade base file access method based on JAWS version if necessary.
		dim FSFile : set FSFile = flist(baseIdx)
		dim FSLine : FSLine = lines(FSFile.lno)
		dim jver : jver = goJAWSInfo.major
		dim newLine
		dim jssPath : jssPath = goJAWSInfo.userDir &"\" &jssName
		dim JSBPath : JSBPath = left(JSSPath, len(JSSPath)-1) &"b"
		if goFSO.fileExists(jsbPath) and not goFSO.fileExists(jssPath) then
			' Likely a commercial script set installed without jss source code.
			dim JSBName : JSBName = left(JSSName, len(JSSName)-1) &"b"
				errmsg = "Error: " &jsbName &" does not come with JSS source; probably a commercial script set that does not support script chain management."
			exit function
		end if
		if jver >= 14 then
			lines.remove FSFile.lno
			lines.add FSFile.lno, "use """ &basename &".jsb"""
			buildRefs
		else
			lines.remove FSFile.lno
			newLine = "use """
			newLine = newLine &basename &fs_suffix &".jsb"""
			lines.add FSFile.lno, newLine
			buildRefs
		end if
		' Verify files exist.
		if not verifyFiles then
			exit function
		end if
		dim oFile
		on error resume next
		set oFile = goFSO.createTextFile(goJAWSInfo.userDir &"\" &jssName, 2)  ' 2 is ForWriting
		if err.number then
			errmsg = err.description
			exit function
		end if
		on error goto 0
		dim n : n = lines.count
		dim i
		for i = 1 to n
			if i = 1 and len(BOM) > 0then
				dim lfirst : lfirst = bom &lines(i)
				oFile.writeline lfirst
			else
				oFile.writeline lines(i)
			end if
		next
		oFile.close
		dim curdir, result, jsbfile
		curdir = goShell.currentDirectory
		jsbfile = goJAWSInfo.userDir &"\" &left(jssName, len(jssName)-4) &".jsb"
		goShell.currentDirectory = goJAWSInfo.userDir
		on error resume next
		goFSO.deleteFile jsbfile
		err.clear
		if goFSO.fileExists(jsbfile) then
			' TODO: Crazy error here, not sure what to raise.
			errmsg = "Can't delete " &jsbfile &" before recreating it."
			exit function
		end if
		result = goJAWSInfo.compile(jssName)
		on error goto 0
		goShell.currentDirectory = curdir
		if not goFSO.fileExists(jsbfile) then
			errmsg = "Failed to recreate " &jsbfile
		end if
		if lcase(jssName) = "default.jss" and goJAWSInfo.running then
			reloadAllJAWSConfigs
		end if
		forceRead
		write = True
	end function

	private function verifyFiles
	' Verify that all Used files exist before committing the chain manager file to disk.
	' This includes verifying the existence of the FS files that start this chain,
	' and in JAWS versions 13 and older,, creating/refreshing the *_fs.* copies thereof in the JAWS user folder.
		verifyFiles = False
		dim i, lrec, uname
		for i = 0 to flist.count -1
			set lrec = flist(i)
			uname = lrec.fname
			if lrec.ftype = "c" and instr(lcase(uname), fs_suffix&".jsb") > 0 then
				' Indicates that this is a copy of an FS file.
				errmsg = ""
				refreshCopies(lrec)
				if len(errmsg) then
					exit function
				end if
			end if
			if instr(uname, "\") < 1 then
				uname = goJAWSInfo.userDir &"\" &uname
			end if
			if not goFSO.fileExists(uname) then
				errmsg = "File does not exist: " &uname
				exit function
			end if
		next
		verifyFiles = True
	end function

	private function refreshCopies(lrec)
	' Refresh copies of jsd/jsb files for a JAWS shared-folder file copy.
		dim uname : uname = lrec.fname
		dim sname
		sname = left(uname, len(uname) -(len(fs_suffix)+4)) &".jsb"
		debug "Copying " &sname &" to " &uname
		sname = goJAWSInfo.getSharedPath(sname)
		uname = goJAWSInfo.userDir &"\" &uname
		on error resume next
		goFSO.copyFile sname, uname
		if err.number then
			errmsg = err.description &" while copying " &sname &" to " &uname
			exit function
		end if
		sname = left(sname, len(sname)-3) &"jsd"
		uname = left(uname, len(uname)-3) &"jsd"
		goFSO.copyFile sname, uname
		' That one is allowed not to exist though.
		on error goto 0
	end function

	private function reloadAllJAWSConfigs
	' If possible, signal JAWS to reload all its config and script files.
	' Returns True if the signal was sent and False otherwise.
		reloadAllJAWSConfigs = False
		' FSAPI COM object instantiation.
		dim oJAWSAPI : set oJAWSAPI = Nothing
		on error resume next
		set oJAWSAPI = createObject("FreedomSci.JAWSAPI")
		on error goto 0
		if oJAWSAPI is Nothing then
			exit function
		end if
		on error resume next
		oJAWSAPI.RunFunction("ReloadAllConfigs")
		if err.number then
			' ToDo: No error thrown so the whole process doesn't fail,
			' but the user is thus not warned of the need to reload configs.
			' The caller may fix this based on the False return value though.
			exit function
		end if
		reloadAllJAWSConfigs = True
		' If this announcement fails but the actual operation didn't,
		' still return True.
		' TODO:  This message should be localized.
		dim s : s = "Updates to the default scripts have been loaded"
		' oJAWSAPI.RunFunction("SayString(""" &s &""", 0)")
		dim func : func = "sayUsingVoice(""Message"", """ &s &""", 0)"
		oJAWSAPI.RunFunction(func)
		on error goto 0
	end function
end class

class JDictEntry
' One JAWS dictionary entry and methods to deal with it.

	' JAWS dictionary field separators in order of JAWS' apparent preference.
	private property get SEPS
		SEPS = ".,!@#$%^&*()_+abcdefghijklmnopqrstuvwxyz"
	end property

	' Fields in a .jdf entry, in order
	' Sep is the character that separates entries.
	' i1 is an integer of unknown use, always seen as 0.
	public sep, actual, replacement, langCode, synthName, voiceName, watchCase, i1
	' Double quote character.
	private dq

	private sub Class_Initialize()
		dq = chr(34)
	end sub

	public function makeReplacement(phrase, lang, sound)
		' Call this to generate a proper replacement-entry when it's not just a word or phrase.
		dim entry : entry = ""
		if sound then
			entry = entry & "<sound name=" &dq &sound &dq &"/>"
		end if
		if lang then
			entry = entry &"<lang langid=" &dq &lang &dq &">"
		end if
		entry = entry &phrase
		if lang then
			entry = entry &"</lang>"
		end if
		makeReplacement = entry
	end function

	public function splitReplacement(phrase, lang, sound)
		' Call to get parts of a replacement.
		' If the replacement is a simple phrase, nothing is done.
		' Otherwise, phrase becomes just the phrase (i.e., this is a destructive call).
		' Returns non-zero if anything was done and 0 otherwise.
		lang = ""
		sound = ""
		splitReplacement = 0
		if left(phrase, 1) <> "<" then
			exit function
		end if
		dim entry : entry = phrase  ' starts as the whole thing.
		dim oRE : set oRE = new RegExp
		dim oMatches, oMatch
		oRE.global = False
		oRE.ignoreCase = True

		' Sound first.
		oRE.pattern = "<sound\s+name=" &dq &"([^" &dq &"]*)" &dq &"\s*/>"
		set oMatches = oRE.execute(entry)
		if oMatches.count > 0 then
			sound = entry
			oRE.replace sound, "$1"
			oRE.replace entry, ""
			splitReplacement = 1
		end if

		' Now phrase and lang.
		oRE.pattern = "<lang\s+langid=" &dq &"([^" &dq &"]*)" &dq &"\s*>(.*)</lang>"
		set oMatches = oRE.execute(entry)
		if oMatches.count > 0 then
			lang = entry
			oRE.replace lang, "$1"
			phrase = entry
			oRE.replace phrase, "$2"
			oRE.replace entry, ""
			' entry should be empty now.
			splitReplacement = 1
		end if
	end function

	public function makeEntry(actual, replacement)
		' TODO: Write, and maybe update parameter list.
	end function

	public function splitEntry(entry)
		' Split the given entry into the class variables.
		actual = ""
		replacement = ""
		langCode = ""
		synthName = ""
		voiceName = ""
		watchCase = 0
		i1 = 0
		splitEntry = False

		sep = left(entry, 1)
		if right(entry, 1) <> sep then
			exit function
		end if
		dim fields : fields = split(mid(entry, 2, len(entry)-2), sep)
		dim i : i = 0
		for each field in fields
			i = i +1
			select case i
				case 1: actual = field
				case 2: replacement = field
				case 3: langCode = field
				case 4: synthName = field
				case 5: voiceName = field
				case 6: watchCase = field
				case 7: i1 = field
			end select
		next
		splitEntry = True
	end function
end class

class JDict
' A JAWS dictionary in memory, with methods for transferring it to/from file, merging files into it, etc.

	' In-memory dictionary entry hash.
	private oDict
	' Storage for one entry.
	private oEntry

	private sub Class_Initialize()
		set oDict = createObject("Scripting.Dictionary")
		set oEntry = new JDictEntry
	end sub

	public sub readFile(sFile, updateMatches)
		' 1 is ForReading
		dim oFile : set oFile = goFSO.openTextFile(sFile, 1)
		dim sLine
		do while not oFile.atEndOfStream
			sLine = oFile.readLine
			oEntry.splitEntry(sLine)
			' TODO:  JAWS reportedly can't handle more than 1,000 entries in one jdf.
			if updateMatches then
				oDict(oEntry.actual) = sLine
			else
				on error resume next
				oDict.add oEntry.actual, sLine
				on error goto 0
			end if
		loop
		oFile.close
	end sub

	public function count
		count = oDict.count
	end function
end class

' JDict test code.
'dim oJDict : set oJDict = new JDict
'oJDict.readFile "dfl.jdf", False
'oJDict.readFile "dfl0.jdf", False
'errOutput oJDict.count &" items"

