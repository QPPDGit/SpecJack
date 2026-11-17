CLASS /sct/qp_cl_ui_selection DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/qp_if_ui_selection.

*    ALIASES mr_selfields  FOR /sct/qp_if_ui_selection~mr_selfields.
    ALIASES mt_selfields  FOR /sct/qp_if_ui_selection~mt_selfields.
    ALIASES init          FOR /sct/qp_if_ui_app~init.
    ALIASES process_fcode FOR /sct/qp_if_ui_app~process_fcode.

    DATA mv_max_sel_count TYPE i. " string wird bei input( type = Number ) nicht unterstützt
    DATA mv_max_bom_level TYPE i. " string wird bei input( type = Number ) nicht unterstützt

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_description,
        name      TYPE string,
        scrtext_l TYPE string,
        shlpname  TYPE shlpname,
        convexit  TYPE convexit,
        lowercase TYPE lowercase,
      END OF ty_description.

    METHODS do_show_data.
    METHODS do_build_selection_buttons IMPORTING io_hbox        TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_build_selection_fields  IMPORTING io_items       TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_display_popup.
    METHODS do_start_search            RETURNING VALUE(rt_guid) TYPE /sct/qp_t_guid.
    METHODS do_clear_selection.

    METHODS do_callback                                                                               " AD, 2026.10.09, changed
                        IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS do_token_add                                                                              " AD, 2026.10.09, changed
                         IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS do_token_delete                                                                           " AD, 2026.10.09, changed
                            IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS _do_prepare_where IMPORTING iv_fieldname TYPE string
                                        it_token     TYPE /sct/qp_if_ui_selection=>tt_token
                              CHANGING  cv_where     TYPE string.

    METHODS do_prepare_where RETURNING VALUE(rv_where) TYPE string.

    METHODS do_convert_input IMPORTING ir_field       TYPE REF TO /sct/qp_if_ui_selection=>ty_s_input
                                       iv_value       TYPE string
                             RETURNING VALUE(r_value) TYPE string.

    METHODS get_description IMPORTING is_component    TYPE /sct/qp_s_components
                            RETURNING VALUE(r_result) TYPE ty_description.

    METHODS init_instances     REDEFINITION.
    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_SELECTION IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~init.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.25, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->/sct/qp_if_ui_app~init( is_control = is_control ).

    " Die Datenhaltung der Selektion erfolgt in der Hauptapplikation,
    " damit das 2-Wege Binding im Stateless Modus funktionieren kann.

* FT20261027 del
*    DATA(lo_root) = CAST /sct/qp_cl_ui( is_control-root_app ).
*    " Die Daten sind in der Hauptapplikation global gehalten
*    mr_select = REF #( lo_root->ms_globals-select ).
*    mr_selfields = REF #( lo_root->ms_globals-t_selfields ).
*    IF mr_selfields->* IS INITIAL.
*      mr_selfields->* = mt_selfields.
*      " Default für BOM Level & Anzahl Datensätze
*      mr_select->max_bom_level = 5.
*      mr_select->max_sel_count = mo_cust->get_tusrpref_maxrows( ).
*    ENDIF.

    DATA(lv_max_rows) = mo_cust->get_tusrpref_maxrows( ).
    IF lv_max_rows IS INITIAL.
      lv_max_rows = 10.
    ENDIF.

    IF mv_max_sel_count IS INITIAL.
      mv_max_sel_count = lv_max_rows.
    ENDIF.

    DATA(lv_max_bom) = mo_cust->get_param( mc->param-max_bom_level ).
    IF lv_max_bom IS INITIAL.
      lv_max_bom = 3.
    ENDIF.
    IF mv_max_bom_level IS INITIAL.
      mv_max_bom_level = lv_max_bom.
    ENDIF.

*    IF mt_selfields[ fieldname = 'MAX_SEL_COUNT' ]-value IS INITIAL.
*      mt_selfields[ fieldname = 'MAX_SEL_COUNT' ]-value = lv_max.
*    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.20, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    super->constructor( ).

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_bus  = mo_bus
                                                 eo_cust = mo_cust ).

