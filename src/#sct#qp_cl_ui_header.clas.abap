CLASS /sct/qp_cl_ui_header DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_header.

    DATA mr_status TYPE REF TO /sct/qp_if_ui_app=>ty_s_status_display.
    DATA mt_status TYPE STANDARD TABLE OF /sct/qp_if_ui_app=>ty_s_status_display.
    DATA mr_header TYPE REF TO /sct/qp_s_header.
    DATA mt_header TYPE STANDARD TABLE OF /sct/qp_s_header.

    METHODS do_process_saved.
    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_objtyp~check_changes   REDEFINITION.

  PROTECTED SECTION.
    METHODS do_show_data.

    METHODS get_description IMPORTING is_component    TYPE /sct/qp_s_components
                            RETURNING VALUE(r_result) TYPE string.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_HEADER IMPLEMENTATION.


  METHOD constructor.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->constructor( is_obj ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_conv ).
  ENDMETHOD.


  METHOD process_fcode_self.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.

    IF is_get-event = mcu->events-change.
      check_changes( ).
    ENDIF.

*    CASE is_get-event.
*      WHEN mcu->events-show_data.
*        TRY.
*            do_show_data( iv_guid = CONV #( is_get-t_event_arg[ 1 ] ) ).
*          CATCH cx_sy_itab_line_not_found.
*        ENDTRY.
*    ENDCASE.
  ENDMETHOD.


  METHOD do_show_data.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

*    ms_header = ms_control-base->instance->mo_header->ms_header.  verschoben in actualize_bindings

    DATA lv_ertstmp       TYPE /sct/qp_value.
    DATA lv_aetstmp       TYPE /sct/qp_value.
    DATA lv_guelttstmp_fr TYPE /sct/qp_value.
    DATA lv_guelttstmp_to TYPE /sct/qp_value.
    DATA lv_ername        TYPE /sct/qp_ername.
    DATA lv_aename        TYPE /sct/qp_aename.
    DATA lv_relname       TYPE /sct/qp_relname.
    DATA lv_reltstmp      TYPE /sct/qp_value.
    DATA lv_zustbereich   TYPE /sct/qp_zustbereich.
    DATA lv_benutzer      TYPE syuname.
    DATA lv_auth_group    TYPE /sct/qp_auth_group.
    DATA lv_guid          TYPE /sct/qp_guid.
    DATA lv_oguid         TYPE /sct/qp_oguid.
    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    DATA lv_prevoguid     TYPE /sct/qp_oguid.
    DATA lv_vnr           TYPE /sct/qp_vnr.
    DATA lv_vvs           TYPE /sct/qp_vvs.
    DATA lv_vart          TYPE /sct/qp_vart.
    DATA lv_vtyp          TYPE /sct/qp_vtyp.
    DATA lv_knotentyp     TYPE /sct/qp_knotentyp.
    DATA lt_components    TYPE /sct/qp_t_components.

    lv_ername = mr_header->ername.
    lv_ertstmp = mr_header->erdat && mr_header->ertime.
    lv_aename = mr_header->aename.
    lv_aetstmp = mr_header->aedat && mr_header->aetime.
    lv_guelttstmp_fr = mr_header->validfr.
    lv_guelttstmp_to = mr_header->validto.
    lv_relname = mr_header->relname.
    lv_reltstmp = mr_header->reldat && mr_header->reltime.

    lv_zustbereich = mr_header->zustbereich.
    lv_benutzer = mr_header->benutzer.
    lv_auth_group = mr_header->auth_group.

    lv_guid = mr_header->guid.
    lv_oguid = mr_header->oguid.
    lv_prevoguid = mr_header->prevoguid.
    lv_vnr = mr_header->vnr.
    lv_vvs = mr_header->vvs.
    lv_vart = mr_header->vart.
    lv_vtyp = mr_header->vtyp.
    lv_knotentyp = mr_header->knotentyp.

    " DDIC Mittellangtextelemente - Eventuell Kapseln
    lt_components = mo_tools->get_struct_comp( is_data = mr_header->* ).
    LOOP AT lt_components ASSIGNING FIELD-SYMBOL(<component>).
      " DATA(lv_debug_comp) = get_description( <component> ).
      CASE <component>-name.

        WHEN 'VNR'.
          DATA(lv_vnr_desc) = get_description( <component> ).
        WHEN 'VNAME'.
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(lv_vname_desc) = get_description( <component> ).
        WHEN 'GUID'.
          DATA(lv_guid_desc) = get_description( <component> ).
        WHEN 'VVS'.
          DATA(lv_vvs_desc) = get_description( <component> ).
        WHEN 'KNOTENTYP'.
          DATA(lv_knotentyp_desc) = get_description( <component> ).
        WHEN 'VART'.
          DATA(lv_vart_desc) = get_description( <component> ).
        WHEN 'VTYP'.
          DATA(lv_vtyp_desc) = get_description( <component> ).
        WHEN 'VALIDFR'.
          DATA(lv_validfr_desc) = get_description( <component> ).
        WHEN 'VALIDTO'.
          DATA(lv_validto_desc) = get_description( <component> ).
        WHEN 'OGUID'.
          DATA(lv_oguid_desc) = get_description( <component> ).
*        WHEN 'PREVOGUID'.
*          DATA(lv_prevoguid_desc) = get_description( <component> ).
        WHEN 'ZUSTBEREICH'.
          DATA(lv_zustbereich_desc) = get_description( <component> ).
        WHEN 'BENUTZER'.
          DATA(lv_benutzer_desc) = get_description( <component> ).
        WHEN 'AUTH_GROUP'.
          DATA(lv_auth_group_desc) = get_description( <component> ).
        WHEN 'RELDAT'.
          DATA(lv_reldat_desc) = get_description( <component> ).
*        WHEN 'RELTIME'.
*          " TODO: variable is assigned but never used (ABAP cleaner)
*          DATA(lv_reltime_desc) = get_description( <component> ).
        WHEN 'RELNAME'.
          DATA(lv_relname_desc) = get_description( <component> ).
        WHEN 'ERDAT'.
          DATA(lv_erdat_desc) = get_description( <component> ).
*        WHEN 'ERTIME'.
*          " TODO: variable is assigned but never used (ABAP cleaner)
*          DATA(lv_ertime_desc) = get_description( <component> ).
        WHEN 'ERNAME'.
          DATA(lv_ername_desc) = get_description( <component> ).
        WHEN 'AEDAT'.
          DATA(lv_aedat_desc) = get_description( <component> ).
*        WHEN 'AETIME'.
*          " TODO: variable is assigned but never used (ABAP cleaner)
*          DATA(lv_aetime_desc) = get_description( <component> ).
        WHEN 'AENAME'.
          DATA(lv_aename_desc) = get_description( <component> ).

      ENDCASE.
    ENDLOOP.

    mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_ertstmp ).
    mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_aetstmp ).
    mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_guelttstmp_fr ).
    mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_guelttstmp_to ).
    mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_reltstmp ).

