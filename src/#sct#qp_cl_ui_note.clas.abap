CLASS /sct/qp_cl_ui_note DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

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
    TYPES:
      BEGIN OF s_suggestion_items,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF s_suggestion_items.

    DATA ms_fcat TYPE /sct/qp_s_fcat.
    DATA mv_edit TYPE abap_boolean.
    DATA mt_sug  TYPE tty_elem_sug.
    DATA mt_text TYPE /sct/qp_t_stx_data.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_objtyp~check_changes   REDEFINITION.

  PROTECTED SECTION.
    DATA mo_text TYPE REF TO /sct/qp_if_text.

    "! <p class="shorttext synchronized">Baut die Toolbar auf</p>
    "! Kontextabhängig, werden unterschiedlichen Drucktasten zur Verfügung gestellt
    "! @parameter IO_VIEW | <p class="shorttext synchronized"></p>
    METHODS set_toolbar IMPORTING io_view TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_show_text.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter IS_GET       | <p class="shorttext synchronized"></p>
    "! @parameter RV_PROCESSED | <p class="shorttext synchronized"></p>
    METHODS process_event                                                                    " AD, 2026.10.09, changed
                          IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get
                          RETURNING VALUE(rv_processed) TYPE abap_bool.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter STATEFUL | <p class="shorttext synchronized"></p>
    METHODS set_session_stateful IMPORTING stateful TYPE abap_bool.

    METHODS init               REDEFINITION.
    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_NOTE IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~display.
*    get_objtyp_data( ).
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.
    do_show_text( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    init( ms_control-client ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
    IF mv_bound = abap_false.
      RETURN.
    ENDIF.
    LOOP AT mt_text ASSIGNING FIELD-SYMBOL(<text>).

      mo_tools->do_convert_string_to_text( EXPORTING iv_string = <text>-stx_text
                                           IMPORTING et_tline  = DATA(lt_tline) ).
      DATA(ls_result) = mo_text->process( is_data = VALUE #( action = mc->action_update
                                                             stx    = VALUE #( BASE <text>
                                                                               tline = lt_tline ) ) ).

      IF ls_result-changed = abap_true.
        result = abap_true.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( is_obj ).
*    IF is_obj IS NOT INITIAL.
*      ms_obj = is_obj.
*    ELSE.
*      start_standalone = abap_true.
*    ENDIF.
  ENDMETHOD.


  METHOD do_show_text.
    DATA(lo_view) = ms_control-parent_view.

    lo_view = ms_control-parent_view->scroll_container( " height     = '70%'
                                                        width      = '100%'
*                                                        vertical   = abap_true
                                                        horizontal = abap_true ).

    DATA(lv_edit) = is_editable( ).

*    DATA(lo_hbox) = lo_view->horizontal_layout( id    = `vl2

    LOOP AT mt_text ASSIGNING FIELD-SYMBOL(<stx>).
      DATA(lv_tabindex) = sy-tabix.

      lo_view->text_area( value           = ms_control-client->_bind( val       = <stx>-stx_text
                                                                      tab       = mt_text
                                                                      tab_index = lv_tabindex )
                          valueliveupdate = abap_true
*                          livechange      = _event( iv_name = 'TEXT_POST' )  "Nicht optimal für die Pflege (busy)
                          growing         = abap_true
                          growingmaxlines = '7'
                          width           = '100%'
                          placeholder     = 'Insert Text here'
                          editable        = lv_edit ).

    ENDLOOP.
    lo_view->button( text    = 'Ok'
*                     icon    =
*                     type    =
*                     enabled =
                     visible = lv_edit
                     press   = _event( iv_name = 'TEXT_POST' )
*                     class   =
*                     id      =
*                     ns      =
*                     tooltip =
*                     width   =
*                     iconfirst =
*                     icondensityaware =
*                     ariahaspopup =
*                     activeicon =
*                     accessiblerole =
*                     textdirection =
*                     arialabelledby =
*                     ariadescribedby =
*        RECEIVING
*                     result  =
    ).
  ENDMETHOD.


  METHOD init.
    ms_control-client = client.

    mo_text ?= ms_obj-object.

    CLEAR mt_text.
    LOOP AT mo_text->mt_text ASSIGNING FIELD-SYMBOL(<text>)
         WHERE data_ref IS BOUND.
      INSERT <text>-data_ref->* INTO TABLE mt_text.
    ENDLOOP.
*    mt_text = mo_text->mt_text.
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc ).
  ENDMETHOD.


  METHOD process_event.
    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.

    CASE is_get-event.

      WHEN 'TEXT_POST'.
        check_changes( ).

        rv_processed = abap_true.
      WHEN OTHERS.
*
*        DATA(ls_action) = VALUE /sct/qp_s_mamba_action( action = is_get-event ).
*        mt_sel = CORRESPONDING #( ms_fcat-data->* ).
*        DELETE mt_sel WHERE mamba_sel IS INITIAL.
*        LOOP AT mt_sel ASSIGNING FIELD-SYMBOL(<sel>).
*          INSERT <sel>-rowid INTO TABLE ls_action-rows.
*        ENDLOOP.
*
*        mo_mamba->process( ir_base   = ms_obj-base
*                           is_action = ls_action ).

    ENDCASE.
  ENDMETHOD.


  METHOD process_fcode_self.
    rv_processed = process_event( is_get ).
  ENDMETHOD.


  METHOD set_session_stateful.
    ms_control-client->set_session_stateful( stateful ).
    ms_control-client->view_model_update( ).
  ENDMETHOD.


  METHOD set_toolbar.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    _bind( iv_fieldname = |mt_text| ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.
ENDCLASS.