**********************************************************************
** TEST
    "
    DATA(lt_comp_view) = mo_tools->get_struct_comp( is_data = VALUE /sct/qp_r_selection( ) ).

    DATA(lv_group) = CONV string( 'QPPD' ).

    LOOP AT lt_comp_view ASSIGNING FIELD-SYMBOL(<component>).

      IF <component>-name = 'NODENUMBERVERSION'
      OR <component>-name = 'SHORTTEXT'
      OR <component>-name = 'MEDIUMTEXT'.
        CONTINUE.
      ENDIF.

      " Beschreibung, Konvertierungs-exit, Suchhilfe aus Datenelement/Domäne
      DATA(lv_descr) = get_description( <component> ).
      INSERT VALUE #( name      = lv_descr-scrtext_l
                      convexit  = lv_descr-convexit
                      shlp      = lv_descr-shlpname
                      lowercase = lv_descr-lowercase
                      group     = lv_group
                      fieldname = <component>-name ) INTO TABLE mt_selfields ASSIGNING FIELD-SYMBOL(<selfield>).

      " Suchhilfe, convexit, und selkz ergänzen oder ersetzen, falls nötig
      CASE <selfield>-fieldname.
        WHEN 'SPECIFICATIONTYPE'.
          <selfield>-selkz = abap_true.

        WHEN 'NODENUMBER' OR 'NODEVERSION'.
          <selfield>-selkz = abap_true.
          <selfield>-shlp  = '/SCT/QP_SH_MAINQ'.

        WHEN 'ORIGINALNODENODENUMBER' OR 'ORIGINALNODENODEVERSION'.
          <selfield>-shlp  = '/SCT/QP_SH_MAINQ'.

        WHEN 'NAME'.
          <selfield>-selkz = abap_true.

        WHEN 'STATUS'.
          <selfield>-shlp     = '/SCT/QP_SH_TJ02_TEXT4'.
          <selfield>-convexit = 'ZSCTS'.

        WHEN 'SALESDOCUMENT'.
          <selfield>-group = 'ECC'.
          lv_group = <selfield>-group.
          <selfield>-shlp = 'CS_VBELN'.

        WHEN 'SALESDOCUMENTITEM'.
          <selfield>-shlp = 'F4_POSNR_VBAP'.

        WHEN 'PRODUCTIONVERSION'.
          <selfield>-shlp = 'VERID'.

        WHEN 'INSPECTIONLOT'.
          <selfield>-shlp = 'QALS'.

      ENDCASE.

    ENDLOOP.

    " Allgemein
    INSERT VALUE #( name      = mutx->get_text( mutx->u011 ) " Max. Selektionsanzahl
                    fieldname = 'MAX_SEL_COUNT'
                    group     = 'GENERAL'
                    selkz     = abap_true ) INTO TABLE mt_selfields.
  ENDMETHOD.


  METHOD do_build_selection_buttons.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.17, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    " Andere Buttons zusammen in einem hbox ( wandern zusammen auf der 2. Zeile )
    DATA(lo_hbox) = io_hbox->hbox( id = 'Btnhbox' ).

    lo_hbox->vertical_layout( )->label(
          )->button( text  = mutx->get_text( mutx->u032 ) " Auswahl löschen
                     icon  = 'sap-icon://delete'
                     press = _event( mcu->events-nav_list_clear )
                     id    = mcu->events-nav_list_clear
                     type  = 'Transparent' ).

    lo_hbox->vertical_layout( )->label(
          )->button( " text  = mutx->get_text( mutx->u030 ) " Anlegen…
                     text  = mtx->get_text( mtx->n027 )
*                     icon  = 'sap-icon://create'
                     icon  = 'sap-icon://sys-add'
                     press = _event( mcu->events-wiz_display_root )
                     id    = mcu->events-wiz_display_root
                     type  = 'Transparent' ).

    lo_hbox->vertical_layout( )->label(
          )->button( text  = mutx->get_text( mutx->u031 ) " Aktualisieren
                     icon  = 'sap-icon://refresh'
                     press = _event( mcu->events-refresh )
                     id    = mcu->events-refresh
                     type  = 'Transparent' ).
  ENDMETHOD.


  METHOD do_display_popup.
    DATA(view) = /sct/au5_cl_xml_view=>factory_popup( ).

    view->dialog( title             = mutx->get_text( mutx->u008 ) " Filter anpassen
                  resizable         = 'true'
                  draggable         = 'true'
                  contentwidth      = '400px'
                  contentheight     = '300px'
                  verticalscrolling = 'true'
        )->table( mode  = 'MultiSelect'
* FT20251110 : Das Binding scheint nur mit dem "normalen" Binding sauber zu funktionieren
*               unser bind_edit_ref geht hier nicht ;-)
*                  items = _bind( iv_edit = abap_true
*                  ir_data = REF #( mt_selfields )
*                  iv_name = 'SELFIELDS' )
                  items = ms_control-client->_bind( mt_selfields )