*    mo_cust->get_tvart( EXPORTING iv_vart  = mr_header->vart
*                                 " TODO: variable is assigned but never used (ABAP cleaner)
*                        IMPORTING es_tvart = DATA(ls_tvart) ).

    DATA(lo_object_page_section) = ms_control-parent_view->object_page_section( titlevisible = abap_false
                                                                                showtitle    = abap_false ).

    DATA(lo_subsection) = lo_object_page_section->object_page_sub_section( titlevisible = abap_false
                                                                           showtitle    = abap_false ).

    IF is_editable( ) = abap_false.
      " --------------------------------------------------------------------*
*      DATA(lo_block1)  = lo_subsection->blocks( ).
*      DATA(lo_vbox_v1) = lo_block1->vbox( class = 'sapUiLargeMarginEnd sapUiSmallMarginBottom' ).
*
*      DATA(lo_hbox_v1_h1) = lo_vbox_v1->hbox( rendertype = 'Bare'
*                                              class      = 'sapUiTinyMarginBottom' ).
*      lo_hbox_v1_h1->label( class = 'sapUiTinyMarginEnd'
*                            text  = mutx->get_text( mutx->u054 )  ). " Nummer
*      lo_hbox_v1_h1->text( text = get_node_vnr( ms_control-base ) ).
*
*      DATA(lo_hbox_v1_h2) = lo_vbox_v1->hbox( rendertype = 'Bare'
*                                              class      = 'sapUiTinyMarginBottom' ).
*      lo_hbox_v1_h2->label( class = 'sapUiTinyMarginEnd'
*                            text  = mutx->get_text( mutx->u052 )  ). " Name
*      lo_hbox_v1_h2->text( text               = |{ mr_header->vname }|
*                           emptyindicatormode = 'On' ).
*
*      DATA(lo_hbox_v1_h3) = lo_vbox_v1->hbox( rendertype = 'Bare'
*                                              class      = 'sapUiTinyMarginBottom' ).
*      lo_hbox_v1_h3->label( class = 'sapUiTinyMarginEnd'
*                            text  = mutx->get_text( mutx->u053 )  ). " Bezeichnung
*      lo_hbox_v1_h3->text( text               = |{ mr_header->vtext }|
*                           emptyindicatormode = 'On' ).

      " AlternativLayout

      DATA(lo_simplef2) = lo_subsection->simple_form( title           = mutx->get_text( mutx->u055 )
                                                      layout          = 'ResponsiveGridLayout'
                                                      labelspanxl     = '5'
                                                      labelspanl      = '5'
                                                      labelspanm      = '12'
                                                      labelspans      = '12'
                                                      adjustlabelspan = 'true'
                                                      emptyspanxl     = '1'
                                                      emptyspanl      = '1'
                                                      emptyspanm      = '0'
                                                      emptyspans      = '0' ).

      DATA(lo_simplef_content2) = lo_simplef2->content( ns = 'form' ).

      lo_simplef_content2->label( text = mutx->get_text( mutx->u054 ) ). " Nummer
      lo_simplef_content2->text( text = get_node_vnr( ms_control-base ) ).

      lo_simplef_content2->label( text = mutx->get_text( mutx->u052 ) ). " Name
      lo_simplef_content2->text( text               = |{ mr_header->vname }|
                                 emptyindicatormode = 'On' ).

      lo_simplef_content2->label( text = mutx->get_text( mutx->u053 ) ). " Bezeichnung
      lo_simplef_content2->text( text               = |{ mr_header->vtext }|
                                 emptyindicatormode = 'On' ).

      " --------------------------------------------------------------------*
    ELSE. " Change Mode
      DATA(lo_simplef) = lo_subsection->simple_form( title            = mutx->get_text( mutx->u056 )
                                                     layout           = 'ResponsiveGridLayout'
                                                     editable         = 'true'
                                                     backgrounddesign = 'Translucent'
                                                     width            = '100%' ).

      DATA(lo_simplef_content) = lo_simplef->content( ns = 'form' ).

      lo_simplef_content->label( text = mutx->get_text( mutx->u054 ) ). " Nummer
      lo_simplef_content->text( text = get_node_vnr( ms_control-base ) ).

      lo_simplef_content->label( text = mutx->get_text( mutx->u052 ) ). " Name

      lo_simplef_content->input( placeholder = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mr_header->vname ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                                 value       = ms_control-client->_bind( val       = mr_header->vname
                                                                         tab       = mt_header
                                                                         tab_index = 1 )

                                 submit      = _event( mcu->events-change ) ).

      lo_simplef_content->label( text = mutx->get_text( mutx->u053 ) ). " Bezeichnung

      lo_simplef_content->input( placeholder = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mr_header->vtext ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                                 value       = ms_control-client->_bind( val       = mr_header->vtext
                                                                         tab       = mt_header
                                                                         tab_index = 1 )
                                 submit      = _event( mcu->events-change ) ).

    ENDIF.
    " --------------------------------------------------------------------*
    DATA(lo_block2) = lo_subsection->blocks( ).

    DATA(lo_simplef6) = lo_block2->simple_form( layout          = 'ResponsiveGridLayout'
                                                title           = mutx->get_text( mutx->u042 ) " Status
                                                labelspanxl     = '6'
                                                labelspanl      = '6'
                                                labelspanm      = '6'
                                                labelspans      = '12'
                                                adjustlabelspan = 'false'
                                                emptyspanxl     = '0'
                                                emptyspanl      = '0'
                                                emptyspanm      = '0'
                                                emptyspans      = '0'
                                                columnsxl       = '0'
                                                columnsl        = '0'
                                                columnsm        = '0' ).
    DATA(lo_simplef6_c) = lo_simplef6->content( ns = 'form' ).

    lo_simplef6_c->object_status( state = ms_control-client->_bind( val       = mr_status->state
                                                                    tab       = mt_status
                                                                    tab_index = 1 )
                                  text  = ms_control-client->_bind( val       = mr_status->text
                                                                    tab       = mt_status
                                                                    tab_index = 1 )
                                  class = 'sapMObjectStatusLarge' ).

