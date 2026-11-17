CLASS /sct/qp_cl_ui_objlist_root DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objlist
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_objlist_root.

    ALIASES init          FOR /sct/qp_if_ui_app~init.
    ALIASES process_fcode FOR /sct/qp_if_ui_app~process_fcode.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.

  PROTECTED SECTION.
    ALIASES mt_object_list FOR /sct/qp_if_ui_objlist~mt_object_list.

    DATA mv_width_sel TYPE string.

    METHODS insert_object_list IMPORTING ir_base TYPE REF TO /sct/qp_s_base.
    METHODS do_show_data.

    METHODS do_build_data IMPORTING it_guid  TYPE /sct/qp_t_guid OPTIONAL
                                    iv_oguid TYPE /sct/qp_oguid  OPTIONAL
                                    iv_guid  TYPE /sct/qp_guid   OPTIONAL.

    METHODS do_refresh_data.

    METHODS do_create_vart                                                        " AD, 2026.10.09, changed
                           IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS do_clear_nav_list                                                       " AD, 2026.10.09, changed
                              IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get
                              RAISING   /sct/qp_cx_error.

    METHODS init_instances     REDEFINITION.
    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.

ENDCLASS.


CLASS /sct/qp_cl_ui_objlist_root IMPLEMENTATION.
  METHOD /sct/qp_if_ui_app~display.
    ms_control-client      = io_client.
    ms_control-parent_view = io_view.
    init_instances( ).
    do_show_data( ).
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    /sct/qp_if_ui_objlist~mr_object_list = REF #( /sct/qp_if_ui_objlist~mt_object_list ).

    " Sobald ein Objekt selektiert worden ist, wird die Größe des splitters gesetzt (also, wird sichtbar)
    set_splitter_size( ).
  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

*    mt_def_arg = VALUE #( ( `${OGUID}` )
*                          ( `${GUID}`  )
*                          ( `${TYPE}`  )
*                          ( `${$source>/id}` ) ). " Die ID ist wichtig, sie sagt dem Popover wo es erscheinen soll.

    mv_show_vart_vtyp_text = abap_false.
  ENDMETHOD.

  METHOD do_build_data.
    DATA(lv_first) = VALUE abap_bool( ).
    IF it_guid IS NOT INITIAL.
      DATA(lv_count) = lines( it_guid ).
      LOOP AT it_guid ASSIGNING FIELD-SYMBOL(<ls_guid>).
        " Hierarchie + Detailinfo des Roots einlesen
        DATA(lr_base_root) = mo_ui_handler->get_hierarchy( iv_guid     = <ls_guid>-guid
                                                           iv_oguid    = VALUE #( )
                                                           iv_stateful = is_stateful( ) ).

        IF lr_base_root IS INITIAL.
          CONTINUE.
        ENDIF.

        insert_object_list( lr_base_root ).

        IF lv_first = abap_false AND lv_count = 1.
          lv_first = abap_true.
          IF lr_base_root->guid <> <ls_guid>-guid.
            " Unterknoten angefordert.
            ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-show_data
                                                                     t_event_arg = VALUE #( ( CONV #( lr_base_root->guid ) )
                                                                                            ( CONV #( <ls_guid>-guid ) ) ) ) ).
          ELSE.
            ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-show_data
                                                                     t_event_arg = VALUE #( ( CONV #( lr_base_root->guid ) )
                                                                                            ( CONV #( lr_base_root->guid ) ) ) ) ).

          ENDIF.
        ENDIF.

      ENDLOOP.
      SORT /sct/qp_if_ui_objlist~mr_object_list->* BY sortkr
                                                      guid.

    ELSEIF iv_oguid IS NOT INITIAL AND iv_guid IS NOT INITIAL.
      " Hierarchie + Detailinfo des (sub)Knotens einlesen
      mo_ui_handler->get_hierarchy( iv_guid     = iv_guid
                                    iv_oguid    = iv_oguid
                                    iv_stateful = is_stateful( ) ).

      lr_base_root = mo_ui_handler->get_base( iv_guid     = iv_oguid
                                              iv_oguid    = iv_oguid
                                              iv_stateful = is_stateful( ) ).
      insert_object_list( lr_base_root ).
    ENDIF.
  ENDMETHOD.

  METHOD do_create_vart.
    DATA(lv_vart) = VALUE /sct/qp_vart( is_get-t_comp_params[ n = 'VART' ]-v OPTIONAL ).
    DATA(lv_vname) = VALUE /sct/qp_vname( is_get-t_comp_params[ n = 'VNAME' ]-v OPTIONAL ).
    DATA(lv_vbez) = VALUE /sct/qp_qvtext( is_get-t_comp_params[ n = 'VBEZ' ]-v OPTIONAL ).
    set_stateful( ).
    mo_bus->create( EXPORTING is_header = VALUE #( vart  = lv_vart
                                                   vname = lv_vname
                                                   nodet = VALUE #( ( spras = sy-langu
                                                                      vtext = lv_vbez ) ) )