*                  items = ms_control-client->_bind_edit( mr_select->t_selfields )
            )->columns(
                )->column(
                    )->text( mutx->get_text( mutx->u009 ) " Selektionsfelder
            )->get_parent( )->get_parent(
            )->items(
                )->column_list_item( selected = '{SELKZ}'
                    )->cells(
                        )->text( '{NAME}'
        )->get_parent( )->get_parent( )->get_parent( )->get_parent(
        )->buttons(
            )->button( text  = mutx->get_text( mutx->u033 ) " OK
                       press = _event( mcu->events-popup_confirm )
                       type  = 'Emphasized' ).

    ms_control-client->popup_display( view->stringify( ) ).
  ENDMETHOD.


  METHOD do_start_search.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"
    " FT20251110 dynamisiert, vervollständigt.
    "--------------------------------------------------------------------"
    " NS, 28.11.2025, Aufbau des Selects angepasst auf Multiinput
    "--------------------------------------------------------------------"
    " NS, 29.01.2026, Selektion auf CDS View mit allen Feldern umgestellt
    "--------------------------------------------------------------------"

    DATA(lv_where) = do_prepare_where( ).

    IF lv_where IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        SELECT guid FROM /sct/qp_c_selection
          WHERE (lv_where)
          INTO CORRESPONDING FIELDS OF TABLE @rt_guid
          UP TO @mv_max_sel_count ROWS.
      CATCH cx_root INTO DATA(lo_error).
        DATA(lv_text) = lo_error->get_text( ).
        ms_control-client->message_toast_display( text = |{ lv_text }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD process_fcode_self.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    IF  is_get-event <> mcu->events-sel_shlp
    AND is_get-event <> mcu->events-f4_back_sel
    AND is_get-event <> mcu->events-token_delete
    AND is_get-event <> mcu->events-token_add.
      IF lines( is_get-t_event_arg ) IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    rv_processed = abap_true.
    CASE is_get-event.
      WHEN mcu->events-sel_start_search. " Suche ausführen
        " MT aktualisieren
        DATA(lt_arg) = VALUE string_table( FOR <ls_guid> IN do_start_search( )
                                           ( CONV #( <ls_guid>-guid ) ) ).
        IF lt_arg IS INITIAL.
          MESSAGE i420(12) INTO DATA(lv_message).
          ms_control-client->message_toast_display( lv_message ).

        ELSE.
          " neues FCODE absetzen
          ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-nav_list_build
                                                                   t_event_arg = lt_arg )
                                              io_client = ms_control-client ).
          " Bei erfolgreiche selektion wird's zusammengeklappt
          ms_control-root_app->snap_selection( ).
*          DATA(lo_ui) = CAST /sct/qp_cl_ui( ms_control-root_app ).
*          lo_ui->mv_selection_expanded = abap_false.

        ENDIF.
      WHEN mcu->events-sel_clear. " Leere Selektionsparameter
        do_clear_selection( ).
      WHEN mcu->events-sel_shlp. " Suchhilfe für die Selektion
        DATA(mo_ui_f4) = /sct/qp_cl_ui_searchhelp=>get_instance( ).

        mo_ui_f4->init( iv_shlp         = CONV #( is_get-t_event_arg[ 2 ] )
                        iv_multi_result = abap_true
                        iv_value        = CONV #( is_get-t_event_arg[ 1 ] )
                        is_callback     = VALUE #( s_get-event       = mcu->events-f4_back_sel
                                                   s_get-t_event_arg = VALUE #( ( is_get-t_event_arg[ 1 ] ) ) ) ).
        ms_control-client->nav_app_call( CAST /sct/au5_if_app( mo_ui_f4 ) ).

      WHEN mcu->events-f4_back_sel.
        do_callback( is_get ).
      WHEN mcu->events-token_delete.
        do_token_delete( is_get ).

*        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-nav_list_clear )
*                                    io_client = ms_control-client ).
*
*        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-sel_start_search )
*                                            io_client = ms_control-client ).
      WHEN mcu->events-token_add.
        do_token_add( is_get ).