*    DATA(lo_vbox_v2) = lo_block2->vbox( class = 'sapUiLargeMarginEnd sapUiSmallMarginBottom' ).
*
*    lo_vbox_v2->title( text  = mutx->get_text( mutx->u042 ) " Status
*                       class = 'sapUiTinyMarginEnd' ).
*
*    ms_status-text  = get_status_text( ).
*    ms_status-state = get_status_state( ).
*
*    lo_vbox_v2->object_status( state = _bind( iv_edit = abap_true
*                                              ir_data = REF #( ms_status-state )
*                                              iv_name = 'HeaderStatusState' )
*                               text  = _bind( iv_edit = abap_true
*                                              ir_data = REF #( ms_status-text )
*                                              iv_name = 'HeaderStatusText' )
*                               class = 'sapMObjectStatusLarge' ).
    " --------------------------------------------------------------------*
    " Show More Textbloecke - Admin-Daten
    " Verwaltungsdaten
    DATA(lo_more_block1) = lo_subsection->more_blocks( ).
    DATA(lo_simplef3) = lo_more_block1->simple_form( layout          = 'ResponsiveGridLayout'
                                                     title           = mutx->get_text( mutx->u005 ) " Verwaltungsdaten
                                                     labelspanxl     = '6'
                                                     labelspanl      = '6'
                                                     labelspanm      = '6'
                                                     labelspans      = '12'
                                                     adjustlabelspan = 'false'
                                                     emptyspanxl     = '0'
                                                     emptyspanl      = '0'
                                                     emptyspanm      = '0'
                                                     emptyspans      = '0'
                                                     columnsxl       = '0'
                                                     columnsl        = '0'
                                                     columnsm        = '0' ).
    DATA(lo_simplef3_c) = lo_simplef3->content( ns = 'form' ).

    lo_simplef3_c->label( text = lv_ername_desc ). " Author
    lo_simplef3_c->text( text               = lv_ername
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_erdat_desc ). " Author Date
    lo_simplef3_c->text( text               = lv_ertstmp
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_aename_desc ). " Last Author
    lo_simplef3_c->text( text               = lv_aename
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_aedat_desc ). " Last Change Date
    lo_simplef3_c->text( text               = lv_aetstmp
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_relname_desc ). " Released by
    lo_simplef3_c->text( text               = lv_relname
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_reldat_desc ). " Released from Date
    lo_simplef3_c->text( text               = lv_reltstmp
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_validfr_desc ). " Valid from Date
    lo_simplef3_c->text( text               = lv_guelttstmp_fr
                         emptyindicatormode = 'On' ).

    lo_simplef3_c->label( text = lv_validto_desc ). " Valid until Date
    lo_simplef3_c->text( text               = lv_guelttstmp_to
                         emptyindicatormode = 'On' ).

    " --------------------------------------------------------------------*
    " Zustaendigkeit
    DATA(lo_simplef4) = lo_more_block1->simple_form( layout          = 'ResponsiveGridLayout'
                                                     title           = mutx->get_text( mutx->u006 ) " Zustaendigkeit
                                                     labelspanxl     = '6'
                                                     labelspanl      = '6'
                                                     labelspanm      = '6'
                                                     labelspans      = '12'
                                                     adjustlabelspan = 'false'
                                                     emptyspanxl     = '0'
                                                     emptyspanl      = '0'
                                                     emptyspanm      = '0'
                                                     emptyspans      = '0'
                                                     columnsxl       = '0'
                                                     columnsl        = '0'
                                                     columnsm        = '0' ).
    DATA(lo_simplef4_c) = lo_simplef4->content( ns = 'form' ).

    lo_simplef4_c->label( text = lv_zustbereich_desc ). " Zust. Bereich

    IF lv_zustbereich IS NOT INITIAL.
      mo_cust->get_trespon( EXPORTING iv_zustbereich = lv_zustbereich
                            IMPORTING es_trespon     = DATA(ls_trespon) ).

      lv_zustbereich = |{ ls_trespon-zustbezeich } ({ lv_zustbereich })|.
    ENDIF.
    lo_simplef4_c->text( text               = lv_zustbereich
                         emptyindicatormode = 'On' ).

    lo_simplef4_c->label( text = lv_benutzer_desc ). " Sachbearbeiter
    lo_simplef4_c->text( text               = lv_benutzer
                         emptyindicatormode = 'On' ).

    lo_simplef4_c->label( text = lv_auth_group_desc ). " Authorization

    IF lv_auth_group IS NOT INITIAL.
      mo_cust->get_tauthg( EXPORTING iv_auth_group = lv_auth_group
                           IMPORTING es_tauthg     = DATA(ls_tauthg) ).

      lv_auth_group = |{ ls_tauthg-auth_group_text } ({ lv_auth_group })|.
    ENDIF.
    lo_simplef4_c->text( text               = lv_auth_group
                         emptyindicatormode = 'On' ).
    " --------------------------------------------------------------------*
    " Technische Daten
    DATA(lo_simplef5) = lo_more_block1->simple_form( layout          = 'ResponsiveGridLayout'
                                                     title           = mutx->get_text( mutx->u007 ) " Technische Daten
                                                     labelspanxl     = '6'
                                                     labelspanl      = '6'
                                                     labelspanm      = '6'
                                                     labelspans      = '12'
                                                     adjustlabelspan = 'false'
                                                     emptyspanxl     = '0'
                                                     emptyspanl      = '0'
                                                     emptyspanm      = '0'
                                                     emptyspans      = '0'
                                                     columnsxl       = '0'
                                                     columnsl        = '0'
                                                     columnsm        = '0' ).
    DATA(lo_simplef5_c) = lo_simplef5->content( ns = 'form' ).

    lo_simplef5_c->label( text = lv_guid_desc ). " Vorsch. GUID
    lo_simplef5_c->text( text               = |{ lv_guid }|
                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_oguid_desc ). " Origin. GUID
    lo_simplef5_c->text( text               = |{ lv_oguid }|
                         emptyindicatormode = 'On' ).

