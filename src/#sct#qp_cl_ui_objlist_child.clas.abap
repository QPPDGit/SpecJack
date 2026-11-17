CLASS /sct/qp_cl_ui_objlist_child DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objlist
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_objlist_child.

    ALIASES mt_object_list FOR /sct/qp_if_ui_objlist~mt_object_list.

    DATA mt_breadcrumbs      TYPE /sct/qp_if_ui_objlist=>ty_t_breadcrumbs.
    DATA ms_current_location TYPE /sct/qp_if_ui_objlist=>ty_s_current_location.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_app~must_redraw_nested REDEFINITION.
    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.

  PROTECTED SECTION.
    METHODS insert_object_list IMPORTING ir_base TYPE REF TO /sct/qp_s_base.
    METHODS do_show_data.

    METHODS do_build_data IMPORTING iv_guid            TYPE /sct/qp_guid
                                    iv_oguid           TYPE /sct/qp_oguid
                                    iv_parent_location TYPE abap_bool OPTIONAL.

    METHODS do_refresh_data.

    METHODS do_create_vtyp                                                                         " AD, 2026.10.09, changed
                           IMPORTING is_get         TYPE /sct/au5_if_client=>ty_s_get OPTIONAL
                                     iv_vtyp        TYPE /sct/qp_vtyp                 OPTIONAL
                                     iv_parent_guid TYPE /sct/qp_guid                 OPTIONAL.

    METHODS do_get_direct_children RETURNING VALUE(rt_thier) TYPE /sct/qp_t_thier.

    METHODS init_instances     REDEFINITION.
    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS /sct/qp_cl_ui_objlist_child IMPLEMENTATION.
  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    /sct/qp_if_ui_objlist~mr_object_list = REF #( /sct/qp_if_ui_objlist~mt_object_list ).
  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

*    mt_def_arg = VALUE #( ( `${OGUID}` )
*                          ( `${GUID}`  ) ).

    mv_show_vart_vtyp_text = abap_true.
  ENDMETHOD.

  METHOD process_fcode_self.
    mv_must_redraw = abap_false.
    CASE is_get-event.
      WHEN mcu->events-show_data.
        " Zeigt is_get-t_event_arg[ 2 ] im rechten Bereich an
        " in den mittleren Bereich werden die Kinder des Elternteils angezeigt,
        " es sei denn man kommt aus Breadcrumds is_get-t_event_arg[ 3 ] = 'BC'