*        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-nav_list_clear )
*                                            io_client = ms_control-client ).
*
*        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-sel_start_search )
*                                            io_client = ms_control-client ).
      WHEN mcu->events-refresh.
        " FT20251126 REFRESH hatte keine Wirkung, jetzt wird nur die Anzeige aufgefrischt
        ms_control-root_app->set_next_event( VALUE #( event = mcu->events-redraw ) ).
      WHEN OTHERS.
        rv_processed = abap_false.
    ENDCASE.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.
    do_show_data( ).
  ENDMETHOD.


  METHOD do_show_data.
    " Header dynamisch machen
    DATA(lo_box) = ms_control-parent_view->header( )->dynamic_page_header( pinnable = abap_true )->flex_box( alignitems     = `Start`
                                                                                                             " alignitems     = `End`
                                                                                                             justifycontent = `SpaceBetween`
                                                                                                             " justifycontent = `Center`
                                                                                                             ). "->flex_box( alignitems = `Center` ). "`Start`

    DATA(lr_filter_bar) = lo_box->filter_bar( search        = ms_control-client->_event( val = mcu->events-sel_start_search )
                                              clear         = _event( iv_name = mcu->events-sel_clear )
*                                              persistencykey = `myPersKey`

                                              showclearonfb = 'true'
*                                              usetoolbar    = 'true'
*                                              showgoonfb    = 'false'
*                                              showclearonfb = 'false'
*                                              showfilterconfiguration = 'false'
    ).
    DATA(lo_items) = lr_filter_bar->filter_group_items( ).

    do_build_selection_fields( lo_items ).

    DATA(lo_hbox) = lo_box->hbox( alignitems   = 'Start'
                                  " justifycontent = 'Start'
                                  wrap         = 'Wrap'
                                  fitcontainer = abap_true ).

    " Suche starten & Selektionsfilter Button
    do_build_selection_buttons( io_hbox = lo_hbox ).
  ENDMETHOD.


  METHOD get_description.
    DATA(lv_rollname) = CONV ddobjname( is_component-type->get_relative_name( ) ).

    DATA l_dd04v TYPE dd04v.
    CALL FUNCTION 'DDIF_DTEL_GET' EXPORTING  name          = lv_rollname
                                             langu         = sy-langu
                                  IMPORTING  dd04v_wa      = l_dd04v
                                  EXCEPTIONS illegal_input = 1
                                             OTHERS        = 2 ##FM_SUBRC_OK.
    r_result = CORRESPONDING #( l_dd04v ).
    r_result-name = is_component-name.
  ENDMETHOD.


  METHOD init_instances.
    super->init_instances( ).
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_bus  = mo_bus
                                                 eo_cust = mo_cust ).
  ENDMETHOD.


  METHOD do_clear_selection.
