INTERFACE /sct/qp_if_ui_app
  PUBLIC.

  TYPES:
    BEGIN OF ty_s_status_display,
      text  TYPE string,
      state TYPE string,
      type  TYPE string,
      icon  TYPE string,
      act   TYPE /sct/qp_t_status_grid,
    END OF ty_s_status_display.
  TYPES:
* Liste aller Unterapplikationen einer App
    BEGIN OF ty_s_sub_app,
      index TYPE /sct/qp_sortnr,           " SortierNR und zähler, falls die App mehrfach vorkommt ( Mamba )
      id    TYPE string,                   " App identifier
      class TYPE classname,                " SCT Klassenname
      app   TYPE REF TO /sct/qp_if_ui_app, " SCT Klasseninstanz
      aidx  TYPE n LENGTH 2,               " Zähler für globalen Datenhaltung
    END OF ty_s_sub_app.
  TYPES ty_t_sub_app TYPE SORTED TABLE OF ty_s_sub_app WITH UNIQUE KEY index id.
  TYPES:
* Attribute beim initialisieren einer App
    BEGIN OF ty_s_control,
      id          TYPE string,
      parent_view TYPE REF TO /sct/au5_cl_xml_view,   " Screenbereich auf dem die App angezeigt wird.
      client      TYPE REF TO /sct/au5_if_client,     " Abap2ui5 client
      root_app    TYPE REF TO /sct/qp_if_ui_root_app, " SCT Main App
      parent_app  TYPE REF TO /sct/qp_if_ui_app,      " SCT übergeordnete App
      base        TYPE REF TO /sct/qp_s_base,
      aidx        TYPE n LENGTH 2,
    END OF ty_s_control.

  DATA mt_sub_app    TYPE ty_t_sub_app.
  DATA ms_control    TYPE ty_s_control.
  DATA mo_ui_handler TYPE REF TO /sct/qp_if_ui_handler.
  DATA mutx          TYPE REF TO /sct/qp_cl_ui_textelement.
  DATA mcu           TYPE REF TO /sct/qp_cl_ui_const.

  " The app can bind up to 12 data to the UI
  " this should be enough if complete tables are bound an not each single element
  TYPES: BEGIN OF ty_appdata_12,
           id   TYPE string,
           ridx TYPE n LENGTH 2,
           r_01 TYPE REF TO data,
           r_02 TYPE REF TO data,
           r_03 TYPE REF TO data,
           r_04 TYPE REF TO data,
           r_05 TYPE REF TO data,
           r_06 TYPE REF TO data,
           r_07 TYPE REF TO data,
           r_08 TYPE REF TO data,
           r_09 TYPE REF TO data,
           r_10 TYPE REF TO data,
           r_11 TYPE REF TO data,
           r_12 TYPE REF TO data,
         END OF ty_appdata_12.
  " The app can bind up to 5 data to the UI
  TYPES: BEGIN OF ty_appdata_05,
           id   TYPE string,
           ridx TYPE n LENGTH 2,
           r_01 TYPE REF TO data,
           r_02 TYPE REF TO data,
           r_03 TYPE REF TO data,
           r_04 TYPE REF TO data,
           r_05 TYPE REF TO data,
         END OF ty_appdata_05.

  "! <p class="shorttext synchronized"></p>
  "!
  "! @parameter IS_GET       | <p class="shorttext synchronized"></p>
  "! @parameter IO_CLIENT    | <p class="shorttext synchronized"></p>
  "! @parameter RV_PROCESSED | <p class="shorttext synchronized"></p>
  METHODS process_fcode IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get " AD, 2026.10.09, changed
                                  io_client           TYPE REF TO /sct/au5_if_client
                        RETURNING VALUE(rv_processed) TYPE abap_bool
                        RAISING   /sct/qp_cx_error.

  "! <p class="shorttext synchronized"></p>
  "!
  "! @parameter IO_VIEW   | <p class="shorttext synchronized"></p>
  "! @parameter IO_CLIENT | <p class="shorttext synchronized"></p>
  METHODS display IMPORTING io_view       TYPE REF TO /sct/au5_cl_xml_view OPTIONAL
                            io_client     TYPE REF TO /sct/au5_if_client
                  RETURNING VALUE(result) TYPE REF TO /sct/au5_cl_xml_view
                  RAISING   /sct/qp_cx_error.

  "! <p class="shorttext synchronized"></p>
  "!
  "! @parameter IS_CONTROL | <p class="shorttext synchronized"></p>
  METHODS init IMPORTING is_control TYPE ty_s_control.
  "! <p class="shorttext synchronized"></p>
  "!
  "! @parameter RESULT | <p class="shorttext synchronized"></p>
  METHODS must_redraw_nested RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized"></p>
  "!
  "! @parameter IV_PATH | <p class="shorttext synchronized"></p>
  "! @parameter RESULT  | <p class="shorttext synchronized"></p>
  METHODS get_location IMPORTING iv_path       TYPE string
                       RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Check non confirmed changes</p>
  METHODS check_changes RETURNING VALUE(result) TYPE abap_bool.
  METHODS is_stateful   RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">set/unset Stateful mode</p>
  METHODS set_stateful IMPORTING iv_stateful    TYPE abap_bool DEFAULT abap_true
                       RETURNING VALUE(success) TYPE abap_bool.

  "! <p class="shorttext synchronized">Actualize UI5 Data bindings</p>
  METHODS actualize_bindings RAISING /sct/qp_cx_error.
ENDINTERFACE.
