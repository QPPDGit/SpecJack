CLASS /sct/qp_cl_ui_mamba DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES:
      BEGIN OF ty_avatar,
        id           TYPE string,
        initials     TYPE string,
        fallbackicon TYPE string,
        src          TYPE string,
        name         TYPE string,
        tooltip      TYPE string,
        blocked      TYPE abap_bool,
      END OF ty_avatar.
    TYPES tty_avatar TYPE STANDARD TABLE OF ty_avatar WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_avatars,
        element  TYPE string,
        label    TYPE string,
        t_avatar TYPE tty_avatar,
        t_select TYPE tty_avatar,
      END OF ty_avatars.
    " AU5 kann nur mit standard Tabellen umgehen fürs Binding
    TYPES tty_avatars TYPE STANDARD TABLE OF ty_avatars. " WITH UNIQUE SORTED KEY element COMPONENTS element.
    TYPES:
      BEGIN OF ty_sel,
        mamba_sel TYPE abap_bool,
        rowid     TYPE /sct/qp_rowid,
      END OF ty_sel.
    TYPES tty_sel TYPE STANDARD TABLE OF ty_sel WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_sug,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF ty_sug.
    TYPES tty_sug TYPE SORTED TABLE OF ty_sug WITH UNIQUE KEY value.
    TYPES:
      BEGIN OF elem_sug,
        element TYPE string,
        sug_tab TYPE tty_sug,
      END OF elem_sug.
    TYPES tty_elem_sug TYPE STANDARD TABLE OF elem_sug WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_fcat,
             col_pos   TYPE int4,
             fieldname TYPE abp_field_name,
             scrtext_l TYPE string,
             scrtext_m TYPE string,
             scrtext_s TYPE string,
           END OF ty_fcat.
    TYPES tty_fcat TYPE STANDARD TABLE OF ty_fcat WITH DEFAULT KEY.

    DATA:
      BEGIN OF ms_more,
        display   TYPE abap_boolean,          "<more> Anzeigen
        skip      TYPE i            VALUE 0,  " Anfang der Liste
        top       TYPE i            VALUE 50, " Erste 50 Datensätze
        step      TYPE i            VALUE 50, " Inkrement
        count     TYPE i,
        text_more TYPE string,
        text_all  TYPE string,
      END OF ms_more.

    DATA mt_suggestion_sel TYPE STANDARD TABLE OF ty_sug WITH EMPTY KEY.
    DATA ms_fcat           TYPE /sct/qp_s_fcat.
*    DATA mt_button         TYPE ttb_button.
    DATA mv_edit           TYPE abap_boolean.
    DATA mt_sug            TYPE tty_elem_sug.

*    CLASS-DATA mc_key_rowid   TYPE char30 VALUE 'KEY_ROWID' ##NO_TEXT.
*    CLASS-DATA mc_key_visible TYPE char30 VALUE 'KEY_VISIBLE' ##NO_TEXT.

    DATA mv_empty_field    TYPE /sct/qp_ktxt VALUE '' ##NO_TEXT.

    CONSTANTS mc_empty_rangetype TYPE /sct/qp_rangetype VALUE '  ' ##NO_TEXT.

    DATA mv_show_strip TYPE abap_bool.
    DATA ms_message    TYPE /sct/qp_s_message.
    DATA mt_tokens     TYPE /sct/qp_cl_ui=>tty_token.
    DATA mt_avatars    TYPE tty_avatars.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_objtyp~check_changes   REDEFINITION.

  PROTECTED SECTION.
    DATA mo_mamba        TYPE REF TO /sct/qp_if_mamba.
    DATA mo_fcat         TYPE REF TO /sct/qp_if_fcat.
    DATA mr_data_saved   TYPE REF TO data.
    DATA mv_filter_empty TYPE abap_bool.
    DATA mt_sel          TYPE tty_sel.

*    DATA mr_tokens TYPE REF TO /sct/qp_cl_ui=>tty_token .
    METHODS get_jump_url IMPORTING it_arg        TYPE /sct/au5_if_types=>ty_s_get-t_event_arg
                         RETURNING VALUE(result) TYPE /sct/au5_if_client=>ty_s_get.                              " AD, 2026.10.09, changed

    "! <p class="shorttext synchronized">Create output table (outtab)</p>
    "! Aufbau der zu anzeigenden Daten
    "! @parameter IV_SKIP | <p class="shorttext synchronized"></p>
    "! @parameter IV_TOP  | <p class="shorttext synchronized"></p>
    METHODS build_outtab IMPORTING iv_skip TYPE i DEFAULT 0
                                   iv_top  TYPE i DEFAULT 50.

    METHODS avatar_group_popover IMPORTING id           TYPE string
                                           iv_element   TYPE string
                                           iv_fieldname TYPE string
                                           iv_rowid     TYPE string.

    "! <p class="shorttext synchronized">Conversion in -&gt; out</p>
    "!
    "! @parameter is_gruelm        | <p class="shorttext synchronized">Mapping Element to Group</p>
    "! @parameter is_line          | <p class="shorttext synchronized">Mamba line (base structure)</p>
    "! @parameter iv_fieldname     | <p class="shorttext synchronized">ALV-Control: Field name table field</p>
    "! @parameter is_col           | <p class="shorttext synchronized">Mamba column (subtable)</p>
    "! @parameter cv_value         | <p class="shorttext synchronized">Value</p>
    "! @raising   /sct/qp_cx_error | <p class="shorttext synchronized">Error handling QPPD</p>
    METHODS do_format_db2out IMPORTING is_gruelm    TYPE /sct/qp_s_tgruelm
                                       is_line      TYPE /sct/qp_s_mamba   OPTIONAL
                                       iv_fieldname TYPE abp_field_name    OPTIONAL
                                       is_col       TYPE /sct/qp_s_mba_col OPTIONAL
                             CHANGING  cv_value     TYPE /sct/qp_value
                             RAISING   /sct/qp_cx_error.

    "! <p class="shorttext synchronized">Conversion out -&gt; in</p>
    "!
    "! @parameter is_gruelm        | <p class="shorttext synchronized">Mapping Element to Group</p>
    "! @parameter is_line          | <p class="shorttext synchronized">Mamba line (base structure)</p>
    "! @parameter is_col           | <p class="shorttext synchronized">Mamba column (subtable)</p>
    "! @parameter iv_fieldname     | <p class="shorttext synchronized">ALV-Control: Field name table field</p>
    "! @parameter cv_value         | <p class="shorttext synchronized">Value</p>
    "! @parameter cv_statelm       | <p class="shorttext synchronized">Status of the Element (F, R, M, ' ', X)</p>
    "! @raising   /sct/qp_cx_error | <p class="shorttext synchronized">Error handling QPPD</p>
    METHODS do_format_out2db IMPORTING is_gruelm    TYPE /sct/qp_s_tgruelm
                                       is_line      TYPE /sct/qp_s_mamba       OPTIONAL
                                       is_col       TYPE /sct/qp_s_mba_col     OPTIONAL
                                       iv_fieldname TYPE /sct/qp_fieldname_var OPTIONAL
                             CHANGING  cv_value     TYPE /sct/qp_value
                                       cv_statelm   TYPE /sct/qp_statelm
                             RAISING   /sct/qp_cx_error.

    METHODS do_jump                                                        " AD, 2026.10.09, changed
                    IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    "! <p class="shorttext synchronized">prepare output (outtab-columns)</p>
    "!
    "! @parameter is_data          | <p class="shorttext synchronized">base structure for Mamba</p>
    "! @raising   /sct/qp_cx_error | <p class="shorttext synchronized">Error handling QPPD</p>
    METHODS do_mbacol_to_out IMPORTING is_data           TYPE /sct/qp_s_mamba
                             CHANGING  VALUE(cs_outline) TYPE data
                             RAISING   /sct/qp_cx_error.

    "! <p class="shorttext synchronized">prepare output (outtab-line)</p>
    "!
    "! @parameter is_data          | <p class="shorttext synchronized">base structure for Mamba</p>
    "! @raising   /sct/qp_cx_error | <p class="shorttext synchronized">Error handling QPPD</p>
    METHODS do_mbaline_to_out IMPORTING is_data           TYPE /sct/qp_s_mamba
                              CHANGING  VALUE(cs_outline) TYPE data
                              RAISING   /sct/qp_cx_error.

    "! <p class="shorttext synchronized">Display Elements as a list</p>
    METHODS do_show_list.
    "! <p class="shorttext synchronized">Display Elements as a table</p>
    METHODS do_show_tab.

    "! <p class="shorttext synchronized">Set properties for input-fields</p>
    "!
    "! @parameter IO_XML         | <p class="shorttext synchronized"></p>
    "! @parameter IV_EDIT        | <p class="shorttext synchronized"></p>
    "! @parameter IV_FIELDNAME   | <p class="shorttext synchronized"></p>
    "! @parameter IR_KTXT        | <p class="shorttext synchronized"></p>
    "! @parameter IR_VALUE       | <p class="shorttext synchronized"></p>
    "! @parameter IR_UIATTR      | <p class="shorttext synchronized"></p>
    "! @parameter IR_MANDATORY   | <p class="shorttext synchronized"></p>
    "! @parameter IV_ROWID       | <p class="shorttext synchronized"></p>
    "! @parameter IV_FIELDWIDTH  | <p class="shorttext synchronized"></p>
    "! @parameter IV_TABIX       | <p class="shorttext synchronized"></p>
    "! @parameter IV_PLACEHOLDER | <p class="shorttext synchronized"></p>
    "! @parameter IV_ELEMENT     | <p class="shorttext synchronized"></p>
    METHODS field_input IMPORTING io_xml         TYPE REF TO /sct/au5_cl_xml_view
                                  iv_edit        TYPE abap_bool
                                  iv_fieldname   TYPE abp_field_name
                                  ir_ktxt        TYPE REF TO data
                                  ir_value       TYPE REF TO data
                                  ir_uiattr      TYPE REF TO /sct/qp_if_fcat=>ty_s_ui_attr
                                  ir_mandatory   TYPE REF TO data
                                  iv_rowid       TYPE /sct/qp_rowid
                                  iv_fieldwidth  TYPE string
                                  iv_tabix       TYPE i
                                  iv_placeholder TYPE string
                                  iv_element     TYPE /sct/qp_element
                                  iv_span        TYPE string OPTIONAL.

    "! <p class="shorttext synchronized">set style attributes</p>
    METHODS fill_outline_styles IMPORTING is_column  TYPE /sct/qp_s_mba_col
                                CHANGING  cs_outline TYPE any
                                RAISING   /sct/qp_cx_error.

    "! <p class="shorttext synchronized">process user changes</p>
    "!
    "! @parameter rt_changes | <p class="shorttext synchronized">Line change</p>
    METHODS get_changes RETURNING VALUE(rt_changes) TYPE /sct/qp_t_mamba_line_chg.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter is_line | <p class="shorttext synchronized">Mamba column (subtable)</p>
    "! @parameter is_col  | <p class="shorttext synchronized">Mamba column (subtable)</p>
    "! @parameter rv_unit | <p class="shorttext synchronized">unit of measurement</p>
    METHODS get_col_unit IMPORTING is_line        TYPE /sct/qp_s_mamba
                                   is_col         TYPE /sct/qp_s_mba_col
                         RETURNING VALUE(rv_unit) TYPE /sct/qp_value_einh.

    "! <p class="shorttext synchronized">get Field attributes</p>
    "!
    "! @parameter is_column | <p class="shorttext synchronized">Mamba column (subtable)</p>
    METHODS get_field_style IMPORTING is_column TYPE /sct/qp_s_mba_col
                            CHANGING  cs_attr   TYPE /sct/qp_if_fcat=>ty_s_ui_attr.

    METHODS get_jump_node IMPORTING it_arg        TYPE string_table
                          RETURNING VALUE(result) TYPE string_table.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter IV_INIT | <p class="shorttext synchronized"></p>
    METHODS get_objtyp_data IMPORTING iv_init TYPE abap_bool OPTIONAL.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter is_data         | <p class="shorttext synchronized">Mamba line (base structure)</p>
    "! @parameter rv_relattypicon | <p class="shorttext synchronized">Icon</p>
    METHODS get_relattyp_icon IMPORTING is_data                TYPE /sct/qp_s_mamba
                                        iv_as_emoji            TYPE abap_bool OPTIONAL
                              RETURNING VALUE(rv_relattypicon) TYPE string
                              RAISING   /sct/qp_cx_error.

    METHODS get_value_state IMPORTING is_error TYPE /sct/qp_if_mamba=>s_check_error
                            CHANGING  cs_attr  TYPE /sct/qp_if_fcat=>ty_s_ui_attr.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter is_column   | <p class="shorttext synchronized">Mamba column (subtable)</p>
    "! @parameter rv_editable | <p class="shorttext synchronized">bool Variable</p>
    METHODS is_fname_editable_elemformat IMPORTING is_column          TYPE /sct/qp_s_mba_col
                                         RETURNING VALUE(rv_editable) TYPE abap_boolean.

    METHODS popup_f4_element IMPORTING client             TYPE REF TO /sct/au5_if_client
                                       VALUE(iv_elemtext) TYPE string.

    METHODS popup_f4_value                                                               " AD, 2026.10.09, changed
                           IMPORTING VALUE(is_get) TYPE /sct/au5_if_client=>ty_s_get.

    "! <p class="shorttext synchronized">Prepare field catalog</p>
    "!
    "! @parameter et_fcat      | <p class="shorttext synchronized">Field catalog for ListViewerControl</p>
    "! @parameter ev_labeltype | <p class="shorttext synchronized">Single digit indicator</p>
    METHODS prepare_fcat IMPORTING iv_edit      TYPE abap_boolean
                         EXPORTING et_fcat      TYPE tty_fcat
                                   ev_labeltype TYPE sychar01.

    "! <p class="shorttext synchronized">Process all events (FCODE)</p>
    "!
    "! @parameter IS_GET       | <p class="shorttext synchronized"></p>
    "! @parameter RV_PROCESSED | <p class="shorttext synchronized"></p>
    METHODS process_event                                                                    " AD, 2026.10.09, changed
                          IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get
                          RETURNING VALUE(rv_processed) TYPE abap_bool.

    "! <p class="shorttext synchronized"></p>
    METHODS set_error_color.
    "! <p class="shorttext synchronized"></p>
    "! Kontextabhängig, werden unterschiedlichen Drucktasten zur Verfügung gestellt
    "! @parameter IO_VIEW | <p class="shorttext synchronized"></p>
    METHODS set_toolbar IMPORTING io_view TYPE REF TO /sct/au5_cl_xml_view.

    "! <p class="shorttext synchronized">Actualize outtab</p>
    METHODS update_outtab IMPORTING iv_skip TYPE i DEFAULT 0
                                    iv_top  TYPE i DEFAULT 50.

    METHODS get_avatar_initials IMPORTING iv_value      TYPE csequence
                                RETURNING VALUE(result) TYPE string.

    METHODS init               REDEFINITION.
    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS /sct/qp_cl_ui_mamba IMPLEMENTATION.
  METHOD init.
    ms_control-client = client.

    mo_mamba ?= ms_obj-object.
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc
                                                 eo_conv  = mo_conv
                                                 eo_fcat  = mo_fcat ).

    " Gespeicherte Daten wieder setzen (stateless)
    DATA(lv_data) = ms_control-root_app->get_data( |{ mt_def_arg[ 1 ] }{ mt_def_arg[ 2 ] }{ mt_def_arg[ 3 ] }MORE| ).
    IF lv_data IS NOT INITIAL.
      SPLIT lv_data AT ';' INTO TABLE DATA(lt_data).
      IF lines( lt_data ) = 2.
        ms_more-skip = VALUE #( lt_data[ 1 ] ).
        ms_more-top  = VALUE #( lt_data[ 2 ] ).
      ENDIF.
    ENDIF.

    get_objtyp_data( abap_true ).
  ENDMETHOD.

  METHOD process_event.
    FIELD-SYMBOLS <tok_del>    TYPE /sct/qp_if_fcat=>tty_token.
    FIELD-SYMBOLS <uiattr>     TYPE /sct/qp_if_fcat=>ty_s_ui_attr.
    FIELD-SYMBOLS <uiattr_ori> TYPE /sct/qp_if_fcat=>ty_s_ui_attr.

    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.
    CLEAR ms_obj-must_redraw.

    CASE is_get-event.
      WHEN 'SHOW_MORE'.
        " Anzahl Zeilen erhöhen
        ms_more-top += ms_more-step.
        ms_control-root_app->set_data( iv_key  = |{ mt_def_arg[ 1 ] }{ mt_def_arg[ 2 ] }{ mt_def_arg[ 3 ] }MORE|
                                       iv_data = |{ ms_more-skip };{ ms_more-top }| ).
      WHEN 'SHOW_ALL'.
        " Alle Zeilen anzeigen
        ms_more-skip = 0.
        ms_more-top  = 2147483647. " 2^31 - 1, einfach so.
        ms_control-root_app->set_data( iv_key  = |{ mt_def_arg[ 1 ] }{ mt_def_arg[ 2 ] }{ mt_def_arg[ 3 ] }MORE|
                                       iv_data = |{ ms_more-skip };{ ms_more-top }| ).
      WHEN 'POPUP_F4'.
        " Suchhilfe aufrufen
        ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO FIELD-SYMBOL(<line>).
*        ASSIGN ms_fcat-data->*[ ('ROWID') = is_get-t_event_arg[ 5 ] ] TO FIELD-SYMBOL(<line>).
        IF sy-subrc = 0.
          " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
          ASSIGN COMPONENT mc->fname_element OF STRUCTURE <line> TO FIELD-SYMBOL(<element>).
          DATA(lv_fname) = is_get-t_event_arg[ 4 ].
          ASSIGN COMPONENT lv_fname OF STRUCTURE <line> TO FIELD-SYMBOL(<field>).
          IF sy-subrc = 0.
            IF lv_fname = mc->fname_element.
              DATA(lv_hdr_text) = |Elements|.
              mt_suggestion_sel = VALUE #( mt_sug[ element = lv_fname ]-sug_tab OPTIONAL ).
              popup_f4_element( client      = ms_control-client
                                iv_elemtext = lv_hdr_text ).
            ELSE.
              popup_f4_value( is_get = is_get ).
            ENDIF.
          ENDIF.

        ENDIF.
      WHEN 'F4_ELEMENT_BACK'.
        ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO <line>.
        IF sy-subrc = 0.
          ASSIGN COMPONENT is_get-t_event_arg[ 4 ] OF STRUCTURE <line> TO <field>.
          IF sy-subrc = 0.
            DELETE mt_suggestion_sel WHERE selkz = abap_false.
            IF lines( mt_suggestion_sel ) = 1.
              <field> = mt_suggestion_sel[ 1 ]-value.
              ms_control-client->popup_destroy( ).
              ms_obj-must_redraw = abap_true.
              ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-show_data
                                                                       t_event_arg = VALUE #( ( is_get-t_event_arg[ 1 ] )
                                                                                              ( is_get-t_event_arg[ 2 ] ) ) ) ).
            ENDIF.

          ENDIF.
        ENDIF.

      WHEN 'F4_VALUE_BACK'.
        FIELD-SYMBOLS <ls_params> TYPE /sct/au5_if_types=>ty_s_name_value.

        " Wert der Suchhilfe zurückschreiben
        DATA(lv_rowid) = CONV /sct/qp_rowid( is_get-t_event_arg[ 5 ] ).
        ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = lv_rowid ] TO <line>.
        IF sy-subrc = 0.
          DATA(lr_line) = mo_mamba->get_lineref_via_id( lv_rowid ).
          IF lr_line->gruelm->tobel IS BOUND. " SHLP_fieldname befüllt
            DATA(lv_fieldname) = lr_line->gruelm->tobel->shlp_fieldname.
          ENDIF.
          ASSIGN COMPONENT |{ is_get-t_event_arg[ 4 ] }_UIATTR| OF STRUCTURE <line> TO <uiattr>.
          IF <uiattr> IS ASSIGNED AND <uiattr>-multi_input = abap_true.

            FIELD-SYMBOLS <result> TYPE /sct/au5_if_types=>ty_t_name_value.
            IF is_get-r_event_data IS BOUND.
              LOOP AT is_get-r_event_data->* ASSIGNING <result>. " Tabelle fon Ergebnistabellen (Mehfachselektion Suchhilfe)
                LOOP AT <result> ASSIGNING <ls_params>
                     WHERE n = lv_fieldname OR n = is_get-t_event_arg[ 4 ].

                  IF NOT line_exists( <uiattr>-token[ key = <ls_params>-v ] ).
                    " Doppelte Einträge vermeiden.
*                    INSERT VALUE #( key      = <ls_params>-v
*                                    text     = <ls_params>-v
*                                    visible  = abap_true
*                                    editable = abap_true ) INTO TABLE <uiattr>-token.
                    INSERT VALUE #( key      = <ls_params>-v
                                    text     = <ls_params>-v
                                    visible  = abap_true
                                    editable = abap_true ) INTO TABLE <uiattr>-token_add.
                  ENDIF.

                ENDLOOP.
              ENDLOOP.

            ENDIF.

          ELSE.

            ASSIGN COMPONENT is_get-t_event_arg[ 4 ] OF STRUCTURE <line> TO <field>.
            IF sy-subrc = 0.
              DATA(lv_shlp_fieldname) = VALUE #( is_get-t_event_arg[ 6 ] OPTIONAL ).
              IF lv_shlp_fieldname IS NOT INITIAL.
                lv_fieldname = lv_shlp_fieldname.
              ENDIF.
              LOOP AT is_get-t_comp_params ASSIGNING FIELD-SYMBOL(<param>)
                   WHERE n = lv_fieldname OR n = is_get-t_event_arg[ 4 ].
                <field> = <param>-v.
                EXIT.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDIF.
*        check_changes( ).
        ms_obj-must_redraw = abap_true.
        ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-show_data
                                                                 t_event_arg = VALUE #( ( is_get-t_event_arg[ 1 ] )
                                                                                        ( is_get-t_event_arg[ 2 ] ) ) ) ).
      "
      WHEN mc->action_change.
        check_changes( ).

*      WHEN mc->action_filter.
*
*        " only GUI, no need to process anything.
*        IF mv_filter_empty = abap_true.
*          mv_filter_empty = abap_false.
*        ELSE.
*          mv_filter_empty = abap_true.
*        ENDIF.

      WHEN mc->action_jump OR 'JUMP_EXT'.
        do_jump( is_get ).

      WHEN 'EVT_TOKEN_UPD'. " Deleted Token
*        ASSIGN mr_data_saved->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO FIELD-SYMBOL(<line_saved>).
*        ASSIGN COMPONENT |{ is_get-t_event_arg[ 4 ] }_UIATTR-TOKEN| OF STRUCTURE <line_saved> TO FIELD-SYMBOL(<tok_saved>).

        ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO <line>.