*    CLEAR mr_select->*.
*
*    LOOP AT mr_selfields->* ASSIGNING FIELD-SYMBOL(<ls_selfields>).
*      CLEAR <ls_selfields>-token.
*    ENDLOOP.
*
*    mr_select->max_sel_count = mo_cust->get_tusrpref_maxrows( ).
*    mr_select->max_bom_level = '5'.

    CLEAR /sct/qp_if_ui_selection~ms_select.
    LOOP AT mt_selfields ASSIGNING FIELD-SYMBOL(<ls_selfields>).
      CLEAR <ls_selfields>-token.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_callback.
    FIELD-SYMBOLS <ls_params> TYPE /sct/au5_if_types=>ty_s_name_value.

    IF is_get-event <> 'F4_BACK_SEL'.
      RETURN.
    ENDIF.

    DATA(lr_selfield) = REF #( mt_selfields[ fieldname = is_get-t_event_arg[ 1 ] ] OPTIONAL ).
    IF lr_selfield IS NOT BOUND.
      RETURN.
    ENDIF.

    IF is_get-r_event_data IS NOT BOUND.
      RETURN.
    ENDIF.

    LOOP AT is_get-r_event_data->* ASSIGNING FIELD-SYMBOL(<result>).
      LOOP AT <result> ASSIGNING <ls_params>.

        DATA(lv_value) = do_convert_input( ir_field = lr_selfield
                                           iv_value = <ls_params>-v ).

        " Doppelte Einträge vermeiden.
        IF NOT line_exists( lr_selfield->token[ key = <ls_params>-v ] ).
          INSERT VALUE #( key      = lv_value
                          text     = <ls_params>-v
                          visible  = abap_true
                          editable = abap_true ) INTO TABLE lr_selfield->token.
        ENDIF.
        EXIT.
      ENDLOOP.
    ENDLOOP.
*    ELSE.
*      LOOP AT is_get-t_comp_params ASSIGNING <ls_params>.
*
*        lr_selfield = REF #( mr_selfields->*[ fieldname = <ls_params>-n ] OPTIONAL ).
*        IF lr_selfield IS NOT BOUND.
*          RETURN.
*        ENDIF.
*
*        lv_value = do_convert_input( ir_field = lr_selfield
*                                     iv_value = <ls_params>-v ).
*
*        " Doppelte Einträge vermeiden.
*        IF NOT line_exists( lr_selfield->token[ key = <ls_params>-v ] ).
*          INSERT VALUE #( key      = to_upper( lv_value )
*                          text     = to_upper( lv_value )
*                          visible  = abap_true
*                          editable = abap_true ) INTO TABLE lr_selfield->token.
*        ENDIF.
*      ENDLOOP.

*    ms_control-root_app->set_next_event( is_event = VALUE #( event = mcu->events-redraw ) ).
  ENDMETHOD.


  METHOD do_build_selection_fields.
    LOOP AT mt_selfields REFERENCE INTO DATA(lr_field).
*    LOOP AT mr_selfields->* REFERENCE INTO DATA(lr_field).
      DATA(tabix) = sy-tabix.
*      ASSIGN COMPONENT lr_field->fieldname OF STRUCTURE mr_select->* TO FIELD-SYMBOL(<lv_value>).

*      IF sy-subrc <> 0.
*        CONTINUE.
*      ENDIF.

      DATA(lo_filter) = io_items->filter_group_item( name               = lr_field->fieldname
                                                     label              = lr_field->name
                                                     groupname          = COND #( WHEN lr_field->group IS NOT INITIAL
                                                                                  THEN lr_field->group
                                                                                  ELSE 'NoGroup' )
                                                     grouptitle         = COND #( WHEN lr_field->group IS NOT INITIAL
                                                                                  THEN lr_field->group
                                                                                  ELSE 'No Group' )
