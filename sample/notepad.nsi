/*
Have you ever run Notepad and then wondered if the program that starts is in fact Notepad?  You Haven't!  Well this script solves the problem!  It also serves as another example of how to use the JFW.nsh NSIS header file.  It allows  you to confirm that the language versions were in fact compiled.

To use this sample, copy this file and the script folder, along with JFW.nsh, logging.nsh, and uninstlog.nsh and supporting files to a folder and run makensis notepad.nsi.

Requires NSIS v3.0 or later.
*/

Unicode true
RequestExecutionLevel highest
SetCompressor /solid lzma ;create the smallest file
;Name of script (displayed on screens, install folder, etc.) here
!Define ScriptName "Jaws Script for Notepad"
!define ScriptApp "notepad" ; the base name of the app the scripts are for
;!define JAWSMINVERSION "" ; min version of JAWS for which this script can be installed
;!define JAWSMAXVERSION "" ; max version of JAWS for which this script can be installed
!define JAWSALLOWALLUSERS ; comment this line if you don't want to allow installation for all users.
;Uncomment and change if the scripts are in another location.
;!define JAWSSrcDir "script\" ;Folder relative to current folder containing JAWS scripts, empty or ends with backslash.

;!Define JAWSScriptLangs "esn deu" ;Supported languages (not including English; these folders must exist in the script source lang directory ${JAWSSrcDir}\lang.

;Will be omitted if not defined.
;!define LegalCopyright "$(CopyrightMsg)"
;The file name of the license file in ${JAWSSrcDir}.  If not defined, no license page will be included.
;!define JAWSLicenseFile "copying.txt" ; should be defined in langstring file if LangString messages are used.

;Optional installer finish page features
;Assigns default if not defined.
;!define MUI_FINISHPAGE_SHOWREADME "$instdir\${ScriptApp}_readme.txt"
!define JAWSNoReadme ;uncomment if you don't have a README.
;!define MUI_FINISHPAGE_LINK "$(GoToAuthorsPage)"
;!define MUI_FINISHPAGE_LINK_LOCATION "http://"

;SetCompressor is outside the header because including uninstlog.nsh produces code.  setOverWriteDefault should not be in code used to add JAWS to another installer, although we probably want it in the default installer macro.
SetOverwrite on ;always overwrite files
;Allows us to change overwrite and set it back to the default.
!define SetOverwriteDefault "on"

;Uninstlog langstring files are included after inserting the JAWSScriptInstaller macro.
;!include "uninstlog.nsh"
;Remove the ; from the following line and matching close comment to cause the default JAWSInstallScriptItems macro to be used.
;/*
!macro JAWSInstallScriptItems
;$0 is version, e.g. "17.0", $1 is JAWS language folder, e.g. "enu" or "esn".
${JawsScriptFile} "${JAWSSrcDir}" "notepad.jss"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.qs"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jcf"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jgf"



;Language-specific files can be added this way:
${Switch} $1
;Each case entry must contain an item for each file that has a language-specific file.  If a file does not exist for a particular language, include the default language file.
;/*
${Case} "esn"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "notepad.jsd"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "notepad.jsm"
; ${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "notepad.jkm"
; ${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "notepad.jdf"
; ${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "notepad.qsm"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jbs" ;from default lang folder
${Break}
${Case} "deu"
${JawsScriptFile} "${JAWSSrcDir}lang\deu\" "notepad.jsd"
${JawsScriptFile} "${JAWSSrcDir}lang\deu\" "notepad.jsm"
; ${JawsScriptFile} "${JAWSSrcDir}lang\deu\" "notepad.jkm"
; ${JawsScriptFile} "${JAWSSrcDir}lang\deu\" "notepad.jdf"
; ${JawsScriptFile} "${JAWSSrcDir}lang\deu\" "notepad.qsm"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jbs" ;from default lang folder
${Break}
;*/
${Default}
;The default language files for every file that has a language-specific file must appear here.
;English
${JawsScriptFile} "${JAWSSrcDir}" "notepad.jsd"
${JawsScriptFile} "${JAWSSrcDir}" "notepad.jsm"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jkm"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jdf"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.qsm"
; ${JawsScriptFile} "${JAWSSrcDir}" "notepad.jbs"
${Break}
${EndSwitch}
!macroend ;JAWSInstallScriptItems

/*
;Optional: Items to be placed in the installation folder in a full install.
!macro JAWSInstallFullItems
!macroend ;JAWSInstallFullItems
*/

!macro JAWSInstallerSrc
;${File} "" "uninstlog.nsh"
${File} "" "notepad.nsi"
!InsertMacro JAWSJFWNSHInstallerSrc
!MacroEnd ;JAWSInstallerSrc


;-----
!include "jfw.nsh"

!insertmacro JAWSScriptInstaller
;Strange though it seems, the language file includes must follow the invocation of JAWSScriptInstaller.
  ;!include "uninstlog_enu.nsh"
  ;!include "uninstlog_deu.nsh"
  ;!include "uninstlog_esn.nsh"