*        ASSIGN COMPONENT mc->fname_element OF STRUCTURE <line> TO <element>.
*        ASSIGN COMPONENT is_get-t_event_arg[ 4 ] OF STRUCTURE <line> TO <field>.
        ASSIGN COMPONENT |{ is_get-t_event_arg[ 4 ] }_UIATTR-TOKEN_DEL| OF STRUCTURE <line> TO <tok_del>.

        IF sy-subrc = 0 AND is_get-t_event_arg[ 6 ] = `removed`.
          INSERT VALUE #( key = is_get-t_event_arg[ 7 ] ) INTO TABLE <tok_del>.
        ENDIF.

      WHEN 'EVT_TOKEN_CHANGE'. " added Token ( manually or with suggestion )
        ASSIGN mr_data_saved->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO FIELD-SYMBOL(<line_saved>).
        ASSIGN COMPONENT |{ is_get-t_event_arg[ 4 ] }_UIATTR| OF STRUCTURE <line_saved> TO <uiattr_ori>.

        ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO <line>.
        ASSIGN COMPONENT |{ is_get-t_event_arg[ 4 ] }_UIATTR| OF STRUCTURE <line> TO <uiattr>.
        DATA(lv_input) = is_get-t_event_arg[ 6 ].

        CLEAR <uiattr>-token.
        IF <uiattr_ori>-token IS NOT INITIAL.
          INSERT <uiattr_ori>-token[ 1 ] INTO TABLE <uiattr>-token. " Ursprünglicher Token retten
        ENDIF.
        IF NOT line_exists( <uiattr_ori>-token[ key = lv_input ] ).
          " Doppelte Einträge vermeiden.
          INSERT VALUE #( key      = lv_input
                          text     = lv_input
                          visible  = abap_true
                          editable = abap_true ) INTO TABLE <uiattr>-token_add.
        ENDIF.

        " Value löschen wenn Token verarbeitet ist.
        ASSIGN COMPONENT is_get-t_event_arg[ 4 ] OF STRUCTURE <line> TO <field>.
        CLEAR <field>.

      WHEN 'AVATAR_PRESS'.
        " [4]: fieldname
        " [5]: ROWID
        " [6]: Element
        " [7]: Avatar-index (aus Avatar-Group)
        " [8]: boolean (more-popover geklicked)
        " [9]: control-ID für Popover
        " [10]: selektierte Avatar-ID (aus More-Popover)

        IF is_get-t_event_arg[ 8 ] = abap_true.
          " More -> display in popup
          avatar_group_popover( iv_fieldname = is_get-t_event_arg[ 4 ]
                                iv_rowid     = is_get-t_event_arg[ 5 ]
                                iv_element   = is_get-t_event_arg[ 6 ]
                                id           = is_get-t_event_arg[ 9 ] ).
        ELSE.
          " Avatar selektiert
          ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = is_get-t_event_arg[ 5 ] ] TO <line>.
          ASSIGN mt_avatars[ element = is_get-t_event_arg[ 6 ] ] TO FIELD-SYMBOL(<ls_ava>).
          ASSIGN COMPONENT is_get-t_event_arg[ 4 ] OF STRUCTURE <line> TO <field>.
          IF sy-subrc <> 0.
            RETURN.
          ENDIF.
          CLEAR <ls_ava>-t_select.
          IF is_get-t_event_arg[ 7 ] <> ` `. " index innerhalb des Avatar-groups

*            DATA(lt_avatar) = <ls_ava>-t_avatar.
*            DELETE lt_avatar WHERE blocked = abap_false.
*            ASSIGN lt_avatar[ is_get-t_event_arg[ 7 ] + 1 ] TO FIELD-SYMBOL(<ls_selected>).
            ASSIGN <ls_ava>-t_avatar[ is_get-t_event_arg[ 7 ] + 1 ] TO FIELD-SYMBOL(<ls_selected>).
            IF <ls_selected> IS ASSIGNED.
              <field> = <ls_selected>-id.
            ENDIF.
          ELSE. " Avatar aus dem more-popover : hier kommt sofort die ID
            <field> = VALUE #( is_get-t_event_arg[ 10 ] OPTIONAL ).
            ms_control-client->popover_destroy( ). " Ohne wird beim 2.Aufruf das Popover nicht sauber angezeigt
          ENDIF.
          INSERT VALUE #( <ls_ava>-t_avatar[ id = <field> ] OPTIONAL ) INTO TABLE <ls_ava>-t_select.

*          ms_control-client->nest2_view_model_update( ).
*          ms_control-client->nest_view_model_update( ).

*          ms_obj-must_redraw = abap_true.
        ENDIF.
      WHEN OTHERS.

        IF is_get-event = mc->action_newline.
          DATA(lr_fcat_element) = REF #( ms_fcat-fieldcat[ fieldname = mc->fname_element ] ).
          IF lr_fcat_element IS BOUND.
            lr_fcat_element->no_out = abap_false.
            lr_fcat_element->edit   = abap_true.
          ENDIF.
        ENDIF.

        DATA(ls_action) = VALUE /sct/qp_s_mamba_action( action = is_get-event ).
        mt_sel = CORRESPONDING #( ms_fcat-data->* ).
        DELETE mt_sel WHERE mamba_sel IS INITIAL.
        LOOP AT mt_sel ASSIGNING FIELD-SYMBOL(<sel>).
          INSERT <sel>-rowid INTO TABLE ls_action-rows.
        ENDLOOP.

        mo_mamba->process( is_action = ls_action ).
        IF ms_node_object-elementgrp_sp IS INITIAL. " listanzeige
          ms_obj-must_redraw = abap_true.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD constructor.
    super->constructor( is_obj ).
*    IF is_obj IS NOT INITIAL.
*      ms_obj = is_obj.
*    ELSE.
*      start_standalone = abap_true.
*    ENDIF.

** Gespeicherte Daten wieder setzen (stateless)
*      DATA(lv_data) = ms_control-root_app->get_data( |{ mt_def_arg[ 1 ] }{ mt_def_arg[ 2 ] }{ mt_def_arg[ 3 ] }MORE| ).
*      IF lv_data IS NOT INITIAL.
*        SPLIT lv_data AT ';' INTO TABLE DATA(lt_data).
*        IF lines( lt_data ) = 2.
*          ms_more-skip = VALUE #( lt_data[ 1 ] ).
*          ms_more-top  = VALUE #( lt_data[ 2 ] ).
*        ENDIF.
*      ENDIF.
  ENDMETHOD.

  METHOD get_objtyp_data.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " Im gegensatz zu SAP-GUI gibt es eine View-Instanz je (angezeigte) Mamba-Instanz

    " 1) MT_DATA aufbauen, Outtab anpassen
    IF iv_init = abap_true.

      " 2) daraus ein dyn-Tab + FCAT aufbauen
      ms_fcat = mo_fcat->get_ui_fcat( mo_mamba ).

      IF mo_mamba->ms_control-data_built IS INITIAL.
        TRY.
            mo_mamba->do_build_mt_data( ms_obj-base ).
          CATCH /sct/qp_cx_error.
        ENDTRY.
      ELSE.
        " Zurück aus einer anderen App (z.B F4-callback )
        " ms_fcat-data muss neuaufgebaut werden anhand von bestehenden mo_mamba->mt_data Zeilen
        " gui_upd muss erneut gesetzt werden
        DATA(ls_data) = VALUE /sct/qp_s_mamba( gui_upd = abap_true ).

        MODIFY mo_mamba->mt_data FROM ls_data ##PRIMKEY[GUI_UPD] "#EC CI_HASHSEQ
               TRANSPORTING gui_upd
               WHERE gui_upd = abap_false.

      ENDIF.

      IF NOT line_exists( mt_sug[ element = 'ELEMENT' ] ).

        " Suggestions für die Spalte ELEMENT vorbereiten
        mo_cust->get_tgruelm( EXPORTING iv_objekttyp     = ms_node_object-objekttyp
                                        iv_elementgruppe = ms_node_object-elementgruppe
                              IMPORTING et_tgruelm       = DATA(lt_gruelm) ).
        DATA(lt_suggest) = CORRESPONDING tty_sug( lt_gruelm MAPPING value = element descr = elementtext ).
        INSERT VALUE #( element = 'ELEMENT'
                        sug_tab = lt_suggest ) INTO TABLE mt_sug.

        INSERT VALUE #( element = 'EMPTY_LIST'
                        sug_tab = VALUE #( ) ) INTO TABLE mt_sug.

      ENDIF.

      " 3) Suggestions setzen
      IF is_editable( ) = abap_true.
        mo_cust->get_tgruelm( EXPORTING iv_objekttyp     = ms_node_object-objekttyp
                                        iv_elementgruppe = ms_node_object-elementgruppe
                              IMPORTING et_tgruelm       = lt_gruelm ).

        LOOP AT lt_gruelm ASSIGNING FIELD-SYMBOL(<gruelm>).
          IF line_exists( mt_sug[ element = <gruelm>-element ] ).
            CONTINUE.
          ENDIF.
          TRY.
              DATA(lo_toe) = /sct/qp_cl_toe=>get_instance( irs_tobel = <gruelm>-tobel ).
              IF lo_toe IS BOUND.
                " FT20250815 : Ursprüglich waren die Suggestions nur für vollständig geladen Werte (i.e Domain und Table_buffer) verfügbar.
                " Eckard will alle TOE-Werte haben, selbst für Werte die beim Initialisierung nicht komplett geladen werden. (z.B Materialstamm VARTen...)
                " d.h. es werden ggfs. unvollständige Suggestions angezeigt
                "        AND ( lo_toe IS INSTANCE OF /sct/qp_cl_toe_domain OR lo_toe IS INSTANCE OF /sct/qp_cl_toe_table_buffer ).

                INSERT VALUE #( element = <gruelm>-element ) INTO TABLE mt_sug ASSIGNING FIELD-SYMBOL(<ls_sug>).
                lo_toe->get_value_list( EXPORTING is_toe   = VALUE #( element = <gruelm>-element
                                                                      gruelm  = REF #( <gruelm> ) )
                                        IMPORTING et_value = DATA(lt_values) ).
                <ls_sug>-sug_tab = CORRESPONDING tty_sug( lt_values MAPPING descr = ktxt ).

                IF <gruelm>-tobjel = 'AVATAR'.
                  ASSIGN mt_avatars[ element = <gruelm>-element ] TO FIELD-SYMBOL(<ls_avatar>).
                  IF sy-subrc <> 0.
                    INSERT VALUE #( element = <gruelm>-element
                                    label   = |{ <gruelm>-elementtext } ({ <gruelm>-element })| )
                           INTO TABLE mt_avatars ASSIGNING <ls_avatar>.
                  ENDIF.

                  IF <ls_avatar>-t_avatar IS INITIAL.
*                    DATA(lv_src) = |{ /sct/qp_if_ui_app~get_location( /sct/qp_cl_ui=>c_mime_path ) }AVATARS/{ <gruelm>-element }/|.
                    DATA(lv_src) = |{ /sct/qp_cl_ui=>c_mime_path }AVATARS/{ <gruelm>-element }/|.

                    LOOP AT lt_values ASSIGNING FIELD-SYMBOL(<value>).
                      DATA(ls_text) = VALUE #( <value>-valt[ spras = sy-langu ] OPTIONAL ).
                      INSERT VALUE #( id           = <value>-value
                                      name         = <value>-ktxt
                                      src          = |{ lv_src }{ <value>-value }|
                                      fallbackicon = 'sap-icon://error'
                                      initials     = get_avatar_initials( <value>-value )
                                      tooltip      = ls_text-scrtext_l ) INTO TABLE <ls_avatar>-t_avatar.
                    ENDLOOP.
                  ENDIF.
                ENDIF.

                CLEAR lt_values.

              ENDIF.
            CATCH /sct/qp_cx_error.
          ENDTRY.

        ENDLOOP.

      ENDIF. " editierbar

    ELSE.
      TRY.
          mo_mamba->do_update_mt_data( ms_obj-base ).
        CATCH /sct/qp_cx_error.
      ENDTRY.

      update_outtab( iv_skip = ms_more-skip
                     iv_top  = ms_more-top ).
*    ENDIF.
      set_error_color( ).

*      " 3) Suggestions setzen
*      IF is_editable( ) = abap_true.
*        mo_cust->get_tgruelm( EXPORTING iv_objekttyp     = ms_node_object-objekttyp
*                                        iv_elementgruppe = ms_node_object-elementgruppe
*                              IMPORTING et_tgruelm       = lt_gruelm ).
*
*        LOOP AT lt_gruelm ASSIGNING FIELD-SYMBOL(<gruelm>).
*          IF line_exists( mt_sug[ element = <gruelm>-element ] ).
*            CONTINUE.
*          ENDIF.
*          TRY.
*              DATA(lo_toe) = /sct/qp_cl_toe=>get_instance( irs_tobel = <gruelm>-tobel ).
*              IF lo_toe IS BOUND.
*                " FT20250815 : Ursprüglich waren die Suggestions nur für vollständig geladen Werte (i.e Domain und Table_buffer) verfügbar.
*                " Eckard will alle TOE-Werte haben, selbst für Werte die beim Initialisierung nicht komplett geladen werden. (z.B Materialstamm VARTen...)
*                " d.h. es werden ggfs. unvollständige Suggestions angezeigt
*                "        AND ( lo_toe IS INSTANCE OF /sct/qp_cl_toe_domain OR lo_toe IS INSTANCE OF /sct/qp_cl_toe_table_buffer ).
*
*                INSERT VALUE #( element = <gruelm>-element ) INTO TABLE mt_sug ASSIGNING FIELD-SYMBOL(<ls_sug>).
*                lo_toe->get_value_list( EXPORTING is_toe   = VALUE #( element = <gruelm>-element
*                                                                      gruelm  = REF #( <gruelm> ) )
*                                        IMPORTING et_value = DATA(lt_values) ).
*                <ls_sug>-sug_tab = CORRESPONDING tty_sug( lt_values MAPPING descr = ktxt ).
*
*                IF <gruelm>-tobjel = 'AVATAR'.
*                  ASSIGN mt_avatars[ element = <gruelm>-element ] TO FIELD-SYMBOL(<ls_avatar>).
*                  IF sy-subrc <> 0.
*                    INSERT VALUE #( element = <gruelm>-element
*                                    label   = |{ <gruelm>-elementtext } ({ <gruelm>-element })| )
*                           INTO TABLE mt_avatars ASSIGNING <ls_avatar>.
*                  ENDIF.
*
*                  IF <ls_avatar>-t_avatar IS INITIAL.
*                    DATA(lv_src) = |{ /sct/qp_if_ui_app~get_location( /sct/qp_cl_ui=>c_mime_path ) }AVATARS/{ <gruelm>-element }/|.
*
*                    LOOP AT lt_values ASSIGNING FIELD-SYMBOL(<value>).
*                      DATA(ls_text) = VALUE #( <value>-valt[ spras = sy-langu ] OPTIONAL ).
*                      INSERT VALUE #( id           = <value>-value
*                                      name         = <value>-ktxt
*                                      src          = |{ lv_src }{ <value>-value }|
*                                      fallbackicon = 'sap-icon://error'
*                                      initials     = get_avatar_initials( <value>-value )
*                                      tooltip      = ls_text-scrtext_l ) INTO TABLE <ls_avatar>-t_avatar.
*                    ENDLOOP.
*                  ENDIF.
*                ENDIF.
*
*                CLEAR lt_values.
*
*              ENDIF.
*            CATCH /sct/qp_cx_error.
*          ENDTRY.
*
*        ENDLOOP.
*
*      ENDIF. " editierbar

      IF ms_node_object-elementgrp_sp IS INITIAL.
        " Aufbereitung MULTI-VALUE:
        " Wenn Elemente mehrfach bewertbar sind, wird nur eine Zeile angezeigt (hidden = X für die anderen).
        " alle Tokens werden gesammelt und die Werte gecleared.

        TYPES: BEGIN OF ty_line,
                 element     TYPE /sct/qp_element,
                 rowgrp      TYPE /sct/qp_rowgrp,
                 multi_input TYPE abap_bool,
                 hidden      TYPE REF TO abap_bool,
                 data        TYPE REF TO data,
               END OF ty_line.
        TYPES ty_table TYPE SORTED TABLE OF ty_line WITH UNIQUE KEY element rowgrp.
        DATA lt_table TYPE ty_table.
        FIELD-SYMBOLS <uiattr> TYPE /sct/qp_if_fcat=>ty_s_ui_attr.
        " GROUP BY ist auf eine dynamische Tabelle nicht möglich ( Dump STRUCTURE_ILLEGAL ) weil das groupierungselement statisch nicht bekannt ist
        LOOP AT ms_fcat-data->* ASSIGNING FIELD-SYMBOL(<data>).
          ASSIGN <data>-('VALUE_UIATTR') TO <uiattr>. " Mehrfachbewertung nur für VALUE-Felder der VAL
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.
          IF <uiattr>-multi_input IS NOT INITIAL.
            INSERT VALUE #( element = <data>-('element')
                            rowgrp  = <data>-('rowgrp')
                            hidden  = REF #( <data>-('hidden') )
                            data    = REF #( <data> ) )
                   INTO TABLE lt_table.
          ENDIF.
          IF <uiattr>-avatar = abap_false.
            CONTINUE.
          ENDIF.

          ASSIGN COMPONENT mc->fname_element OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_element>).
*          lv_src = |{ /sct/qp_if_ui_app~get_location( /sct/qp_cl_ui=>c_mime_path ) }AVATARS/{ <lv_element> }/|.
          lv_src = |{ /sct/qp_cl_ui=>c_mime_path }AVATARS/{ <lv_element> }/|.

          ASSIGN mt_avatars[ element = <lv_element> ] TO <ls_avatar>.
          IF sy-subrc <> 0.
            INSERT VALUE #( element = <lv_element> ) INTO TABLE mt_avatars ASSIGNING <ls_avatar>.
          ENDIF.
          CLEAR <ls_avatar>-t_select.
          DATA(lv_value) = CONV /sct/qp_value( <data>-('value') ).
          IF lv_value IS NOT INITIAL.
            INSERT VALUE #( id           = lv_value
                            name         = <data>-('ktxt')
                            src          = |{ lv_src }{ lv_value }|
                            initials     = get_avatar_initials( lv_value )
                            fallbackicon = 'sap-icon://error'
                            tooltip      = <data>-('ktxt') ) INTO TABLE <ls_avatar>-t_select.

*              MODIFY <ls_avatar>-t_avatar FROM VALUE #( blocked = abap_true ) TRANSPORTING blocked where id <> ' '.
*              DATA(lr_sel) = REF #( <ls_avatar>-t_avatar[ id = lv_value ] OPTIONAL ).
*              IF lr_sel IS BOUND.
*                lr_sel->blocked = abap_false.
*              ENDIF.

*            ELSE.
*              INSERT value #( fallbackicon = "'sap-icon://error'
*              'sap-icon://SAP-icons-TNT/marquee'
*              ) INTO TABLE  <ls_avatar>-t_select.

          ENDIF.
        ENDLOOP.

        LOOP AT lt_table ASSIGNING FIELD-SYMBOL(<group_data>) GROUP BY ( element = <group_data>-element
*                                                                         multi   = <group_data>-multi_input
*                                                                         size    = GROUP SIZE
           ) REFERENCE INTO DATA(lr_group).

          DATA(index) = VALUE i( ).
          LOOP AT GROUP lr_group ASSIGNING FIELD-SYMBOL(<line>).
            index += 1.
            IF index = 1.

              CLEAR : <line>-data->('value'),
                      <line>-data->('ktxt'),
                      <line>-hidden->*.

              DATA(lr_target_token) = REF #( <line>-data->('VALUE_UIATTR-TOKEN') ).
              CLEAR lr_target_token->*.
            ELSE.
              <line>-hidden->* = abap_true.
            ENDIF.

            DATA(lr_mba_line) = mo_mamba->get_lineref_via_id( <line>-data->('rowid') ).
            IF lr_mba_line IS BOUND.
              DATA(lr_col) = REF #( lr_mba_line->col[ fieldname = mc->fname_value ] ).
              IF lr_col IS BOUND AND lr_col->content IS NOT INITIAL.
                INSERT VALUE /sct/qp_if_fcat=>ty_s_token( key      = lr_col->content
                                                          text     = COND #( WHEN lr_col->ktxt IS INITIAL
                                                                             THEN lr_col->content
                                                                             ELSE lr_col->ktxt )
                                                          visible  = abap_true
                                                          editable = abap_true ) INTO TABLE lr_target_token->*.
              ENDIF.
            ENDIF.

*                ASSIGN <line>-data->('VALUE_UIATTR-TOKEN') TO FIELD-SYMBOL(<source_token>).
*                INSERT LINES OF <source_token> INTO TABLE lr_target_token->*.
*                <line>-hidden->* = abap_true.

