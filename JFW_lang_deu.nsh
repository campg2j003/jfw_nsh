/*
German User-visible messages for JFW.nsh (updated 2016-09-21)
Translation of file JFW_lang_enu.nsh last updated 2016-09-21.
This file last updated 2017-09-09.
Translated by Michael Vogt.
Does not include debug messages or messages printed to log file/log window.
*/

;Do not translate text inside ${...}.  These will be replaced with their values.  Also true for things like $variablename, $0, or $R1.  (To cause a $ to appear in text, it is doubled, like $$R0 will appear as $0.)

!ifndef JFW_DEU_INCLUDED
  !define JFW_DEU_INCLUDED

  ;$R1=script file name without extension, $1=exit code (number), $R2=text output by program.
LangString CouldNotCompile ${LANG_GERMAN} "Kann $R1.jss nicht kompilieren, SCompile zur�ckgegeben $1$\r$\n$$OutDir=$OutDir, Ausgabe:$\r$\n$R2."

LangString CouldNotFindCompiler ${LANG_GERMAN} "Kann Jaws Script Compiler $R0 nicht finden.  Bitte kompilieren Sie das Skript mit dem JAWS Skript Manager, um Jaws Skript f�r Audacity verwenden zu k�nnen."

LangString NoVersionSelected ${LANG_GERMAN} "Keine Versionen ausgew�hlt."

LangString InstallFolderExists ${LANG_GERMAN} "Das angegebene Verzeichnis existiert bereits. Wahrscheinlich ist ${ScriptName} bereits auf diesem Computer installiert.  W�hlen Sie Ja, um das Setup �ber die vorhandene Installation fortzusetzen."

LangString InstDirNotFolder ${LANG_GERMAN} "$INSTDIR ist vorhanden und ist kein Ordner!"

LangString InstConfirmHdr ${LANG_GERMAN} "Konfiguration der Installation best�tigen"

LangString InstConfirmText ${LANG_GERMAN} "Im Folgenden eine Zusammenfassung der Schritte, die w�hrend der Installation durchgef�hrt werden.  W�hlen Sie zur�ck, um Einstellungen zu �ndern. W�hlen Sie Installieren (ALT + I), um fortzufahren."
LangString InstConfirmCurrentUser ${LANG_GERMAN} "den aktuellen Benutzer"
LangString InstConfirmAllUsers ${LANG_GERMAN} "alle Benutzer"