*    lo_simplef5_c->label( text = lv_prevoguid_desc ). " Prev Origin. GUID
*    lo_simplef5_c->text( text               = |{ lv_prevoguid }|
*                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_vnr_desc ). " Vorsch. NR.
    lo_simplef5_c->text( text               = lv_vnr
                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_vvs_desc ). " Version
    lo_simplef5_c->text( text               = lv_vvs
                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_vart_desc ). " Vorsch. Art.

*    IF lv_vart IS NOT INITIAL.
*      mo_cust->get_tvart( EXPORTING iv_vart  = mr_header->vart
*                          IMPORTING es_tvart = DATA(ls_tvart) ).
*      DATA(lv_vart_string) = |{ ls_tvart-varttext } ({ lv_vart })|.
*    ENDIF.
    lo_simplef5_c->text( text               = lv_vart
                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_vtyp_desc ). " Pos. Typ
*    IF lv_vtyp IS NOT INITIAL.
*      mo_cust->get_tvtyp( EXPORTING iv_vtyp  = mr_header->vtyp
*                          IMPORTING es_tvtyp = DATA(ls_tvtyp) ).
*      data(lv_vtyp_string) = |{ ls_tvtyp-vtyptext } ({ lv_vtyp })|.
*    ENDIF.

    lo_simplef5_c->text( text               = lv_vtyp
                         emptyindicatormode = 'On' ).

    lo_simplef5_c->label( text = lv_knotentyp_desc ). " Rel. Typ Node

    lo_simplef5_c->text( text               = lv_knotentyp
                         emptyindicatormode = 'On' ).
    " --------------------------------------------------------------------*
  ENDMETHOD.


  METHOD do_process_saved.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-client      = io_client.
    ms_control-parent_view = io_view.
    do_show_data( ).
  ENDMETHOD.


  METHOD get_description.
    DATA(lv_rollname) = CONV abp_field_name( is_component-type->get_relative_name( ) ).

    " Möchtegern CleanCore
    SELECT SINGLE ABAPLongFieldLabel
      FROM I_DataElementLabelText
      WHERE ABAPDataElement = @lv_rollname
        AND Language        = @sy-langu
      INTO @r_result.