**              INSERT VALUE #( key = <line>-data->('value') text = <line>-data->('ktxt') visible = abap_true editable = abap_true ) INTO TABLE <tok>-tok.
**              IF index <> 1.
**                <line>-hidden->* = abap_true.
**              ENDIF.
          ENDLOOP.
        ENDLOOP.

      ENDIF.

      " 4) Daten kopieren (wegen Vergleich für GUI Änderungen)
      IF mr_data_saved IS NOT INITIAL.
        CLEAR mr_data_saved->*.
        FREE mr_data_saved.
      ENDIF.
      CREATE DATA mr_data_saved LIKE ms_fcat-data->*.
      mr_data_saved->* = ms_fcat-data->*.

      " 5) Log strip aktualisieren

      DATA(lt_messages) = mo_mamba->mo_parent->mo_log->get_messages( iv_objekttyp = ms_node_object-objekttyp ).

      DELETE lt_messages WHERE msgty <> mc->msgtype_e AND msgty <> mc->msgtype_a.
      CASE lines( lt_messages ).
        WHEN 0.
          mv_show_strip = abap_false.
        WHEN 1.
          ms_message = lt_messages[ 1 ].
          IF ms_message-message IS INITIAL.
            ms_message-message = mo_tools->get_msg_from_msgv( iv_id     = ms_message-msgid
                                                              iv_number = ms_message-msgno
                                                              iv_msgv1  = ms_message-msgv1
                                                              iv_msgv2  = ms_message-msgv2
                                                              iv_msgv3  = ms_message-msgv3
                                                              iv_msgv4  = ms_message-msgv4 ).
          ENDIF.
          mv_show_strip = abap_true.
        WHEN OTHERS.
          ms_message-message = mutx->get_text( mutx->u060 ).
          mv_show_strip = abap_true.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD build_outtab.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    FIELD-SYMBOLS <lt_outtab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_outline> TYPE any.
    FIELD-SYMBOLS <ls_data>    TYPE /sct/qp_s_mamba.

    ASSIGN ms_fcat-data->* TO <lt_outtab>.

    CLEAR <lt_outtab>.
    DATA lr_outline TYPE REF TO data.
    CREATE DATA lr_outline LIKE LINE OF <lt_outtab>.

    DATA(lv_end) = iv_skip + iv_top.
    LOOP AT mo_mamba->mt_data ASSIGNING <ls_data>
         USING KEY sortnr FROM iv_skip TO lv_end.

      ASSIGN lr_outline->* TO <ls_outline>.
      CLEAR <ls_outline>.

      mo_mamba->do_read_text_line( ir_line = REF #( <ls_data> ) ).

      do_mbaline_to_out( EXPORTING is_data    = <ls_data>
                         CHANGING  cs_outline = <ls_outline> ).

      INSERT <ls_outline> INTO TABLE <lt_outtab>.

    ENDLOOP.
  ENDMETHOD.

  METHOD do_format_db2out.
    " --------------------------------------------------------------------*
    "  Änderungslog
    " --------------------------------------------------------------------*
    "  AD, 2016.09.21, Note 934
    "  CONVERT: Klassenbasierte Ausnahmen
    " --------------------------------------------------------------------*
    " FT20170216 Note 1155 Keine Fehler produzieren
    "            bei Referenzen oder gen.Werte
    " --------------------------------------------------------------------*
    "  NS, 2017.09.12, NOTE 1373,
    "  Umstellung auf neues Interface /SCT/QP_CL_CONVERT => /SCT/QP_IF_CONV
    " --------------------------------------------------------------------*
    "  FT20171020 Note 1542 - Mamba : Konvertierungsfehler nicht gelöscht
    " --------------------------------------------------------------------*
    "  MD, 2018.04.20: N1653 remove_check_error Parameterübergabe optimiert
    " --------------------------------------------------------------------*
    "  MD, 2018.04.30: N1656 remove_check_error ROWID übergeben
    " --------------------------------------------------------------------*
    "  FT20210222 Note 3105 Dyn Nachkommastellen je Einheit
    " --------------------------------------------------------------------*
    "  ES20230615 NOTE-3410 Simplifizierung
    "  löschen von lanege in GRUELM
    " --------------------------------------------------------------------*

    DATA lv_key1 TYPE /sct/qp_logkey.
    DATA lv_key2 TYPE /sct/qp_logkey.
    DATA lv_key3 TYPE /sct/qp_logkey.

    IF is_gruelm-convmeth IS INITIAL.
      RETURN.
    ENDIF.

    lv_key1 = mo_mamba->mo_parent->ms_node_data-guid.
    lv_key2 = is_gruelm-element.
    lv_key3 = is_line-rowgrp && mc->init_lfdnr.
    " FT20171020 Note 1542 BoI
    mo_mamba->remove_check_error( iv_rowid   = is_line-rowid                               " MD180430 N1656 INS
                                  iv_element = is_gruelm-element
*                                  iv_type    = /sct/qp_cx_check=>mc_error_type_conv_out   "MD171124 N1653 DEL
                                  iv_source  = /sct/qp_cx_check=>mc_error_source_conversion
                                  iv_field   = CONV #( iv_fieldname ) ). " MD171124 N1653 INS
    " FT20171020 Note 1542 EoI

    TRY.
        mo_conv->db_to_out( EXPORTING iv_convmeth   = is_gruelm-convmeth
                            " iv_laenge     = is_gruelm-laenge   " MD160205 Längenüberprüfung
                                      iv_element    = is_gruelm-element
                                      iv_unit       = get_col_unit( is_line = is_line
                                                                    is_col  = is_col ) " FT20210222 Note 3105
                            CHANGING  cv_value_char = cv_value ).

      CATCH /sct/qp_cx_error INTO mx.
        " FT20170216 Note 1155 nicht immer eine Nachricht erzeugen
        IF iv_fieldname(3)   = mc->fname_gen
        OR is_line-relattyp <> mc->relattyp_original.
          " Kein Fehler produzieren beim konvertieren von gen_werte
          " oder Referenzen
          RETURN.
        ENDIF.
        DATA(ls_msg_log) = mx->get_msg_log( ).
        ls_msg_log-key1   = lv_key1.
        ls_msg_log-key2   = lv_key2.
        ls_msg_log-key3   = lv_key3.
        " FT20171020 Note 1542 BoI
        ls_msg_log-type   = /sct/qp_cx_check=>mc_error_type_conv_out.
        " FT20171020 Note 1542 EoI
        ls_msg_log-source = /sct/qp_cx_check=>mc_error_source_conversion.
        ls_msg_log-fields = iv_fieldname.

        " Prüfungs-Ausnahme für spätere Auswertung speichern
        mo_mamba->add_check_error( is_check_error = VALUE #( rowid   = is_line-rowid
                                                             element = is_gruelm-element
                                                             msg     = ls_msg_log ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD do_format_out2db.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2016.09.21, Note 934
    " CONVERT: Klassenbasierte Ausnahmen
    " --------------------------------------------------------------------*
    " NS, 2017.09.12, NOTE 1373,
    " Umstellung auf neues Interface /SCT/QP_CL_CONVERT => /SCT/QP_IF_CONV
    " --------------------------------------------------------------------*
    " FT20171020 Note 1542 - Mamba : Konvertierungsfehler nicht gelöscht
    " --------------------------------------------------------------------*
    " MD, 2018.04.20: N1653 remove_check_error Parameterübergabe optimiert
    " --------------------------------------------------------------------*
    " FT20200402 Note 2453 rowid_row
    " --------------------------------------------------------------------*
    " FT20210222 Note 3105 Dyn Nachkommastellen je Einheit
    " --------------------------------------------------------------------*
    " ES20230615 NOTE-3410 Simplifizierung
    " Löschen von Tabelleninhlaten auch für die dyn_ucon_method
    " --------------------------------------------------------------------*

    DATA lv_key1 TYPE /sct/qp_logkey.
    DATA lv_key2 TYPE /sct/qp_logkey.
    DATA lv_key3 TYPE /sct/qp_logkey.

    " Bestehende Konvertierungsfehler zum Element löschen
*    mo_mamba->remove_check_error( iv_rowid     = is_line-rowid
    mo_mamba->remove_check_error( iv_rowid_row = is_line-rowid " FT20200402 ROWID_ROW
                                  iv_element   = is_gruelm-element
*                                  iv_type      = /sct/qp_cx_check=>mc_error_type_conv_out    "MD171124 1653 DEL
                                  iv_source    = /sct/qp_cx_check=>mc_error_source_conversion
                                  iv_field     = iv_fieldname ).

    lv_key1 = mo_mamba->mo_parent->ms_node_data-guid.
    lv_key2 = is_gruelm-element.
    lv_key3 = is_line-rowgrp && mc->init_lfdnr.

    IF is_gruelm IS NOT INITIAL.

      IF is_gruelm-convmeth IS NOT INITIAL.

        TRY.
            mo_conv->out_to_db( EXPORTING iv_convmeth   = is_gruelm-convmeth
                                " iv_laenge     = is_gruelm-laenge   " MD160205 Längenüberprüfung
                                          iv_element    = is_gruelm-element
                                          iv_unit       = get_col_unit( is_line = is_line
                                                                        is_col  = is_col ) " FT20210222 Note 3105
                                CHANGING  cv_value_char = cv_value ).
            cv_statelm = mc->statelm_f.

          CATCH /sct/qp_cx_error INTO mx.
            " FT20170216 Note 1155 nicht immer eine Nachricht erzeugen
            IF iv_fieldname(3)   = mc->fname_gen
            OR is_line-relattyp <> mc->relattyp_original.
              " Kein Fehler produzieren beim konvertieren von gen_werte
              " oder Referenzen
              RETURN.
            ENDIF.
            DATA(ls_msg_log) = mx->get_msg_log( ).
            ls_msg_log-key1   = lv_key1.
            ls_msg_log-key2   = lv_key2.
            ls_msg_log-key3   = lv_key3.
            ls_msg_log-source = /sct/qp_cx_check=>mc_error_source_conversion.
            " FT20171020 Note 1542 BoI
            ls_msg_log-type   = /sct/qp_cx_check=>mc_error_type_conv_in.
            " FT20171020 Note 1542 EoI
            ls_msg_log-fields = iv_fieldname.

            cv_statelm = mc->statelm_r.
            " Prüfungs-Ausnahme für spätere Auswertung speichern
            mo_mamba->add_check_error( is_check_error = VALUE #( rowid   = is_line-rowid
                                                                 element = is_gruelm-element
                                                                 msg     = ls_msg_log ) ).
        ENDTRY.

      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD do_mbacol_to_out.
    " *********************************************************************
    "  Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    DATA lv_fieldname  TYPE abp_field_name.
    DATA lv_fname_ktxt TYPE abp_field_name.
    DATA lv_fname_gen  TYPE abp_field_name.

    FIELD-SYMBOLS <ls_target> TYPE any.
    FIELD-SYMBOLS <ls_col>    TYPE LINE OF /sct/qp_s_mamba-col.

    DATA lv_value TYPE /sct/qp_value.
*          lv_statelm LIKE <ls_col>-statelm.

    LOOP AT is_data-col ASSIGNING <ls_col>.

      UNASSIGN <ls_target>.
      IF <ls_col>-element IS INITIAL.
        lv_fieldname = <ls_col>-fieldname.
      ELSE.
        lv_fieldname = <ls_col>-fieldname_dyn.
      ENDIF.
      ASSIGN COMPONENT lv_fieldname OF STRUCTURE cs_outline TO <ls_target>.

      "--------------------------------------------------------------------*
      " WERT
      "--------------------------------------------------------------------*
      IF <ls_target> IS ASSIGNED.

        " Das Customizing GRUELM ist nur für "VALUE" Felder vorhanden, die auch
        " eine Konvertierung benötigen
        IF  lv_fieldname    IN mo_mamba->mt_value_field
        AND <ls_col>-gruelm IS NOT INITIAL.
          lv_value = <ls_col>-content. " MD191209 N2350 MOV

          " Konvertierungsfehler zum Feld vorhanden? Dann nicht konvertieren.
          DATA(lt_conversion_errors) = mo_mamba->get_check_errors(
* FT20200402 Note 2453 ROWID_ROW
*                                                                   iv_rowid     = is_data-rowid
                                                                   iv_rowid_row = is_data-rowid
                                                                   iv_element   = COND #( WHEN <ls_col>-element IS NOT INITIAL
                                                                                          THEN <ls_col>-element
                                                                                          ELSE is_data-element )
*                                                                   iv_field     = <ls_col>-fieldname
                                                                   iv_field     = COND #( WHEN <ls_col>-fieldname_dyn IS NOT INITIAL
                                                                                          THEN <ls_col>-fieldname_dyn
                                                                                          ELSE <ls_col>-fieldname ) " FT20210222 Note 3105
*FT20171020 Note 1542 BoI
                                                                   iv_type      = /sct/qp_cx_check=>mc_error_type_conv_in
*FT20171020 Note 1542 EoI
                                                                   iv_source    = /sct/qp_cx_check=>mc_error_source_conversion ).

          IF lt_conversion_errors IS NOT INITIAL.
            " Ein Konvertierungsfehler ist zu diesem ELEMENT aufgetreten.
            " Ohne wiederholte Konvertierung ausgeben

          " **            " seit Note 3105 dyn-Nachkommastellen nicht mehr aktuell:
          " **
          " *** stattdessen Konvertierung nochmal komplett ausführen :
          " *** Wenn die Einheit geändert wurde muss man die Konvertierung nochmal ausführen, es kann sein dass Fehler erzeugt bzw gelöscht werden
          " *** Leider gibt es an dieser Stelle keine Möglichkeit zu wissen dass die Einheit sich geändert hat.
          " **
          " **            do_format_out2db( EXPORTING is_gruelm     = <ls_col>-gruelm->*
          " **                                       is_line       = is_data
          " **                                       iv_fieldname  = CONV #( lv_fieldname )
          " **                                       is_col        = <ls_col>
          " **                             CHANGING  cv_value = lv_value
          " **                                       cv_statelm   = lv_statelm ).
          " **            IF lv_statelm = mc->statelm_f. "Konvert IN war ok.
          " **              do_format_db2out( EXPORTING is_gruelm     = <ls_col>-gruelm->*
          " **                                          is_line       = is_data
          " **                                          iv_fieldname  = lv_fieldname
          " **                                          is_col        = <ls_col>
          " **                                CHANGING  cv_value = lv_value ).
          " **            ENDIF.

          ELSE.
            do_format_db2out( EXPORTING is_gruelm    = <ls_col>-gruelm->*
                                        is_line      = is_data
                                        iv_fieldname = lv_fieldname
                                        is_col       = <ls_col> " FT20210222 Note 3105
                              CHANGING  cv_value     = lv_value ).
          ENDIF.

          <ls_target> = lv_value.
        ELSE. " MD191209 N2350 INS

          <ls_target> = <ls_col>-content.
        ENDIF.
      ENDIF.

      "--------------------------------------------------------------------*
      " KURZTEXT
      "--------------------------------------------------------------------*
      IF <ls_col>-fieldname = mc->fname_value.
        " Kurztext können nur exisiteren wenn VALUE vorhanden ist.
        " Kurztext in cs_outline kopieren
        UNASSIGN <ls_target>.
        IF <ls_col>-element IS INITIAL.
          lv_fname_ktxt = mc->fname_ktxt.
        ELSE.
          " Kurztext zu dynamischen Spalten : KTXT und VALUE teilen sich den gleichen Präfix
          CONCATENATE <ls_col>-fieldname_dyn(3) mc->fname_ktxt INTO lv_fname_ktxt.
        ENDIF.
        ASSIGN COMPONENT lv_fname_ktxt OF STRUCTURE cs_outline TO <ls_target>.

        IF <ls_target> IS ASSIGNED.
          <ls_target> = <ls_col>-ktxt.
        ENDIF.
      ENDIF.

      "--------------------------------------------------------------------*
      " GEN WERT
      "--------------------------------------------------------------------*
      IF <ls_col>-gruelm IS NOT INITIAL.
        CASE <ls_col>-gruelm->techtyp.
          WHEN mc->techtyp_tme.
            " FT20170522 Note 1379 BoD
            "            IF <ls_col>-fieldname IN mo_mamba->mt_value_field.
            " FT20170522 Note 1379 EoD
            UNASSIGN <ls_target>.
            IF <ls_col>-element IS INITIAL.
              CONCATENATE 'GEN_' <ls_col>-fieldname INTO lv_fname_gen.
            ELSE.
              CONCATENATE <ls_col>-fieldname_dyn(3) 'GEN_' <ls_col>-fieldname INTO lv_fname_gen.
            ENDIF.
            ASSIGN COMPONENT lv_fname_gen OF STRUCTURE cs_outline TO <ls_target>.

            IF <ls_target> IS ASSIGNED.
              lv_value = <ls_col>-gen_content.
              " FT20170522 Note 1379 BoI
              IF <ls_col>-fieldname IN mo_mamba->mt_value_field.
                " FT20170522 Note 1379 EoI
                do_format_db2out( EXPORTING is_gruelm    = <ls_col>-gruelm->*
                                            is_line      = is_data
                                            iv_fieldname = lv_fname_gen
                                            is_col       = <ls_col> " FT20210222 Note 3105
                                  CHANGING  cv_value     = lv_value ).
                " FT20170522 Note 1379 BoI
              ENDIF.
              " FT20170522 Note 1379 EoI
              <ls_target> = lv_value.

            ENDIF.
          " FT20170522 Note 1379 BoD
          "            ENDIF.
          " FT20170522 Note 1379 EoD
          WHEN mc->techtyp_pmk.
            " FT20170522 Note 1379 BoD
            "            IF <ls_col>-fieldname IN mo_mamba->mt_value_field.
            " FT20170522 Note 1379 EoD
            UNASSIGN <ls_target>.
            IF <ls_col>-element IS INITIAL.
              CONCATENATE 'GEN' <ls_col>-fieldname INTO lv_fname_gen.
            ELSE.
              CONCATENATE <ls_col>-fieldname_dyn(3) 'GEN' <ls_col>-fieldname INTO lv_fname_gen.
            ENDIF.
            ASSIGN COMPONENT lv_fname_gen OF STRUCTURE cs_outline TO <ls_target>.

            IF <ls_target> IS ASSIGNED.
              lv_value = <ls_col>-gen_content.
              " FT20170522 Note 1379 BoI
              IF <ls_col>-fieldname IN mo_mamba->mt_value_field.
                " FT20170522 Note 1379 EoI
                do_format_db2out( EXPORTING is_gruelm    = <ls_col>-gruelm->*
                                            is_line      = is_data
                                            iv_fieldname = lv_fname_gen
                                            is_col       = <ls_col> " FT20210222 Note 3105
                                  CHANGING  cv_value     = lv_value ).
                " FT20170522 Note 1379 BoI
              ENDIF.
              " FT20170522 Note 1379 EoI
              <ls_target> = lv_value.
            ENDIF.
          " FT20170522 Note 1379 BoD
          "            ENDIF.
          " FT20170522 Note 1379 EoD
          WHEN mc->techtyp_ana.
        ENDCASE.
* FT20170522 Note 1379 BoD
** FT20170412 Note 1310 GENSOLLEXTRANGET nicht befüllt BoI
*      ELSE.
** Spalten ohne GRUELM (z.B Rangetype)
*        UNASSIGN <ls_target>.
*
*        IF <ls_col>-element IS INITIAL.
** TECHM Style
*          CONCATENATE 'GEN_' <ls_col>-fieldname INTO  lv_fname_gen.
*          ASSIGN COMPONENT lv_fname_gen OF STRUCTURE cs_outline TO <ls_target>.
*          IF <ls_target> IS NOT ASSIGNED.
** PMK Style
*            CONCATENATE 'GEN' <ls_col>-fieldname INTO  lv_fname_gen.
*            ASSIGN COMPONENT lv_fname_gen OF STRUCTURE cs_outline TO <ls_target>.
*          ENDIF.
*          IF <ls_target> IS ASSIGNED.
*            <ls_target> = <ls_col>-gen_content.
*          ENDIF.
*        ENDIF.
** FT20170412 Note 1310 GENSOLLEXTRANGET nicht befüllt EoI
* FT20170522 Note 1379 EoD
      ENDIF.

      "--------------------------------------------------------------------*
      " EINHEIT
      "--------------------------------------------------------------------*
      IF <ls_col>-fieldname = mc->fname_value_eih
      OR <ls_col>-fieldname = mc->fname_solleinh
      OR <ls_col>-fieldname = mc->fname_sollinteinh " Note 2463
      OR <ls_col>-fieldname = mc->fname_altzeugeinh. " FT20210622 Note 3143 ALTZEUGEINH
        " Dimension in cs_outline kopieren
        UNASSIGN <ls_target>.
        IF <ls_col>-element IS INITIAL.
          lv_fname_ktxt = mc->fname_dimid.
        ELSE.
          " Kurztext zu dynamischen Spalten : KTXT und VALUE teilen sich den gleichen Präfix
          CONCATENATE <ls_col>-fieldname_dyn(3) mc->fname_dimid INTO lv_fname_ktxt.
        ENDIF.
        IF <ls_col>-gruelm IS BOUND.

          ASSIGN COMPONENT lv_fname_ktxt OF STRUCTURE cs_outline TO <ls_target>.
          IF sy-subrc = 0.
            <ls_target> = <ls_col>-gruelm->dimid.
          ENDIF.
        ENDIF.
        UNASSIGN <ls_target>.
        ASSIGN COMPONENT lv_fieldname OF STRUCTURE cs_outline TO <ls_target>.
        IF <ls_col>-content IS INITIAL.
          CLEAR <ls_target>.
        ELSE.
          lv_value = <ls_col>-content.
* CleanCore : nicht supported
*          DATA(lv_long) = |{ lv_value UNIT = OUT }|.

          SELECT SINGLE UnitOfMeasureLongName,
                        UnitOfMeasureCommercialName
            FROM I_UnitOfMeasureText
            WHERE UnitOfMeasure = @lv_value AND Language = @sy-langu
            INTO ( @DATA(lv_long),
                   @lv_value ).

*          DATA lv_long LIKE lv_value.
*          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT' EXPORTING  input          = lv_value
**                                                                  LANGUAGE       = SY-LANGU
*                                                       IMPORTING  long_text      = lv_long
*                                                                  output         = lv_value
**                                                                  SHORT_TEXT     =
*                                                       EXCEPTIONS unit_not_found = 1
*                                                                  OTHERS         = 2.
*          IF sy-subrc <> 0.
*            " Implement suitable error handling here
*          ENDIF.
          IF lv_long IS NOT INITIAL.
            <ls_target> = |{ lv_long } ({ lv_value })|.
          ELSE.
            <ls_target> = lv_value.
          ENDIF.
        ENDIF.

      ENDIF.
      "--------------------------------------------------------------------*
      " STYLE
      "--------------------------------------------------------------------*
      fill_outline_styles( EXPORTING is_column  = <ls_col>
                           CHANGING  cs_outline = cs_outline ).
    ENDLOOP.
  ENDMETHOD.

  METHOD do_mbaline_to_out.
    " *********************************************************************
    "  Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " ls_data_refpri TYPE /sct/qp_s_mamba,
    DATA ls_mamba TYPE /sct/qp_s_mamba_gui.

    " lv_value       TYPE /sct/qp_value,
    MOVE-CORRESPONDING cs_outline TO ls_mamba.
    CLEAR cs_outline.

    " 1 ) Customizing
    IF is_data-gruelm IS NOT INITIAL. " Neue Zeile ohne ELEMENT -> Customizing nicht unbedingt eingelesen
      MOVE-CORRESPONDING is_data-gruelm->* TO cs_outline.
    ELSE.
      MOVE-CORRESPONDING mo_mamba->ms_node_object TO cs_outline.
      " FT20170210 Icon des Objekttypes nicht übernehmen
      ASSIGN COMPONENT mc->fname_icon OF STRUCTURE cs_outline TO FIELD-SYMBOL(<ls_icon>).
      IF <ls_icon> IS ASSIGNED.
        CLEAR <ls_icon>.
      ENDIF.
    ENDIF.

    " 2 a) Inhalt: flache Struktur
    MOVE-CORRESPONDING is_data TO cs_outline.

    ASSIGN COMPONENT 'MANDATORY-BOOL' OF STRUCTURE cs_outline TO FIELD-SYMBOL(<mandatory>).
    IF sy-subrc = 0.
      <mandatory> = is_data-mandatory.
    ENDIF.

    " FT20170830 Note 1513 BoI
    "*********************************************************************
    " MAINSORT nicht verlieren wenn fruher gesetzt ( nur im View vorhanden )
    "*********************************************************************
    ASSIGN COMPONENT mc->fname_mainsort OF STRUCTURE cs_outline TO FIELD-SYMBOL(<ls_mainsort>).
    IF sy-subrc = 0 AND ls_mamba-mainsort IS NOT INITIAL.
      <ls_mainsort> = ls_mamba-mainsort.
    ENDIF.

    " Initialbefüllung valuestate/textalign
    FIELD-SYMBOLS <ls_uiattr> TYPE /sct/qp_if_fcat=>ty_s_ui_attr.
    LOOP AT mo_mamba->mt_tspalt ASSIGNING FIELD-SYMBOL(<ls_tspalt>).
      IF <ls_tspalt>-element IS NOT INITIAL.
        DATA(ls_col) = VALUE #( is_data-col[ element = <ls_tspalt>-element ] OPTIONAL ).
      ELSE.
        CLEAR ls_col.
      ENDIF.
      UNASSIGN <ls_uiattr>.

      IF ls_col-fieldname_dyn IS NOT INITIAL.
        ASSIGN COMPONENT |{ ls_col-fieldname_dyn(3) }{ <ls_tspalt>-feldname }_UIATTR| OF STRUCTURE cs_outline TO <ls_uiattr>.
      ELSE.
        ASSIGN COMPONENT |{ <ls_tspalt>-feldname }_UIATTR| OF STRUCTURE cs_outline TO <ls_uiattr>.
      ENDIF.
      IF <ls_uiattr> IS ASSIGNED.
        <ls_uiattr>-valuestate = 'None'.
        <ls_uiattr>-textalign  = 'Begin'.
        " Wenn kein Datensatz in is_data-col vorhanden ist (dort könnte die Editierbarkeit anders gesetzt sein)
        " Dan die Editierbarkeit der Spaltengruppe übernehmen
        IF NOT line_exists( is_data-col[ element   = <ls_tspalt>-element
                                         fieldname = <ls_tspalt>-feldname ] ).
          <ls_uiattr>-edit = <ls_tspalt>-edit.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " 2 b) Inhalt: subtabelle
    " Nur falls das Element befüllt ist muss man die Subtabelle aufbauen
    " und die Eingabebereitschaft setzten
    " Im Fall eine neue Zeile ohne Element muss nur das Element eingabebereit sein
    IF is_data-gruelm IS NOT INITIAL.
      do_mbacol_to_out( EXPORTING is_data    = is_data
                        CHANGING  cs_outline = cs_outline ).
    ENDIF.

    " Relattypicon.
    UNASSIGN <ls_icon>.
    ASSIGN COMPONENT mc->fname_relattypicon OF STRUCTURE cs_outline TO <ls_icon>.
    IF <ls_icon> IS ASSIGNED.
      <ls_icon> = get_relattyp_icon( is_data ).
    ENDIF.

    " Editierbarkeit der Zeile:
    " GUID = Knoten-GUID -> Ja
    " GUID <> Knoten-GUID -> Nein

    " Editierbarkeit/ Zellen:
    " VALUE abhängig vom Typ ( TECHM )
    " PMK ??? QUAN/QUAL

    " Zeilenfarbe
    " Rot = Gelöscht
    " Grün = SekRef

    " Links
    " Suchhilfe
    " checkbox
    " Hotspot
    " usw

    " **    ASSIGN COMPONENT mc->fname_xyzstylezyx OF STRUCTURE cs_outline TO <ls_cellstyles>.
    " **    ASSERT sy-subrc = 0.
    " **
    " **    ASSIGN COMPONENT mc->fname_rowcolor OF STRUCTURE cs_outline TO FIELD-SYMBOL(<ls_rowcolor>).
    " **    ASSERT sy-subrc = 0.
    " **
    " **    " FT, 2019.08.12: N2380, BoI Bei TOE-Context => Element = Hotspot
    " **    IF is_data-gruelm IS NOT INITIAL.
    " **
    " **      IF is_data-gruelm->tobel IS BOUND.
    " **        IF is_data-gruelm->tobel->toecontext IS NOT INITIAL.
    " **          DATA(lv_hotspot) = abap_true.
    " **        ELSE.
    " **          lv_hotspot = abap_false.
    " **        ENDIF.
    " **      ENDIF.
    " **
    " **      IF is_data-gruelm->tobelgen IS BOUND AND lv_hotspot = abap_false.
    " **        IF is_data-gruelm->tobelgen->toecontext IS NOT INITIAL.
    " **          lv_hotspot = abap_true.
    " **        ELSE.
    " **          lv_hotspot = abap_false.
    " **        ENDIF.
    " **      ENDIF.

    ##PRIMKEY
    " **      READ TABLE mo_mamba->mt_tspalt INTO DATA(ls_elem)
    " **           WITH KEY spaltengruppe = mo_mamba->ms_node_object-spaltengruppe
    " **                    element       = space
    " **                    feldname      = mc->fname_element.
    " **
    " **      INSERT me->get_style_from_mbacol( is_data   = is_data
    " **                                        is_column = VALUE #( fieldname = mc->fname_element
    " **                                                             edit      = ls_elem-edit ) ) INTO TABLE <ls_cellstyles>.
    " **
    " **      set_hotspot( EXPORTING iv_fieldname = mc->fname_element
    " **                             iv_value     = lv_hotspot
    " **                   CHANGING  ct_style     = <ls_cellstyles> ).
    " **      set_hotspot( EXPORTING iv_fieldname = mc->fname_elementtext
    " **                             iv_value     = lv_hotspot
    " **                   CHANGING  ct_style     = <ls_cellstyles> ).

    " **    ENDIF.
    " FT, 2019.08.12: N2380, EoI

    " FT20171219 Note 1689 Submethode angelegt BoC
    " Eingabebereitschaft
    " **    set_line_editabilty( EXPORTING is_data      = is_data
    " **                         CHANGING  ct_cellstyle = <ls_cellstyles> ).
    " FT20171219 Note 1689 Submethode angelegt EoC

    " FT20170713 Note 1463 - submethode angelegt BoC
    " Farbliche Kennzeichnung der Zeile
    " **    <ls_rowcolor> = get_line_color( is_data ).
    " FT20170713 Note 1463 - submethode angelegt EoC

    IF sy-uname = 'TROMFRA'.
      DATA(lt_comp) = mo_tools->get_struct_comp( is_data = cs_outline ).

      DELETE lt_comp WHERE name NP '*UIATTR*'.

      LOOP AT lt_comp ASSIGNING FIELD-SYMBOL(<comp>).

        ASSIGN COMPONENT |{ <comp>-name }-TEXTALIGN| OF STRUCTURE cs_outline TO FIELD-SYMBOL(<data>).
        IF sy-subrc = 0 AND <data> IS INITIAL.
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(fehlt) = 'x'.
        ENDIF.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD fill_outline_styles.
    FIELD-SYMBOLS <attr> TYPE /sct/qp_if_fcat=>ty_s_ui_attr.

    ASSIGN COMPONENT |{ COND #( WHEN is_column-fieldname_dyn IS INITIAL
                                THEN is_column-fieldname
                                ELSE is_column-fieldname_dyn ) }_UIATTR| OF STRUCTURE cs_outline TO <attr>.
    IF <attr> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    get_field_style( EXPORTING is_column = is_column
                     CHANGING  cs_attr   = <attr> ).
  ENDMETHOD.

  METHOD get_col_unit.
    " *********************************************************************
    " Einheit zu Wertefeld
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20210222 Note 3105 angelegt
    " --------------------------------------------------------------------*

    " In welchem Feld befindet sich die Einheit zum Wert in ir_col ?

    " Für VAL, immer in VALUE_EIH es sei denn, das Feld ist nicht in ir_line->col, dann
    " gruelm->default_eih übernehmen.

    "  Für PMK :
    "  SOLLINT* -> SOLLINTEINH
    "  SOLLEXT* -> SOLLEINH
    "  ALTSOLL* -> ALTZEUGEINH
    " es sei denn, das Feld ist nicht in ir_line-col, dann gruelm->default_eih übernehmen.

    IF is_col-gruelm IS NOT BOUND. " Nur für Wertefelder
      RETURN.
    ENDIF.

    DATA(lv_length) = strlen( is_col-fieldname ).

    IF lv_length >= 5 AND is_col-fieldname(5) = mc->fname_value.
      DATA(lv_fname_eih) = mc->fname_value_eih.
    ELSEIF lv_length >= 7 AND is_col-fieldname(7) = 'SOLLINT'.
      lv_fname_eih = mc->fname_sollinteinh.
    ELSEIF lv_length >= 7 AND is_col-fieldname(7) = 'SOLLEXT'.
      lv_fname_eih = mc->fname_solleinh.
    ELSEIF lv_length >= 7 AND is_col-fieldname(7) = 'ALTSOLL'.
      lv_fname_eih = mc->fname_altzeugeinh.
    ENDIF.

    IF lv_fname_eih IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE is_line-col REFERENCE INTO DATA(lr_col)
         WITH KEY element   = is_col-element
                  fieldname = lv_fname_eih.
    IF sy-subrc = 0.
      rv_unit = lr_col->content.
    ELSE.
      rv_unit = is_col-gruelm->dflt_einheit.
    ENDIF.
  ENDMETHOD.

  METHOD get_relattyp_icon.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    IF line_exists( mo_mamba->mt_data[ KEY prowid
                                       prowid   = is_data-rowid
                                       relattyp = mc->relattyp_refpri ] ).
      " PrimärReferenz vorhanden
      IF line_exists( mo_mamba->mt_data[ KEY prowid
                                         prowid   = is_data-rowid
                                         relattyp = mc->relattyp_refsek ] ).
        " Primär und sekRef vorhanden
        DATA(lv_ref) = mc->relattyp_refsek.

      ELSE.
        " Nur Primär vorhanden
        lv_ref = mc->relattyp_refpri.
      ENDIF.
    ELSE.
      " Keine Primärreferenz und keine Sekundärreferenz vorhanden
      CLEAR lv_ref.
    ENDIF.

    CASE is_data-relattyp.
      "     Eigener Knoten ist eine Sekundärreferenz
      WHEN mc->relattyp_refsek.
        " Egal wie MODEREF / MANU sind, es ist immer das gleiche ICON
        rv_relattypicon = 'sap-icon://chain-link'. " icon_wd_navigation_link.

      "     Eigener Knoten ist ein originaler Knoten oder eine Primärreferenz
      WHEN mc->relattyp_original
        OR mc->relattyp_refpri
        OR mc->relattyp_space.

        " Welches MODEREF?
        CASE is_data-moderef.
          " Eingefügt (I)
          " oder generierten Wert geändert (C)
          " oder referenzierten Wert geändert (C)
          WHEN mc->moderef_i
            OR mc->moderef_c.

            " Manuell geändert?
            IF is_data-manu = mc->x.
              " Manuell geändert bekommt immer ICON_CHANGE
              rv_relattypicon = 'sap-icon://write-new-document'. " icon_change.
            ELSE.
              " Nicht manuell geändert.
              CASE lv_ref.
                WHEN space.
                  " Keine Referenz vorhanden
                  IF is_data-moderef = mc->moderef_i.
