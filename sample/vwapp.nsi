/*
This installer makes history in that it provides support for an app BEFORE it is released!  It supports the amazing VWAPP from VaporWare Inc.  While we are anxiously waiting its release, it also serves as an example of how to use the JFW.nsh NSIS header file.

To use this sample, copy this file and the script folder, along with JFW.nsh, logging.nsh, and uninstlog.nsh and supporting files to a folder and run makensis vwapp.nsi.

Requires NSIS v3.0 or later.
*/

Unicode true
SetCompressor /solid lzma ;create the smallest file
;Name of script (displayed on screens, install folder, etc.) here
!Define ScriptName "Jaws Script for VWAPP"
!define ScriptApp "vwapp" ; the base name of the app the scripts are for
;!define JAWSMINVERSION "" ; min version of JAWS for which this script can be installed
;!define JAWSMAXVERSION "" ; max version of JAWS for which this script can be installed
!define JAWSALLOWALLUSERS ; comment this line if you don't want to allow installation for all users.
;Uncomment and change if the scripts are in another location.
;!define JAWSSrcDir "script\" ;Folder relative to current folder containing JAWS scripts, empty or ends with backslash.

;!Define JAWSScriptLangs "esn" ;Supported languages (not including English; these folders must exist in the script source lang directory ${JAWSSrcDir}\lang.

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
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jss"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.qs"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jcf"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jgf"



;Language-specific files can be added this way:
${Switch} $1
;Each case entry must contain an item for each file that has a language-specific file.  If a file does not exist for a particular language, include the default language file.
/*
${Case} "esn"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "vwapp.jsd"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "vwapp.jsm"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "vwapp.jkm"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "vwapp.jdf"
${JawsScriptFile} "${JAWSSrcDir}lang\esn\" "vwapp.qsm"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jbs" ;from default lang folder
${Break}
*/
${Default}
;The default language files for every file that has a language-specific file must appear here.
;English
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jsd"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jsm"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jkm"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jdf"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.qsm"
${JawsScriptFile} "${JAWSSrcDir}" "vwapp.jbs"
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
${File} "" "vwapp.nsi"
!InsertMacro JAWSJFWNSHInstallerSrc
!MacroEnd ;JAWSInstallerSrc


;-----
!include "jfw.nsh"

!insertmacro JAWSScriptInstaller
;Strange though it seems, the language file includes must follow the invocation of JAWSScriptInstaller.
  ;!include "uninstlog_enu.nsh"
  ;!include "uninstlog_esn.nsh"
