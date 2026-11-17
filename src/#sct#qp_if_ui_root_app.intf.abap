interface /SCT/QP_IF_UI_ROOT_APP
  public .


  interfaces /SCT/AU5_IF_APP .
  interfaces /SCT/QP_IF_UI_APP .
  interfaces IF_SERIALIZABLE_OBJECT .

  aliases DISPLAY
    for /SCT/QP_IF_UI_APP~DISPLAY .
  aliases PROCESS_FCODE
    for /SCT/QP_IF_UI_APP~PROCESS_FCODE .

  types:
    tty_events TYPE STANDARD TABLE OF /sct/au5_if_client=>ty_s_get WITH EMPTY KEY .     " AD, 2026.10.09, changed
  types:
    BEGIN OF ty_settings,
      graph_hierarchy TYPE abap_bool,
      max_sel_count   TYPE i,
      save_scroll     TYPE abap_bool,
      disp_app_state  TYPE abap_bool,
    END OF ty_settings .
  types:
    BEGIN OF ty_context,
      flp        TYPE abap_bool,
      embedded   TYPE abap_bool,
      embed_edit TYPE abap_bool,
      profile    TYPE /sct/qp_profile,
    END OF ty_context .
  types:
  " UP to 10 sub-app may be used to display data
    BEGIN OF ty_app,
           root      TYPE /sct/qp_if_ui_app=>ty_appdata_05,
           selection TYPE /sct/qp_if_ui_app=>ty_appdata_05,
           olr       TYPE /sct/qp_if_ui_app=>ty_appdata_05,
           olc       TYPE /sct/qp_if_ui_app=>ty_appdata_05,
           node      TYPE /sct/qp_if_ui_app=>ty_appdata_12,
           BEGIN OF sub,
             aidx TYPE n LENGTH 2,
             a_01 TYPE /sct/qp_if_ui_app=>ty_appdata_05, "Header
             a_02 TYPE /sct/qp_if_ui_app=>ty_appdata_05, "Log
             a_03 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_04 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_05 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_06 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_07 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_09 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
             a_10 TYPE /sct/qp_if_ui_app=>ty_appdata_12,
*             a_11 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_12 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_13 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_14 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_15 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_16 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_17 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_18 TYPE /sct/qp_if_ui_app=>ty_appdata,
*             a_19 TYPE /sct/qp_if_ui_app=>ty_appdata,
           END OF sub,
         END OF ty_app .
  types:
    BEGIN OF ty_ref,
           path      TYPE string,
           fieldname TYPE string,
           refname   TYPE string,
         END OF ty_ref .
  types:
    tty_ref TYPE SORTED TABLE OF ty_ref WITH UNIQUE KEY path fieldname .

  data CHECK_INITIALIZED type BOOLEAN . " AD, 2026.10.09, inserted
  data CHECK_STICKY type BOOLEAN .     " AD, 2026.10.09, inserted
  constants C_MAX_AIDX type I value 10 ##NO_TEXT.
  data MS_APPDATA type TY_APP .
  data MV_UNSAVED_STATE type STRING .
  data MT_NEXT_EVENTS type TTY_EVENTS .

  "! <p class="shorttext synchronized">get_footer instance</p>
  "!
  "! @parameter RO_VIEW | <p class="shorttext synchronized">Footer View übergeben</p>
  methods GET_FOOTER
    returning
      value(RO_VIEW) type ref to /SCT/AU5_CL_XML_VIEW .
  "! <p class="shorttext synchronized">Build the complete page again</p>
  "!
  methods SET_STRINGIFY .
  "! <p class="shorttext synchronized">close the popover</p>
  "!
  methods POPOVER_CLOSE .
  "! <p class="shorttext synchronized">open the popover</p>
  "!
  "! @parameter IV_CLOSE_EVENT | <p class="shorttext synchronized"></p>
  methods POPOVER_OPEN
    importing
      !IV_CLOSE_EVENT type STRING .
  "! <p class="shorttext synchronized">Snap selection screen</p>
  "!
  methods SNAP_SELECTION .
  "! <p class="shorttext synchronized">get current user settings</p>
  "!
  methods GET_SETTINGS
    returning
      value(RESULT) type TY_SETTINGS .
  "! <p class="shorttext synchronized">get callback data</p>
  "!
  methods CALLBACK                                                                   " AD, 2026.10.09, changed
    returning
      value(RESULT) type /SCT/AU5_IF_CLIENT=>TY_S_GET .
  methods SET_NEXT_EVENT                                                             " AD, 2026.10.09, changed
    importing
      !IS_EVENT type /SCT/AU5_IF_CLIENT=>TY_S_GET .
  "! <p class="shorttext synchronized">set global data</p>
  "!
  methods SET_DATA
    importing
      !IV_KEY type STRING
      !IV_DATA type STRING .
  "! <p class="shorttext synchronized">get global data</p>
  "!
  methods GET_DATA
    importing
      !IV_KEY type STRING
    returning
      value(RV_DATA) type STRING .
  methods GET_CONTEXT
    returning
      value(RESULT) type TY_CONTEXT .
  methods DELETE_SUB_REFS .
  methods GET_REF
    importing
      !IV_PATH type STRING
      !IV_FIELDNAME type STRING
    returning
      value(RESULT) type /SCT/QP_IF_UI_ROOT_APP=>TY_REF .
  methods SET_REF
    importing
      !IS_REF type /SCT/QP_IF_UI_ROOT_APP=>TY_REF .
endinterface.