*                    rv_relattypicon = 'sap-icon://document'. " icon_create.
                  ELSE.
                    rv_relattypicon = 'sap-icon://write-new-document'. " icon_change.
                  ENDIF.
                WHEN mc->relattyp_refpri.
                  " An dem originalen Knoten oder an der Primärreferenz hängt wiederum eine Primärreferenz
                  rv_relattypicon = 'sap-icon://chain-link'. " icon_wf_link.
                WHEN mc->relattyp_refsek.
                  " An dem originalen Knoten oder an der Primärreferenz hängt wiederum eine Sekundärreferenz
                  rv_relattypicon = 'sap-icon://BusinessSuiteInAppSymbols/icon-empty-sequence'. " icon_ppe_assy_head.
              ENDCASE.
            ENDIF.

          WHEN mc->moderef_g.
            IF is_data-manu = mc->x.
              rv_relattypicon = 'sap-icon://write-new-document'. " icon_change.
            ELSE.
              rv_relattypicon = 'sap-icon://SAP-icons-TNT/ai-1'. " icon_generate.
            ENDIF.
          WHEN mc->moderef_d.
            rv_relattypicon = 'sap-icon://delete'. " icon_delete.
        ENDCASE.

    ENDCASE.

    " icon_create Dokument: 📄
    " icon_change Bleistift: ✏️
    " icon_wf_link Kettensymbol : 🔗
    " icon_wd_navigation_link Verhakte Büroklammern: 🖇️
    " icon_delete Kübel: 🗑️

    IF iv_as_emoji = abap_true.
      CASE rv_relattypicon.
        WHEN 'sap-icon://document'.
          rv_relattypicon = '📄'.
        WHEN 'sap-icon://write-new-document'.
          rv_relattypicon = '✏️'.
        WHEN 'sap-icon://delete'.
          rv_relattypicon = '🗑'.
        WHEN 'sap-icon://SAP-icons-TNT/ai-1'.
          rv_relattypicon = '✨'.
        WHEN 'sap-icon://BusinessSuiteInAppSymbols/icon-empty-sequence'.
          rv_relattypicon = '🖇'.
        WHEN 'sap-icon://chain-link'.
          rv_relattypicon = '🔗'.

        WHEN OTHERS.
          CLEAR rv_relattypicon.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD get_field_style.
    cs_attr-valuestate   = 'None'. " Nicht Fehlerhaft
    cs_attr-textalign    = 'Begin'.
    cs_attr-jump         = abap_false.
    cs_attr-multi_input  = abap_false.
    cs_attr-dats_vis     = abap_false.
    cs_attr-dats_not_vis = abap_true.

    " Fname_Rangetype hinzugefügt
    IF is_column-fieldname = mc->fname_value
    OR is_column-fieldname = mc->fname_value_min
    OR is_column-fieldname = mc->fname_value_max
    OR is_column-fieldname = mc->fname_rangetype
    OR is_column-fieldname = mc->fname_value_eih
    OR is_column-fieldname = mc->fname_katalgart1
    OR is_column-fieldname = mc->fname_auswmenge1
    OR is_column-fieldname = mc->fname_auswmgwrk1
    OR is_column-fieldname = mc->fname_auswvers1
    OR is_column-fieldname = mc->fname_sollintuntmin
    OR is_column-fieldname = mc->fname_sollintunt
    OR is_column-fieldname = mc->fname_sollintnennwert
    OR is_column-fieldname = mc->fname_sollintobe
    OR is_column-fieldname = mc->fname_sollintobemax
    OR is_column-fieldname = mc->fname_sollintranget
    OR is_column-fieldname = mc->fname_sollintplranget
    OR is_column-fieldname = mc->fname_sollinteinh
    OR is_column-fieldname = mc->fname_sollextuntmin
    OR is_column-fieldname = mc->fname_sollextunt
    OR is_column-fieldname = mc->fname_sollextnennwert
    OR is_column-fieldname = mc->fname_sollextobe
    OR is_column-fieldname = mc->fname_sollextobemax
    OR is_column-fieldname = mc->fname_sollextranget
    OR is_column-fieldname = mc->fname_sollextplranget
    OR is_column-fieldname = mc->fname_solleinh
    OR is_column-fieldname = mc->fname_altsollzeugunt
    OR is_column-fieldname = mc->fname_altsollnennwert
    OR is_column-fieldname = mc->fname_altsollzeugobe
    OR is_column-fieldname = mc->fname_altzeugranget
    OR is_column-fieldname = mc->fname_altzeugeinh
    OR is_column-fieldname = mc->fname_nkom.
      " Feld eingabebereit?
      IF  is_column-edit                                        = abap_true
      AND is_fname_editable_elemformat( is_column = is_column ) = abap_true.
        cs_attr-edit = abap_true.
      ENDIF.

    ELSEIF is_column-fieldname CS mc->fname_langtext. " FT20191021 Note 2274
    " ** TODO
    " **      DATA lv_style_ltxt LIKE LINE OF lt_styles.
    " **
    " **      IF is_column-gruelm->langtext = abap_true.
    " **        lv_style_enabled = cl_gui_alv_grid=>mc_style_enabled.
    " **        lv_style_ltxt    = cl_gui_alv_grid=>mc_style_button.
    " **      ENDIF.
    " **
    " **      APPEND lv_style_ltxt TO lt_styles.

    ELSE.
      " Andere Felder laut Spaltengruppe

      IF is_column-edit = mc->x.
        cs_attr-edit = abap_true.
      ELSE.
        cs_attr-edit = abap_false.
      ENDIF.
    ENDIF.

    " FT20170705 Note 1441 Anzeige Checkbox BoI
    IF  is_column-fieldname    = mc->fname_rangetype
* FT20240612 NOTE-3576 N1916 zurück, anders gelöst
    AND is_column-gruelm      IS BOUND
    AND is_column-gruelm->typ  = mc->outtab_typ_o.
      " Range nur für Typ N und M
      cs_attr-edit = abap_true.
    ENDIF.

    IF is_column-fieldname = mc->fname_genrule
    OR is_column-fieldname = mc->fname_conrule.
*** TODO
**      ev_style4 = cl_gui_alv_grid=>mc_style4_link.
    ENDIF.

    IF is_column-gruelm IS BOUND.
      " FT20160112 : Nur für Wert-Spalten

      " FT20170523 Note 1383 BoI Suchhilfe für TME-Dyn kommt nicht
      DATA(lv_fieldname) = is_column-fieldname.
      IF is_column-fieldname_dyn IS NOT INITIAL.
        lv_fieldname = is_column-fieldname_dyn.
      ENDIF.

*      IF is_column-fieldname IN mo_mamba->mt_value_field.
      IF lv_fieldname IN mo_mamba->mt_value_field.

        IF is_column-gruelm->tobjel = 'AVATAR'.
          cs_attr-avatar = abap_true.
        ENDIF.
        " FT20170523 Note 1383 EoI Suchhilfe für TME-Dyn kommt nicht

        "*********************************************************************
        "   Search Help Display

        IF  is_column-gruelm->tobjel IS NOT INITIAL AND is_column-gruelm->shlp IS NOT INITIAL
        AND cs_attr-edit              = abap_true.
          cs_attr-f4 = abap_true.
          IF is_column-gruelm->multielem IS NOT INITIAL AND mo_mamba->ms_node_object-elementgrp_sp IS INITIAL.
            " Mehrfachbewertetet Elementen ->multi_input
            cs_attr-multi_input = abap_true.
*            IF is_column-content IS NOT INITIAL. "Ein Token je Zeile wird erzeugt.
            " Die Tokens werden in get_objtyp_data anschließend gesammelt
*              cs_attr-token       = VALUE #( ( key      = is_column-content
*                                               text     = COND #( WHEN is_column-ktxt IS INITIAL
*                                                                  THEN is_column-content
*                                                                  ELSE is_column-ktxt )
*                                               visible  = abap_true
*                                               editable = abap_true ) ).
*            ENDIF.
          ENDIF.
        ELSE.
          cs_attr-f4 = abap_false.
        ENDIF.

        cs_attr-cvtyp = is_column-gruelm->cvtyp.
        IF cs_attr-cvtyp = mc->cvtyp_dats.
          cs_attr-dats_vis     = abap_true.
          cs_attr-dats_not_vis = abap_false.
        ELSE.
          cs_attr-dats_vis     = abap_false.
          cs_attr-dats_not_vis = abap_true.
        ENDIF.

        "*********************************************************************
        "   Hotspot Display
        " ** TODO
        " **        IF is_column-gruelm->tobjel IS NOT INITIAL AND is_column-gruelm->jump IS NOT INITIAL.
        " **          lv_style_link = cl_gui_alv_grid=>mc_style4_link.
        " **
        " **        ELSE.
        " **          lv_style_link = cl_gui_alv_grid=>mc_style4_link_no.
        " **        ENDIF.

        CASE is_column-gruelm->cvtyp.
          WHEN mc->cvtyp_bool.
            cs_attr-textalign = 'Center'.
            cs_attr-f4        = xsdbool( is_column-content IS NOT INITIAL ).
          WHEN mc->cvtyp_fltp.
            cs_attr-textalign = 'End'.
        ENDCASE.
        " FT20231128 Status bitte zentriert darstellen
        " ** TODO
        IF is_column-gruelm->convmeth = 'STATUSICON'
        OR ( is_column-gruelm->convert IS BOUND AND is_column-gruelm->convert->convexit = mc->convexit-status_icon ).
          cs_attr-textalign = 'Center'.
        ENDIF.

      ENDIF.
      " FT20170419 Note 1318 EoI

      "*********************************************************************
      " Suchhilfe für die Einheit
      IF is_column-fieldname = mc->fname_value_eih
      OR is_column-fieldname = mc->fname_solleinh
      OR is_column-fieldname = mc->fname_sollinteinh " Note 2463
      OR is_column-fieldname = mc->fname_altzeugeinh. " HWP 2020.11.30, Note 3061
        cs_attr-f4 = abap_true.
      ENDIF.

      IF is_column-gruelm->jump IS NOT INITIAL.
        mo_cust->get_tjump( EXPORTING iv_jump  = is_column-gruelm->jump
                            IMPORTING es_tjump = DATA(ls_tjump) ).
        IF ls_tjump-fm = '/SCT/QP_DO_JUMP_NODE'.
          cs_attr-jump = abap_true.
        ENDIF.
      ENDIF.

    ENDIF. " gruelm bound

    IF is_column-fieldname = mc->fname_element.
      cs_attr-f4 = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD is_fname_editable_elemformat.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2018.03.12, NOTE 1788, angelegt
    " --------------------------------------------------------------------*
    " AD, 2019.09.20, NOTE 2250
    " Erweiterung Eindeutigkeitsprüfung "Mehrfach bewertbar (mit Konditionen)"
    " --------------------------------------------------------------------*
    " FT20200515 Note 2470 Einheit editierbar ohne Dimension
    " --------------------------------------------------------------------*
    " NS, 2020.08.07, Note 2519
    " Mamba: Editierbarkeit von Feldern auf Grundlage von Element Customizing
    " Für das Feld Einheit wird überprüft ob eine Dimension oder default Einheit existiert.
    " Falls das der Fall ist, ist das Einheitenfeld editierbar.
    " Außerdem werden jetzt Felder bei PMK je nach PMKTYP (QUAN/QUAL) auf editierbar gesetzt.
    " --------------------------------------------------------------------*
    " NS, 2020.09.25, Note 3010
    " Folgend auf die Note 2519 muss nochmal das Editieren der Felder je nach PMKTYP
    " angepasst werden. Der Katalog soll bei Qualitativ und nicht bei Quantitativ
    " editierbar sein.
    " ES, 29.09.2020 Methode immer noch Fehlerhaft. zukompliziert alle
    " IF-Bedinungen nachzuvollziehen. Deshalb komplett neu Strukturiert
    " --------------------------------------------------------------------*
    " FT20210319 : Anhand vom Typ ist jetzt auch die Editibarkeit für
    " PMK Werte Felder eingeschräkt worden (analog zu TME)
    " Die Nenn-Spalte eine Min/Max-Elementes wird nicht eingabebereit sein
    " --------------------------------------------------------------------*
    " ES20231102 NOTE-3480
    " MAMBA Editierbarkeit bei /SCT/QP_VAL Feld Rangetype nicht korrekt
    " --------------------------------------------------------------------*
    IF is_column-gruelm IS NOT BOUND.
      RETURN.
    ENDIF.

    " Gilt nur TME
    CASE is_column-gruelm->techtyp.

      WHEN mc->techtyp_tme.
        CASE is_column-fieldname. " Feldname
          WHEN mc->fname_value. " Nominalwert
            CASE is_column-gruelm->typ.
              WHEN mc->outtab_typ_n OR mc->outtab_typ_o.
                rv_editable = abap_true.
            ENDCASE.
          WHEN mc->fname_value_min. " Min-Wert
            CASE is_column-gruelm->typ.
              WHEN mc->outtab_typ_n OR mc->outtab_typ_m OR mc->outtab_typ_min.
                rv_editable = abap_true.
            ENDCASE.
          WHEN mc->fname_value_max. " Max-Wert
            CASE is_column-gruelm->typ.
              WHEN mc->outtab_typ_n OR mc->outtab_typ_m OR mc->outtab_typ_max.
                rv_editable = abap_true.
            ENDCASE.
          WHEN mc->fname_rangetype. " Intervall Kennzeichen  ES20231102 NOTE-3480
            CASE is_column-gruelm->typ.
              WHEN mc->outtab_typ_n OR mc->outtab_typ_m OR mc->outtab_typ_min OR mc->outtab_typ_max.
                rv_editable = abap_true.
            ENDCASE.
          WHEN mc->fname_value_eih. " Einheit
            IF is_column-gruelm->dimid IS NOT INITIAL OR is_column-gruelm->dflt_einheit IS NOT INITIAL.
              rv_editable = abap_true.
            ENDIF.
        ENDCASE. " Ende Feldname

      WHEN mc->techtyp_pmk. " Techtyp PMK
        CASE is_column-gruelm->pmktyp. " Prüfmerkmale
          WHEN mc->pmktyp_qual.       " Qualitatives Prüfmerkmal
            CASE is_column-fieldname. " Feldname
              WHEN mc->fname_auswmenge1
                OR mc->fname_auswmgwrk1
                OR mc->fname_auswvers1
                OR mc->fname_katalgart1.
                rv_editable = abap_true.
            ENDCASE.                  " Ende Feldname
          WHEN mc->pmktyp_quan. " Quantative Merkmale
            CASE is_column-fieldname. " Feldname
              WHEN mc->fname_sollintuntmin
                OR mc->fname_sollintunt
                OR mc->fname_sollintnennwert
                OR mc->fname_sollintobe
                OR mc->fname_sollintobemax
                OR mc->fname_sollintranget
                OR mc->fname_sollintplranget
                OR mc->fname_sollinteinh
                OR mc->fname_sollextuntmin
                OR mc->fname_sollextunt
                OR mc->fname_sollextnennwert
                OR mc->fname_sollextobe
                OR mc->fname_sollextobemax
                OR mc->fname_sollextranget
                OR mc->fname_sollextplranget
                OR mc->fname_solleinh
                OR mc->fname_altsollzeugunt
                OR mc->fname_altsollnennwert
                OR mc->fname_altsollzeugobe
                OR mc->fname_altzeugranget " ES20231102 NOTE-3480
                OR mc->fname_altzeugeinh
                OR mc->fname_nkom.
                rv_editable = abap_true.

                " FT20210319 Note 3010 BoI
                " Einschränkung der Editierbarkeit je Typ, analog zu TME
                CASE is_column-gruelm->typ.
                  WHEN mc->outtab_typ_nenn.
                    IF is_column-fieldname CS 'UNT' OR is_column-fieldname CS 'OBE'.
                      rv_editable = abap_false.
                    ENDIF.
                  WHEN mc->outtab_typ_minmax.
                    IF is_column-fieldname CS 'NENN'.
                      rv_editable = abap_false.
                    ENDIF.
                  WHEN mc->outtab_typ_min.
                    IF is_column-fieldname CS 'NENN' OR is_column-fieldname CS 'OBE'.
                      rv_editable = abap_false.
                    ENDIF.
                  WHEN mc->outtab_typ_max.
                    IF is_column-fieldname CS 'UNT' OR is_column-fieldname CS 'NENN'.
                      rv_editable = abap_false.
                    ENDIF.
                ENDCASE.
                " FT20210319 Note 3010 EoI

            ENDCASE. " Ende Feldname

          WHEN OTHERS.
            rv_editable = abap_true.
        ENDCASE.
      WHEN OTHERS.
        rv_editable = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD process_fcode_self.
    rv_processed = process_event( is_get ).

    " FT zum Testen BAUM immer aktualisiern (statusänderung)