*                              it_items  =
*                              iv_builder =
*                              iv_suppress_globgen =
*                              iv_mark_for_display = abap_true
                    IMPORTING es_header = DATA(ls_header)
                    " TODO: variable is assigned but never used (ABAP cleaner)
                              et_return = DATA(lt_return)
                    " TODO: variable is assigned but never used (ABAP cleaner)
                              ev_error  = DATA(lv_error)
*                              es_base   =
*                              ev_no_authority =
*                              eo_error  =
                             ).

    ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-show_data
                                                             t_event_arg = VALUE #( ( CONV #( ls_header-guid ) )
                                                                                    ( CONV #(  ls_header-oguid ) )
*                                                                                          ( mcu->sap-m-listtype-navigation )
                                        ) )
                                        io_client = ms_control-client ).
  ENDMETHOD.

  METHOD do_refresh_data.
    LOOP AT /sct/qp_if_ui_objlist~mr_object_list->* ASSIGNING FIELD-SYMBOL(<list>).
      DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = <list>-guid
                                               iv_oguid    = <list>-oguid
                                               iv_stateful = is_stateful( ) ).

      IF lr_base IS BOUND.
        <list>-vname    = lr_base->instance->ms_node_data-vname.
        <list>-vtext    = get_node_vtext( ir_base = lr_base ).
        <list>-istat    = get_status_text( ir_base = lr_base ).
        <list>-icon     = get_status_icon( ir_base = lr_base ).
        <list>-state    = get_status_state( ir_base = lr_base ).
        <list>-workmode = lr_base->workmode.
        <list>-marker   = get_marker( lr_base ).
        <list>-type     = COND #( WHEN lr_base->instance->mt_childs IS INITIAL
                                  THEN mcu->sap-m-listtype-active
                                  ELSE mcu->sap-m-listtype-navigation ).
        <list>-sortkr   = lr_base->sortkr.
      ELSE.
        " Wenn ein Knoten über das Popover Menü gelöscht wird, muss es auch auch aus der Objektliste verschwinden.
        DATA(lt_del) = mo_controller->mo_model->get_base_delete( ).
        IF line_exists( lt_del[ KEY guid COMPONENTS guid = <list>-oguid ] ).
          DELETE /sct/qp_if_ui_objlist~mr_object_list->* WHERE guid = <list>-guid.
        ENDIF.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD do_show_data.
    " Splitter with fixed size on top, containing a list of 1 item (the selected one)

    DATA(page) = ms_control-parent_view->page( id              = 'ROOT-page'
                                               showheader      = abap_false
                                               enablescrolling = abap_true ).

    DATA(lo_split) = page->splitter( orientation = `Vertical`
                                     width       = '100%' ).

    " Workaroud FLP: Horizontale Scrollbars erscheinen in FLP (und nicht wenn die App direkt aufgerufen wird )
    " Mit 98 statt 100% sind die scollbars wieder weg
    IF ms_control-root_app->get_context( )-flp = abap_true.
      DATA(lv_width) = `98%`.
    ELSE.
      lv_width = `100%`.
    ENDIF.

    DATA(lo_fixed) = lo_split->vbox( width = lv_width ). " "mit 100% wird ein Scrollbar in FLP angezeigt .-/
    lo_fixed->layout_data(
*               )->splitter_layout_data( size      = _bind( iv_fieldname = 'mv_sel_size' )
              )->splitter_layout_data( size      = ms_control-client->_bind( mv_sel_size )
                                       resizable = abap_false ).

    DATA(lo_selection) = lo_fixed->list( id    = 'Root_List_selected'
*                                         items = |\{path:'{ _bind( iv_fieldname = |/sct/qp_if_ui_objlist~mt_object_selected|
*                                         iv_path = abap_true ) }', sorter:[ \{ path: 'SORTKR', descending: false \}] \}|
                                         items = |\{path:'{ ms_control-client->_bind( val  = /sct/qp_if_ui_objlist~mt_object_selected
                                                                                      path = abap_true ) }', sorter:[ \{ path: 'SORTKR', descending: false \}] \}|