;$2=$(InstConfirmCurrentUser or $(InstConfirmAllUsers followed by a space, $1=comma-separated list of versions.
LangString InstConfirmVersions ${LANG_GERMAN} "Die Skripts werden f�r $2 in den folgenden Jaws Versionen installiert:$\r$\n$1.$\r$\n"

;$0=previous text, should not be followed by space.  $1=list of versions.
LangString InstConfirmHaveFiles ${LANG_GERMAN} "$0Die folgenden Jaws Versionen  enthalten bereits Dateien f�r diese Anwendung (Dateien, die mit ${ScriptApp}.* �bereinstimmen): $1$\r$\nDiese Dateien k�nnen w�hrend der Installation �berschrieben werden.$\r$\n"

LangString InstConfirmUninstAddRemovePrograms ${LANG_GERMAN} "$0Installationsverzeichnis: $INSTDIR.$\r$\nDiese Installation sollte �ber Programme hinzuf�gen / entfernen deinstalliert werden.$\r$\n"

;$0=previous text.
LangString InstConfirmExistingInstall ${LANG_GERMAN} "$0Auf diesem Computer ist ${ScriptName} bereits installiert.$\r$\n"

LangString InstConfirmInstallerSrc ${LANG_GERMAN} "$0Die Quelldaten des Installers werden in $INSTDIR\${JAWSINSTALLERSRC} installiert."
LangString InstConfirmNotInstalled ${LANG_GERMAN} "$0Diese Installation kann nicht �ber Programme hinzuf�gen / entfernen deinstalliert werden."
LangString OverwriteScriptsQuery ${LANG_GERMAN} "Skriptdateien f�r ${ScriptName} sind bereits in $2 vorhanden.  M�chten Sie diese �berschreiben?"

LangString JawsNotInstalled ${LANG_GERMAN} "Das Setup kann nicht ausgef�hrt werden, da Jaws nicht auf diesem Computer installiert ist."

LangString CantFindJawsProgDir ${LANG_GERMAN} "Kann das Verzeichnis $0 in $programfiles oder $programfiles64 nicht finden.  Die Installation kann durchgef�hrt werden, Sie m�ssen jedoch die Scripts selbst kompilieren."

LangString BrandingText ${LANG_GERMAN} "${ScriptName}"
LangString SuccessfullyRemoved ${LANG_GERMAN} "${ScriptName}  wurde erfolgreich von Ihrem Computer entfernt."
LangString InstallFolderNotRemoved ${LANG_GERMAN} "Warnung: das Installationsverzeichnis $INSTDIR konnte nicht entfernt werden. Wahrscheinlich sind darin auch nicht gel�schte Dateien enthalten."
LangString SureYouWantToUninstall ${LANG_GERMAN} "Sind Sie sicher, dass Sie $(^Name) mit allen Komponenten deinstallieren wollen?"
LangString UninstallUnsuccessful ${LANG_GERMAN} "Die Deinstallation konnte nicht erfolgreich durchgef�hrt werden (Code $1).  W�hlen Sie ok, um die Installation trotzdem fortzusetzen oder Abbrechen um die Installation zu beenden."
LangString AlreadyInstalled ${LANG_GERMAN} "${ScriptName} ist bereits auf diesem Computer installiert.  Bitte deinstallieren Sie die Anwendung, bevor Sie fortfahren.  M�chten Sie die bereits vorhandene Installation deinstallieren?"

;e.g. V2.0 ...
LangString VersionMsg ${LANG_GERMAN} "V${VERSION}"

;Messages in the Install Type combo box.
LangString InstTypeFull ${LANG_GERMAN} "Vollst�ndig"
LangString InstTypeJustScripts ${LANG_GERMAN} "Nur Skript"

;Text at the top of the Components page.
LangString InstTypeFullMsg ${LANG_GERMAN} "Der Installationstyp Vollst�ndig erm�glicht, die Skripts bei Bedarf �ber Programme hinzuf�gen / entfernen zu deinstallieren.  $\n\
Der Installationstyp nur Skript installiert die Skripts und die Readme-Datei. Die Installation kann nicht �ber Programme hinzuf�gen / entfernen deinstalliert werden."

;Name of the Installer Sourse section (the Install Source custom component)
LangString SecInstallerSource ${LANG_GERMAN} "Quelldaten des Installers"

LangString WelcomePageTitle ${LANG_GERMAN} "Setup f�r ${ScriptName}"

!if VERSION != ""
!define _VERSIONMSG " $(VersionMsg)"
!else
!define _VERSIONMSG ""
!endif

LangString WelcomeTextCopyright ${LANG_GERMAN} "Willkommen bei der Installation des ${ScriptName}${_VERSIONMSG}.$\n\
Dieser Assistent f�hrt Sie durch die Installation des ${ScriptName}.$\n\
${LegalCopyright}$\n"
LangString WelcomeTextNoCopyright ${LANG_GERMAN} "Willkommen bei der Installation des ${ScriptName}${_VERSIONMSG}.$\n\
Dieser Assistent f�hrt Sie durch die Installation des ${ScriptName}.$\n"
!undef _VERSIONMSG

;list view
;Text at the top of the Select JAWS Versions/Languages dialog.
LangString SelectJawsVersions ${LANG_GERMAN} "W�hlen Sie die Jaws Versionen und Sprachen, in denen Sie die Skripts installieren m�chten:"

;JAWS versions/languages list view caption
LangString LVLangVersionCaption ${LANG_GERMAN} "Jaws Versionen / Sprachen"

;Install for All/Current user group box ($JAWSGB)
LangString GBInstallForCaption ${LANG_GERMAN} "Installieren f�r"
LangString RBCurrentUser ${LANG_GERMAN} "&Aktueller Benutzer" ;$JAWSRB1
LangString RBAllUsers ${LANG_GERMAN} "A&lle Benutzer" ;$JAWSRB2

LangString DirPageText ${LANG_GERMAN} "W�hlen Sie das Verzeichnis, in dem ${ScriptName} inklusive Deinstallationsprogramm, Hilfe- und andere Dateien installiert werden sollen. $\n\
Das Setup installiert ${ScriptName} im folgenden Verzeichnis. W�hlen Sie Durchsuchen, um ein anderes Verzeichnis als Ziel der Installation auszuw�hlen."

LangString ViewReadmeFile ${LANG_GERMAN} "Lies mich Datei anzeigen"

!EndIf ;JFW_DEU_INCLUDED