*        DATA(lv_bc) = VALUE #( is_get-t_event_arg[ 3 ] OPTIONAL ).
*        do_build_data( iv_oguid           = CONV #( is_get-t_event_arg[ 1 ] )
*                       iv_guid            = CONV #( is_get-t_event_arg[ 2 ] )
*                       iv_parent_location = xsdbool( lv_bc <> `BC` )  ).

        " GUID <> OGUID => parent location = true
        do_build_data( iv_oguid           = CONV #( is_get-t_event_arg[ 1 ] )
                       iv_guid            = CONV #( is_get-t_event_arg[ 2 ] )
                       iv_parent_location = xsdbool( is_get-t_event_arg[ 1 ] <> is_get-t_event_arg[ 2 ] ) ).

        do_refresh_data( ).
        /sct/qp_if_ui_objlist~do_set_navigated( CONV #( is_get-t_event_arg[ 2 ] ) ).
* FT20251125 Nicht mehr notwendig seitdem das Binding aktualisiert wird
*        IF NOT is_stateful( ).
*          mv_must_redraw = abap_true.
*        ENDIF.
        rv_processed = abap_false. " Prozessierung der Detailanzeige
*        ms_control-client->nest_view_model_update( ).
      WHEN mcu->events-drill.
        " Zeigt is_get-t_event_arg[ 2 ] im rechten Bereich an
        " in den mittleren Bereich werden die Kinder dieses Knotens angezeigt

        do_build_data( iv_oguid = CONV #( is_get-t_event_arg[ 1 ] )
                       iv_guid  = CONV #( is_get-t_event_arg[ 2 ] ) ).
        do_refresh_data( ).
        /sct/qp_if_ui_objlist~do_set_navigated( CONV #( is_get-t_event_arg[ 2 ] ) ).
        rv_processed = abap_false. " Prozessierung der Detailanzeige

      WHEN mcu->events-nav_list_refresh.
        do_refresh_data( ).
        /sct/qp_if_ui_objlist~do_set_navigated( CONV #( is_get-t_event_arg[ 2 ] ) ).
        rv_processed = abap_true.

      WHEN mcu->events-bc_navigate.
        ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-drill
                                                                 t_event_arg = is_get-t_event_arg ) ).

        rv_processed = abap_true.

      WHEN mcu->events-wiz_display_child.
        DATA(lt_thier) = do_get_direct_children( ).

        " Prüfen ob nur ein direktes Kind möglich ist oder mehrere.
        " Wenn nur ein direktes Kind möglich ist, soll dieses direkt angelegt werden.
        " Wenn mehere Kinder möglich sind, soll der Wizard aufgerufen werden.
        IF lines( lt_thier ) = 1.

          IF ms_current_location-show_cl = abap_false.
            DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = ms_current_location-guid
                                                     iv_oguid    = ms_current_location-oguid
                                                     iv_stateful = is_stateful( ) ).
            DATA(lv_parent_guid) = mo_ui_handler->get_base_parent_resolve_vblock( ir_base     = lr_base
                                                                                  iv_stateful = is_stateful( ) )-guid.
          ELSE.
            lv_parent_guid = ms_current_location-guid.
          ENDIF.

          do_create_vtyp( iv_parent_guid = lv_parent_guid
                          iv_vtyp        = VALUE #( lt_thier[ 1 ]-hvtyp OPTIONAL ) ).
        ELSE.
          DATA(lo_wizard) = /sct/qp_cl_ui_wizard=>get_instance( ).
          lo_wizard->init( iv_object           = 'child'
                           is_callback         = VALUE #( s_get-event = mcu->events-wiz_callback_child )
                           is_current_location = ms_current_location
                           is_control          = ms_control ).
          ms_control-client->nav_app_call( CAST /sct/au5_if_app( lo_wizard ) ).
        ENDIF.
        rv_processed = abap_true.

      WHEN mcu->events-nav_list_clear.
*        CLEAR mt_object_list.
        CLEAR /sct/qp_if_ui_objlist~mr_object_list->*.
        rv_processed = abap_true.
      WHEN mcu->events-duplicate_child.
*        ms_control-client->popover_destroy( ).
        /sct/qp_if_ui_objlist~do_duplicate( iv_guid = is_get-t_event_arg[ 2 ] ).
        rv_processed = abap_true.
      WHEN mcu->events-delete_child.
*        ms_control-client->popover_destroy( ).
        /sct/qp_if_ui_objlist~do_delete( iv_guid = is_get-t_event_arg[ 2 ] ).
        do_refresh_data( ).
        rv_processed = abap_true.
      WHEN mcu->events-wiz_callback_child. " Neu
        do_create_vtyp( is_get = is_get ).

    ENDCASE.
  ENDMETHOD.

  METHOD do_build_data.
    IF iv_guid IS INITIAL OR iv_oguid IS INITIAL.
      RETURN.
    ENDIF.

    ms_current_location-oguid = iv_oguid.
    ms_current_location-guid  = iv_guid.

    IF iv_parent_location = abap_true.
      " Ziel ohne Kinder
      DATA(lr_base) = mo_ui_handler->get_hierarchy( iv_guid     = iv_guid
                                                    iv_oguid    = iv_oguid
                                                    iv_stateful = is_stateful( ) ).

      " ggfs VBLÖCKE überspringen
      DATA(lv_parent_guid) = mo_ui_handler->get_base_parent_resolve_vblock( ir_base     = lr_base
                                                                            iv_stateful = is_stateful( ) )-guid.
      " Geschwister
      mo_ui_handler->get_hierarchy( EXPORTING iv_guid     = lv_parent_guid
                                              iv_oguid    = iv_oguid
                                              iv_stateful = is_stateful( )
                                    IMPORTING et_base     = DATA(lt_base) ).

      ms_current_location-show_cl = abap_false.
    ELSE.
      " Ziel mit Kindern
      lr_base = mo_ui_handler->get_hierarchy( EXPORTING iv_guid     = iv_guid
                                                        iv_oguid    = iv_oguid
                                                        iv_stateful = is_stateful( )
                                              IMPORTING et_base     = lt_base ).

      ms_current_location-show_cl = abap_true.
    ENDIF.
    IF lr_base IS BOUND.
      ms_control-base = lr_base.
    ENDIF.

    IF /sct/qp_if_ui_objlist~mr_object_list->* IS INITIAL.
*      " Wechsel 2-Spalten -> 3-Spalten Objekt in stateful mode
      mv_must_redraw = abap_true.
    ENDIF.

    CLEAR /sct/qp_if_ui_objlist~mr_object_list->*.

    LOOP AT lt_base INTO lr_base.
      insert_object_list( lr_base ).
    ENDLOOP.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~display.
    IF io_view IS BOUND.
      ms_control-parent_view = io_view.
    ELSE.
      ms_control-parent_view = /sct/au5_cl_xml_view=>factory( t_ns = VALUE #( ( n = 'id'
                                                                                v = 'CHILD_VIEW' ) ) ).

    ENDIF.
    result = ms_control-parent_view.
    ms_control-client = io_client.
    init_instances( ).
    do_show_data( ).
  ENDMETHOD.

  METHOD do_show_data.