*                                                     visibleinfilterbar = lr_field->selkz )->filter_control( ).
                                                     visibleinfilterbar = ms_control-client->_bind( val       = lr_field->selkz
                                                                                                    tab       = mt_selfields
                                                                                                    tab_index = tabix ) )->filter_control( ).

      CASE lr_field->fieldname.
        WHEN 'MAX_SEL_COUNT' OR 'MAX_BOM_LEVEL'.

          lo_filter->input(  " value     = _bind( iv_fieldname = |mv_max_sel_count| )
                            value     = ms_control-client->_bind( val = mv_max_sel_count )
*                            value     = ms_control-client->_bind( val       = lr_field->value
*                            tab       = mt_selfields
*                            tab_index = tabix )

*                            width     = `5rem`     "WTF es geht nicht in UI5 wird width in fieldwidth gemapped, keine Wirkung :-(
                            type      = 'Number'
*                            fieldwidth = `30%`
                            textalign = `End` ).

*          DATA(lv_string) = lo_filter->stringify( ).
        WHEN 'ERDAT' OR 'AEDAT'
        OR 'CREATIONDATE' OR 'LASTCHANGEDATE'.

          lo_filter->date_range_selection( value = ms_control-client->_bind( val       = lr_field->value
                                                                             tab       = mt_selfields
                                                                             tab_index = tabix )
                                           " value = _bind( iv_fieldname = |ms_select-{ lr_field->fieldname }| )
*                                           datevalue = _bind( iv_fieldname = |ms_select-{ lr_field->fieldname }_d1| )
*                                           seconddatevalue = _bind( iv_fieldname = |ms_select-{ lr_field->fieldname }_d2| )
                                            ).

*          lo_filter->date_range_selection( value = ms_control-client->_bind( val       = lr_field->value
*                                                                             tab       = mt_selfields
*                                                                             tab_index = tabix ) ).

        WHEN 'CREATIONTIME' OR 'LASTCHANGETIME'.
          lo_filter->time_picker( ms_control-client->_bind( val       = lr_field->value
                                                            tab       = mt_selfields
                                                            tab_index = tabix )
*            EXPORTING
*                                  value = _bind( iv_fieldname = |ms_select-{ lr_field->fieldname }| )
*                                  placeholder =
*                                  enabled =
*                                  valuestate =
*                                  displayformat =
*                                  valueformat =
*                                  required =
*                                  width =
*                                  datevalue =
*                                  localeid =
*                                  mask  =
*                                  maskmode =
*                                  minutesstep =
*                                  name  =
*                                  placeholdersymbol =
*                                  secondsstep =
*                                  textalign =
*                                  textdirection =
*                                  title =
*                                  showcurrenttimebutton =
*                                  showvaluestatemessage =
*                                  support2400 =
*                                  initialfocuseddatevalue =
*                                  hideinput =
*                                  editable =
*                                  visible =
*                                  valuestatetext =
*                                  livechange =
*                                  change =
*                                  aftervaluehelpopen =
*                                  aftervaluehelpclose =
*            RECEIVING
*                                  result =
          ).

        WHEN OTHERS.
          IF lr_field->shlp IS INITIAL.
            lo_filter->multi_input( placeholder   = lr_field->name
                                    tokens        = ms_control-client->_bind( val       = lr_field->token
                                                                              tab       = mt_selfields
                                                                              tab_index = tabix )
                                    value         = ms_control-client->_bind( val       = lr_field->value
                                                                              tab       = mt_selfields
                                                                              tab_index = tabix )
                                    tokenupdate   = ms_control-client->_event( val   = mcu->events-token_delete
                                                                               t_arg = VALUE #( ( lr_field->fieldname )
                                                                                                ( `$event.mParameters.type` )
                                                                                                ( `$event.mParameters.removedTokens[0].mProperties.key` ) ) )
                                    change        = ms_control-client->_event( val   = mcu->events-token_add
                                                                               t_arg = VALUE #( ( lr_field->fieldname )
                                                                                                ( `${$parameters>/value}` ) ) )
                                    showvaluehelp = abap_false
