/*
This script makes history in that it provides support for an app BEFORE it is released!  It supports the amazing VWAPP from VaporWare Inc.  While we are anxiously waiting its release, it also serves as an example of how to use the JFW.nsh NSIS header file.

*/

; This constant contains the script version.  The spacing of the following line must be preserved exactly so that the installer can read the version from it.  There is exactly 1 space between const and the name, and 1 space on either side of the equals sign.
    Const CS_SCRIPT_VERSION = "1.0"

    Script  ScriptFileName ()
ScriptAndAppNames("VWAPP")
EndScript ; ScriptFileName