*    IF mt_object_list IS INITIAL.
*      RETURN.
*    ENDIF.

    DATA(lo_page) = ms_control-parent_view->page( showheader = abap_false
                                                  id         = 'CHILD-page'
* FT20260218 Wird wahrscheinlich benötigt für kleinere Bildschirme( Handys )
*                                                  showheader = abap_true
*                                                  navbuttonpress = ms_control-client->_event( val = 'PREVIOUS_NODE' )
*                                                  shownavbutton = abap_true
                                                   ).

    " *********************************************************************
    " Breadcrumbs
    " *********************************************************************

*    DATA(lv_lines) = lines( mt_breadcrumbs ).
*    IF line_exists( mt_object_list[ is_selected = abap_true ] ).
*      " Alle Breadcrumbs als Link anzeigen.
*      CLEAR mv_current_location.
*    ELSE.
*      " Der letzte Eintrag ist so nicht clickbar
*      mv_current_location = mt_breadcrumbs[ lv_lines ]-name.
*      DELETE mt_breadcrumbs FROM lv_lines.
*    ENDIF.

    DATA(lo_links) = lo_page->breadcrumbs( id                  = 'childBreadcrumbs'
                                           currentlocationtext = ms_control-client->_bind( ms_current_location-name )
                                           links               = ms_control-client->_bind( mt_breadcrumbs )
*                                           separatorstyle      = `/`
                                           separatorstyle      = `Slash`
                                           visible             = abap_true )->link( ).

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lo_link) = lo_links->link( text  = '{NAME}'
                                    press = _event( iv_name = mcu->events-bc_navigate
                                                    it_arg  = VALUE #( ( `${OGUID}` )
                                                                       ( `${GUID}` ) ) ) ).

    " *********************************************************************
    " Objektliste
    " *********************************************************************
    DATA(lo_items) = lo_page->list( id    = 'Child_List'
                                    items = ms_control-client->_bind( /sct/qp_if_ui_objlist~mr_object_list->* )
                                            )->items( ).

    IF mv_list_type = /sct/qp_if_ui_objlist=>object_list_item.
      build_object_list_item( lo_items ).
    ELSE.
      build_custom_list_item( io_items = lo_items ).
    ENDIF.

    IF ms_control-base IS BOUND.
      DATA(lt_excl) = ms_control-base->excl_action.

      " Das Profil hat eine höhere Prioriät als die TOOGLE-Actioncodes oben.
      LOOP AT mo_controller->get_excl_actions_prof( iv_workmode = ms_control-base->workmode
                                                    iv_app      = VALUE #( ) ) ASSIGNING FIELD-SYMBOL(<ls_excl_actions_prof>).
        INSERT <ls_excl_actions_prof> INTO TABLE lt_excl.
      ENDLOOP.
    ENDIF.

    IF NOT line_exists( lt_excl[ table_line = mc->action_create_child ] ).

      lo_page->splitter( height = '1rem' ).

      lo_page->hbox( justifycontent = 'Center'
                     class          = `sapUiTinyMargin`
                      )->button( text  = mtx->get_text( mtx->taq )
                                 icon  = 'sap-icon://sys-add'
                                 type  = 'Transparent'
                                 press = _event( iv_name = mcu->events-wiz_display_child
                                                 it_arg  = VALUE #( ) ) ).
    ENDIF.

*
*    lo_page->flex_box( justifycontent   = 'Center'
*                       aligncontent     = 'Center'
*                       backgrounddesign = 'Transparent'
*        )->icon( src         = 'sap-icon://sys-add'
**                 decorative  = abap_true
*                 color       = '#556B82' "'#CACACA'
*                 size        = '200%'
*                 hovercolor  = '#0070F2'
*                 press       = _event( iv_name = mcu->events-wiz_display_child )
*                 activecolor = '#E8743B' ).
  ENDMETHOD.

  METHOD do_refresh_data.
    " *********************************************************************
    " Liste aktualisieren (Icon, Status, Marker)
    " *********************************************************************
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lv_first) = abap_true.

    IF is_stateful( ).
      DATA(lt_del) = mo_controller->mo_model->get_base_delete( ).
    ENDIF.

    LOOP AT /sct/qp_if_ui_objlist~mr_object_list->* ASSIGNING FIELD-SYMBOL(<list>).
*         WHERE relattyp = mc->relattyp_original.

      IF is_stateful( ).
        IF line_exists( lt_del[ KEY guid COMPONENTS guid = <list>-guid ] ).
          DELETE /sct/qp_if_ui_objlist~mr_object_list->* WHERE guid = <list>-guid.
          CONTINUE.
        ENDIF.
      ENDIF.
      DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = <list>-guid
                                               iv_oguid    = <list>-oguid
                                               iv_stateful = is_stateful( ) ).

      IF lr_base IS NOT BOUND.

        " Nachladen von Objekten : Kind anlegen dann Änderungen verwerfen.
        " Zurück ins Stateless, die angezeigte GUID ist nicht mehr vorhanden

*        IF line_exists( lt_del[ KEY guid COMPONENTS guid = <list>-oguid ] ).
        DELETE mt_object_list WHERE guid = <list>-guid.
*        ENDIF.
        CONTINUE.

      ENDIF.
      IF lr_base->vblock IS NOT INITIAL.
        mo_cust->get_tvblock( EXPORTING iv_vblock  = lr_base->vblock                 " Vorschriftenblock
                              IMPORTING es_tvblock = DATA(ls_tvblock) ). " Vorschrift Block

        <list>-vname = ls_tvblock-vblocktext.
      ELSE.
        <list>-vname = lr_base->instance->ms_node_data-vname.

      ENDIF.
      <list>-vtext    = get_node_vtext( ir_base = lr_base ).
      <list>-istat    = get_status_text( ir_base = lr_base ).
      <list>-icon     = get_status_icon( ir_base = lr_base ).
      <list>-state    = get_status_state( ir_base = lr_base ).
      <list>-workmode = lr_base->workmode.
      <list>-marker   = get_marker( lr_base ).

*      <list>-markervisible = COND #( WHEN ls_base-workmode <> mc->workmode_display THEN abap_true ).
      <list>-type     = COND #( WHEN lr_base->instance->mt_childs IS INITIAL
                                THEN mcu->sap-m-listtype-active
                                ELSE mcu->sap-m-listtype-navigation ).

    ENDLOOP.
    IF sy-subrc = 0.
      ms_control-client->nest_view_model_update( ).
    ENDIF.

    CLEAR mt_breadcrumbs.
    lr_base = mo_ui_handler->get_hierarchy( iv_guid     = ms_current_location-guid                 " Vorschriften GUID
                                            iv_oguid    = ms_current_location-oguid                 " Vorschriften GUID
                                            iv_stateful = is_stateful( ) ).

    IF lr_base IS NOT BOUND.
      CLEAR ms_current_location.
    ELSE.
      IF ms_current_location-show_cl = abap_true.
        ms_current_location-name = get_node_objtext( lr_base ).
      ELSE.
        CLEAR ms_current_location-name.
      ENDIF.
      DATA(lt_parents) = mo_ui_handler->get_base_parents( ir_base     = lr_base
                                                          iv_stateful = is_stateful( ) ).

      LOOP AT lt_parents ASSIGNING FIELD-SYMBOL(<parent>).

        INSERT VALUE #( guid      = <parent>-guid
                        oguid     = <parent>-oguid
                        name      = get_node_objtext( REF #( <parent> ) )
                        navigated = abap_true ) INTO TABLE mt_breadcrumbs.

      ENDLOOP.

    ENDIF.
  ENDMETHOD.

  METHOD insert_object_list.
    DATA(lv_icon) = get_ui_icon( ir_base ).