* "Auswahl" anzeigen oberhalb des selektierten Knotens ( dafür muss die Höhe von 5 auf 7 geändert werden ( siehe mv_sel_size in SET_SPLITTER_SIZE() )
*                                         iv_path = abap_true ) }', sorter:[\{ path: 'TEXT', descending: false, group: true \}] \}|

                           )->items( ).

    IF mv_list_type = /sct/qp_if_ui_objlist=>object_list_item.
      build_object_list_item( lo_selection ).
    ELSE.
      build_custom_list_item( lo_selection ).
    ENDIF.

    DATA(lo_list_area) = lo_split->vbox( width = lv_width ). " alignitems = 'Center'  ).
    lo_list_area->layout_data(
                )->splitter_layout_data( size      = `100%`
                                         resizable = abap_true ).

    DATA(items) = lo_list_area->list( id    = 'Root_List'
*                                      items = |\{path:'{ _bind( iv_fieldname = |/sct/qp_if_ui_objlist~mr_object_list->*|
*                                      iv_path = abap_true ) }', sorter:[\{ path: 'TEXT', descending: false, group: true \}, \{ path: 'SORTKR', descending: false \}] \}|
                                      items = |\{path:'{ ms_control-client->_bind(
                                                             val  = /sct/qp_if_ui_objlist~mr_object_list->*
                                                             path = abap_true ) }', sorter:[\{ path: 'TEXT', descending: false, group: true \}, \{ path: 'SORTKR', descending: false \}] \}|

                           )->items( ).

    IF mv_list_type = /sct/qp_if_ui_objlist=>object_list_item.
      build_object_list_item( items ).
    ELSE.
      build_custom_list_item( items ).
    ENDIF.

    DATA(lt_excl) = mo_controller->get_excl_actions_prof( iv_workmode = mc->workmode_change
                                                          iv_app      = VALUE #( ) ).

    IF NOT line_exists( lt_excl[ table_line = mc->action_create ] ).

      lo_list_area->hbox( justifycontent = 'Center'
                          class          = `sapUiTinyMargin`
                      )->button( text  = mtx->get_text( mtx->n027 )
                                 icon  = 'sap-icon://sys-add'
                                 type  = 'Transparent'
                                 press = _event( iv_name = mcu->events-wiz_display_root
                                                 it_arg  = VALUE #( ) ) ).

    ENDIF.
  ENDMETHOD.

  METHOD init_instances.
    super->init_instances( ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

    mt_def_arg = VALUE #( ( `${OGUID}` )
                          ( `${GUID}`  )
                          ( `${TYPE}`  )
                          ( `${$source>/id}` ) ). " Die ID ist wichtig, sie sagt dem Popover wo es erscheinen soll.

    mv_show_vart_vtyp_text = abap_false.
  ENDMETHOD.

  METHOD insert_object_list.
    IF line_exists( /sct/qp_if_ui_objlist~mr_object_list->*[ oguid = ir_base->oguid
                                                             guid  = ir_base->guid ] ).
      RETURN.
    ENDIF.

    DATA(lv_icon) = get_ui_icon( ir_base ).

    INSERT VALUE #( key       = ir_base->key
                    oguid     = ir_base->oguid
                    guid      = ir_base->guid
                    pguid     = ir_base->parent_guid
                    vart      = ir_base->vart
                    vtyp      = ir_base->vtyp
                    vnrvvs    = get_node_vnr( ir_base )
                    text      = get_vart_vtyp_text( ir_base )
                    image_src = lv_icon
                    minus_vis = abap_true
*                    drill_vis = lv_visible
                    highlight = mcu->sap-ui-core-message-MessageType-none )
           INTO TABLE /sct/qp_if_ui_objlist~mr_object_list->*.
  ENDMETHOD.

  METHOD process_fcode_self.
    CASE is_get-event.
      WHEN mcu->events-show_data.
        " Überprüfen, dass die Daten geladen sind, ggfs laden
        do_build_data( iv_oguid = CONV #( is_get-t_event_arg[ 1 ] )
                       iv_guid  = CONV #( is_get-t_event_arg[ 2 ] ) ).

        " rv_processed bleibt hier auf false.
        do_refresh_data( ).

        /sct/qp_if_ui_objlist~do_set_navigated( CONV #( is_get-t_event_arg[ 1 ] ) ).

      WHEN mcu->events-nav_list_build.
        DATA lt_guid TYPE /sct/qp_t_guid.

        LOOP AT is_get-t_event_arg ASSIGNING FIELD-SYMBOL(<ls_event>).
          INSERT VALUE #( guid = CONV bel_guid( <ls_event> ) ) INTO TABLE lt_guid.
        ENDLOOP.

        do_build_data( it_guid = lt_guid ).
        do_refresh_data( ).
        rv_processed = abap_true.

      WHEN mcu->events-nav_list_clear.
        do_clear_nav_list( is_get ).

      WHEN mcu->events-nav_list_refresh.
        do_refresh_data( ).
        /sct/qp_if_ui_objlist~do_set_navigated( CONV #( is_get-t_event_arg[ 1 ] ) ).
      WHEN mcu->events-node_action.
        TRY.
            /sct/qp_if_ui_objlist~do_popover( iv_guid  = CONV #( is_get-t_event_arg[ 2 ] )
                                              iv_oguid = CONV #( is_get-t_event_arg[ 1 ] )
                                              iv_id    = is_get-t_event_arg[ 4 ] ).

            rv_processed = abap_true.
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.

      WHEN 'BUTTON_CANCEL' OR 'BUTTON_CONFIRM'.
        ms_control-client->popup_destroy( ).
*      WHEN mcu->events-show_data.
*        DATA(lr_base) = get_parameter_base_ref( is_get ).
*        READ TABLE mt_object_list ASSIGNING FIELD-SYMBOL(<list>)
*        WITH KEY guid = lr_base->oguid.
*        IF sy-subrc = 0.
*          <list>-navigated = abap_true.
*        ENDIF.
        rv_processed = abap_true.

*      WHEN mcu->events-after_close_popover.
*        ms_control-client->popover_destroy( ).
      WHEN mcu->events-duplicate_root.
*        ms_control-client->popover_destroy( ).
        /sct/qp_if_ui_objlist~do_duplicate( iv_guid = is_get-t_event_arg[ 2 ] ).
        rv_processed = abap_true.
      WHEN mcu->events-delete_root.
*        ms_control-client->popover_destroy( ).
        /sct/qp_if_ui_objlist~do_delete( iv_guid = is_get-t_event_arg[ 2 ] ).
        do_refresh_data( ).
        rv_processed = abap_true.
      WHEN mcu->events-wiz_display_root. " Zeige Root Wizard
        DATA(lo_wizard) = /sct/qp_cl_ui_wizard=>get_instance( ).
        lo_wizard->init( iv_object   = 'root'
                         is_callback = VALUE #( s_get-event = mcu->events-wiz_callback_root )
                         is_control  = ms_control ).
        ms_control-client->nav_app_call( CAST /sct/au5_if_app( lo_wizard ) ).
      WHEN mcu->events-wiz_callback_root. " Neu
        do_create_vart( is_get ).
      WHEN mcu->events-where_used.

        DATA(lo_whereused) = /sct/qp_cl_ui_popup_whereused=>factory( iv_guid = CONV #( is_get-t_event_arg[ 2 ] ) ).
        ms_control-client->nav_app_call( lo_whereused ).
    ENDCASE.
  ENDMETHOD.

  METHOD do_clear_nav_list.
    " 1) Delete all unchanged data (always !)
    DELETE /sct/qp_if_ui_objlist~mr_object_list->* WHERE workmode = mc->workmode_display.
    IF sy-subrc = 0.
      DATA(lv_del) = abap_true.
    ENDIF.
    IF /sct/qp_if_ui_objlist~mr_object_list->* IS INITIAL.
      set_splitter_size( ).
    ELSE.

      " 2) PopUp for Dataloss. Should changed data also be discarded ?
      IF      mo_controller->get_changed_status( ) IS NOT INITIAL              " Es gab nicht gespeicherte Änderungen
      AND NOT line_exists( is_get-t_event_arg[ table_line = `FORCE_FREE` ] ).

        " POPUP Datenverlust
        DATA(ls_callback_event) = is_get.
        " 2.1) Button okay -> changed data will be discarded, list will be empty
        ls_callback_event-t_event_arg = VALUE #( BASE mt_def_arg
                                                 ( `FORCE_FREE` ) ).

        IF lv_del = abap_true.
          " 2.2) Button cancel: all changed and unsaved data remain in the list. The first entry will be selected
          DATA(ls_cancel_event) = VALUE /sct/au5_if_client=>ty_s_get( event       = mcu->events-show_data " AD, 2026.10.09, changed
                                                                      t_event_arg = VALUE #( ( CONV #( /sct/qp_if_ui_objlist~mr_object_list->*[ 1 ]-guid ) )
                                                                                             ( CONV #( /sct/qp_if_ui_objlist~mr_object_list->*[ 1 ]-guid ) ) ) ).
        ENDIF.

        DATA(lo_popup) = /sct/qp_cl_ui_popup=>factory( i_title               = |{ mutx->get_text( mutx->n100 ) }|
                                                       i_text                = |{ cl_abap_char_utilities=>cr_lf }{ mutx->get_text( mutx->n101 ) }|
                                                       i_button_text_confirm = mutx->get_text( mutx->n102 )
                                                       i_button_text_cancel  = mutx->get_text( mutx->n103 )
                                                       is_callback_event     = ls_callback_event
                                                       is_callback_cancel    = ls_cancel_event ).
        ms_control-client->nav_app_call( lo_popup ).

      ELSE.

        " 3) Delete all list data
        mo_controller->do_free( ).
        set_stateful( abap_false ).
        CLEAR /sct/qp_if_ui_objlist~mr_object_list->*.
        CLEAR /sct/qp_if_ui_objlist~mt_object_selected.
        set_splitter_size( ).
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~actualize_bindings.
    init_instances( ).
    _bind( iv_fieldname = 'mv_sel_size' ).
    _bind( iv_fieldname = |/sct/qp_if_ui_objlist~mt_object_selected| ).
    _bind( iv_fieldname = |/sct/qp_if_ui_objlist~mr_object_list->*| ).
  ENDMETHOD.
ENDCLASS.
