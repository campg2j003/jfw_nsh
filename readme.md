(This file last updated 2018-05-27 for JFW.nsh version 2.7 dated 2018-05-27.)
Jaws script installer
Written by Dang Manh Cuong <dangmanhcuong@gmail.com> and Gary Campbell <campg2003@gmail.com>
This installer requires the NSIS program from http://nsis.sourceforge.net version 3.0 or later.

# Features:
- Installs into all English versions of Jaws. This will be true as long as Freedom Scientific does not change the place to put scripts.
- Supports JAWS 17.0 shared scripts folder structure (as I currently understand it).
- Installs for the highest privelege available to the user.  If it can install for all users, the /currentuser command line switch can be supplied to force a current user install.
- For all user installs the user can choose whether to install the script as shared or for the current user.
- Gets the correct install path of Jaws from the registry.
- Checks for a Jaws installation before starting setup. If Jaws is not installed, displays a warning message and quits.
- contains macros for extracting, compiling, deleting, and modifying scripts, so the user can create a package containing multiple script files-- (I hope!) quickly and easily.

# Overview
This header file provides the following pages:
- Welcome
- License (optional)
- Install type
- Select JAWS versions/languages
- Destination folder (for Full and Custom installs)
- Confirm Installation Settings
- Finish

Three install types are supported:
- Just Script: installs the script but does not install uninstall information or make a folder in %ProgramFiles%.
- Full: installs scripts in the script folder for the selected versions/languages, creates a folder in %programfiles% (%localappdata% for current user install) wich contains an uninstaller and optional additional files such as README, etc.
- Custom: like Full but allows installation of the installer source.

For full or custom installations for all users the uninstaller and README files are installed in %programfiles%.  For current user installations they are installed in %localappdata%.

If the user's priveleges allow for installing for all users, the user can choose whether to install for all users or the current user.  If privileges allow for all user installation, current user installation can be forced by adding the /CurrentUser command line switch.

The Versions/Languages page displays the JAWS versions installed on the system and the languages they support.  This is presented in a checkable list view with entries like "17.0/enu".  Select the desired versions/languages by pressing SPACE, which checks the highlighted entry.  For all users installations this page also optionally allows you to choose whether to install the script for the current user or as a shared script.

The Finish page offers to open a README file if desired.


# Usage
To use JFW.nsh, you set some defines, define a couple of macros that install the files, and insert the JAWSScriptInstaller macro.  See the included [sample](sample/vwapp.nsi) for an example.

By default, the script files are expected to be contained in a folder called script in the folder containing this header.

Currently, if your installer contains any LangStrings, there must be definitions for all supported languages.