*    IF lv_icon IS INITIAL.
*      lv_icon = 'sap-icon://dimension'.
*    ENDIF.

    DATA(lt_thier) = mo_cust->get_thier_childs( iv_vart   = ir_base->hvart                 " Vorschriftenart
                                                iv_hiera  = ir_base->hinfo                 " Hierachiestufe
                                                iv_action = mc->action_create_child ). " Aktionscode
    IF lt_thier IS NOT INITIAL.
      " Unterknoten sind möglich
      DATA(lv_visible) = abap_true.
    ENDIF.

    DATA(lv_text) = get_vart_vtyp_text( ir_base ).
    DATA(lv_vnrvvs) = get_node_vnr( ir_base ).
    IF lv_vnrvvs CO ' -'.
      lv_vnrvvs = |({ lv_text })|.
    ELSE.
      lv_vnrvvs = |{ lv_vnrvvs } ({ lv_text })|.
    ENDIF.
    INSERT VALUE #( key           = ir_base->key
                    oguid         = ir_base->oguid
                    guid          = ir_base->guid
                    pguid         = ir_base->parent_guid
                    vart          = ir_base->vart
                    vtyp          = ir_base->vtyp
                    vnrvvs        = lv_vnrvvs
                    image_src     = lv_icon
                    relattyp      = ir_base->relattyp
