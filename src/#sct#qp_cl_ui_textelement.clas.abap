CLASS /sct/qp_cl_ui_textelement DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_textelement
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">UI5 Applikation für QPPD</p>
    CONSTANTS u001 TYPE textpoolky VALUE '001' ##NO_TEXT.
    "! <p class="shorttext synchronized">Vorschriftennummer</p>
    CONSTANTS u002 TYPE textpoolky VALUE '002' ##NO_TEXT.
    "! <p class="shorttext synchronized">Vorschriftenname</p>
    CONSTANTS u003 TYPE textpoolky VALUE '003' ##NO_TEXT.
    "! <p class="shorttext synchronized">Vorschriftenbezeichnung</p>
    CONSTANTS u004 TYPE textpoolky VALUE '004' ##NO_TEXT.
    "! <p class="shorttext synchronized">Verwaltungsdaten</p>
    CONSTANTS u005 TYPE textpoolky VALUE '005' ##NO_TEXT.
    "! <p class="shorttext synchronized">Zust&amp;auml;ndigkeit</p>
    CONSTANTS u006 TYPE textpoolky VALUE '006' ##NO_TEXT.
    "! <p class="shorttext synchronized">Technische Daten</p>
    CONSTANTS u007 TYPE textpoolky VALUE '007' ##NO_TEXT.
    "! <p class="shorttext synchronized">Filter anpassen</p>
    CONSTANTS u008 TYPE textpoolky VALUE '008' ##NO_TEXT.
    "! <p class="shorttext synchronized">Selektionsfelder</p>
    CONSTANTS u009 TYPE textpoolky VALUE '009' ##NO_TEXT.
    "! <p class="shorttext synchronized">Start</p>
    CONSTANTS u010 TYPE textpoolky VALUE '010' ##NO_TEXT.
    "! <p class="shorttext synchronized">Max. Selektionsanzahl</p>
    CONSTANTS u011 TYPE textpoolky VALUE '011' ##NO_TEXT.
    "! <p class="shorttext synchronized">Neues Element</p>
    CONSTANTS u012 TYPE textpoolky VALUE '012' ##NO_TEXT.
    "! <p class="shorttext synchronized">Element l&amp;ouml;schen</p>
    CONSTANTS u013 TYPE textpoolky VALUE '013' ##NO_TEXT.
    "! <p class="shorttext synchronized">Element kopieren</p>
    CONSTANTS u014 TYPE textpoolky VALUE '014' ##NO_TEXT.
    "! <p class="shorttext synchronized">Unbewertete Merkmale filtern</p>
    CONSTANTS u015 TYPE textpoolky VALUE '015' ##NO_TEXT.
    "! <p class="shorttext synchronized">Alle Merkmale anzeigen</p>
    CONSTANTS u016 TYPE textpoolky VALUE '016' ##NO_TEXT.
    "! <p class="shorttext synchronized">Generieren</p>
    CONSTANTS u017 TYPE textpoolky VALUE '017' ##NO_TEXT.
    "! <p class="shorttext synchronized">Generieren mit &amp;Uuml;berschreiben</p>
    CONSTANTS u018 TYPE textpoolky VALUE '018' ##NO_TEXT.
    "! <p class="shorttext synchronized">&amp;Auml;ndern</p>
    CONSTANTS u019 TYPE textpoolky VALUE '019' ##NO_TEXT.
    "! <p class="shorttext synchronized">Bemerkung</p>
    CONSTANTS u020 TYPE textpoolky VALUE '020' ##NO_TEXT.
    "! <p class="shorttext synchronized">L&amp;ouml;schen</p>
    CONSTANTS u021 TYPE textpoolky VALUE '021' ##NO_TEXT.
    "! <p class="shorttext synchronized">Builder</p>
    CONSTANTS u022 TYPE textpoolky VALUE '022' ##NO_TEXT.
    "! <p class="shorttext synchronized">Generierung aktivieren</p>
    CONSTANTS u023 TYPE textpoolky VALUE '023' ##NO_TEXT.
    "! <p class="shorttext synchronized">Generierung deaktivieren</p>
    CONSTANTS u024 TYPE textpoolky VALUE '024' ##NO_TEXT.
    "! <p class="shorttext synchronized">Objekt l&amp;ouml;schen</p>
    CONSTANTS u025 TYPE textpoolky VALUE '025' ##NO_TEXT.
    "! <p class="shorttext synchronized">Aktivieren</p>
    CONSTANTS u026 TYPE textpoolky VALUE '026' ##NO_TEXT.
    "! <p class="shorttext synchronized">Sichern</p>
    CONSTANTS u027 TYPE textpoolky VALUE '027' ##NO_TEXT.
    "! <p class="shorttext synchronized">Anzeigen</p>
    CONSTANTS u028 TYPE textpoolky VALUE '028' ##NO_TEXT.
    "! <p class="shorttext synchronized">Funktionen</p>
    CONSTANTS u029 TYPE textpoolky VALUE '029' ##NO_TEXT.
    "! <p class="shorttext synchronized">Anlegen</p>
    CONSTANTS u030 TYPE textpoolky VALUE '030' ##NO_TEXT.
    "! <p class="shorttext synchronized">Aktualisieren</p>
    CONSTANTS u031 TYPE textpoolky VALUE '031' ##NO_TEXT.
    "! <p class="shorttext synchronized">Auswahl l&amp;ouml;schen</p>
    CONSTANTS u032 TYPE textpoolky VALUE '032' ##NO_TEXT.
    "! <p class="shorttext synchronized">Ok</p>
    CONSTANTS u033 TYPE textpoolky VALUE '033' ##NO_TEXT.
    "! <p class="shorttext synchronized">Abbrechen</p>
    CONSTANTS u034 TYPE textpoolky VALUE '034' ##NO_TEXT.
    "! <p class="shorttext synchronized">Objekt anlegen</p>
    CONSTANTS u035 TYPE textpoolky VALUE '035' ##NO_TEXT.
    "! <p class="shorttext synchronized">Objekt bearbeiten</p>
    CONSTANTS u036 TYPE textpoolky VALUE '036' ##NO_TEXT.
    "! <p class="shorttext synchronized">Position anlegen</p>
    CONSTANTS u037 TYPE textpoolky VALUE '037' ##NO_TEXT.
    "! <p class="shorttext synchronized">Position bearbeiten</p>
    CONSTANTS u038 TYPE textpoolky VALUE '038' ##NO_TEXT.
    "! <p class="shorttext synchronized">Position l&amp;ouml;schen</p>
    CONSTANTS u039 TYPE textpoolky VALUE '039' ##NO_TEXT.
    "! <p class="shorttext synchronized">Vorschriftenart</p>
    CONSTANTS u040 TYPE textpoolky VALUE '040' ##NO_TEXT.
    "! <p class="shorttext synchronized">Beschreibung</p>
    CONSTANTS u041 TYPE textpoolky VALUE '041' ##NO_TEXT.
    "! <p class="shorttext synchronized">Status</p>
    CONSTANTS u042 TYPE textpoolky VALUE '042' ##NO_TEXT.
    "! <p class="shorttext synchronized">Suchhilfe</p>
    CONSTANTS u043 TYPE textpoolky VALUE '043' ##NO_TEXT.
    "! <p class="shorttext synchronized">Element</p>
    CONSTANTS u044 TYPE textpoolky VALUE '044' ##NO_TEXT.
    "! <p class="shorttext synchronized">Wert</p>
    CONSTANTS u045 TYPE textpoolky VALUE '045' ##NO_TEXT.
    "! <p class="shorttext synchronized">Beschreibung der Vorschriftenart im Wizard</p>
    CONSTANTS u046 TYPE textpoolky VALUE '046' ##NO_TEXT.
    "! <p class="shorttext synchronized">Beschreibung des Vorschriftennamens im Wizard</p>
    CONSTANTS u047 TYPE textpoolky VALUE '047' ##NO_TEXT.
    "! <p class="shorttext synchronized">Beschreibung der Vorschriftenbezeichnung im Wizard</p>
    CONSTANTS u048 TYPE textpoolky VALUE '048' ##NO_TEXT.
    "! <p class="shorttext synchronized">Optional</p>
    CONSTANTS u049 TYPE textpoolky VALUE '049' ##NO_TEXT.
    "! <p class="shorttext synchronized">Aktionen</p>
    CONSTANTS u050 TYPE textpoolky VALUE '050' ##NO_TEXT.
    "! <p class="shorttext synchronized">Art</p>
    CONSTANTS u051 TYPE textpoolky VALUE '051' ##NO_TEXT.
    "! <p class="shorttext synchronized">Name</p>
    CONSTANTS u052 TYPE textpoolky VALUE '052' ##NO_TEXT.
    "! <p class="shorttext synchronized">Bezeichnung</p>
    CONSTANTS u053 TYPE textpoolky VALUE '053' ##NO_TEXT.
    "! <p class="shorttext synchronized">Nummer</p>
    CONSTANTS u054 TYPE textpoolky VALUE '054' ##NO_TEXT.
    "! <p class="shorttext synchronized">Kopfdaten</p>
    CONSTANTS u055 TYPE textpoolky VALUE '055' ##NO_TEXT.
    "! <p class="shorttext synchronized">Kopfdaten bearbeiten</p>
    CONSTANTS u056 TYPE textpoolky VALUE '056' ##NO_TEXT.
    "! <p class="shorttext synchronized">Zeichenl&amp;auml;nge</p>
    CONSTANTS u057 TYPE textpoolky VALUE '057' ##NO_TEXT.
    "! <p class="shorttext synchronized">Max.</p>
    CONSTANTS u058 TYPE textpoolky VALUE '058' ##NO_TEXT.
    "! <p class="shorttext synchronized">Min.</p>
    CONSTANTS u059 TYPE textpoolky VALUE '059' ##NO_TEXT.
    "! <p class="shorttext synchronized">More than 1 error</p>
    CONSTANTS u060 TYPE textpoolky VALUE '060' ##NO_TEXT.
    CONSTANTS u061 TYPE textpoolky VALUE '061' ##NO_TEXT.
    CONSTANTS u062 TYPE textpoolky VALUE '062' ##NO_TEXT.
    CONSTANTS u063 TYPE textpoolky VALUE '063' ##NO_TEXT.
    CONSTANTS u064 TYPE textpoolky VALUE '064' ##NO_TEXT.
    CONSTANTS u065 TYPE textpoolky VALUE '065' ##NO_TEXT.
    CONSTANTS u066 TYPE textpoolky VALUE '066' ##NO_TEXT.
    CONSTANTS u067 TYPE textpoolky VALUE '067' ##NO_TEXT.
    CONSTANTS u068 TYPE textpoolky VALUE '068' ##NO_TEXT.
    CONSTANTS u069 TYPE textpoolky VALUE '069' ##NO_TEXT.
    CONSTANTS u070 TYPE textpoolky VALUE '070' ##NO_TEXT.
    CONSTANTS u071 TYPE textpoolky VALUE '071' ##NO_TEXT.
    CONSTANTS u072 TYPE textpoolky VALUE '072' ##NO_TEXT.
    CONSTANTS u073 TYPE textpoolky VALUE '073' ##NO_TEXT.
    CONSTANTS u074 TYPE textpoolky VALUE '074' ##NO_TEXT.
    "! <p class="shorttext synchronized">Position anlegen</p>
    CONSTANTS u075 TYPE textpoolky VALUE '075' ##NO_TEXT.
    "! <p class="shorttext synchronized">Fehlender Wert</p>
    CONSTANTS u076 TYPE textpoolky VALUE '076' ##NO_TEXT.
    "! <p class="shorttext synchronized">Falscher Wert</p>
    CONSTANTS u077 TYPE textpoolky VALUE '077' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positionstyp</p>
    CONSTANTS u078 TYPE textpoolky VALUE '078' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positionsname</p>
    CONSTANTS u079 TYPE textpoolky VALUE '079' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positiontstyp anlegen Beschreibung</p>
    CONSTANTS u080 TYPE textpoolky VALUE '080' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positiontsname anlegen Beschreibung</p>
    CONSTANTS u081 TYPE textpoolky VALUE '081' ##NO_TEXT.
    "! <p class="shorttext synchronized">Typ</p>
    CONSTANTS u082 TYPE textpoolky VALUE '082' ##NO_TEXT.
    CONSTANTS u083 TYPE textpoolky VALUE '083' ##NO_TEXT.
    CONSTANTS u084 TYPE textpoolky VALUE '084' ##NO_TEXT.
    CONSTANTS u085 TYPE textpoolky VALUE '085' ##NO_TEXT.
    CONSTANTS u086 TYPE textpoolky VALUE '086' ##NO_TEXT.
    CONSTANTS u087 TYPE textpoolky VALUE '087' ##NO_TEXT.
    CONSTANTS u088 TYPE textpoolky VALUE '088' ##NO_TEXT.
    CONSTANTS u089 TYPE textpoolky VALUE '089' ##NO_TEXT.
    CONSTANTS u090 TYPE textpoolky VALUE '090' ##NO_TEXT.
    CONSTANTS u091 TYPE textpoolky VALUE '091' ##NO_TEXT.
    CONSTANTS u092 TYPE textpoolky VALUE '092' ##NO_TEXT.
    CONSTANTS u093 TYPE textpoolky VALUE '093' ##NO_TEXT.
    CONSTANTS u094 TYPE textpoolky VALUE '094' ##NO_TEXT.
    CONSTANTS u095 TYPE textpoolky VALUE '095' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positionsdaten</p>
    CONSTANTS u096 TYPE textpoolky VALUE '096' ##NO_TEXT.
    "! <p class="shorttext synchronized">Positionsdaten Langtext</p>
    CONSTANTS u097 TYPE textpoolky VALUE '097' ##NO_TEXT.
    CONSTANTS u098 TYPE textpoolky VALUE '098' ##NO_TEXT.
    CONSTANTS u099 TYPE textpoolky VALUE '099' ##NO_TEXT.
    CONSTANTS u100 TYPE textpoolky VALUE '100' ##NO_TEXT.
    CONSTANTS u101 TYPE textpoolky VALUE '101' ##NO_TEXT.
    CONSTANTS u102 TYPE textpoolky VALUE '102' ##NO_TEXT.
    CONSTANTS u103 TYPE textpoolky VALUE '103' ##NO_TEXT.
    CONSTANTS u104 TYPE textpoolky VALUE '104' ##NO_TEXT.
    CONSTANTS u105 TYPE textpoolky VALUE '105' ##NO_TEXT.
    CONSTANTS u106 TYPE textpoolky VALUE '106' ##NO_TEXT.
    CONSTANTS u107 TYPE textpoolky VALUE '107' ##NO_TEXT.
    CONSTANTS u108 TYPE textpoolky VALUE '108' ##NO_TEXT.
    CONSTANTS u109 TYPE textpoolky VALUE '109' ##NO_TEXT.

    METHODS get_field_length IMPORTING iv_field         TYPE any
                             RETURNING VALUE(rv_length) TYPE i.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS /SCT/QP_CL_UI_TEXTELEMENT IMPLEMENTATION.


  METHOD get_field_length.
    DATA(lo_descr) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( iv_field ) ).
    IF lo_descr IS BOUND.
      rv_length = lo_descr->output_length.
    ENDIF.

*    TRY.
*        DESCRIBE FIELD i_field LENGTH e_length IN CHARACTER MODE.
*      CATCH cx_root.
*    ENDTRY.
  ENDMETHOD.
ENDCLASS.