*                                    submit        = _event( mcu->events-sel_start_search ) )->item( key  = `{KEY}`
*                                    text          = `{TEXT}`
                                    )->tokens( )->token( key      = `{KEY}`
                                                         text     = `{TEXT}`
                                                         visible  = `{VISIBLE}`
                                                         selected = `{SELKZ}`
                                                         editable = `{EDITABLE}` ).
          ELSE.
            lo_filter->multi_input( placeholder      = lr_field->name
                                    tokens           = ms_control-client->_bind( val       = lr_field->token
                                                                                 tab       = mt_selfields
                                                                                 tab_index = tabix )
                                    value            = ms_control-client->_bind( val       = lr_field->value
                                                                                 tab       = mt_selfields
                                                                                 tab_index = tabix )
                                    tokenupdate      = ms_control-client->_event( val   = mcu->events-token_delete
                                                                                  t_arg = VALUE #( ( lr_field->fieldname )
                                                                                                   ( `$event.mParameters.type` )
                                                                                                   ( `$event.mParameters.removedTokens[0].mProperties.key` ) ) )
                                    change           = ms_control-client->_event( val   = mcu->events-token_add
                                                                                  t_arg = VALUE #( ( lr_field->fieldname )
                                                                                                   ( `${$parameters>/value}` ) ) )
                                    valuehelprequest = _event( iv_name = mcu->events-sel_shlp
                                                               it_arg  = VALUE #( ( |{ lr_field->fieldname }| )
                                                                                  ( |{ lr_field->shlp }| ) ) )
*                                    submit           = _event( mcu->events-sel_start_search ) )->item( key  = `{KEY}`
*                                    text             = `{TEXT}`
                                    )->tokens( )->token( key      = `{KEY}`
                                                         text     = `{TEXT}`
                                                         visible  = `{VISIBLE}`
                                                         selected = `{SELKZ}`
                                                         editable = `{EDITABLE}` ).
          ENDIF.
*          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_token_add.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " NS, 25.06.2025, NOTE-3592, angelegt
    "--------------------------------------------------------------------"
    " NS, 30.01.2026, Konvertierung für Felder die mit 0 aufgefüllt
    " werden müssen eingebaut. (z.B. VBELN)
    "--------------------------------------------------------------------"
    IF is_get-t_event_arg IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lr_selfield) = REF #( mt_selfields[ fieldname = is_get-t_event_arg[ 1 ] ] OPTIONAL ).

    IF lr_selfield IS NOT BOUND.
      RETURN.
    ENDIF.

    lr_selfield->value = is_get-t_event_arg[ 2 ].

    DATA(lv_value) = do_convert_input( ir_field = lr_selfield
                                       iv_value = lr_selfield->value ).

    IF lr_selfield->lowercase IS INITIAL.
      lr_selfield->value = to_upper( lr_selfield->value ).
    ENDIF.

    INSERT VALUE #( key      = lv_value
                    text     = lr_selfield->value
                    visible  = abap_true
                    editable = abap_true ) INTO TABLE lr_selfield->token.

    CLEAR lr_selfield->value.
*    ms_control-client->view_model_update( ). " Ohne wird's nicht aktualisiert
  ENDMETHOD.


  METHOD do_token_delete.
    DATA(lr_selfield) = REF #( mt_selfields[ fieldname = is_get-t_event_arg[ 1 ] ] OPTIONAL ).

    IF lr_selfield IS NOT BOUND.
      RETURN.
    ENDIF.

    IF is_get-t_event_arg[ 2 ] = `removed`.
      DELETE lr_selfield->token WHERE key = is_get-t_event_arg[ 3 ].
    ENDIF.