*                    vname         = ir_base->instance->ms_node_data-vname
*                    text          = get_vart_vtyp_text( ir_base )
*                    istat         = get_status_text( ir_base = ir_base )
*                    icon          = get_status_icon( ir_base = ir_base )
*                    state         = get_status_state( ir_base = ir_base )
*                    type          = COND #( WHEN ir_base->instance->mt_childs IS INITIAL
*                                            THEN mcu->sap-m-listtype-active
*                                            ELSE mcu->sap-m-listtype-navigation )
*                    workmode      = ir_base->workmode
                    markervisible = abap_false
                    minus_vis     = abap_true
                    drill_vis     = lv_visible )
           INTO TABLE /sct/qp_if_ui_objlist~mr_object_list->*.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~must_redraw_nested.
    result = mv_must_redraw.
  ENDMETHOD.

  METHOD init_instances.
    super->init_instances( ).

    mt_def_arg = VALUE #( ( `${OGUID}` )
                          ( `${GUID}`  )
                          ( `${TYPE}`  )
                          ( `${$source>/id}` ) ).

    mv_show_vart_vtyp_text = abap_true.
  ENDMETHOD.

  METHOD do_create_vtyp.
    DATA(lv_vtyp) = COND /sct/qp_vtyp(
      WHEN iv_vtyp IS SUPPLIED
      THEN iv_vtyp
      ELSE VALUE #( is_get-t_comp_params[ n = 'VTYP' ]-v OPTIONAL ) ).

    DATA(lv_parent_guid) = COND /sct/qp_guid(
      WHEN iv_parent_guid IS SUPPLIED
      THEN iv_parent_guid
      ELSE VALUE #( is_get-t_comp_params[ n = 'PARENT' ]-v OPTIONAL ) ).

    DATA(lv_vname) = VALUE /sct/qp_vname( is_get-t_comp_params[ n = 'VNAME' ]-v OPTIONAL ).
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lv_vbez) = VALUE /sct/qp_qvtext( is_get-t_comp_params[ n = 'VBEZ' ]-v OPTIONAL ).

    IF lv_vtyp        IS INITIAL
    OR lv_parent_guid IS INITIAL.
      RETURN.
    ENDIF.

    mo_bus->read( EXPORTING iv_guid   = lv_parent_guid
                  IMPORTING et_base   = DATA(lt_base)
                  " TODO: variable is assigned but never used (ABAP cleaner)
                            et_return = DATA(lt_return)
                  " TODO: variable is assigned but never used (ABAP cleaner)
                            ev_error  = DATA(lv_error) ).

    DATA(ls_base_parent) = VALUE #( lt_base[ KEY guid COMPONENTS guid = lv_parent_guid ] OPTIONAL ).

    mo_bus->create_child( EXPORTING is_node_parent = ls_base_parent-instance->ms_node_data
                                    is_node_child  = VALUE #( vtyp  = lv_vtyp
                                                              vname = lv_vname )
                          IMPORTING et_return      = lt_return
                                    ev_error       = lv_error
                                    es_base_new    = DATA(ls_base_new) ).

    set_stateful( ).

    ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-show_data
                                                             t_event_arg = VALUE #( ( CONV #( ls_base_new-oguid ) )
                                                                                    ( CONV #(  ls_base_new-guid ) )
*                                                                                          ( mcu->sap-m-listtype-navigation )
                                        ) )
                                        io_client = ms_control-client ).
  ENDMETHOD.

  METHOD do_get_direct_children.
    DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = ms_current_location-guid
                                             iv_oguid    = ms_current_location-oguid
                                             iv_stateful = is_stateful( ) ).

    IF ms_current_location-show_cl = abap_false.
      " ggfs VBLÖCKE überspringen
      DATA(lv_hinfo) = mo_ui_handler->get_base_parent_resolve_vblock( ir_base     = lr_base
                                                                      iv_stateful = is_stateful( ) )-hinfo.
    ELSE.
      lv_hinfo = lr_base->hinfo.
    ENDIF.

    mo_cust->get_thier( EXPORTING iv_vart  = CONV #( lr_base->ovart )
                                  iv_hiera = CONV #( lv_hinfo )
                        IMPORTING et_thier = DATA(lt_thier) ).

    DATA(lv_level) = CONV /sct/qp_hier_level( VALUE #( lt_thier[ hiera = lv_hinfo ]-level OPTIONAL ) + 1 ).
    rt_thier = FILTER #( lt_thier USING KEY level WHERE level = lv_level ).

*    IF lr_base->hinfo IS INITIAL.
*      LOOP AT lt_thier ASSIGNING FIELD-SYMBOL(<ls_thier>) WHERE hiera    IS NOT INITIAL
**                                                          AND   hiera NP '*.%'  " NP = Not Pattern (enthält keinen Punkt)
*                                                            AND relattyp  = mc->relattyp_original
*                                                            AND hvtyp    IS NOT INITIAL.
*        " Prüfe ob hiera einen Punkt enthält
*        IF <ls_thier>-hiera CA '.'. " CA = Contains Any (enthält das Zeichen '.')
*          CONTINUE.
*        ENDIF.
*        INSERT <ls_thier> INTO TABLE rt_thier.
*      ENDLOOP.
*
*
*    ELSE.
*
    " Wenn gefüllt: nur direkte Kinder (eine Ebene tiefer)
*      DATA(lv_hiera_trimmed) = CONV string( lr_base->hinfo ).
*      CONDENSE lv_hiera_trimmed NO-GAPS.
*
*      DATA(lv_prefix) = |{ lv_hiera_trimmed }.|.
*      DATA(lv_prefix_len) = strlen( lv_prefix ).
*
*      " Zähle Punkte im ursprünglichen Wert
*      DATA(lv_parent_depth) = strlen( lv_hiera_trimmed ) - strlen( replace( val  = lv_hiera_trimmed
*                                                                            sub  = '.'
*                                                                            with = '' ) ).
*
*      LOOP AT lt_thier ASSIGNING <ls_thier> WHERE relattyp  = mc->relattyp_original
*                                              AND hvtyp    IS NOT INITIAL.
*
*        " Hiera trimmen für Vergleich
*        DATA(lv_thier_hiera) = CONV string( <ls_thier>-hiera ).
*        CONDENSE lv_thier_hiera NO-GAPS.
*
*        " Prefix prüfen
*        IF strlen( lv_thier_hiera )         < lv_prefix_len
*        OR lv_thier_hiera+0(lv_prefix_len) <> lv_prefix.
*          CONTINUE.
*        ENDIF.
*
*        " Zähle Punkte im aktuellen Wert
*        DATA(lv_current_depth) = strlen( lv_thier_hiera ) - strlen( replace( val  = lv_thier_hiera
*                                                                             sub  = '.'
*                                                                             with = '' ) ).
*
*        " Nur direkte Kinder (genau eine Ebene tiefer = ein Punkt mehr)
*        IF lv_current_depth = lv_parent_depth + 1.
*          INSERT <ls_thier> INTO TABLE rt_thier.
*        ENDIF.
*
*      ENDLOOP.
*    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~actualize_bindings.
    init_instances( ).
    _bind( iv_fieldname = |/sct/qp_if_ui_objlist~mr_object_list->*| ).
    _bind( iv_fieldname = |ms_current_location-name| ).
    _bind( iv_fieldname = |mt_breadcrumbs| ).
  ENDMETHOD.
ENDCLASS.