## Dependencies
This header uses header files currently shipped with NSIS.  It also requires the following:
- [uninstlog](https://github.com/campg2j003/uninstlog) header file v0.1.4.
- JAWSUtil.vbs from Doug Lee's [BX, the JAWS Toolbox](http://www.dlee.org/bx/).

## About the JAWS script compiler and multiple languages
The JAWS script compiler (scompile.exe) always compiles the script for the language of the currently-running JAWS.  This means that, even though it generates a JSB file in the folder containing a JSS for another language, the script actually compiled is that of the running language.  We work around this by using `JAWSUtil.vbs` (taken from BX, the JAWS Toolbox revision 1876, by Doug Lee).  If you do not want to use `JAWSUtil.vbs`, you can include the `/compile=` command line switch.  Its format is `/compile={j|s|n}`.  `j` (the default) uses `JAWSUtil.vbs`.  `s` uses `scompile.exe` directly as before and does not install `JAWSUtil.vbs`.  `n` suppresses compilation of scripts.  You can also define `JAWSDefaultCompileMethod` to one of these values before including JFW.nsh.  Using `n` allows you to install precompiled `.jsb` files.

## Defines
The following can be defined in your installer before including the header.  Most have defaults if not defined.
If you want to enable support for choosing to install in either the current user or all users, define JAWSALLOWALLUSERS before including this file.  If not defined, the default is to install into the current user.  If you execute SetShellVarContext you should also set the variable JAWSSHELLCONTEXT to match.  The macro JAWSSETSHELLCONTEXT has been provided to allow setting the shell var context based on the value of a parameter.

Note: Due to addition of support for all/current user installations it is recommended that you define JAWSALLOWALLUSERS.  This define may be removed in the future.  The installer has not been tested with this undefined.

### User settings:
```
!Define ScriptName "Jaws Script for <program name>" ;name displayed to user and used for folder in %programfiles%
!define ScriptApp "<program name>" ; the base name of the app the scripts are for
!define JAWSMINVERSION "" ; min version of JAWS for which this script can be installed, e.g. "9.0"
!define JAWSMAXVERSION "" ; max version of JAWS for which this script can be installed, e.g. "17.0"
;(If "" no restriction is imposed.)
!define JAWSALLOWALLUSERS ; comment this line if you don't want to allow installation for all users.  (Not recommended.)
;Uncomment to change the default compile method, can be j=JAWSUtil, s=scompile, or n=do not compile scripts.
;!define JAWSDefaultCompileMethod "j"
;Uncomment and change if the scripts are in another location.
;!define JAWSSrcDir "script\" ;Folder relative to current folder containing JAWS scripts, empty or ends with backslash.

;Will be omitted if not defined.
!define LegalCopyright "Copyright Message"
;The file name of the license file in ${JAWSSrcDir}.  If not defined, no license page will be included.
!define JAWSLicenseFile "copying.txt"

;Optional installer finish page features
;Assigns default if not defined.
;!define MUI_FINISHPAGE_SHOWREADME "$instdir\${ScriptApp}_readme.txt"
;!define JAWSNoReadme ;uncomment if you don't have a README.
!define MUI_FINISHPAGE_LINK "$(GoToAuthorsPage)"
!define MUI_FINISHPAGE_LINK_LOCATION "http://site_url"

!define SetOverwriteDefault "on"  ;Set this to the value of SetOverwrite.
```

(ToDo: Reorder these in the installer and use its value with the define.)

### User-defined macros
The files for your script are specified by defining several macros.

```
; Define The following before including the JFW.nsh header.
;We include the langstring header after the MUI_LANGUAGE macro.
```

Define the following macro to install the files for one version of JAWS.

```
!macro JAWSInstallScriptItems
;Contains the instructions to install the scripts in each version of JAWS.  If not defined, the installer will use a default version that tries to install every type of JAWS script file for an application I know of.
;Assumes uninstlog is open when called.
;Version in $0, lang in $1.
${JawsScriptFile} "${JAWSSrcDir}" "audacity.jdf"
${JawsScriptFile} "${JAWSSrcDir}" "audacity.jss"
${JawsScriptFile} "${JAWSSrcDir}" "audacity.qs"
...
!macroend ;JAWSInstallScriptItems

;The macro ${JawsScriptFile} SrcDir file
;is provided to install a script file into the proper folder based on JAWS version, current/shared, and script language.  It should be used for installing all script files.  For more control over how you install a file, you can use the ${JawsScriptSetPath} macro.

;Items to be placed in the installation folder in a full install.  Note that if this macro is not defined, makensis will generate a warning about undefined symbols which may be ignored.
!macro JAWSInstallFullItems
...
!macroend ;JAWSInstallFullItems
```

Define the following macro to allow the installer source to be installed.  It must include an invocation of the macro JAWSJFWNSHInstallerSrc.

```
!macro JAWSInstallerSrc
;Install your installer source files here.
!InsertMacro JAWSJFWNSHInstallerSrc
!MacroEnd ;JAWSInstallerSrc
```

If this macro is defined and the user selects the Installer Source component, the installer will create a folder in the installation folder called "Installer Source" and install the installer source files in it.  If this macro is not defined, a default macro is used that only installs the source for JFW.nsh.

The installer uses the Modern UI II package, so it includes mui2.nsh.  You should not include mui2.nsh before including JFW.nsh.  After the above defines you include this header, set some defines for your supported languages, and insert the JAWSScriptInstaller macro which produces the installer code:

```
Unicode true
!include "jfw.nsh"

;Uncomment the following defines for the languages you want your installer to support.  If none are uncommented, all will be defined and if you have LangStrings specific to your installer they must be defined for all languages.
;Defining one of these causes the appropriate JFW_lang and uninstlog_ language files to be included and the appropriate MUI_LANGUAGE macro to be invoked.
;!Define JAWSInstallerLang_ENU ;English
;!Define JAWSInstallerLang_ESN ;Spanish
;!Define JAWSInstallerLang_DEU ;German

!insertmacro JAWSScriptInstaller

;Include any language files for your installer.
;Strange though it seems, the language file includes must follow the invocation of JAWSScriptInstaller.
!include "installer_lang_enu.nsh"
!include "installer_lang_esn.nsh"
!include "installer_lang_deu.nsh"
```
If no JAWSInstallerLang_ symbols are defined, jfw.nsh will define them all to be compatible with older versions of this package.  If you do not define any of them, and your installer contains LangStrings, there must be a definition for each supported language.

After that you can add any sections specific to your installer if you need them.

# Available macros
(Some of these are used by the JAWSScriptInstaller macro.)
```
!Macro CompileSingle JAWSVer Source
;Assumes $OUTDIR points to folder where source file is and compiled file will be placed.
;JAWSVer - JAWS version/lang or version, i.e. "10.0/enu" or "10.0"
;Source - name of script to compile without .jss extension
;return: writes error message on failure, returns exit code of scompile (0 if successful) in $1.
;Recommend for scripts wich have only one source (*.JSS) file, or don't make any modification to any original files
;This macro saves time because it doesn't store and delete any temporary files.
;Note: this macro calls the function __CompileSingle_bx, which runs the JAWSUtil.vbs script to do the compile.  This script copies all required files to a temp folder and uses the -d scompile option to compile the script.  This makes it possible to compile versions of the script for multiple languages.  The function __CompileSingle, which runs scompile directly, is currently retained in case it may be useful.

;These are used to open the uninstlog facility which records the files for the uninstaller to uninstall.
!macro JAWSLOG_OPENINSTALL
!macro JAWSLOG_CLOSEINSTALL

!macro JAWSLOG_UNINSTALL

!macro JawsScriptSetPath ext
;Set $OUTDIR to proper location for script file type ext.
;Usage: ${JawsScriptSetPath} ext
;ext -- script file extension, e.g. jss.
;Assumes $0 = version, $1 = lang, shell var context is set to $SHELLSCRIPTCONTEXT.

!macro JawsScriptFile SrcDir file
;Install a JAWS script file into the proper location.  Takes into account whether installing into current user's scripts or shared scripts, JAWS version, and language.
;Usage: ${JawsScriptFile} SrcDir file
  ;SrcDir -- folder containing source file, used in FileDated macro.
;File -- name of file in SrcDir, used in FileDated macro and elsewhere.
  ;Assumes uninstlog macros available (either the real thing or dummies defined here) -- for SetOutPath and FileDated.
  ;Assumes $0 = version, $1 = lang, shell var context is set to $SHELLSCRIPTCONTEXT.
;This macro installs the file with the ${FileDated} uninstlog macro.  If this isn't what you need, use ${JawsScriptSetPath} to set $OUTDIR followed by the appropriate installation commands.

!macro JAWSMultiuserInstallModePage
;Includes a page to allow the user to choose whether to install for all users or the current user.
;This macro has been tested but is not currently used.  This choice is currently made on the Select Languages/Versions page.
```

The LangString `JawsInstallerLanguage` contains the JAWS abbreviation of the currently-selected language.  Thas can be used, for instance, to display the README for the selected installer language.

The following macros are not used by the Audacity JAWS script installer.  They were inherited from the code that was the basis for this package.  I have not used them and have not tested them.

```
!Macro AdvanceCompileSingle JAWSVer Path Source
;Assumes $OUTDIR points to folder where source file is and compiled file will be placed.
;JAWSVer - JAWS version/lang or version, i.e. "10.0/enu" or "10.0"
;Path - desired context, either "current" or "all".
;Source - name of script to compile without .jss extension
;return: writes error message on failure, returns exit code of scompile (0 if successful)-- actually returns 1 on failure.

!Macro AddHotkey JKM Key Script
;Add hotkeys to *.jkm file
;Usually used by advanced user
;Assumes JKM file is in $OUTDIR.
;JKM - name of JKM file without the .jkm extension.
;key - string containing the key sequence, like "CTRL+JAWSKey+a".
;Script - name of script to bind to key.
;Entries will be added to the "Common Keys" section.

!macro ModifyScript JAWSVer File Code
;Use to add some code to an existing script file
;Like adding: use "skypewatch.jsb"" to default.jss

!macro AdvanceModifyScript JAWSVer Path File Code
;Use to add some code to an existing script file
;Like adding: use "skypewatch.jsb"" to default.jss


```

# Development environment
This package is hosted on GitHub.  The repo is at https://github.com/campg2j003/jfw_nsh.  The required uninstlog package is at https://github.com/campg2j003/uninstlog.  If you would like to contribute changes to the script, fork a copy of the repository, create a branch for your changes, and make a pull request.  The installer uses the [uninstlog](https://github.com/campg2j003/uninstlog) package.  If you want to make changes in it it is probably best to fork it as well and make your changes there.  A consequence of using submodules is that if you make a clone of the jfw_nsh repo on your machine you should add the --recursive switch to the git clone command.  You also need to run `git submodule update --remote` after checking out a new branch or pulling new work from GitHub.  Also note that if you download the repo from GitHub as a zip file, the submodule folder will be empty.  You will have to download the other repo and put the files in the appropriate subfolder.  (You also must make sure that you download the proper branch.  The file .gitmodules in the top-level folder may be of help in determining the right branch.)

To build the package you will also need [NSIS](http://nsis.sf.net) version 3.0 or later.  

There is a [build.cmd](build.cmd) script in the repo to build the sample installers.  It creates a build folder at the top level of the repo, copies the required files to it, and runs the installer.  You may have to customize it based on your environment.  You can run `build` with no arguments for help on using it.

The `b` option produces the following structure in the root of the repo:
```
build\
  script\
    script files for samples
  installer files
```

Each JAWS script file in the sample\script folder is also copied to the build\script folder.  Note that since specific files are copied to the script folder, other files that may be in the repo will not be copied.  The required installer files are copied from the top level of the repo and uninstlog to `build`.  

The installer messages are localizable.  The message text is separated from the installer code so that message sets can be prepared for each language.  English, German, and Spanish are currently supported.  Messages are in .nsh header files with names like *_enu.nsh or *_lang_enu.nsh.  Although the code provides for using ANSI or Unicode, the language files are encoded as UTF-8.  Testing is only done with `Unicode true`.

Messages (or any text visible to the user) are contained in `LangString` instructions.  If you add a new string, be sure to add it to each language file.  If you don't have a translation, just copy the English string.

If you add a file to this package, you should also add an entry for it in macro `JAWSJFWNSHInstallerSrc`.

To add a language to the installer:
- Copy JFW_lang_enu.nsh to JFW_lang_xxx.nsh where xxx is the JAWS language designation for your language.
- Copy the initial comment information from JFW_lang_esn.nsh to the top of your new language file and edit it appropriately.  This will help keep track of what file on which your translation is based.
- Make a language file for `uninstlog`.
- Near where the language files are included, there is a set of nested !IfNDefs for each supported language.  
Add another level of nesting to this block and a define for the new language.
- Add a new block to include your language by copying an existing one and editing it appropriately.  This block includes an invocation of MUI_LANGUAGE and includes for `JFW.nsh` and `uninstlog.nsh`.
- Add the new files to macro `JAWSJFWNSHInstallerSrc` so they will be included in the installer source installed when the user requests installer source.

# Copyright
    Copyright (C) 2012-2017  Gary Campbell and Dang Manh Cuong.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
    
    See the file copying.txt for details.

The included file `JAWSUtil.vbs` is Copyright (c) 2009-2017 Doug Lee, which see for details.