*    FIELD-SYMBOLS <range> TYPE /sct/qp_if_ui_selection=>ty_s_select-rng_name.
*    ASSIGN COMPONENT |RNG_{ is_get-t_event_arg[ 1 ] }| OF STRUCTURE ms_select TO <range>.
*
*    DELETE <range> WHERE low = is_get-t_event_arg[ 3 ].

    ms_control-client->view_model_update( ). " ohne ist zwar die Anzeige ok, die interne Tabelle wird aber nicht sauber aktualisiert bei mehrfache konsekutive anpassung von Tokens
  ENDMETHOD.


  METHOD _do_prepare_where.
    IF cv_where IS NOT INITIAL.
      cv_where = |{ cv_where } AND |.
    ENDIF.

    LOOP AT it_token ASSIGNING FIELD-SYMBOL(<ls_token>).
      IF sy-tabix > 1.
        cv_where = |{ cv_where } OR |.
      ELSE.
        cv_where = |{ cv_where } ( |.
      ENDIF.

      DATA(lv_value) = <ls_token>-key.

      " Prüfen auf Vergleichsoperatoren
      IF lv_value(2) = '>=' OR lv_value(2) = '<=' OR lv_value(2) = '<>'.
        cv_where = |{ cv_where }{ iv_fieldname } { lv_value(2) } '{ lv_value+2 }'|.
      ELSEIF lv_value(1) = '>' OR lv_value(1) = '<'.
        cv_where = |{ cv_where }{ iv_fieldname } { lv_value(1) } '{ lv_value+1 }'|.
      ELSEIF lv_value CA '*'.
        " Enthält Wildcard -> LIKE verwenden
        REPLACE ALL OCCURRENCES OF '*' IN lv_value WITH '%'.
        cv_where = |{ cv_where }{ iv_fieldname } LIKE '{ lv_value }'|.
      ELSE.
        " Normale Gleichheit
        cv_where = |{ cv_where }{ iv_fieldname } = '{ lv_value }'|.
      ENDIF.
    ENDLOOP.

    cv_where = |{ cv_where } )|.
  ENDMETHOD.


  METHOD do_prepare_where.
    LOOP AT mt_selfields ASSIGNING FIELD-SYMBOL(<ls_selfields>) WHERE token IS NOT INITIAL.
      _do_prepare_where( EXPORTING it_token     = <ls_selfields>-token
                                   iv_fieldname = <ls_selfields>-fieldname
                         CHANGING  cv_where     = rv_where ).

    ENDLOOP.
  ENDMETHOD.


  METHOD do_convert_input.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " NS, 30.01.2026, angelegt
    "--------------------------------------------------------------------"

    DATA lv_operator TYPE string.

    IF ir_field->lowercase IS NOT INITIAL.
      r_value = iv_value.
    ELSE.
      r_value = to_upper( iv_value ).
    ENDIF.
    DATA(lv_clean_value) = r_value.

    " Operator extrahieren
    IF strlen( r_value ) >= 2 AND ( r_value+0(2) = '>=' OR r_value+0(2) = '<=' OR r_value+0(2) = '<>' ).
      lv_operator = r_value+0(2). " Die ersten 2 Zeichen ab Position 0
      lv_clean_value = r_value+2. " Alles ab Position 2
    ELSEIF strlen( r_value ) >= 1 AND ( r_value+0(1) = '>' OR r_value+0(1) = '<' ).
      lv_operator = r_value+0(1). " Das erste Zeichen ab Position 0
      lv_clean_value = r_value+1. " Alles ab Position 1
    ELSEIF r_value CS '*'.
      " Bei Wildcards keine Konvertierung
      RETURN.
    ENDIF.

    IF ir_field->convexit IS NOT INITIAL.
      DATA ls_struct TYPE /sct/qp_r_selection.
      ASSIGN COMPONENT ir_field->fieldname OF STRUCTURE ls_struct TO FIELD-SYMBOL(<input_format>).
      IF <input_format> IS ASSIGNED.
        DATA(lv_fuba) = |CONVERSION_EXIT_{ ir_field->convexit }_INPUT|.
        CALL FUNCTION lv_fuba EXPORTING input  = lv_clean_value
                              IMPORTING output = <input_format>.
        lv_clean_value = <input_format>.
      ENDIF.
    ENDIF.

    " Falls vorhanden, Operator wieder davorsetzen
    IF lv_operator IS NOT INITIAL.
      r_value = |{ lv_operator }{ lv_clean_value }|.
    ELSE.
      r_value = lv_clean_value.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    init_instances( ).
    _bind( iv_fieldname = 'mt_selfields' ).
    _bind( iv_fieldname = 'mv_max_sel_count' ).
  ENDMETHOD.
ENDCLASS.