*    IF rv_processed = abap_true.
*      ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-nav_list_refresh )
*                                          io_client = ms_control-client ).
*
*    ENDIF.
  ENDMETHOD.

  METHOD get_changes.
    " *********************************************************************
    " Sammeln der GUI-Änderungen
    " *********************************************************************

    DATA ls_column TYPE /sct/qp_s_mamba_cell_chg.

    FIELD-SYMBOLS <ls_col>       TYPE LINE OF /sct/qp_s_mamba-col.
    FIELD-SYMBOLS <lv_field>     TYPE any.
    FIELD-SYMBOLS <ls_uiattr>    TYPE /sct/qp_if_fcat=>ty_s_ui_attr.
    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    FIELD-SYMBOLS <lt_token_old> TYPE /sct/qp_if_fcat=>ty_s_ui_attr-token.

    FIELD-SYMBOLS <lt_old>       TYPE STANDARD TABLE.

    ASSIGN mr_data_saved->* TO <lt_old>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    IF <lt_old> = ms_fcat-data->*. " Die Tabellen sind unterschiedlich, Daten sind erfasst worden
      RETURN.
    ENDIF. " Tabellen unterschiedlich

    LOOP AT ms_fcat-data->* ASSIGNING FIELD-SYMBOL(<ls_new>).
      ASSIGN <lt_old>[ sy-tabix ] TO FIELD-SYMBOL(<ls_old>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF <ls_new> = <ls_old>. " Die Zeilen sind unterschiedlich
        CONTINUE.
      ENDIF. " Zeile geändert

      ASSIGN COMPONENT 'ROWID' OF STRUCTURE <ls_old> TO FIELD-SYMBOL(<rowid>).
      DATA(lr_line) = mo_mamba->get_lineref_via_id( <rowid> ).

      INSERT VALUE #( rowid = <rowid> ) INTO TABLE rt_changes ASSIGNING FIELD-SYMBOL(<changes>).
      LOOP AT ms_fcat-fieldcat ASSIGNING FIELD-SYMBOL(<ls_fcat>) WHERE edit = abap_true.
        ASSIGN COMPONENT <ls_fcat>-fieldname OF STRUCTURE <ls_old> TO FIELD-SYMBOL(<lv_old>).
        ASSIGN COMPONENT <ls_fcat>-fieldname OF STRUCTURE <ls_new> TO FIELD-SYMBOL(<lv_new>).
        ASSIGN COMPONENT |{ <ls_fcat>-fieldname }_UIATTR| OF STRUCTURE <ls_new> TO <ls_uiattr>.
        IF <ls_uiattr> IS ASSIGNED AND <ls_uiattr>-cvtyp = mc->cvtyp_bool.
          DATA(lv_bool) = abap_true.
        ELSE.
          lv_bool = abap_false.
        ENDIF.

        IF <ls_uiattr> IS ASSIGNED AND <ls_uiattr>-multi_input IS NOT INITIAL.
          DATA(lv_multi) = abap_true.
        ELSE.
          lv_multi = abap_false.
        ENDIF.

        IF <lv_new> = <lv_old> AND lv_bool = abap_false AND lv_multi = abap_false. " Die Felder sind unterschiedlich
          CONTINUE.
        ENDIF.
        " Fehler zurücksetzen
        <ls_uiattr>-valuestate = 'None'. " Nicht Fehlerhaft
        CLEAR <ls_uiattr>-valuestatetext.

        " Mehrfachbewertung.
        IF lv_multi = abap_true.
          ASSIGN COMPONENT |{ <ls_fcat>-fieldname }_UIATTR-TOKEN| OF STRUCTURE <ls_old> TO <lt_token_old>.
*          IF <ls_uiattr>-token <> <lt_token_old>.

          IF <ls_uiattr>-token_del IS NOT INITIAL.
            LOOP AT <ls_uiattr>-token_del ASSIGNING FIELD-SYMBOL(<del>).
              LOOP AT mo_mamba->mt_data ASSIGNING FIELD-SYMBOL(<data>)
                   WHERE element = <ls_new>-('element').

                IF <data>-col[ fieldname = mc->fname_value ]-content = <del>-key.
                  DATA(lr_del) = REF #( <data> ).
                  EXIT.
                ENDIF.
              ENDLOOP.
              IF lr_del IS BOUND.
                ASSIGN rt_changes[ rowid = lr_del->rowid ] TO FIELD-SYMBOL(<to_delete>).
                IF <to_delete> IS ASSIGNED.
                  <to_delete>-rowdel = abap_true.
                  ms_obj-must_redraw = abap_true. " Wenn eine aktuell sichtbare Zeile eines mehrfachbewerteten Elementes gelöscht wird,
                " Soll dann eine andere Element-Zeile angezeigt werden -> Redraw notwendig.
                ELSE.
                  INSERT VALUE #( rowid  = lr_del->rowid
                                  rowdel = abap_true ) INTO TABLE rt_changes.
                ENDIF.
              ENDIF.
              CLEAR lr_del.
            ENDLOOP.
            CLEAR <ls_uiattr>-token_del.
          ELSEIF <ls_uiattr>-token_add IS NOT INITIAL.
            " Aus einer Suchhilfe wird token_add direkt befüllt.
            DATA(lr_source) = mo_mamba->get_lineref_via_id( iv_rowid = <rowid> ).

            LOOP AT <ls_uiattr>-token_add ASSIGNING FIELD-SYMBOL(<add>).
              DATA(lr_new_line) = mo_mamba->mo_line->copy( lr_source ). " Hier wirde lediglich eine Kopie erstellt ( dies erzeugt ggft Fehler in Mamba )

              CLEAR ls_column.

              DATA(lv_val) = CONV /sct/qp_value( <add>-key ).
              IF <ls_fcat>-fieldname IN mo_mamba->mt_value_field.
                do_format_out2db( EXPORTING is_gruelm    = lr_new_line->gruelm->*
                                            is_line      = lr_new_line->*
                                            iv_fieldname = CONV #( <ls_fcat>-fieldname )
*                                            is_col       = <ls_col> " FT20210222 Note 3105
                                  CHANGING  cv_value     = lv_val
                                            cv_statelm   = ls_column-statelm ).

              ENDIF.
              INSERT VALUE #( rowid = lr_new_line->rowid ) INTO TABLE rt_changes ASSIGNING FIELD-SYMBOL(<multi_changes>).
              ls_column-element   = lr_new_line->element.
              ls_column-fieldname = <ls_fcat>-fieldname.
              ls_column-manu      = abap_true.
              ls_column-input     = <add>-key.
              ls_column-content   = lv_val.
              INSERT ls_column INTO TABLE <multi_changes>-column. " Anschließend werden die Änderungen gesammelt zur spätere Prozessierung

            ENDLOOP.
            CLEAR <ls_uiattr>-token_add.
          ENDIF.
          CONTINUE.
        ENDIF.

        IF lr_line IS INITIAL.
          ASSIGN mo_mamba->ms_init-col[ element   = space
                                        fieldname = <ls_fcat>-fieldname ] TO <ls_col>.
        ELSE.
          " Die Zeile existiert bereits ins Model. Hier ist das Customizing in <ls_col> auch gepflegt
          ASSIGN lr_line->col[ element   = space
                               fieldname = <ls_fcat>-fieldname ] TO <ls_col>.
        ENDIF.

        IF sy-subrc = 0.
          " Im Fall von normalen Spalten, Element immer leer, Feldname = Feldname aus der View
          IF <ls_col>-gruelm IS NOT INITIAL.
            DATA(lv_element) = <ls_col>-gruelm->element.
          ELSE.
            lv_element = space.
          ENDIF.
          DATA(lv_fieldname) = <ls_fcat>-fieldname.
        ELSE.
          " Im Fall von dyn. Spalten muss aus "fieldname_dyn"  der vollständige Key der Spalten (Element+Feldname) ermittelt werden
          READ TABLE mo_mamba->ms_init-col ASSIGNING <ls_col>
               WITH KEY field_dyn COMPONENTS fieldname_dyn = <ls_fcat>-fieldname.
          IF sy-subrc = 0.
            lv_element = <ls_col>-element.
            lv_fieldname = <ls_col>-fieldname.
          ELSE.
            UNASSIGN <lv_field>.
            ASSIGN COMPONENT <ls_fcat>-fieldname OF STRUCTURE mo_mamba->ms_init TO <lv_field>.
            IF <lv_field> IS ASSIGNED.
              lv_element = space.
              lv_fieldname = <ls_fcat>-fieldname.
            ELSE.
*          mo_tools->do_breakpoint( ).
              " Wenn eine neue Zeile hinzugefügt wird,
              " enthält er_data_changed->mt_mod_cells auch Zellen die in der Mamba Struktur nicht verfügbar sind,
              " aber nur in view, z.B expander: diese Änderungen kann man vergessern
              CONTINUE.
            ENDIF.

          ENDIF.
        ENDIF.
        CLEAR ls_column.

        DATA(lv_value) = CONV /sct/qp_value( <lv_new> ).
        IF lv_bool = abap_true.
          lv_value = <ls_uiattr>-f4.
        ENDIF.
        IF <ls_fcat>-fieldname IN mo_mamba->mt_value_field.
          IF <ls_col>-gruelm IS BOUND AND lr_line IS BOUND. " FT20251203 TODO Nicht sauber !! Die Zeile existiert zwar noch nicht, ELEMENT und GRUELM müssten ja bekannt sein
            do_format_out2db( EXPORTING is_gruelm    = <ls_col>-gruelm->*
                                        is_line      = lr_line->*
                                        iv_fieldname = CONV #( <ls_fcat>-fieldname )
                                        is_col       = <ls_col> " FT20210222 Note 3105
                              CHANGING  cv_value     = lv_value
                                        cv_statelm   = ls_column-statelm ).

          ENDIF.
        ENDIF.

        ls_column-element   = lv_element.
        ls_column-fieldname = lv_fieldname.
        ls_column-manu      = abap_true.
        ls_column-input     = <lv_new>.
        ls_column-content   = lv_value.
        INSERT ls_column INTO TABLE <changes>-column.
      ENDLOOP.

    ENDLOOP. " aktuelle Daten

    DELETE rt_changes WHERE rowdel IS INITIAL AND column IS INITIAL AND valt IS INITIAL.
  ENDMETHOD.

  METHOD set_toolbar.
*    io_view->title( 'Toolbar Text' ).

    TYPES: BEGIN OF ty_button,
             function TYPE string,
             type     TYPE string,
             text     TYPE string,
             icon     TYPE string,
             disabled TYPE abap_bool,
             visible  TYPE abap_bool,
           END OF ty_button.
    DATA lt_button TYPE TABLE OF ty_button.

    IF is_editable( ) = abap_true.
      " New
      INSERT VALUE #( function = mc->action_newline
                      type     = ''
                      text     = mutx->get_text( mutx->u012 ) " Neues Element
                      icon     = |sap-icon://add-document|
                      disabled = abap_false
                      visible  = abap_true )
             INTO TABLE lt_button.
      IF ms_node_object-elementgrp_sp IS NOT INITIAL. " Nur im GRID-Modus
        " Delete
        INSERT VALUE #( function = mc->action_delline
                        type     = ''
                        text     = mutx->get_text( mutx->u013 ) " Element löschen
                        icon     = |sap-icon://delete|
                        disabled = abap_false
                        visible  = abap_true )
               INTO TABLE lt_button.
        " Copy
        INSERT VALUE #( function = mc->action_copyline
                        type     = ''
                        text     = mutx->get_text( mutx->u014 ) " Element kopieren
                        icon     = |sap-icon://copy|
                        disabled = abap_false
                        visible  = abap_true )
               INTO TABLE lt_button.
      ENDIF.
    ENDIF.
    INSERT VALUE #( type = 'spacer' ) INTO TABLE lt_button.
*
*    IF mv_filter_empty = abap_false.
*      "Filter
*      INSERT VALUE #(
*             function = mc->action_filter
*             type     = ''
*             text     = mutx->get_text( mutx->u015 ) " Unbewertete Merkmale filtern
*             icon     = |sap-icon://filter|
*             disabled = abap_false
*             visible  = abap_true
*          ) INTO TABLE lt_button.
*    ELSE.
*      "Filter undo
*      INSERT VALUE #(
*             function = mc->action_filter
*             type     = ''
*             text     = mutx->get_text( mutx->u016 ) " Alle Merkmale anzeigen
*             icon     = |sap-icon://clear-filter|
*             disabled = abap_false
*             visible  = abap_true
*          ) INTO TABLE lt_button.
*    ENDIF.

    IF  mo_mamba->ms_control-workmode      = mc->workmode_change
    AND mo_mamba->ms_node_object-genclass IS NOT INITIAL.

      " Separator
      INSERT VALUE #( type = 'spacer' ) INTO TABLE lt_button.

      " Generieren
      INSERT VALUE #( function = mc->action_gener
                      type     = ''
                      text     = mutx->get_text( mutx->u017 ) " Generieren
                      icon     = |sap-icon://da|
                      disabled = abap_false
                      visible  = abap_true )
             INTO TABLE lt_button.

      " Generieren mit Überschreiben
      INSERT VALUE #( function = mc->action_generu
                      type     = ''
                      text     = mutx->get_text( mutx->u018 ) " Generieren mit Überschreiben
                      icon     = |sap-icon://da-2|
                      disabled = abap_false
                      visible  = abap_true )
             INTO TABLE lt_button.

    ENDIF.

    LOOP AT lt_button ASSIGNING FIELD-SYMBOL(<button>).
      IF <button>-type = 'spacer'.
        io_view->toolbar_spacer( ).
      ELSE.
        io_view->button( text    = <button>-text
                         icon    = <button>-icon
                         type    = <button>-type
                         enabled = xsdbool( <button>-disabled = abap_false )
                         visible = <button>-visible
                         press   = ms_control-client->_event( val   = <button>-function
                                                              t_arg = mt_def_arg )  )->get_parent( )->get_parent( ).

      ENDIF.
    ENDLOOP.

*      io_view->title( |Editable:{ ms_node_object-objekttyptext }| ).
*    ELSE.
*      io_view->title( |Noedit:{ ms_node_object-objekttyptext }| ).
*    ENDIF.
*    LOOP AT mt_button ASSIGNING FIELD-SYMBOL(<button>).
*      "
*      IF <button>-butn_type = '3'.
*        io_view->toolbar_spacer( ).
*      ELSE.
*
*        IF <button>-text IS NOT INITIAL.
*          DATA(lv_text) = |{ <button>-text }|.
*        ELSEIF <button>-quickinfo IS NOT INITIAL.
*          lv_text = <button>-quickinfo.
*        ELSE.
*          lv_text = <button>-function.
*        ENDIF.
*
*        CASE <button>-function.
*          WHEN 'DELETE'.
*            DATA(lv_icon) = |sap-icon://delete|.
*          WHEN 'FILTER'.
*            lv_icon = |sap-icon://filter|.
*          WHEN 'CHGVALS'.
*            lv_icon = |sap-icon://edit-outside|.
*          WHEN 'REREF'.
*            lv_icon = |sap-icon://chain-link|.
*          WHEN OTHERS.
*            lv_icon = | |.
*        ENDCASE.
*
*        io_view->button( text    = lv_text
*                        icon    = lv_icon
**                        type    = <button>-butn_type
*                        enabled = xsdbool( <button>-disabled = abap_false )
*                        visible = abap_true
*                        press   = ms_control-client->_event( <button>-function ) )->get_parent( )->get_parent( ).
*
*      ENDIF.
*
*
*    ENDLOOP.
  ENDMETHOD.

  METHOD update_outtab.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20250626 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    FIELD-SYMBOLS <lt_outtab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_outline> TYPE any.
    FIELD-SYMBOLS <ls_data>    TYPE /sct/qp_s_mamba.
    FIELD-SYMBOLS <uiattr>     TYPE /sct/qp_if_fcat=>ty_s_ui_attr.

    ASSIGN ms_fcat-data->* TO <lt_outtab>.

*    CLEAR <lt_outtab>.
    DATA lr_outline TYPE REF TO data.
    CREATE DATA lr_outline LIKE LINE OF <lt_outtab>.

    DATA(lv_end) = iv_skip + iv_top.

    " Aus dem Model gelöschte Datensätze auch im View löschen
    LOOP AT mo_mamba->mt_data_del_view ASSIGNING <ls_data>.

      READ TABLE <lt_outtab>  ASSIGNING <ls_outline>
           WITH KEY
*           (mc_key_rowid) COMPONENTS
           (mc->fname_rowid) = <ls_data>-rowid.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " FT20251216 Multiinput BoI
      ASSIGN <ls_outline>-('value_uiattr') TO <uiattr>.
      IF <uiattr> IS ASSIGNED AND <uiattr>-multi_input IS NOT INITIAL.
        DATA ls_data LIKE <ls_data>.
        ls_data-gui_upd = abap_true.
        MODIFY mo_mamba->mt_data FROM ls_data TRANSPORTING gui_upd WHERE element = <ls_data>-element.

      ELSE.
        " Kein Multi-input dann neuaufbau notwendig wegen Binding
        ms_obj-must_redraw = abap_true.

      ENDIF.
      " FT20251216 Multiinput EoI
      IF <ls_data>-prowid IS INITIAL.
        " Normale löschung
        ASSIGN COMPONENT mc->fname_mainsort OF STRUCTURE <ls_outline> TO FIELD-SYMBOL(<ls_mainsort>).
        IF sy-subrc = 0.
          <ls_data>-mainsort = <ls_mainsort>.
        ENDIF.
        " FT20170830 Note 1513 EoI
        DELETE <lt_outtab> INDEX sy-tabix. " USING KEY (mc_key_rowid).
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_del) = abap_true.
      ELSE.
        " Ersetzung (start_initial oder neues Element)

        READ TABLE <lt_outtab> TRANSPORTING NO FIELDS
             WITH KEY
