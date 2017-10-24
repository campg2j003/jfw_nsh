/*
Identifies Notepad.
*/

; This constant contains the script version.  The spacing of the following line must be preserved exactly so that the installer can read the version from it.  There is exactly 1 space between const and the name, and 1 space on either side of the equals sign.
    Const CS_SCRIPT_VERSION = "1.0"

include "hjconst.jsh"
include "notepad.jsm"

    Script  ScriptFileName ()
ScriptAndAppNames("NOTEPAD")
EndScript ; ScriptFileName

Function AutoStartEvent ()
SayFormattedMessage (OT_NO_DISABLE, msg_App_Start)
EndFunction
	