*    CALL FUNCTION 'DDIF_DTEL_GET' EXPORTING  name          = lv_rollname
*                                             langu         = sy-langu
*                                  IMPORTING  dd04v_wa      = l_dd04v
*                                  EXCEPTIONS illegal_input = 1
*                                             OTHERS        = 2 ##FM_SUBRC_OK.
*    r_result = l_dd04v-scrtext_l.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
    IF mv_bound = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_flag) = ms_control-base->instance->mo_header->ms_control-is_changed.
    mr_header = REF #( mt_header[ 1 ] ).
    ms_control-base->instance->mo_header->set_header_pai( is_header = mr_header->* ).

    IF ms_control-base->instance->mo_header->ms_control-is_changed = abap_true.
      IF lv_flag = abap_false.
        result = abap_true.
      ELSE.
        result = abap_undefined.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    IF mt_header IS INITIAL.
      INSERT INITIAL LINE INTO TABLE mt_header.
    ENDIF.
    mr_header = REF #( mt_header[ 1 ] ).
    mr_header->* =  ms_control-base->instance->mo_header->ms_header.

    IF mt_status IS INITIAL.
      INSERT INITIAL LINE INTO TABLE mt_status.
    ENDIF.

    _bind( iv_fieldname = 'mt_header' ).
    _bind( iv_fieldname = 'mt_status' ).

    mr_status = REF #( mt_status[ 1 ] ).
    mr_status->text  = get_status_text( ).
    mr_status->state = get_status_state( ).

    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.
ENDCLASS.