*           (mc_key_rowid) COMPONENTS
             (mc->fname_rowid) = <ls_data>-prowid.
        IF sy-subrc = 0.
          " Der Datensatz existiert bereits, keine Anpassung notwendig.
          ASSIGN COMPONENT mc->fname_rowid OF STRUCTURE <ls_outline> TO FIELD-SYMBOL(<lv_rowid>).
          CLEAR <lv_rowid>.
          CONTINUE.
        ENDIF.

        ASSIGN mo_mamba->mt_data[ rowid = <ls_data>-prowid ] TO FIELD-SYMBOL(<ls_data_new>).
        mo_mamba->do_read_text_line( ir_line = REF #( <ls_data_new> ) ).

        do_mbaline_to_out( EXPORTING is_data    = <ls_data_new>
                           CHANGING  cs_outline = <ls_outline> ).

        <ls_data_new>-gui_upd = abap_false.

      ENDIF.

    ENDLOOP.

    SORT mo_mamba->mt_data BY sortnr
                              element.

    DATA(lv_lines) = lines( mo_mamba->mt_data ).
    DATA(lv_rest) = lv_lines - lv_end.

    IF lv_rest > 0.
      " Nich alle Zeilen wurden angezeigt
      ms_more-display = abap_true.
      ms_more-count   = lv_rest.
      IF ms_more-count > ms_more-step.
        ms_more-count = ms_more-step.
      ENDIF.
      ms_more-text_more = mutx->get_text( mutx->n117 ).
      DATA(lv_anz) = CONV string( ms_more-count ).
      CONDENSE lv_anz.
      REPLACE '&' IN ms_more-text_more WITH lv_anz.
      ms_more-text_all = mutx->get_text( mutx->n118 ).
      lv_anz = CONV string( lv_lines ).
      CONDENSE lv_anz.
      REPLACE '&' IN ms_more-text_all WITH lv_anz.

    ELSE.
      ms_more-display = abap_false.
    ENDIF.

    LOOP AT mo_mamba->mt_data ASSIGNING <ls_data>
*         USING KEY gui_upd
         USING KEY sortnr FROM iv_skip TO lv_end.

      IF <ls_data>-gui_upd <> mc->x.
        CONTINUE.
      ENDIF.

      <ls_data>-gui_upd = abap_false.

      mo_mamba->do_read_text_line( ir_line = REF #( <ls_data> ) ).

      "  optimierter Zugriff (sek. Key mit ROWID)
      READ TABLE <lt_outtab>  ASSIGNING <ls_outline>
           WITH KEY
*           (mc_key_rowid) COMPONENTS
           (mc->fname_rowid) = <ls_data>-rowid.

      IF sy-subrc <> 0.
        READ TABLE <lt_outtab>  ASSIGNING <ls_outline>
             WITH KEY
*           (mc_key_rowid) COMPONENTS
             (mc->fname_rowid) = 0.
      ENDIF.
      IF sy-subrc <> 0.
        " Der Datensatz existiert im Model, aber noch nicht im View : neue Zeile hinzufügen
        ASSIGN lr_outline->* TO <ls_outline>.
        CLEAR <ls_outline>.

        " FT20170830 Note 1513 BoI
        READ TABLE mo_mamba->mt_data_del_view WITH KEY prowid COMPONENTS root_rowid = 0
                                                                         prowid     = <ls_data>-rowid
             ASSIGNING FIELD-SYMBOL(<ls_del>).
        IF sy-subrc = 0.
          " Die Zeile in mt_data_Del_view ist durch <ls_data> ersetzt worden.
          " MAINSORT übernehmen
          <ls_data>-mainsort = <ls_del>-mainsort.

        ENDIF.
        " FT20170830 Note 1513 EoI
        do_mbaline_to_out( EXPORTING is_data    = <ls_data>
                           CHANGING  cs_outline = <ls_outline> ).
        APPEND <ls_outline> TO <lt_outtab>.
      ELSE.
        " Bestehende Zeile ändern
        do_mbaline_to_out( EXPORTING is_data    = <ls_data>
                           CHANGING  cs_outline = <ls_outline> ).
      ENDIF.

    ENDLOOP.

    CLEAR mo_mamba->mt_data_del_view.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~display.
*    get_objtyp_data( ).
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.

*    DATA(lt_messages) = mo_mamba->mo_parent->mo_log->get_messages( iv_objekttyp = ms_node_object-objekttyp ).
*
*    DELETE lt_messages WHERE msgty <> mc->msgtype_e AND msgty <> mc->msgtype_a.
*    CASE lines( lt_messages ).
*      WHEN 0.
*        mv_show_strip = abap_false.
*      WHEN 1.
*        ms_message = lt_messages[ 1 ].
*        IF ms_message-message IS INITIAL.
*          ms_message-message = mo_tools->get_msg_from_msgv( iv_id     = ms_message-msgid
*                                                            iv_number = ms_message-msgno
*                                                            iv_msgv1  = ms_message-msgv1
*                                                            iv_msgv2  = ms_message-msgv2
*                                                            iv_msgv3  = ms_message-msgv3
*                                                            iv_msgv4  = ms_message-msgv4 ).
*        ENDIF.
*        mv_show_strip = abap_true.
*      WHEN OTHERS.
*        ms_message-message = mutx->get_text( mutx->u060 ).
*        mv_show_strip = abap_true.
*    ENDCASE.

    IF is_stateful( ) = abap_true.

      IF is_editable( ) = abap_false AND ms_message IS NOT INITIAL.
        io_view->message_strip( text = ms_message-message
                                type = 'Error' ).

      ELSE.
        io_view->message_strip( text     = ms_control-client->_bind( ms_message-message )
*                                iv_name  = |#{ ms_node_object-objekttyp }_MSG_TEXT|
*                                ir_data  = REF #( ms_message-message ) )
                                type     = 'Error'
                                visible  = ms_control-client->_bind( mv_show_strip
*                                                  iv_name      = |#{ ms_node_object-objekttyp }_MSG_VIS|
*                                                  ir_data      = REF #( mv_show_strip )
*                                                  iv_path      =
                                           )
                                showicon = abap_true ).
      ENDIF.
    ELSE.
      " Stateless, kein Binding notwendig.
      IF is_editable( ) = abap_false AND ms_message IS NOT INITIAL.
        io_view->message_strip( text = ms_message-message
                                type = 'Error' ).

      ELSE.
        io_view->message_strip( text     = ms_message-message
                                type     = 'Error'
                                visible  = mv_show_strip
                                showicon = abap_true ).
      ENDIF.

    ENDIF.
    IF ms_node_object-elementgrp_sp IS INITIAL.
      do_show_list( ).
    ELSE.
      do_show_tab( ).
    ENDIF.
*    IF ms_more-display = abap_true.
**      mo_mamba->do_reset_gui_flag( ).
*    ELSE.
    mo_mamba->do_reset_gui_flag( ).
*    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    init( ms_control-client ).
  ENDMETHOD.

  METHOD do_show_tab.
    " Scroll container immer at 100%
    DATA(lo_view) = ms_control-parent_view->scroll_container( width      = '100%'
                                                              horizontal = abap_true ).
    " Table width > 100% -> Scrollbar visible
    " Wenn mehr als 10 Spalten -> Scrollbar
    DATA(lv_cnt_before_scroll) = 10.
    DATA lv_cnt TYPE i.
    LOOP AT ms_fcat-fieldcat TRANSPORTING NO FIELDS
         WHERE no_out = space.
      lv_cnt += 1.
    ENDLOOP.
    IF lv_cnt <= lv_cnt_before_scroll.
      DATA(lv_table_width) = |100%|.
    ELSE.
      lv_table_width = |{ 100 * lv_cnt DIV lv_cnt_before_scroll }%|.
    ENDIF.

    DATA(lv_edit) = is_editable( ).

    IF lv_edit = abap_true.
      DATA(lv_mode) = 'MultiSelect'.
    ELSE.
      CLEAR lv_mode.
    ENDIF.

    DATA(lo_table) = lo_view->table( alternaterowcolors = abap_true
*                                     id                 = |TAB{ ms_node_object-objekttyp }|
                                     items              = ms_control-client->_bind( ms_fcat-data->* )
*                                     ir_data            = ms_fcat-data
*                                     iv_name            = |{ ms_obj-base->guid }{ ms_node_object-objekttyp }| ) " Bind the table data
*                                     class              = 'sapUiNoMargin'

*                                     showseparators     = abap_true
                                     mode               = lv_mode "'MultiSelect'
*                                     fixedlayout        = abap_true
*                                     autopopinmode      = abap_true
                                     width              = lv_table_width ).

    DATA(lo_otb) = lo_table->header_toolbar( )->overflow_toolbar( ).

    set_toolbar( lo_otb ).

    DATA(lo_cells) = lo_table->items( )->column_list_item( selected = '{MAMBA_SEL/BOOL}' )->cells( ).

    LOOP AT ms_fcat-fieldcat ASSIGNING FIELD-SYMBOL(<fcat>)
         WHERE no_out = space.
      " AND tech = space.
      IF <fcat>-outputlen IS NOT INITIAL.
        DATA(lv_width) = CONV string( <fcat>-outputlen ).
        SHIFT lv_width LEFT DELETING LEADING '0'.
        lv_width = |{ lv_width }rem|.
      ELSE.
        CLEAR lv_width.
      ENDIF.

      IF <fcat>-fieldname CS 'ELEMENT' OR <fcat>-fieldname CS 'VALUE'.
        DATA(imp) = 'High'.
      ELSE.
        imp = 'Low'.
      ENDIF.

      lo_table->columns( )->column( " visible = xsdbool( <fcat>-no_out = abap_false ) " sortindicator = 'None' "'Ascending' 'Descending'
                                    width      = lv_width
                                    importance = imp
*                                    styleclass = 'sapUiTinyMarginBeginEnd'
                                    styleclass = 'sapUiSizeCondensed'
*                                    class      = 'sapUiNoMargin'
*                                    class      = 'sapUiTinyMarginBeginEnd'
                                    class      = 'sapUiSizeCondensed'
*                                    minscreenwidth = '20rem'
                  )->text( text     = <fcat>-scrtext_s
                           wrapping = abap_false ).

      DATA(lv_attr_fieldname) = |{ <fcat>-fieldname }_UIATTR|.
      "

      DATA(editfname) = |\{{ lv_attr_fieldname }/EDIT\}|.
      DATA(showf4) = |\{{ lv_attr_fieldname }/F4\}|.
      " TODO: variable is assigned but never used (ABAP cleaner)
      " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
      DATA(dats_vis) = |\{{ lv_attr_fieldname }/DATS_VIS\}|.
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(dats_not_vis) = |\{{ lv_attr_fieldname }/DATS_NOT_VIS\}|.
      DATA(text_align) = |\{{ lv_attr_fieldname }/TEXTALIGN\}|.

      IF line_exists( ms_fcat-fieldcat[ fieldname = lv_attr_fieldname ] ) AND lv_edit = abap_true.

*        DATA(editfname) = |\{{ lv_attr_fieldname }/EDIT\}|.
**        DATA(f4fname) = |\{{ lv_attr_fieldname }/F4\}|.
*        DATA(showf4) = |\{{ lv_attr_fieldname }/F4\}|.
*
*        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
*        " TODO: variable is assigned but never used (ABAP cleaner)
*        DATA(dats_vis) = |\{{ lv_attr_fieldname }/DATS_VIS\}|.
*        " TODO: variable is assigned but never used (ABAP cleaner)
*        DATA(dats_not_vis) = |\{{ lv_attr_fieldname }/DATS_NOT_VIS\}|.
*        DATA(text_align) = |\{{ lv_attr_fieldname }/TEXTALIGN\}|.

        IF <fcat>-fieldname = 'ELEMENT'.
          DATA(lr_sug) = REF #( mt_sug[ element = mc->fname_element ] ).
          DATA(lv_sug_index) = line_index( mt_sug[ element = mc->fname_element ] ).
          " Suggestions hinzufügen.
          lo_cells->input( value            = |\{{ <fcat>-fieldname }\}|
                           enabled          = 'true'
                           showvaluehelp    = showf4
                           valuehelprequest = _event( iv_name = 'POPUP_F4'
                                                      it_arg  = VALUE #( BASE mt_def_arg
                                                                         ( |{ <fcat>-fieldname }| )
                                                                         ( `${ROWID}` ) ) )
                           editable         = editfname
                           submit           = _event( mc->action_change )
                           suggestionitems  = ms_control-client->_bind( val       = lr_sug->sug_tab
                                                                        tab       = mt_sug
                                                                        tab_index = lv_sug_index )
                           showsuggestion   = abap_true )->get(
                                                                           )->suggestion_items( )->get(
                                                                               )->list_item( text           = '{VALUE}'
                                                                                             additionaltext = '{DESCR}' ).

        ELSEIF <fcat>-checkbox = abap_true.
          lo_cells->checkbox( selected = showf4
                              select   = _event( 'CHANGE' )
*                              textalign = 'Center'
                              editable = lv_edit ).

        ELSE.
          lo_cells->input( value            = |\{{ <fcat>-fieldname }\}|
                           enabled          = 'true' " editfname
                           showvaluehelp    = showf4
                           textalign        = text_align
                           valuehelprequest = _event( iv_name = 'POPUP_F4'
                                                      it_arg  = VALUE #( BASE mt_def_arg
                                                                         ( |{ <fcat>-fieldname }| )
                                                                         ( `${ROWID}` ) ) )
                           editable         = editfname
                           submit           = _event( mc->action_change ) ).

        ENDIF.
      ELSEIF <fcat>-icon = abap_true.
        lo_cells->icon( src   = |\{{ <fcat>-fieldname }\}|
                        class = `size1` ).

      ELSEIF <fcat>-checkbox = abap_true.
        lo_cells->checkbox( selected = showf4

                            editable = lv_edit ).

      ELSE.
        lo_cells->text( text = |\{{ <fcat>-fieldname }\}| ).

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_value_state.
    cs_attr-valuestate     = mcu->sap-ui-core-message-MessageType-error.
    cs_attr-valuestatetext = is_error-message.
  ENDMETHOD.

  METHOD set_error_color.
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Änderungslog
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    "--------------------------------------------------------------------"

    " Färbt das Feld wenn Fehler vorhanden sind.

    FIELD-SYMBOLS <lt_outtab>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <ls_rowid>   TYPE /sct/qp_rowid.
    FIELD-SYMBOLS <ls_element> TYPE /sct/qp_element.
    FIELD-SYMBOLS <lt_color>   TYPE ANY TABLE.
    DATA lv_fname TYPE abp_field_name.

    mo_mamba->get_check_errors( IMPORTING et_errors_outdated = DATA(lt_errors_old)
                                RECEIVING rt_errors          = DATA(lt_errors) ).

    ASSIGN ms_fcat-data->* TO <lt_outtab>.

    " Veraltete Fehler entmarkieren
    IF lt_errors_old IS NOT INITIAL.
      LOOP AT <lt_outtab> ASSIGNING FIELD-SYMBOL(<ls_outtab>).
        UNASSIGN <ls_rowid>.
        ASSIGN COMPONENT mc->fname_rowid OF STRUCTURE <ls_outtab> TO <ls_rowid>.
        IF line_exists( lt_errors_old[ rowid_row = <ls_rowid> ] ). " MD181102 N1965 CHG
          ASSIGN COMPONENT mc->fname_cellcolor OF STRUCTURE <ls_outtab> TO <lt_color>.
          IF sy-subrc = 0.
            CLEAR <lt_color>.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
    " veraltete Fehler löschen
    mo_mamba->do_reset_outdated_errors( ).

    " Aktuelle Fehler verarbeiten
    LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

      <ls_error>-message = mo_tools->get_msg_from_msgv( iv_id     = COND #( WHEN <ls_error>-msgid IS NOT INITIAL
                                                                            THEN <ls_error>-msgid
                                                                            ELSE mc->msgid_sctqp )
                                                        iv_number = <ls_error>-msgno
                                                        iv_msgv1  = <ls_error>-msgv1
                                                        iv_msgv2  = <ls_error>-msgv2
                                                        iv_msgv3  = <ls_error>-msgv3
                                                        iv_msgv4  = <ls_error>-msgv4 ).

      UNASSIGN <ls_outtab>.

      IF <ls_error>-type = /sct/qp_cx_check=>mc_error_type_affiliation.
        READ TABLE <lt_outtab> ASSIGNING <ls_outtab>
**           WITH KEY (mc_key_rowid) COMPONENTS (mc->fname_rowid) = <ls_error>-rowid_row.
             WITH KEY ('ROWID') = <ls_error>-rowid_row.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT |ELEMENT_UIATTR| OF STRUCTURE <ls_outtab> TO FIELD-SYMBOL(<ui_attr>).
        IF sy-subrc = 0.
          get_value_state( EXPORTING is_error = <ls_error>               " Mamba-Spalte (Untertabelle)
                           CHANGING  cs_attr  = <ui_attr> ).
        ENDIF.
      ELSE.
        " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.BoI
        DATA(lr_line_color) = mo_mamba->get_lineref_via_id( mo_mamba->get_line_rowid( <ls_error>-rowid ) ).
        " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.EoI
        READ TABLE <lt_outtab> ASSIGNING <ls_outtab>
**           WITH KEY (mc_key_rowid) COMPONENTS (mc->fname_rowid) = <ls_error>-rowid_row.
             WITH KEY ('ROWID') = <ls_error>-rowid_row.
        " FT20170424 Note 1330 EoC
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT mc->fname_element OF STRUCTURE <ls_outtab> TO <ls_element>.
        IF <ls_element> IS NOT ASSIGNED.
          CONTINUE.
        ENDIF.
*      ASSIGN COMPONENT mc->fname_cellcolor OF STRUCTURE <ls_outtab> TO <lt_color>.
*      IF <lt_color> IS NOT ASSIGNED.
*        CONTINUE.
*      ENDIF.

        DATA(lt_affected_fields) = /sct/qp_cl_log=>pick_affected_fields( iv_fields = <ls_error>-fields ).

        IF lt_affected_fields IS INITIAL.
          " Color all value fields
          "          LOOP AT mo_mamba->mt_value_field ASSIGNING FIELD-SYMBOL(<ls_value_field>).
          "            APPEND <ls_value_field>-low TO lt_affected_fields.
          "          ENDLOOP.

          IF <ls_error>-rowid <> <ls_error>-rowid_row.
            LOOP AT mo_mamba->ms_init-col ASSIGNING FIELD-SYMBOL(<ls_col>) USING KEY element
                 WHERE element = <ls_error>-element.
              APPEND <ls_col>-fieldname_dyn TO lt_affected_fields.
            ENDLOOP.
          ELSE.
            LOOP AT mo_mamba->ms_init-col ASSIGNING <ls_col> USING KEY element
                 WHERE element = space.
              APPEND <ls_col>-fieldname TO lt_affected_fields.
            ENDLOOP.
          ENDIF.
        ENDIF.

        LOOP AT lt_affected_fields ASSIGNING FIELD-SYMBOL(<ls_field>).
          IF <ls_element> = <ls_error>-element. " Haupt element ( Zeile in MT_DATA )
            " Horizontales Element
            " Dann ist der Zellname der OUTTAB gleich dem Feldnamen
            lv_fname = <ls_field>-fieldname.

            " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.BoI
            " Wenn Editierbar dann markieren

            IF lr_line_color->gruelm IS NOT INITIAL. " FT20190708 Note 2188
              IF abap_true <> is_fname_editable_elemformat( VALUE #( fieldname = <ls_field>-fieldname
                                                                     gruelm    = lr_line_color->gruelm ) ).
                CONTINUE.
              ENDIF.
            ENDIF.
          " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.EoI

          ELSE.
            " AD, 2021.01.11, NOTE-3213, BoC
            " FT20170904 Note 1472 BoC
            " Dynamisches Element
            TRY.
                " Wenn der Fehler im View durch den Benutzer entstanden ist, dann kann der FIELDNAME eine dynamische Spalte sein, z.B. X01VALUE.
                " Dann wird hier auch Existenz geprüft
                DATA(ls_col) = mo_mamba->ms_init-col[ KEY field_dyn
                                                      fieldname_dyn = <ls_field>-fieldname ].
              CATCH cx_sy_itab_line_not_found.
                " Fehler wurde evtl. durch BUS erzeugt. Dann muss hier der dyn. Feldname ermittelt werden, damit die Zelle in OUTTAB
                " eingefärbt werden kann.
                TRY.
                    ls_col = mo_mamba->ms_init-col[ element   = <ls_error>-element
                                                    fieldname = <ls_field>-fieldname ].
                  CATCH cx_sy_itab_line_not_found.
                    " Diese Logik ist so ein Müll und muss dringend überarbeitet werden
                    ls_col = mo_mamba->ms_init-col[ fieldname = <ls_field>-fieldname ].
                ENDTRY.
            ENDTRY.

            " FT20170904 Note 1472 EoC
            lv_fname = ls_col-fieldname_dyn.

            " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.BoI
            IF is_fname_editable_elemformat( ls_col ) = abap_false.
              CONTINUE.
            ENDIF.
            " FT20181130 Note 2010 - Mamba färbt bei Fehlern zu viele Spalten ein.EoI
          ENDIF.
          " AD, 2021.01.11, NOTE-3213, EoC
          ASSIGN COMPONENT |{ lv_fname }_UIATTR| OF STRUCTURE <ls_outtab> TO <ui_attr>.
          IF sy-subrc = 0.
            get_value_state( EXPORTING is_error = <ls_error>                " Mamba-Spalte (Untertabelle)
                             CHANGING  cs_attr  = <ui_attr> ).
          ENDIF.
          " TODO
          " ***         IF <ls_error>-msgty = mc->msgtype_w.
          " ***          ls_color-color-col = mc_field_color_total.
          " ***        ELSE.
          " ***          ls_color-color-col = mc_field_color_negative.
          " ***        ENDIF.
          " ***
          " ***        INSERT ls_color INTO TABLE <lt_color>.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Farbliche Kennzeichnung (Zeilenübergreifend)
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " For each duplicative element line, color the whole row in red

**    DATA(lv_rowcolor_negative) = mo_tools->get_alv_row_color( iv_color       = /sct/qp_cl_const=>alv_color_number_negative
**                                                              iv_intensified = /sct/qp_cl_const=>alv_color_intensified_off
**                                                              iv_inverted    = /sct/qp_cl_const=>alv_color_inverted_off ).
**
**    DATA(lt_duplicate_errors) = mo_mamba->get_check_errors( iv_type = /sct/qp_cx_check=>mc_error_type_duplicate ).
**
**    LOOP AT <lt_outtab> ASSIGNING <ls_outtab>.
**      ASSIGN COMPONENT mc->fname_rowcolor OF STRUCTURE <ls_outtab> TO FIELD-SYMBOL(<ls_rowcolor>).
**      ASSIGN COMPONENT mc->fname_rowid OF STRUCTURE <ls_outtab> TO <ls_rowid>.
**      " TODO: variable is assigned but never used (ABAP cleaner)
**      ASSIGN lt_duplicate_errors[ (mc->fname_rowid) = <ls_rowid> ] TO FIELD-SYMBOL(<ls_duplicate_error>).
**      IF sy-subrc = 0.
**        <ls_rowcolor> = lv_rowcolor_negative.
**      ELSE.
**        " Check for further errors resulting in critical red coloring of row
**        DATA(lt_critical_row_errors) = mo_mamba->get_check_errors( iv_rowid = <ls_rowid>
**                                                                 iv_type  = /sct/qp_cx_check=>mc_error_type_affiliation ).
**        "     If row is red but no further errors found, the color shall be cleared
**        IF <ls_rowcolor> = lv_rowcolor_negative AND lt_critical_row_errors IS INITIAL.
**          " FT20170713 Note 1463 - MAMBA Inkonsistente Fehlermeldungen #2 BoC
**          " Originalfarbe zurücksetzen
**          DATA(lr_line) = mo_mamba->get_lineref_via_id( <ls_rowid> ).
**          <ls_rowcolor> = get_line_color( lr_line->* ).
**          "          CLEAR <ls_rowcolor>.
**          " FT20170713 Note 1463 - MAMBA Inkonsistente Fehlermeldungen #2 EoC
**
**        ENDIF.
**      ENDIF.
**    ENDLOOP.
  ENDMETHOD.

  METHOD do_show_list.
    FIELD-SYMBOLS <uiattr>     TYPE /sct/qp_if_fcat=>ty_s_ui_attr.
    FIELD-SYMBOLS <data_table> TYPE STANDARD TABLE.

    DATA(lo_view) = ms_control-parent_view.
    DATA(lv_edit) = is_editable( ).

    ASSIGN ms_fcat-data->* TO <data_table>.
    IF <data_table> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    " *********************************************************************
    " SPALTEN ANALYSIEREN : nur Spalten mit Inhalt
    " *********************************************************************
    prepare_fcat( EXPORTING iv_edit      = lv_edit
                  IMPORTING et_fcat      = DATA(lt_fcat)
                            ev_labeltype = DATA(lv_labeltype) ).

    " *********************************************************************
    " SPALTEN ANALYSIEREN ENDE
    " *********************************************************************

    DATA(lo_otb) = lo_view->overflow_toolbar( ).

    set_toolbar( lo_otb ).

    DATA(lo_simpleform) = lo_view->simple_form( " title            =
                                                layout           = 'ResponsiveGridLayout'
                                                editable         = 'true'
                                                id               = |SimpleForm:{ ms_node_object-objekttyp }|
*                                                adjustlabelspan  = 'false'
                                                backgrounddesign = 'Translucent'
*                                                breakpointl      =
*                                                breakpointm      =
*                                                breakpointxl     =
                                                emptyspans       = '0'
                                                emptyspanm       = '1'
                                                emptyspanl       = '1'
                                                emptyspanxl      = '3'
                                                labelspans       = '12'
                                                labelspanm       = '4'
                                                labelspanl       = '2'
                                                labelspanxl      = '2'
*                                                maxcontainercols =
*                                                minwidth         =
*                                                singlecontainerfullsize =
*                                                visible          =
                                                width            = '100%' ).

*    _bind( iv_fieldname = |ms_fcat-data->*| ).
*    _bind( iv_fieldname = |mt_sug| ).
*    _bind( iv_fieldname = |MV_EMPTY_FIELD| ).

    " Emojis.
    "
    " icon_create Dokument: 📄
    " icon_change Bleistift: ✏️
    " icon_wf_link Kettensymbol : 🔗
    " icon_wd_navigation_link Verhakte Büroklammern: 🖇️
    " icon_delete Kübel: 🗑️

    DATA(lo_form_content) = lo_simpleform->content( ns = 'form' ).

    " *********************************************************************
    " LISTE aufbauen:
    " Die erste Spalte ( Element und/oder Elementtext) ist ein Label
    " die anderen ein Text
    " *********************************************************************
    LOOP AT <data_table> ASSIGNING FIELD-SYMBOL(<data>).
      IF <data>-('hidden') = abap_true. " u.a. Mehrfach bewertbare Elementen
        CONTINUE.
      ENDIF.

      DATA(lv_tabix) = sy-tabix.
*      DATA(first) = abap_true.
      ASSIGN COMPONENT 'ROWID' OF STRUCTURE <data> TO FIELD-SYMBOL(<rowid>).
      ASSIGN COMPONENT 'MANDATORY-BOOL' OF STRUCTURE <data> TO FIELD-SYMBOL(<mandatory>).

      IF lv_edit = abap_false.
        " Im Anzeigemodus werden Rangetype und Einheit werden ggfs mit VALUE-Felder konkateniert
        ASSIGN COMPONENT mc->fname_value_eih OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_unit>).
        IF <lv_unit> IS NOT ASSIGNED.
          ASSIGN mv_empty_field TO <lv_unit>.
        ENDIF.
        ASSIGN COMPONENT mc->fname_rangetype OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_rangetype>).
        IF <lv_rangetype> IS NOT ASSIGNED.
          ASSIGN mc_empty_rangetype TO <lv_rangetype>.
        ENDIF.
      ENDIF.
      ASSIGN COMPONENT mc->fname_ktxt OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_ktxt>).
      IF <lv_ktxt> IS NOT ASSIGNED.
        ASSIGN mv_empty_field TO <lv_ktxt>.
      ENDIF.
      ASSIGN COMPONENT mc->fname_element OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_element>).
      ASSIGN COMPONENT mc->fname_elementtext OF STRUCTURE <data> TO FIELD-SYMBOL(<lv_elementtext>).

      CASE lv_labeltype.
        WHEN 'E'.
          DATA(lv_label) = |{ <lv_element> }|.
        WHEN 'T'.
          lv_label = |{ <lv_elementtext> }|.
        WHEN 'B'.
          lv_label = |{ <lv_elementtext> } ({ <lv_element> })|.
      ENDCASE.
      IF <lv_element> IS INITIAL.
        " Neues Element
        lv_label = |({ mutx->get_text( mutx->u012 ) })|. " Neues Element
      ENDIF.

      lo_form_content->label( showcolon = 'false'
                              text      = |{ get_relattyp_icon( is_data     = mo_mamba->mt_data[ rowid = <rowid> ]
                                                                iv_as_emoji = abap_true ) } { lv_label }|
                              "                              design    = 'Bold'  Gemäß Kundenauftrag v2:nicht Fett
                                                            ).

      " Element anzeigen wenn leer und Eingabebereit.
      DATA(lv_elemuiattr) = |{ mc->fname_element }_UIATTR|.
      ASSIGN COMPONENT lv_elemuiattr OF STRUCTURE <data> TO <uiattr>.

      IF <lv_element> IS INITIAL OR <uiattr>-valuestatetext IS NOT INITIAL.
        <uiattr>-f4 = abap_true.
        " Neues Element ? -> stringify notwendig.
*        ms_obj-must_redraw = abap_true.
        <mandatory> = abap_true.
        field_input( io_xml         = lo_form_content
                     iv_edit        = lv_edit
                     iv_element     = CONV #( mc->fname_element )
                     iv_fieldname   = mc->fname_element
                     iv_placeholder = CONV #( ms_fcat-fieldcat[ fieldname = mc->fname_element ]-scrtext_s )
                     ir_ktxt        = REF #( mv_empty_field )
                     ir_value       = REF #( <lv_element> )
                     ir_uiattr      = REF #( <uiattr> )
                     ir_mandatory   = REF #( <mandatory> )
                     iv_rowid       = <rowid>
                     iv_fieldwidth  = |100%|
                     iv_tabix       = lv_tabix ).

        UNASSIGN <uiattr>.
      ENDIF.

      " gemäß FCAT die Spalten aufbereiten
      LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fcat>).

        " Welche Spalten sollen überhaupt angezeigt werden
        ASSIGN COMPONENT <fcat>-fieldname OF STRUCTURE <data> TO FIELD-SYMBOL(<content>).
        IF <content> IS NOT ASSIGNED.
          CONTINUE.
        ENDIF.
        DATA(lv_uiattr) = |{ <fcat>-fieldname }_UIATTR|.
        ASSIGN COMPONENT lv_uiattr OF STRUCTURE <data> TO <uiattr>.
        IF sy-subrc = 0. " UI Attribute ( nur für die Spalten, die in der Spaltengruppe definiert worden sind )

          IF <fcat>-fieldname IN mo_mamba->mt_value_field
          OR <uiattr>-edit     = abap_true. " Editiebare Felder, die nicht in ms-data-col sind ( z.B sortnr )
*          IF 1 = 1.

*            DATA(lo_box) = lo_form_content->hbox(
**                    id               =
**                    height           =
**                    justifycontent   =
**                    class            =
**                    rendertype       =
**                    aligncontent     =
**                    direction        =
**                    alignitems       =
**                    width            =
**                    wrap             =
**                    backgrounddesign =
**                    displayinline    =
*              fitcontainer = abap_true
**             visible      =
*            ).

*            DATA(lo_box) = lo_form_content->hbox( justifycontent = 'SpaceBetween'
**                                       aligncontent   = 'Center'
*                                                   alignitems = 'Center'
*             ).

            DATA(lo_box) = lo_form_content.

            " *********************************************************************
            " WERTEFELDER
            " *********************************************************************
            IF <uiattr>-edit = abap_true. " Nur editierbare Value-Felder werden angezeigt.

              IF lv_edit = abap_true.

*                DATA(lv_span) = |3|.
                DATA(lv_fieldwidth) = |50%|.

                IF <lv_ktxt> IS NOT INITIAL.
*                  lv_span = '9'. " With KTXT 9 and fieldwidth is 33%, so all inputs are equally big and there is enough space for the short text
                  lv_fieldwidth = |50%|.
                ENDIF.

                field_input( io_xml         = lo_box
                             iv_edit        = lv_edit
                             iv_element     = <lv_element>
                             iv_fieldname   = <fcat>-fieldname
                             iv_placeholder = CONV #( <fcat>-scrtext_s )
                             ir_ktxt        = REF #( <lv_ktxt> )
                             ir_value       = REF #( <content> )
                             ir_uiattr      = REF #( <uiattr> )
                             ir_mandatory   = REF #( <mandatory> )
                             iv_rowid       = <rowid>
*                             iv_span        = lv_span
                             iv_fieldwidth  = lv_fieldwidth
                             iv_tabix       = lv_tabix ).

              ELSE.
                IF <uiattr>-cvtyp = mc->cvtyp_bool.
                  <uiattr>-f4 = xsdbool( <content> IS NOT INITIAL ).
                  lo_box->checkbox( selected  = <uiattr>-f4
                                    textalign = <uiattr>-textalign
                                    editable  = lv_edit ).

                ELSEIF <uiattr>-multi_input = abap_true.
                  " Nicht editierbare multi-input

                  lo_box->multi_input(  " id               = lv_id
                                       tokens         = ms_control-client->_bind( val       = <uiattr>-token
                                                                                  tab       = ms_fcat-data->*
                                                                                  tab_index = lv_tabix )
                                       valuestate     = <uiattr>-valuestate
                                       valuestatetext = <uiattr>-valuestatetext
                                       editable       = abap_false
                                    )->tokens(
                                        )->token( key      = `{KEY}`
                                                  text     = `{TEXT}`
                                                  visible  = `{VISIBLE}`
                                                  selected = `{SELKZ}`
                                                  editable = `{EDITABLE}` ).

                ELSE.

                  IF <uiattr>-avatar = abap_true.
                    " Bild und Inputbox nebeneinander und vertikal zentriert
                    lo_box = lo_box->hbox( justifycontent = 'Start'
                                           alignitems     = 'Center' ).
*                    " TODO: variable is assigned but never used (ABAP cleaner)
*                    DATA(lv_fw) = `40%`. "`50%`.

                    ASSIGN mt_avatars[ element = <lv_element> ] TO FIELD-SYMBOL(<ls_avatar>).
                    DATA(lv_ava_tabix) = sy-tabix.
                    " *********************************************************************
                    " Selektierter Wert
                    " *********************************************************************

                    lo_box->hbox( class = 'sapUiSmallMargin' )->avatar_group( grouptype         = `Individual`
                                                                              avatardisplaysize = `M`
                                                                              items             = ms_control-client->_bind( val       = <ls_avatar>-t_select
                                                                                                                            tab       = mt_avatars
                                                                                                                            tab_index = lv_ava_tabix )
                                                                              )->avatar_group_item( initials     = `{INITIALS}`
                                                                                                    fallbackicon = `{FALLBACKICON}`
                                                                                                    src          = `{SRC}`
                                                                                                    tooltip      = `{NAME}` ).

                  ENDIF.

                  " Anzeige ONLY
                  DATA(lv_value) = ||.
                  IF <fcat>-fieldname = mc->fname_value AND <lv_ktxt> IS NOT INITIAL.
                    IF <content> = <lv_ktxt>.
                      lv_value = <content>. " 2 Mal den gleichen Wert braucht kein Mensch  "ABC (ABC)"
                    ELSE.
                      lv_value = |{ <lv_ktxt> } ({ <content> })|.
                    ENDIF.
                  ELSEIF <lv_ktxt> IS INITIAL.

                    IF <fcat>-fieldname = mc->fname_value_min.
                      lv_value = |{ <lv_rangetype>(1) } { <content> }|.
                    ELSEIF <fcat>-fieldname = mc->fname_value_max.
                      lv_value = |{ <content> } { <lv_rangetype>+1(1) }|. " { <lv_unit> }|.
                    ELSE.
                      IF <content> IS NOT INITIAL.
                        lv_value = |{ <content> } { <lv_unit> }|.
                      ELSE.
                        CLEAR lv_value.
                      ENDIF.
                    ENDIF.
                  ENDIF.

                  IF lv_value CO space.
                    CLEAR lv_value.
                  ENDIF.
*                  lo_form_content->text( text               = lv_value
                  lo_box->text( text               = lv_value
                                emptyindicatormode = 'On' ).
                  IF <fcat>-fieldname = mc->fname_value_max.
*                    lo_form_content->text( text = |{ <lv_unit> }| ).
                    lo_box->text( text = |{ <lv_unit> }| ).
                  ENDIF.

                ENDIF.
              ENDIF.
            ELSE.

              " *********************************************************************
              " Nicht editierbare Felder (kein Binding)
              " *********************************************************************

              IF <fcat>-fieldname = mc->fname_value AND <lv_ktxt> IS NOT INITIAL.
*                lo_form_content->text( text               = |{ <lv_ktxt> } ({ <content> })|
                lo_box->text( text               = |{ <lv_ktxt> } ({ <content> })|
                              emptyindicatormode = 'On' ).

              ELSE.
                IF <content> IS NOT INITIAL.
*                  lo_form_content->text( text               = |{ <content> }|
                  lo_box->text( text               = |{ <content> }|
                                emptyindicatormode = 'On' ).
                ENDIF.
              ENDIF.
            ENDIF.

            IF <uiattr>-jump = abap_true AND <content> IS NOT INITIAL.
              DATA(lo_box_icon) = lo_box->hbox( justifycontent = 'End' ).

              " BUTTON mit 1 Aktion OK
              lo_box_icon->button( icon    = 'sap-icon://display-more'
                                   width   = '2rem'
                                   tooltip = mutx->get_text( mutx->n105 )
                                   class   = 'sapUiTinyMarginBeginEnd'
                                   press   = _event( iv_name = 'JUMP'
                                                     it_arg  = VALUE #( BASE mt_def_arg
                                                                        ( CONV #( <rowid> ) )
                                                                        ( CONV #( <fcat>-fieldname ) )
                                                                        ( CONV #( <content> ) ) ) ) ). " string table

              lo_box_icon->button( icon    = 'sap-icon://enter-more'
                                   width   = '2rem'
                                   tooltip = mutx->get_text( mutx->n106 )
                                   press   = _event( iv_name = 'JUMP_EXT'
                                                     it_arg  = VALUE #( BASE mt_def_arg
                                                                        ( CONV #( <rowid> ) )
                                                                        ( CONV #( <fcat>-fieldname ) )
                                                                        ( CONV #( <content> ) ) ) ) ). " string table
*
** Split Menü (Jump, Jump new Tab)
*              DATA(lo_menu) = get_menu( io_parent_view = lo_box
*                                        iv_type        = mcu->sap-m-buttontype-default
*                                        iv_icon        = 'sap-icon://display-more'
*                                        iv_text        = `Jump`
*                                        iv_width       = '8rem' )->items( )->menu_item( press = _event( iv_name = 'JUMP' )
*                                                                                        icon = 'sap-icon://display-more'
*                                                                                        text = 'Jump'
*                                                                          )->menu_item( press = _event( iv_name = 'JUMP_EXT' )
*                                                                                        icon = 'sap-icon://enter-more'
*                                                                                        text = 'Jump ext' ).
*

            ENDIF.
          ELSE.
            " *********************************************************************
            " Andere Felder aus der Spaltengruppe (mit _UIATTR)
            " **********************************************************************
            " Immer anzeigen
            lo_form_content->text( text = ms_control-client->_bind( val       = <content>
                                                                    tab       = ms_fcat-data->*
                                                                    tab_index = lv_tabix ) ).
          ENDIF.

        ELSE.
          " *********************************************************************
          " Andere Felder (ohne _UIATTR)
          " **********************************************************************

          lo_form_content->text( text = <content> ).
        ENDIF.

      ENDLOOP.
    ENDLOOP.

    lo_view->hbox( justifycontent = 'Center'
                 )->button( text    = ms_more-text_more
                            type    = mcu->sap-m-buttontype-transparent
                            visible = ms_more-display
                            class   = 'sapUiLargeMarginBeginEnd'
                            press   = _event( 'SHOW_MORE' )

                )->button( text    = ms_more-text_all
                           type    = mcu->sap-m-buttontype-transparent
                           visible = ms_more-display
                           class   = 'sapUiLargeMarginBeginEnd'
                           press   = _event( 'SHOW_ALL' ) ).
  ENDMETHOD.

  METHOD field_input.
    DATA(lv_sug_index) = line_index( mt_sug[ element = iv_element ] ).
    DATA(lr_sug) = REF #( mt_sug[ element = iv_element ]-sug_tab OPTIONAL ).
    IF lr_sug IS NOT BOUND.
      lv_sug_index = line_index( mt_sug[ element = 'EMPTY_LIST' ] ).
      lr_sug = REF #( mt_sug[ element = 'EMPTY_LIST' ]-sug_tab ).
      DATA(lv_show) = abap_false.
    ELSE.
      lv_show = abap_true.
    ENDIF.

    " *********************************************************************
    " CHECKBOX
    " *********************************************************************
    IF ir_uiattr->cvtyp = mc->cvtyp_bool.
      " value ist ein String und enthält ' ' oder 'X', und das sind keine zulässige Boolean Werte ;-)
      " F4 ist als Boolean definiert und wird für checkboxes nicht benutzt,
      " => Der Wert wird in F4 umgesetzt
      ir_uiattr->f4 = xsdbool( ir_value->* IS NOT INITIAL ).

      io_xml->checkbox( selected  = ms_control-client->_bind( val       = ir_uiattr->f4
                                                              tab       = ms_fcat-data->*
                                                              tab_index = iv_tabix )
                        select    = _event( 'CHANGE' )
                        textalign = ms_control-client->_bind( val       = ir_uiattr->textalign
                                                              tab       = ms_fcat-data->*
                                                              tab_index = iv_tabix )
                        editable  = iv_edit ).

    " *********************************************************************
    " DATE
    " *********************************************************************
    ELSEIF ir_uiattr->cvtyp = mc->cvtyp_dats.
      io_xml->date_picker( value          = ms_control-client->_bind( val       = ir_value->*
                                                                      tab       = ms_fcat-data->*
                                                                      tab_index = iv_tabix )
*                           placeholder    = iv_placeholder "ohne Platzhaler wird ein Datumsbeispiel angezeigt
                           required       = ms_control-client->_bind( val       = ir_mandatory->*
                                                                      tab       = ms_fcat-data->*
                                                                      tab_index = iv_tabix )

                           valuestate     = ms_control-client->_bind( val       = ir_uiattr->valuestate
                                                                      tab       = ms_fcat-data->*
                                                                      tab_index = iv_tabix )
                           valuestatetext = ms_control-client->_bind( val       = ir_uiattr->valuestatetext
                                                                      tab       = ms_fcat-data->*
                                                                      tab_index = iv_tabix )
                           change         = _event( 'CHANGE' )

                           editable       = iv_edit
                           textalign      = ms_control-client->_bind( val       = ir_uiattr->textalign
                                                                      tab       = ms_fcat-data->*
                                                                      tab_index = iv_tabix ) ).

    " *********************************************************************
    " MULTI-INPUT
    " *********************************************************************
    ELSEIF ir_uiattr->multi_input = abap_true.

      io_xml->multi_input(  " id               = lv_id
                           placeholder            = iv_placeholder
                           tokens                 = ms_control-client->_bind( val       = ir_uiattr->token
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )
                           value                  = ms_control-client->_bind( val       = ir_value->*
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )
                           tokenupdate            = _event( iv_name = 'EVT_TOKEN_UPD'
                                                            it_arg  = VALUE #( BASE mt_def_arg
                                                                               ( |{ iv_fieldname }| )
                                                                               ( |{ iv_rowid }| )
                                                                               ( `$event.mParameters.type` )
                                                                               ( `$event.mParameters.removedTokens[0].mProperties.key` ) ) )
                           change                 = _event( iv_name = 'EVT_TOKEN_CHANGE'
                                                            it_arg  = VALUE #( BASE mt_def_arg
                                                                               ( |{ iv_fieldname }| )
                                                                               ( |{ iv_rowid }| )
                                                                               ( `$event.mParameters.newValue` ) ) ) " Input-value
                           valuestate             = ms_control-client->_bind( val       = ir_uiattr->valuestate
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )
                           valuestatetext         = ms_control-client->_bind( val       = ir_uiattr->valuestatetext
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )

                           required               = ms_control-client->_bind( val       = ir_mandatory->*
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )
                           showvaluehelp          = ms_control-client->_bind( val       = ir_uiattr->f4
                                                                              tab       = ms_fcat-data->*
                                                                              tab_index = iv_tabix )

                           valuehelprequest       = _event( iv_name = 'POPUP_F4'
                                                            it_arg  = VALUE #( BASE mt_def_arg
                                                                               ( |{ iv_fieldname }| )
                                                                               ( |{ iv_rowid }| ) ) )
                           suggestionitemselected = _event( iv_name = 'EVT_TOKEN_CHANGE'
                                                            it_arg  = VALUE #( BASE mt_def_arg
                                                                               ( |{ iv_fieldname }| )
                                                                               ( |{ iv_rowid }| )
                                                                               ( `$event.mParameters.selectedItem.mProperties.text` ) ) ) " Genauso muss der Parameter angesprochen werden…

                           suggestionitems        = ms_control-client->_bind( val       = lr_sug->*
                                                                              tab       = mt_sug
                                                                              tab_index = lv_sug_index )
                           showsuggestion         = lv_show
                           fieldwidth             = iv_fieldwidth
                            )->get( )->suggestion_items(
*                              )->get(
                            )->list_item( text           = '{VALUE}'
                                          additionaltext = '{DESCR}' )->get_parent(

                        )->tokens(
                            )->token( key      = `{KEY}`
                                      text     = `{TEXT}`
                                      visible  = `{VISIBLE}`
                                      selected = `{SELKZ}`
                                      editable = `{EDITABLE}` ).

    " *********************************************************************
    " SINGLE INPUT (standard)
    " *********************************************************************
    ELSE.

      IF ir_uiattr->avatar = abap_true.
        " Bild und Inputbox nebeneinander und vertikal zentriert
        DATA(lo_xml) = io_xml->hbox( justifycontent = 'Start'
                                     alignitems     = 'Center' ).
        DATA(lv_fw) = `40%`. "`50%`.

        ASSIGN mt_avatars[ element = iv_element ] TO FIELD-SYMBOL(<ls_avatar>).
        DATA(lv_ava_tabix) = sy-tabix.
        " *********************************************************************
        " Selektierter Wert
        " *********************************************************************

        lo_xml->hbox( class = 'sapUiSmallMargin' )->avatar_group( grouptype         = `Individual`
                                                                  avatardisplaysize = `XL`
                                                                  items             = ms_control-client->_bind( val       = <ls_avatar>-t_select
                                                                                                                tab       = mt_avatars
                                                                                                                tab_index = lv_ava_tabix )
                        )->avatar_group_item( initials     = `{INITIALS}`
                                              fallbackicon = `{FALLBACKICON}`
                                              src          = `{SRC}`
                                              tooltip      = `{NAME}` ).

      ELSE.
        lo_xml = io_xml.
        lv_fw = iv_fieldwidth.
      ENDIF.
      lo_xml->input( description      = ms_control-client->_bind( val       = ir_ktxt->*
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )

                     placeholder      = iv_placeholder
                     value            = ms_control-client->_bind( val       = ir_value->*
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )
                     editable         = iv_edit
                     textalign        = ms_control-client->_bind( val       = ir_uiattr->textalign
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )

                     valuestate       = ms_control-client->_bind( val       = ir_uiattr->valuestate
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )

                     valuestatetext   = ms_control-client->_bind( val       = ir_uiattr->valuestatetext
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )
                     required         = ms_control-client->_bind( val       = ir_mandatory->*
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )

                     showvaluehelp    = ms_control-client->_bind( val       = ir_uiattr->f4
                                                                  tab       = ms_fcat-data->*
                                                                  tab_index = iv_tabix )
                     valuehelprequest = _event( iv_name = 'POPUP_F4'
                                                it_arg  = VALUE #( BASE mt_def_arg
                                                                   ( |{ iv_fieldname }| )
                                                                   ( |{ iv_rowid }| ) ) )
                     submit           = _event( 'CHANGE' )
                     width            = '100%'
                     fieldwidth       = lv_fw  " If an input has a span over 4 columns and the fieldwidth is 50%, then the description and the input get each 2 columns
                     valueliveupdate  = abap_true
                     suggestionitems  = ms_control-client->_bind( val       = lr_sug->*
                                                                  tab       = mt_sug
                                                                  tab_index = lv_sug_index )
                     showsuggestion   = lv_show
*
                     )->get(
                     )->suggestion_items(
                     )->get(
                     )->list_item( text           = '{VALUE}'
                                   additionaltext = '{DESCR}' ).

      IF ir_uiattr->avatar = abap_true.
        " *********************************************************************
        " Werteliste
        " *********************************************************************
        " Empty label ( neue Zeile )
        io_xml->label( text    = ''
                       visible = abap_false
          )->vertical_layout( class = `sapUiContentPadding` ")

             )->avatar_group( grouptype         = `Individual`
                              avatardisplaysize = `L`
                              press             = ms_control-client->_event( val   = `AVATAR_PRESS`
                                                                             t_arg = VALUE #( BASE mt_def_arg
                                                                                              ( |{ iv_fieldname }| )
                                                                                              ( |{ iv_rowid }| )
                                                                                              ( |{ iv_element }| )
                                                                                              ( `$event.oSource.indexOfItem($event.getParameter("eventSource"))` )
                                                                                              ( `${$parameters>/overflowButtonPressed}` )
                                                                                              ( `$event.getParameter("eventSource").getId()` )
*                                                                                              ( `${INITIALS}` )
                                                                                            ) )

                              items             = ms_control-client->_bind( val       = <ls_avatar>-t_avatar
                                                                            tab       = mt_avatars
                                                                            tab_index = lv_ava_tabix )
                )->avatar_group_item( initials     = `{INITIALS}`
                                      fallbackicon = `{FALLBACKICON}`
                                      src          = `{SRC}`
                                      tooltip      = `{NAME}`
*                                      id           = `{ID}`
*                                      visible      = `{BLOCKED}`
                                      ).
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_objtyp~check_changes.
    IF mv_bound = abap_false.
      RETURN.
    ENDIF.
    " Änderungen in Mamba zurückschreiben
    DATA(lt_changes) = get_changes( ).
    IF lt_changes IS NOT INITIAL.
      mo_mamba->process( it_line_chg = lt_changes
                         is_action   = VALUE #( ) ).
      result = abap_true.
    ENDIF.
*    " View-Daten aktualisieren
*    get_objtyp_data( ).
  ENDMETHOD.

  METHOD prepare_fcat.
    CLEAR : et_fcat,
            ev_labeltype.

    ASSIGN ms_fcat-data->* TO FIELD-SYMBOL(<data_table>).

    LOOP AT ms_fcat-fieldcat ASSIGNING FIELD-SYMBOL(<valued>)
         WHERE no_out = abap_false.
      DATA(lv_where) = |{ <valued>-fieldname } IS NOT INITIAL OR { <valued>-fieldname }_UIATTR-EDIT IS NOT INITIAL|.
      TRY.
          " TODO: variable is assigned but never used (ABAP cleaner)
          LOOP AT <data_table> ASSIGNING FIELD-SYMBOL(<data>)
               WHERE (lv_where).
            EXIT.
          ENDLOOP.
        CATCH cx_sy_itab_dyn_loop INTO DATA(lx). " TODO: variable is assigned but never used (ABAP cleaner)
          lv_where = |{ <valued>-fieldname } IS NOT INITIAL|.
          LOOP AT <data_table> TRANSPORTING NO FIELDS
               WHERE (lv_where).
            EXIT.
          ENDLOOP.
      ENDTRY.

      IF sy-subrc = 0.
        " Nur die Spalten die wirklich befüllt sind sollen angezeigt werden.
        INSERT CORRESPONDING #( <valued> ) INTO TABLE et_fcat.
      ENDIF.
    ENDLOOP.

* FT20250804 Voraussichtlich deaktiviert : keine Mehhrfachelektion in der einfachen Liste
*    INSERT VALUE #( fieldname = 'MAMBA_SEL' ) INTO lt_fcat INDEX 1.

    IF line_exists( et_fcat[ fieldname = mc->fname_element ] ).
      ev_labeltype = 'E'. " Element
    ENDIF.
    IF line_exists( et_fcat[ fieldname = mc->fname_elementtext ] ).
      IF ev_labeltype IS NOT INITIAL.
        ev_labeltype = 'B'. " Both Element and Elementtext
      ELSE.
        ev_labeltype = 'T'. " Elementtext
      ENDIF.
    ELSEIF ev_labeltype IS INITIAL.
      ev_labeltype = 'E'.
    ENDIF.

    DELETE et_fcat WHERE fieldname = mc->fname_ktxt.
    DELETE et_fcat WHERE fieldname = mc->fname_icon.
    DELETE et_fcat WHERE fieldname = mc->fname_relattypicon.
    " Label enthält Element und/oder Elementttext
    DELETE et_fcat WHERE fieldname = mc->fname_element.
    DELETE et_fcat WHERE fieldname = mc->fname_elementtext.

    IF iv_edit = abap_false.
      " Im Anzeigemodus werden diese Spalten nicht separat ausgewiesen, sondern im VALUE-Feld konkateniert
      DELETE et_fcat WHERE fieldname = mc->fname_value_eih.
      DELETE et_fcat WHERE fieldname = mc->fname_rangetype.

    ENDIF.
  ENDMETHOD.

  METHOD do_jump.
    " *********************************************************************
    " Ermittelt Ziel OGUID GUID zu Absprung
    " *********************************************************************
    DATA(ls_event) = VALUE /sct/au5_if_client=>ty_s_get( event       = mcu->events-show_data   " AD, 2026.10.09, changed
                                                         t_event_arg = get_jump_node( is_get-t_event_arg ) ).

    IF ls_event-t_event_arg IS NOT INITIAL. " Keine GUIDs gefunden dann kein Jump.

      IF is_get-event = mc->action_jump.
        " JUMP
        ms_control-root_app->set_next_event( is_event = ls_event ).
      ELSE.
* JUMP (neuer Tab)
* Nichts passiert... siehe https://github.com/abap2UI5/abap2UI5/issues/398
*        ms_control-client->_event_client( val = ms_control-client->cs_event-open_new_tab
*                                          t_arg  = VALUE #( ( `https://www.google.com/search?q=abap2ui5&oq=abap2ui5` ) ) ).

        ls_event = get_jump_url( it_arg = ls_event-t_event_arg ).

        ms_control-root_app->set_next_event( is_event = ls_event ).

*        ms_control-client->timer_set(
*           interval_ms    = `0`
*           event_finished = ms_control-client->_event_client( val = ms_control-client->cs_event-open_new_tab
*                                         t_arg  = VALUE #( ( `https://www.google.com/search?q=abap2ui5&oq=abap2ui5` ) ) ) ).

      ENDIF.

* FT nicht mehr notwendig, die root app kümmert sich selber ob einen kompletten redraw notwendig ist.
*      IF NOT is_stateful( ).
*        ms_control-root_app->set_stringify( ).
*      ENDIF.
    ELSE.
      do_show_message( it_return  = VALUE #( ( type    = 'I'
                                               message = 'No Target found' ) )
                       iv_msgtype = 'I' ).
    ENDIF.
  ENDMETHOD.

  METHOD get_jump_node.
    TRY.
        " OGUID GUID OBJEKTTYP are 1,2,3
        DATA(lv_rowid) = CONV /sct/qp_rowid( it_arg[ 4 ] ).
        DATA(lv_fname) = CONV /sct/qp_fieldname( it_arg[ 5 ] ).
        DATA(lv_value) = CONV /sct/qp_value( it_arg[ 6 ] ).

      CATCH cx_root.
        RETURN.
    ENDTRY.

    DATA(lr_line) = mo_mamba->get_lineref_via_id( lv_rowid ).
    IF lr_line IS NOT BOUND.
      RETURN.
    ENDIF.

    ASSIGN lr_line->col[ element   = space
                         fieldname = lv_fname ] TO FIELD-SYMBOL(<ls_col>).
    IF sy-subrc <> 0.
      READ TABLE lr_line->col ASSIGNING <ls_col>
           WITH KEY field_dyn COMPONENTS fieldname_dyn = lv_fname.
    ENDIF.
    IF <ls_col> IS ASSIGNED.
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(lv_fieldname) = <ls_col>-fieldname.
    ELSE.
      lv_fieldname = lv_fname.
    ENDIF.
    IF <ls_col> IS NOT ASSIGNED OR <ls_col>-element = space. " MD190710 N2427 CHG
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(lv_element) = lr_line->element.
    ELSE.
      lv_element = <ls_col>-element.
    ENDIF.

    mo_cust->get_ttobel( EXPORTING iv_tobjel = <ls_col>-gruelm->tobjel
                         IMPORTING es_ttobel = DATA(ls_tobjel) ).

    IF ls_tobjel-jump IS INITIAL.
      RETURN.
    ENDIF.

    mo_cust->get_tjump( EXPORTING iv_jump  = ls_tobjel-jump
                        IMPORTING es_tjump = DATA(ls_tjump) ).

    " FuBa vorhanden?
    IF ls_tjump-fm <> '/SCT/QP_DO_JUMP_NODE'.
      RETURN.
    ENDIF.

    DATA ls_nodekey TYPE /sct/qp_s_qvc_data_sort.

    " Aktuell nur für bereits gespeicherte Knoten
    CASE ls_tobjel-texttabl.
      WHEN /sct/qp_cl_const=>toe-vart_key-guid.
        ls_nodekey-guid = CONV #( lv_value ).
        SELECT SINGLE guid,
                      oguid
          FROM /sct/qp_node
          WHERE guid = @ls_nodekey-guid
          INTO @DATA(ls_node).
      WHEN /sct/qp_cl_const=>toe-vart_key-vnr. " ES20131025 NOTE-3475
        ls_nodekey-vnr = CONV #( lv_value ).
        IF ls_tobjel-textfeld IS NOT INITIAL. " In abhängigkeit vom Status die Version ermitteln.#
          SELECT SINGLE node~vvs
            FROM /sct/qp_node              AS node
                 INNER JOIN /sct/qp_status AS status ON node~guid = status~guid

            WHERE node~vnr     = @ls_nodekey-vnr
              AND status~istat = @ls_tobjel-textfeld
            INTO @ls_nodekey-vvs.
        ENDIF.
        ls_nodekey-vvs = COND #( WHEN ls_nodekey-vvs IS INITIAL
                                 THEN '001'
                                 ELSE ls_nodekey-vvs ). " Default immer die erste Version ziehen

        SELECT SINGLE guid,
                      oguid
          FROM /sct/qp_node
          WHERE vnr = @ls_nodekey-vnr
            AND vvs = @ls_nodekey-vvs
          INTO @ls_node.

      WHEN /sct/qp_cl_const=>toe-vart_key-vname OR space.
        ls_nodekey-vname = lv_value.
        ls_nodekey-vart  = ls_tobjel-pruftabl.
        ls_nodekey-vtyp  = ls_tobjel-pruffeld.
        IF  ls_nodekey-vname IS NOT INITIAL
        AND ls_nodekey-vgrp  IS INITIAL.
          ls_nodekey-vgrp = mo_cust->get_vgrp( iv_vart = ls_nodekey-vart ).
        ENDIF.
        SELECT SINGLE guid,
                      oguid
          FROM /sct/qp_node
          WHERE vname = @ls_nodekey-vname
            AND vgrp  = @ls_nodekey-vgrp
          INTO @ls_node.

      WHEN /sct/qp_cl_const=>toe-vart_key-vnrvvs.
        ls_nodekey-vnr = CONV #( lv_value(10) ).
        ls_nodekey-vvs = CONV #( lv_value+11(3) ).
        SELECT SINGLE guid,
                      oguid
          FROM /sct/qp_node
          WHERE vnr = @ls_nodekey-vnr
            AND vvs = @ls_nodekey-vvs
          INTO @ls_node.

    ENDCASE.

    IF ls_node IS NOT INITIAL.
      result = VALUE #( ( CONV #( ls_node-oguid ) )
                        ( CONV #( ls_node-guid ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~actualize_bindings.
    " Wegen Limitationen in ABAP2UI5 Framework, was das Binding von globalen Daten angeht,
    " müssen alle globalen public Daten, die an der Oberfläche angezeigt und gebunden werden mussen,
    " müssen vorab mit _bind(  iv_fieldname = 'mv_my_global_data' ) angeprochen werden.
    " erst dann kann man in IF_UI_APP~DISPLAY( ) ms_control-client->_bind( mv_my_global_data ) nutzen

    get_objtyp_data( ).
    _bind( iv_fieldname = |ms_fcat-data->*| ).
    _bind( iv_fieldname = |ms_message-message| ).
    _bind( iv_fieldname = |mv_show_strip| ).
    _bind( iv_fieldname = |mt_avatars| ).
    _bind( iv_fieldname = |mt_sug| ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.

  METHOD popup_f4_element.
    IF mt_suggestion_sel IS INITIAL.
      RETURN.
    ENDIF.
    _bind( iv_fieldname = |mt_suggestion_sel| ).
    DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( ).

    DATA(lt_event_arguments) = ms_control-client->get( )-t_event_arg.

    popup->dialog( mutx->get_text( mutx->u012 )
      )->table( mode  = 'SingleSelectLeft'
                items = client->_bind( mt_suggestion_sel )
        )->columns(
            )->column( width = '20rem'
                )->text( iv_elemtext )->get_parent(
            )->column( width = '30rem'
                )->text( mutx->get_text( mutx->u041 ) " Beschreibung
        )->get_parent( )->get_parent(
        )->items(
            )->column_list_item( selected = '{SELKZ}'
                )->cells(
                    )->text( '{VALUE}'
                    )->text( '{DESCR}'
      )->get_parent( )->get_parent( )->get_parent( )->get_parent(
      )->buttons(
            )->button( text  = mutx->get_text( mutx->u033 ) " Ok
                       press = client->_event( val   = 'F4_ELEMENT_BACK'
                                               t_arg = lt_event_arguments )
                       type  = 'Emphasized' ).
    client->popup_display( popup->stringify( ) ).
  ENDMETHOD.

  METHOD popup_f4_value.
    DATA(lv_rowid) = CONV /sct/qp_rowid( is_get-t_event_arg[ 5 ] ).
    DATA(lv_fieldname) = CONV abp_field_name( is_get-t_event_arg[ 4 ] ).

    ASSIGN ms_fcat-data->*[ (mc->fname_rowid) = lv_rowid ] TO FIELD-SYMBOL(<line>).
    ASSIGN COMPONENT lv_fieldname OF STRUCTURE <line> TO FIELD-SYMBOL(<value>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(ls_r_modline) = mo_mamba->get_lineref_via_id( lv_rowid ).

    READ TABLE ls_r_modline->col ASSIGNING FIELD-SYMBOL(<ls_col>) WITH KEY field_dyn COMPONENTS fieldname_dyn = lv_fieldname.
    IF sy-subrc <> 0.
      ASSIGN ls_r_modline->col[ element   = space
                                fieldname = lv_fieldname ] TO <ls_col>.
    ENDIF.
    IF <ls_col> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    " Customizing übernehmen
    DATA(ls_gruelm) = <ls_col>-gruelm.

    IF lv_fieldname IN mo_mamba->mt_value_field.
      DATA lo_toe TYPE REF TO /sct/qp_if_toe.

      /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                        CHANGING  co_instance  = lo_toe ).

      lo_toe->f4_call( is_toe       = VALUE #( element    = COND #( WHEN <ls_col>-element IS NOT INITIAL
                                                                    THEN <ls_col>-element
                                                                    ELSE ls_r_modline->element )
                                               value      = <value>
                                               value_type = lo_toe->get_value_type( ir_tobel = ls_gruelm->tobel
                                                                                    iv_field = lv_fieldname )
                                               gruelm     = ls_gruelm
                                               objekttyp  = ls_r_modline->objekttyp
                                               rowgrp     = ls_r_modline->rowgrp
                                               valid_date = ms_obj-base->instance->get_expl_date( )
                                               o_node     = mo_mamba->mo_parent
                                               o_mamba    = mo_mamba )
                       iv_disponly  = abap_false
                       io_ui_client = ms_control-client
                       is_callback  = VALUE #( s_get-event       = 'F4_VALUE_BACK'
                                               s_get-t_event_arg = is_get-t_event_arg ) ).

    ELSEIF lv_fieldname = mc->fname_value_eih
        OR lv_fieldname = mc->fname_solleinh
        OR lv_fieldname = mc->fname_sollinteinh
        OR lv_fieldname = mc->fname_altzeugeinh.

      " is_callback-named_params ermöglicht, Zusatzwerte an der Suchhilfe-Interface zu setzen,
      " wie z.B hier DIMID, um die Wertehilfe einzuschränken zu können

      DATA(lo_ui_f4) = /sct/qp_cl_ui_searchhelp=>get_instance( ).
      lo_ui_f4->init( iv_shlp     = '/SCT/QP_SH_UNIT'
                      is_callback = VALUE #( s_get-event       = 'F4_VALUE_BACK'
                                             s_get-t_event_arg = is_get-t_event_arg
                                             fieldname         = mc->shlpfield_msehi
                                             named_params      = VALUE #( ( n = mc->shlpfield_dimid
                                                                            v = ls_gruelm->dimid ) ) ) ).
      ms_control-client->nav_app_call( CAST /sct/au5_if_app( lo_ui_f4 ) ).

    ENDIF.
  ENDMETHOD.

  METHOD get_jump_url.
    DATA(lv_guid) = VALUE #(  it_arg[ 2 ] OPTIONAL ).
    IF lv_guid IS INITIAL.
      RETURN.
    ENDIF.

    " CleanCore
    DATA(lv_target_guid) = to_lower( xco_cp=>uuid( CONV /sct/qp_guid( lv_guid ) )->as( xco_cp_uuid=>format->c36 )->value ).

*    CALL FUNCTION 'CONVERSION_EXIT_FUUID_OUTPUT' EXPORTING input  = CONV /sct/qp_guid( lv_guid )
*                                                 IMPORTING output = lv_target_guid.

    DATA(ls_get) = ms_control-client->get( ).
    DATA(lv_url) = |{ ls_get-s_config-origin }{ ls_get-s_config-pathname }|.

    result-event = 'OPEN_NEW_TAB'.

    IF ls_get-check_launchpad_active = abap_true. " GUID steht in HASH-Teil sonst im SEARCH-Teil
      " GUID in die URL packen
      SPLIT ls_get-s_config-hash AT 'GUID=' INTO DATA(part1) DATA(part2).

      IF part2 IS INITIAL.
        " Kein GUID drin, anfügen
        SPLIT part1 AT '&' INTO DATA(vorne) DATA(hinten).
        lv_url = |{ lv_url }{ ls_get-s_config-search }{ vorne }?GUID={ lv_target_guid }&{ hinten }|.
      ELSE.
        " GUIDS ersetzen
        SPLIT part2 AT '&' INTO DATA(guid) DATA(other_args).
        lv_url = |{ lv_url }{ ls_get-s_config-search }{ part1 }GUID={ lv_target_guid }&{ other_args }|.
      ENDIF.

    ELSE.

      " GUID in die URL packen
      SPLIT ls_get-s_config-search AT 'GUID=' INTO part1 part2.

      IF part2 IS INITIAL.
        " Kein GUID drin, anfügen
        lv_url = |{ lv_url }{ ls_get-s_config-search }&GUID={ lv_target_guid }|.
      ELSE.
        " GUIDS ersetzen
        SPLIT part2 AT '&' INTO guid other_args.
        lv_url = |{ lv_url }{ part1 }GUID={ lv_target_guid }&{ other_args }|.
      ENDIF.

    ENDIF.

    result-t_event_arg = VALUE #( ( lv_url ) ).
  ENDMETHOD.

  METHOD avatar_group_popover.
    DATA(view) = /sct/au5_cl_xml_view=>factory_popup( ).

    DATA(lr_avatar) = REF #( mt_avatars[ element = iv_element ] ).
    DATA(lv_tabindex) = line_index( mt_avatars[ element = iv_element ] ).
    _bind( iv_fieldname = |mt_avatars| ).

    DATA(nav_container) = view->popover( id            = `groupPopover`
                                         class         = `sapFAvatarGroupPopover`
                                         showheader    = abap_false
                                         contentwidth  = '50%' " ms_control-client->_bind( content_width )
                                         contentheight = '50%' " ms_control-client->_bind( content_height )
                                         placement     = `Bottom`
                                         afterclose    = _event( 'POPOVER_CLOSE' )
                                                         )->nav_container( id = `navContainer` ).

    nav_container->page( id             = `main`
                         titlealignment = `Center`
                         title          = lr_avatar->label " |#Values ({ lines( lr_avatar->t_avatar ) })|
                )->vertical_layout( class = `sapUiTinyMarginTop`
                                    width = `100%`
                    )->grid( default_span = `XL4 L4 M6 S12`
                             content      = ms_control-client->_bind( val       = lr_avatar->t_avatar
                                                                      tab       = mt_avatars
                                                                      tab_index = lv_tabindex )

                        )->hbox( alignitems = `Center`
                            )->vbox(
                                )->avatar( class        = `sapUiTinyMarginEnd`
                                           initials     = `{INITIALS}`
                                           fallbackicon = `{FALLBACKICON}`
                                           src          = `{SRC}`
                                           badgetooltip = `{NAME}`
                                           press        = ms_control-client->_event( val   = `AVATAR_PRESS`
                                                                                     t_arg = VALUE #( BASE mt_def_arg
                                                                                                      ( |{ iv_fieldname }| )
                                                                                                      ( |{ iv_rowid }| )
                                                                                                      ( |{ iv_element }| )
                                                                                                      ( ` ` )
                                                                                                      ( ` ` )
                                                                                                      ( ` ` )
                                                                                                      ( `${ID}` ) ) )

                            )->get_parent(
                            )->vbox(
                                )->text( text = `{NAME}`                                 ).

    ms_control-client->popover_display( xml   = view->stringify( )
                                        by_id = id ).

    ms_control-root_app->popover_open( iv_close_event = 'POPOVER_CLOSE' ).
  ENDMETHOD.

  METHOD get_avatar_initials.
    IF strlen( iv_value ) >= 3.
      result = iv_value(3).
    ELSE.
      result = iv_value.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
