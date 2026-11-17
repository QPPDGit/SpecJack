CLASS /sct/qp_cl_ui_objlist DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/qp_if_ui_objlist.

    DATA mv_sel_size TYPE string VALUE `0rem` ##NO_TEXT.

    METHODS constructor.

  PROTECTED SECTION.
    DATA mv_list_type           TYPE /sct/qp_if_ui_objlist=>ty_list_type.
    DATA mv_show_vart_vtyp_text TYPE abap_bool.
    DATA mv_must_redraw         TYPE abap_bool.

    "! <p class="shorttext synchronized">create as object list item</p>
    "!
    "! @parameter IO_ITEMS | <p class="shorttext synchronized"></p>
    METHODS build_object_list_item IMPORTING io_items TYPE REF TO /sct/au5_cl_xml_view.
    "! <p class="shorttext synchronized">create as custom list item</p>
    "!
    "! @parameter IO_ITEMS | <p class="shorttext synchronized">create as custom list</p>
    METHODS build_custom_list_item IMPORTING io_items TYPE REF TO /sct/au5_cl_xml_view.

    "! <p class="shorttext synchronized">get marker type (unsaved changes, locked)</p>
    "!
    "! @parameter ir_base | <p class="shorttext synchronized">specification data</p>
    "! @parameter result  | <p class="shorttext synchronized">Username: Locked by</p>
    METHODS get_marker IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                       RETURNING VALUE(result) TYPE /sct/qp_if_ui_objlist=>ty_marker.

    METHODS do_delete_childs IMPORTING is_base TYPE /sct/qp_s_base.

    METHODS do_popover_child IMPORTING iv_guid    TYPE /sct/qp_guid
                                       iv_oguid   TYPE /sct/qp_oguid
                                       iv_id      TYPE string
                                       io_navlist TYPE REF TO /sct/au5_cl_xml_view
                                       ir_base    TYPE REF TO /sct/qp_s_base.

    METHODS do_popover_root IMPORTING iv_guid    TYPE /sct/qp_guid
                                      iv_oguid   TYPE /sct/qp_oguid
                                      iv_id      TYPE string
                                      io_navlist TYPE REF TO /sct/au5_cl_xml_view
                                      ir_base    TYPE REF TO /sct/qp_s_base
                            RAISING   /sct/qp_cx_error.

    METHODS set_splitter_size.

  PRIVATE SECTION.

ENDCLASS.



CLASS /SCT/QP_CL_UI_OBJLIST IMPLEMENTATION.


  METHOD /sct/qp_if_ui_objlist~do_add_menu_item.
    r_result = io_parent->_generic( name   = `MenuItem`
                                    t_prop = VALUE #( ( n = `press`
                                                        v = iv_press )
                                                      ( n = `text`
                                                        v = iv_text )
                                                      ( n = `icon`
                                                        v = iv_icon ) ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_add_menu_item_group.
    r_result = io_parent->_generic( name   = 'NavigationListGroup '
                                    ns     = `tnt`
                                    t_prop = VALUE #( ( n = `itemSelectionMode`
                                                        v = iv_itemselectionmode ) ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_add_navlist_group.
    r_result = io_parent->_generic( name   = 'NavigationListGroup '
                                    ns     = `tnt`
                                    t_prop = VALUE #( ( n = `text`
                                                        v = iv_text )
                                                      ( n = `icon`
                                                        v = iv_icon )
                                                      ( n = `href`
                                                        v = iv_href )
                                                      ( n = `key`
                                                        v = iv_key )
                                                      ( n = `select`
                                                        v = iv_select )
                                                      ( n = `hasExpander`
                                                        v = iv_has_expander )
                                                      ( n = `expanded`
                                                        v = iv_expanded ) ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_add_navlist_item.
    r_result = io_parent->_generic( name   = `NavigationListItem`
                                    ns     = `tnt`
                                    t_prop = VALUE #( ( n = `text`
                                                        v = iv_text )
                                                      ( n = `icon`
                                                        v = iv_icon )
                                                      ( n = `href`
                                                        v = iv_href )
                                                      ( n = `key`
                                                        v = iv_key )
                                                      ( n = `select`
                                                        v = iv_select )
                                                      ( n = `selectable`
                                                        v = iv_selectable )
                                                      ( n = `expanded`
                                                        v = iv_expanded ) ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_delete.
    mo_bus->read( EXPORTING iv_guid   = CONV #( iv_guid )
                  IMPORTING es_header = DATA(ls_header)
                            et_base   = DATA(lt_base) ).

    " Entscheidung ob es sich um einen Root oder ein Kind handelt.
    " *********************************************************************
    " Root löschen
    " *********************************************************************
    IF ls_header-guid = iv_guid. " Root löschen
      mo_bus->delete( EXPORTING is_header = ls_header
                      " TODO: variable is assigned but never used (ABAP cleaner)
                      IMPORTING et_return = DATA(lt_return)
                      " TODO: variable is assigned but never used (ABAP cleaner)
                                ev_error  = DATA(lv_error)
                      " TODO: variable is assigned but never used (ABAP cleaner)
                                eo_error  = DATA(lo_error) ).

      " Wenn ein Knoten gelöscht wird, welcher selektiert ist, muss die Anzeige auf Singlecolumn zurückgesetzt werden.
      " Außerdem muss der Knoten aus der MT_OBJECT_LIST gelöscht werden
      DATA(lv_selected) = VALUE #( /sct/qp_if_ui_objlist~mr_object_list->*[ guid = iv_guid ]-is_selected OPTIONAL ).

      DELETE /sct/qp_if_ui_objlist~mr_object_list->* WHERE guid = iv_guid.
      IF lv_selected = abap_true.
        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-reset_layout_root )
                                            io_client = ms_control-client ).
      ENDIF.

      " Wenn eine Vorschrift gelöscht wird, soll hier im Gegensatz zur GUI direkt gespeichert werden
      mo_bus->save( ).

      " Nachdem gespeichert wurde, kann auch wieder auf Stateless gestellt werden
      /sct/qp_if_ui_app~set_stateful( abap_false ).

    " *********************************************************************
    " Kinder löschen
    " *********************************************************************
    ELSE.

      DATA(ls_base_child) = VALUE #( lt_base[ KEY guid COMPONENTS guid = iv_guid ] OPTIONAL ).
      IF ls_base_child IS INITIAL.
        RETURN.
      ENDIF.

*      do_delete_childs( ls_base_child ).

      mo_bus->delete( EXPORTING is_header = ls_header
                                it_items  = VALUE #( ( ls_base_child-instance->ms_node_data ) )
                      IMPORTING et_return = lt_return
                                ev_error  = lv_error
                                eo_error  = lo_error ).

      " Wenn ein Kinderknoten gelöscht wird, welcher selektierst ist, muss hier auch die Anzeige zurückgesetzt werden
      " Außerdem muss der Knoten aus der MT_OBJECT_LIST gelöscht werden
      lv_selected = VALUE #( /sct/qp_if_ui_objlist~mr_object_list->*[ guid = iv_guid ]-is_selected OPTIONAL ).

      DELETE /sct/qp_if_ui_objlist~mr_object_list->* WHERE guid = iv_guid.
      IF lv_selected = abap_true.
        ms_control-root_app->process_fcode( is_get    = VALUE #( event = mcu->events-reset_layout_root )
                                            io_client = ms_control-client ).
      ENDIF.

      " Wenn eine Vorschrift gelöscht wird, soll hier im Gegensatz zur GUI direkt gespeichert werden
      mo_bus->save( ).

      " Nachdem gespeichert wurde, kann auch wieder auf Stateless gestellt werden
      /sct/qp_if_ui_app~set_stateful( abap_false ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_duplicate.
    mo_bus->read( EXPORTING iv_guid   = CONV #( iv_guid )
                  IMPORTING es_header = DATA(ls_header)
                            et_base   = DATA(lt_base) ).

    IF ls_header-guid = iv_guid. " Kopf duplizieren

      mo_bus->copy( EXPORTING iv_vname_new = ls_header-vname
                              is_source    = VALUE #( guid = iv_guid )
                    " TODO: variable is assigned but never used (ABAP cleaner)
                    IMPORTING et_return    = DATA(lt_return)
                    " TODO: variable is assigned but never used (ABAP cleaner)
                              ev_error     = DATA(lv_error)
                              es_base_new  = DATA(ls_base_new) ).

      ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-nav_list_build
                                                               t_event_arg = VALUE #( ( CONV #( ls_base_new-guid ) ) ) )
                                          io_client = ms_control-client ).

    ELSE. " Kinder duplizieren
      DATA(ls_base) = VALUE #( lt_base[ KEY guid COMPONENTS guid = iv_guid ] OPTIONAL ).
      IF ls_base IS INITIAL.
        RETURN.
      ENDIF.

      mo_bus->create_copy( EXPORTING is_header         = ls_header
                                     iv_parent_guid    = ls_base-parent_guid
                                     is_node_target    = ls_base-instance->ms_node_data
                                     iv_node_copy_guid = ls_base-guid
                           IMPORTING et_return         = lt_return
                                     ev_error          = lv_error
                                     et_base_new       = DATA(lt_base_new) ).

      DATA(ls_base_child_new) = VALUE #( lt_base_new[ 1 ] OPTIONAL ).

      ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-show_data
                                                               t_event_arg = VALUE #( ( CONV #( ls_base_child_new-oguid ) )
                                                                                      ( CONV #( ls_base_child_new-parent_guid ) ) ) )
                                          io_client = ms_control-client ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_popover.
    DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = iv_guid
                                             iv_oguid    = iv_oguid
                                             iv_stateful = is_stateful( ) ).

    IF lr_base IS NOT BOUND.
      RETURN.
    ENDIF.

*    DATA(lt_toolbar_functions) = mo_tools->get_tree_toolbar_functions( abap_false ).

    DATA(lo_xml) = /sct/au5_cl_xml_view=>factory_popup( ).

    DATA(lo_popover) = lo_xml->popover( placement         = `Right`
*                                        title             = lr_base->instance->ms_node_data-vname
*                                        contentwidth      = `13rem`
*                                        contentheight     = `13rem`
                                        resizable         = `false`
                                        verticalscrolling = `true`
*                                        afterclose        = _event( mcu->events-after_close_popover )
                                        beforeclose       = _event( mcu->events-after_close_popover )
                                        showheader        = `false`
                                        showarrow         = `true`
                                        offsety           = '-13'
                                        offsetx           = '0' ).

    DATA(lo_flexbox) = lo_popover->flex_box( width      = '100%'
                                             height     = '90%'
                                             alignitems = 'Start' ).

    DATA(lo_side_navigation) = lo_flexbox->_generic( name   = 'SideNavigation'
                                                     ns     = `tnt`
                                                     t_prop = VALUE #( ( n = `id`
                                                                         v = 'sideNavigation' )
                                                                       ( n = `expanded`
                                                                         v = 'true' ) " COND #( WHEN mv_expand = abap_true THEN 'true' ELSE 'false' ) )
                                                                       ( n = `itemselect`
                                                                         v = 'OnItemSelect' ) ) ).

    DATA(lo_navlist) = lo_side_navigation->_generic( name   = `NavigationList`
                                                     ns     = `tnt`
                                                     t_prop = VALUE #( ( n = `expanded`
                                                                         v = 'true' ) ) ).

    IF iv_guid = iv_oguid.
      do_popover_root( iv_guid    = iv_guid
                       iv_oguid   = iv_oguid
                       iv_id      = iv_id
                       io_navlist = lo_navlist
                       ir_base    = lr_base ).
    ELSE.
      do_popover_child( iv_guid    = iv_guid
                        iv_oguid   = iv_oguid
                        iv_id      = iv_id
                        io_navlist = lo_navlist
                        ir_base    = lr_base ).
    ENDIF.

    ms_control-root_app->popover_open( iv_close_event = CONV #( mcu->events-after_close_popover ) ).

    ms_control-client->popover_display( xml   = lo_xml->stringify( )
                                        by_id = iv_id ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~do_set_navigated.
    " is_selected setzen, damit die Selektion auf dem Screen sichtbar wird

    LOOP AT /sct/qp_if_ui_objlist~mr_object_list->* ASSIGNING FIELD-SYMBOL(<list>).
      <list>-is_selected = xsdbool( <list>-guid = iv_guid ).
      IF <list>-is_selected = abap_true.
        <list>-highlight = mcu->sap-ui-core-message-MessageType-information.
        /sct/qp_if_ui_objlist~mt_object_selected = VALUE #( ( VALUE #( BASE <list>
                                                                       text = mtx->get_text( 'TAT' ) ) ) ).
      ELSE.
        <list>-highlight = mcu->sap-ui-core-message-MessageType-none.
      ENDIF.
    ENDLOOP.

    IF me IS INSTANCE OF /sct/qp_if_ui_objlist_root.
      set_splitter_size( ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objlist~is_fcode_excluded.
    r_return = COND #( WHEN line_exists( ir_base->excl_action[ actioncode = iv_action ] )
                       THEN abap_true
                       ELSE abap_false ).
  ENDMETHOD.


  METHOD build_custom_list_item.
    " Modifiziertes custom_list_item ( mit type und Event )

*    IF sy-uname = 'xTROMFRA'.
*
*      DATA(cli) = io_items->custom_list_item( press     = _event( iv_name = mcu->events-show_data )
*                                              type      = '{TYPE}'
*                                              navigated = '{IS_SELECTED}'
*                                              highlight = '{HIGHLIGHT}'
*
*              )->drag_drop_config(
*                  )->drag_info( sourceaggregation = `items`
*                  )->grid_drop_info( targetaggregation = `items`
*                                     dropposition      = `Between`
**                                     droplayout        = `Horizontal`
*                                     drop              = ms_control-client->_event( val   = 'onDrop'
*                                                                                    t_arg = VALUE #( ( `${$parameters>/draggedControl/oParent}.indexOfItem(${$parameters>/draggedControl})` )
*                                                                                                     ( `${$parameters>/droppedControl/oParent}.indexOfItem(${$parameters>/droppedControl})` )
*                                                                                                     ( `${$parameters>/dropPosition}` ) ) ) ).
*    ELSE.

    DATA(lo_cli) = io_items->custom_list_item( press     = _event( iv_name = mcu->events-show_data )
                                               type      = '{TYPE}'
                                               navigated = '{IS_SELECTED}'
                                               highlight = '{HIGHLIGHT}' ).

*    ENDIF.

    " Die Unterobjekte dieses HBOX haben space in der Mitte
    DATA(hb) = lo_cli->hbox( alignitems     = 'Center'
                             justifycontent = 'SpaceBetween' ).

    " Links : Icon / Title nebeneinander (HBOX)
    DATA(hb_left) = hb->hbox( class      = 'sapUiTinyMargin'
                              alignitems = 'Center' ).

    hb_left->icon( src   = '{IMAGE_SRC}'
                   size  = '2rem'
                   class = 'sapUiTinyMargin'
                   press = _event( iv_name = mcu->events-node_action )
                  )->text( text    = '{TEXT}'
                           class   = 'sapUiTinyMargin'
                           visible = mv_show_vart_vtyp_text
                          )->object_identifier( title       = '{VNAME}'
                                                text        = '{VNRVVS} {VTEXT}'
                                                titleactive = abap_true
                                                titlepress  = _event( iv_name = mcu->events-node_action ) ).

    " Rechts Status und Sperre übereinander ( VBOX )
    DATA(hb_right) = hb->hbox( class          = 'sapUiTinyMargin'
                               alignitems     = 'Center'
                               justifycontent = 'End' ).

*    hb_right->text( text = '{VTEXT}' class          = 'sapUiTinyMargin' ).

    DATA(vb) = hb_right->vbox( alignitems = 'Center' ).

    vb->object_status( text  = '{ISTAT}'
                       icon  = '{ICON}'
                       state = '{STATE}'
*                       class = 'sapUiTinyMargin'
                       ).

    vb->object_marker( visible        = '{MARKER/VISIBLE}'
                       type           = '{MARKER/TYPE}'
                       visibility     = '{MARKER/VISIBILITY}'
                       additionalinfo = '{MARKER/INFO}' ).

    DATA(hi) = vb->hbox( ).

    " Tiefer navigieren
    hi->icon( src         = 'sap-icon://arrow-down'
*              class       = 'sapUiTinyMargin'
              color       = '#556B82'
              size        = '150%'
              hovercolor  = '#0070F2'
*              useicontooltip = abap_true
              visible     = '{DRILL_VIS}'
              press       = _event( iv_name = mcu->events-drill )
              activecolor = '#E8743B' ).

*     hi->icon( src         = 'sap-icon://sys-minus'
*               class       = 'sapUiTinyMargin'
*               color       = '#C00000'
*               size        = '100%'
*               hovercolor  = '#0070F2'
*            alt         = 'Knoten löschen'
*               visible     = '{MINUS_VIS}'
*               press       = _event( iv_name = 'MINUS' )
*               activecolor = '#E8743B' ).
  ENDMETHOD.


  METHOD build_object_list_item.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lo_objectlist) = io_items->object_list_item( title = '{VNAME}'
*                                                      number = '{VNRVVS}'
                                                      icon  = '{IMAGE_SRC}'
                                                      type  = '{TYPE}'
*                                                      intro = '{TEXT}'
*                                                       selected
                                                      press = _event( iv_name = mcu->events-show_data  )
                                    )->first_status(
                                        )->object_status( text  = '{ISTAT}'
                                                          icon  = '{ICON}'
                                                          state = '{STATE}'
                                        )->get_parent(
                                    )->get_parent(
                                    )->object_attribute(
                                    )->object_attribute( text = '{VNRVVS}'
                                        )->markers(
                                            )->object_marker( visible        = '{MARKERVISIBLE}'
                                                              type           = 'LockedBy'
                                                              additionalinfo = |{ sy-uname }| ).
  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    mv_list_type = /sct/qp_if_ui_objlist=>custom_list_item.
*    mv_list_type = /sct/qp_if_ui_objlist=>object_list_item.
  ENDMETHOD.


  METHOD do_delete_childs.
    " Kindes Kinder löschen
    LOOP AT is_base-instance->mt_childs ASSIGNING FIELD-SYMBOL(<ls_childs>).
      do_delete_childs( <ls_childs>-node->ms_base ).
    ENDLOOP.

    " Kind löschen
    mo_bus->delete( EXPORTING is_header = is_base-root_instance->ms_node_data
                              it_items  = VALUE #( ( is_base-instance->ms_node_data ) )
                    " TODO: variable is assigned but never used (ABAP cleaner)
                    IMPORTING et_return = DATA(lt_return)
                              ev_error  = DATA(lv_error) ).
    IF lv_error IS NOT INITIAL.
      " TODO
    ENDIF.
  ENDMETHOD.


  METHOD do_popover_child.
    DATA lo_strucdescr TYPE REF TO cl_abap_structdescr.

    mo_cust->get_tj0x( EXPORTING iv_vart = ir_base->vart
                       IMPORTING es_tj0x = DATA(ls_tj0x) ).

    IF ir_base IS NOT BOUND.
      RETURN.
    ENDIF.

    " *********************************************************************
    " Basic Actions
    " *********************************************************************

    DATA(lo_basic_actions) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
                                                                         iv_text         = mutx->get_text( mutx->u088 )
                                                                         iv_has_expander = 'false' ).

    " Ändern
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_change
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u019 )
                                                 iv_icon   = 'sap-icon://edit'
                                                 iv_select = _event( iv_name = mcu->events-workmode_change
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ELSEIF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_display
                                                                 ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u028 )
                                                 iv_icon   = 'sap-icon://not-editable'
                                                 iv_select = _event( iv_name = mcu->events-workmode_display
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.

    " Aktivieren
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_activate
                                                              ir_base   = ir_base )
    AND abap_true  = ir_base->instance->is_release_available( ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u026 )
                                                 iv_icon   = 'sap-icon://activate' ).
    ENDIF.

    " Duplizieren
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_duplicate
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_duplicate
                                                            ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = lo_basic_actions
                                                 iv_text     = mutx->get_text( mutx->u083 )
                                                 iv_icon     = 'sap-icon://duplicate'
                                                 iv_expanded = 'false'
                                                 iv_select   = _event( iv_name = mcu->events-duplicate_child
                                                                       it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                          ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.

    "**********************************************************************
    " Status ändern
    "**********************************************************************
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_status_change
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_status_change
                                                            ir_base   = ir_base ).
      DATA(lo_chg_status) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_basic_actions
                                                                       iv_text   = mutx->get_text( mutx->u084 )
                                                                       iv_icon   = 'sap-icon://order-status' ).

      lo_strucdescr ?= cl_abap_typedescr=>describe_by_data( ir_base->instance->ms_node_data-status ).

      LOOP AT lo_strucdescr->components ASSIGNING FIELD-SYMBOL(<ls_comp>) WHERE name CP 'ZQ*'.
        ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE ir_base->instance->ms_node_data-status TO FIELD-SYMBOL(<lv_comp>).
        IF <lv_comp> = abap_false.
          CONTINUE.
        ENDIF.

        DATA(ls_vrgng) = VALUE #( ls_tj0x-activity[ vrgng = <ls_comp>-name ] OPTIONAL ).

        IF ls_vrgng IS INITIAL.
          CONTINUE.
        ENDIF.

        /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_chg_status
                                                   iv_text   = ls_vrgng-txt
                                                   iv_icon   = ls_vrgng-icon_ui
*                                                   iv_select =
        ).
      ENDLOOP.
    ENDIF.

    " Löschen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_delete
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_delete
                                                            ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u085 )
                                                 iv_icon   = 'sap-icon://delete'
                                                 iv_select = _event( iv_name = mcu->events-delete_child
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.

    " *********************************************************************
    " Funktionen
    " *********************************************************************
    DATA(lo_function_group) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
                                                                          iv_text         = mutx->get_text( mutx->u086 )
                                                                          iv_has_expander = 'false'
                                                                          iv_icon         = 'sap-icon://fx'
*                                                                          iv_select       =
*                                                                          iv_href         =
*                                                                          iv_key          =
    ).

    DATA(lo_function) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent     = lo_function_group
                                                                   iv_text       = mutx->get_text( mutx->u086 )
                                                                   iv_expanded   = 'false'
                                                                   iv_icon       = 'sap-icon://fx'
                                                                   iv_selectable = 'false'
*                                                                   iv_select     =
*                                                                   iv_href       =
*                                                                   iv_key        =
    ).

    DATA(lt_functions) = ir_base->vart_instance->get_functions( ir_base->* ).
    LOOP AT lt_functions ASSIGNING FIELD-SYMBOL(<ls_functions>).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent     = lo_function
                                                 iv_text       = <ls_functions>-text-text
                                                 iv_icon       = 'sap-icon://technical-object'
                                                 iv_select     = <ls_functions>-ucomm
                                                 iv_selectable = 'false' " abap_false "xsdbool( <ls_functions>-inactive = abap_false )
*                                                 iv_href       =
*                                                 iv_key        =
      ).
    ENDLOOP.

    " *********************************************************************
    " Erweiterte Action z.B. Anlegen mit Relation etc.
    " *********************************************************************

    DATA(lo_extended_actions) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
                                                                            iv_text         = mutx->get_text( mutx->u087 )
                                                                            iv_has_expander = 'false'
                                                                            iv_icon         = 'sap-icon://detail-more' ).

    " Anlegen einer Verknüpfung
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_relation
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_relation
                                                            ir_base   = ir_base ).
    ENDIF.

    " Anlegen mit Vorlage
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child_template
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_child_template
                                                            ir_base   = ir_base ).

      DATA(lt_thier) = mo_cust->get_thier_childs( iv_vart   = ir_base->vart
                                                  iv_hiera  = ir_base->hinfo
                                                  iv_action = 'CREATE_CHILD' ).
      IF lt_thier IS NOT INITIAL.
        DATA(lo_add_child_template) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = lo_extended_actions
                                                                                 iv_text     = mutx->get_text( mutx->u089 )
                                                                                 iv_expanded = 'false'
                                                                                 iv_icon     = 'sap-icon://create-form'
*                                                                                 iv_select   = _event( iv_name = mcu->events-wiz_create_child it_arg = VALUE #( ( CONV #( iv_oguid ) ) ( CONV #( iv_guid ) ) ) ) ).
        ).
        LOOP AT lt_thier ASSIGNING FIELD-SYMBOL(<ls_thier>).
          /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_add_child_template
                                                     iv_text   = <ls_thier>-vart
*                                                     iv_icon   =
*                                                     iv_select =
*                                                     iv_href   =
*                                                     iv_key    =
          ).
        ENDLOOP.
      ENDIF.
    ENDIF.
    " Anlegen Position
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_child
                                                            ir_base   = ir_base ).

      lt_thier = mo_cust->get_thier_childs( iv_vart   = ir_base->vart
                                            iv_hiera  = ir_base->hinfo
                                            iv_action = 'CREATE_CHILD' ).
      IF lt_thier IS NOT INITIAL.

        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        DATA(lo_add_child) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = lo_extended_actions
                                                                        iv_text     = mutx->get_text( mutx->u090 )
                                                                        iv_expanded = 'false'
                                                                        iv_icon     = 'sap-icon://create-form'
                                                                        iv_select   = _event( iv_name = mcu->events-wiz_create_child
                                                                                              it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                                                 ( CONV #( iv_guid ) ) ) ) ).

*        LOOP AT lt_thier ASSIGNING <ls_thier>.
*          do_add_navlist_item( io_parent = lo_add_child
*                               iv_text   = <ls_thier>-vart
**                               iv_icon   =
**                               iv_select =
**                               iv_href   =
**                               iv_key    =
*          ).
*        ENDLOOP.

      ENDIF.
    ENDIF.

    " Sekundärreferenz hinzufügen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_sec_ref
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_sec_ref
                                                            ir_base   = ir_base ).
    ENDIF.
    " Sekundärreferenz entfernen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_sec_del
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_sec_del
                                                            ir_base   = ir_base ).
    ENDIF.
    " Relation löschen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_delete_relat
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_delete_relat
                                                            ir_base   = ir_base ).
    ENDIF.

    " *********************************************************************
    " Sonstige
    " *********************************************************************

    DATA(lo_misc) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
                                                                iv_text         = mutx->get_text( mutx->u091 )
                                                                iv_has_expander = 'false' ).

    " Favoriten hinzufügen
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_ft_addfav
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u092 )
                                                 iv_icon   = 'sap-icon://add-favorite' ).
    ENDIF.

    " Verwendungsnachweis
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_verna
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u093 )
                                                 iv_icon   = 'sap-icon://split'
                                                 iv_select = _event( iv_name = mcu->events-where_used
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ENDIF.

    " Absprung zum Knoten
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_jump
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u094 )
                                                 iv_icon   = 'sap-icon://inspect'
                                                 iv_select = _event( iv_name = mcu->events-show_data
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ENDIF.

    " Action Log
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u095 )
                                                 iv_icon   = 'sap-icon://sap-box' ).
    ENDIF.
  ENDMETHOD.


  METHOD do_popover_root.
    DATA lo_strucdescr TYPE REF TO cl_abap_structdescr.

    mo_cust->get_tj0x( EXPORTING iv_vart = ir_base->vart
                       " TODO: variable is assigned but never used (ABAP cleaner)
                       IMPORTING es_tj0x = DATA(ls_tj0x) ).

    DATA(lt_activities) = mo_controller->get_mod_node_allowed_activitys( is_base    = ir_base->*
                                                                         iv_userset = abap_true ).

    " *********************************************************************
    " Basic Actions
    " *********************************************************************

*    DATA(lo_basic_actions) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
*                                                                         iv_text         = mutx->get_text( mutx->u088 )
*                                                                         iv_has_expander = 'false' ).

    " Ändern
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_change
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u019 )
                                                 iv_icon   = 'sap-icon://edit'
                                                 iv_select = _event( iv_name = mcu->events-workmode_change
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ELSEIF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_display
                                                                 ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u028 )
                                                 iv_icon   = 'sap-icon://not-editable'
                                                 iv_select = _event( iv_name = mcu->events-workmode_display
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.

    " Aktivieren
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_activate
                                                              ir_base   = ir_base )
    AND abap_true  = ir_base->instance->is_release_available( ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u026 )
                                                 iv_icon   = 'sap-icon://activate' ).
    ENDIF.

    " Duplizieren
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_duplicate
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_duplicate
                                                            ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = io_navlist
*                                                 io_parent   = lo_basic_actions
                                                 iv_text     = mutx->get_text( mutx->u083 )
                                                 iv_icon     = 'sap-icon://duplicate'
                                                 iv_expanded = 'false'
                                                 iv_select   = _event( iv_name = mcu->events-duplicate_root
                                                                       it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                          ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.

    " Löschen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_delete
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_delete
                                                            ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_basic_actions
                                                 iv_text   = mutx->get_text( mutx->u085 )
                                                 iv_icon   = 'sap-icon://delete'
                                                 iv_select = _event( iv_name = mcu->events-delete_root
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).
    ENDIF.
    " **********************************************************************
    " Status ändern
    " **********************************************************************
    "
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_status_change
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_status_change
                                                            ir_base   = ir_base ).

*      DATA(lo_status_group) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
*                                                                          iv_text         = mutx->get_text( mutx->u104 )
*                                                                          iv_has_expander = 'false'
*                                                                          iv_icon         = 'sap-icon://fx' ).

      DATA(lo_chg_status) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = io_navlist
*                                                                       io_parent   = lo_status_group
                                                                       iv_text     = mutx->get_text( mutx->u084 )
                                                                       iv_expanded = 'false'
                                                                       iv_icon     = 'sap-icon://order-status' ).

      lo_strucdescr ?= cl_abap_typedescr=>describe_by_data( ir_base->instance->ms_node_data-status ).

      LOOP AT lo_strucdescr->components ASSIGNING FIELD-SYMBOL(<ls_comp>) WHERE name CP 'ZQ*'.
        ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE ir_base->instance->ms_node_data-status TO FIELD-SYMBOL(<lv_comp>).
        IF <lv_comp> = abap_false.
          CONTINUE.
        ENDIF.

        DATA(ls_vrgng) = VALUE #( lt_activities[ vrgng = <ls_comp>-name ] OPTIONAL ).

        " Ist es eine vom User ausführbare Aktivität?
        IF ls_vrgng IS INITIAL OR ls_vrgng-userset = abap_false.
          CONTINUE.
        ENDIF.

        /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_chg_status
                                                   iv_text   = ls_vrgng-txt
                                                   iv_icon   = ls_vrgng-icon_ui
                                                   iv_select = _event( iv_name = |STATUS_|
                                                                       it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                          ( CONV #( iv_guid ) )
                                                                                          ( CONV #( ls_vrgng-vrgng ) ) ) ) ).
      ENDLOOP.

    ENDIF.

    " *********************************************************************
    " Funktionen
    " *********************************************************************
    DATA(lt_functions) = ir_base->vart_instance->get_functions( ir_base->* ).
    IF lt_functions IS NOT INITIAL.
*      DATA(lo_function_group) = /sct/qp_if_ui_objlist~do_add_navlist_group(
*                                    io_parent       = io_navlist
*                                    iv_text         = mutx->get_text( mutx->u086 )
*                                    iv_has_expander = 'false'
*                                    iv_icon         = 'sap-icon://fx' ).

      DATA(lo_function) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent     = io_navlist
*                                                                     io_parent     = lo_function_group
                                                                     iv_text       = mutx->get_text( mutx->u086 )
                                                                     iv_expanded   = 'false'
                                                                     iv_icon       = 'sap-icon://fx'
                                                                     iv_selectable = 'false' ).

      LOOP AT lt_functions ASSIGNING FIELD-SYMBOL(<ls_functions>).
        /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent     = lo_function
                                                   iv_text       = <ls_functions>-text-text
                                                   iv_icon       = 'sap-icon://technical-object'
                                                   iv_select     = _event( iv_name = <ls_functions>-ucomm
                                                                           it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                              ( CONV #( iv_guid ) ) ) )
                                                   iv_selectable = 'false' " abap_false "xsdbool( <ls_functions>-inactive = abap_false )
*                                                   iv_href       =
*                                                   iv_key        =
        ).
      ENDLOOP.
    ENDIF.

    " *********************************************************************
    " Erweiterte Action z.B. Anlegen mit Relation etc.
    " *********************************************************************

*    DATA(lo_extended_actions) = /sct/qp_if_ui_objlist~do_add_navlist_group(
*                                    io_parent       = io_navlist
*                                    iv_text         = mutx->get_text( mutx->u087 )
*                                    iv_has_expander = 'false'
*                                    iv_icon         = 'sap-icon://detail-more'
**                                    iv_select       =
**                                    iv_href         =
**                                    iv_key          =
*    ).

    " Anlegen einer Verknüpfung
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_relation
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_relation
                                                            ir_base   = ir_base ).
    ENDIF.

*    " Anlegen mit Vorlage
*    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child_template
*                                                              ir_base   = ir_base )
*    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_child_template
*                                                            ir_base   = ir_base ).
*
*      DATA(lt_thier) = mo_cust->get_thier_childs( iv_vart   = ir_base->vart
*                                                  iv_hiera  = ir_base->hinfo
*                                                  iv_action = 'CREATE_CHILD' ).
*      IF lt_thier IS NOT INITIAL.
*        DATA(lo_add_child_template) = /sct/qp_if_ui_objlist~do_add_navlist_item(
*          io_parent   = lo_extended_actions
*          iv_text     = mutx->get_text( mutx->u089 )
*          iv_expanded = 'false'
*          iv_icon     = 'sap-icon://create-form'
**         iv_select   = _event( iv_name = mcu->events-wiz_create_child it_arg = VALUE #( ( CONV #( iv_oguid ) ) ( CONV #( iv_guid ) ) ) ) ).
*        ).
*        LOOP AT lt_thier ASSIGNING FIELD-SYMBOL(<ls_thier>).
*          /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_add_child_template
*                                                     iv_text   = <ls_thier>-vart
**                                                     iv_icon   =
**                                                     iv_select =
**                                                     iv_href   =
**                                                     iv_key    =
*          ).
*        ENDLOOP.
*      ENDIF.
*    ENDIF.

    " Anlegen Position
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_create_child
                                                            ir_base   = ir_base ).

      DATA(lt_thier) = mo_cust->get_thier_childs( iv_vart   = ir_base->vart
                                                  iv_hiera  = ir_base->hinfo
                                                  iv_action = 'CREATE_CHILD' ).
      IF lt_thier IS NOT INITIAL.

        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        DATA(lo_add_child) = /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent   = io_navlist
*                                                                        io_parent   = lo_extended_actions
                                                                        iv_text     = mutx->get_text( mutx->u090 )
                                                                        iv_expanded = 'false'
                                                                        iv_icon     = 'sap-icon://create-form'
                                                                        iv_select   = _event( iv_name = mcu->events-wiz_create_child
                                                                                              it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                                                 ( CONV #( iv_guid ) ) ) ) ).

*        LOOP AT lt_thier ASSIGNING <ls_thier>.
*          do_add_navlist_item( io_parent = lo_add_child
*                               iv_text   = <ls_thier>-vart
**                               iv_icon   =
**                               iv_select =
**                               iv_href   =
**                               iv_key    =
*          ).
*        ENDLOOP.

      ENDIF.
    ENDIF.

    " Sekundärreferenz hinzufügen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_sec_ref
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_sec_ref
                                                            ir_base   = ir_base ).
    ENDIF.
    " Sekundärreferenz entfernen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_sec_del
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_sec_del
                                                            ir_base   = ir_base ).
    ENDIF.
    " Relation löschen
    IF  abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_delete_relat
                                                              ir_base   = ir_base )
    AND abap_true  = mo_ui_handler->is_base_action_allowed( iv_action = mc->action_delete_relat
                                                            ir_base   = ir_base ).
    ENDIF.

*    " *********************************************************************
*    " Sonstige
*    " *********************************************************************
*
*    DATA(lo_misc) = /sct/qp_if_ui_objlist~do_add_navlist_group( io_parent       = io_navlist
*                                                                iv_text         = mutx->get_text( mutx->u091 )
*                                                                iv_has_expander = 'false'
**                                                                iv_icon         =
**                                                                iv_select       =
**                                                                iv_href         =
**                                                                iv_key          =
*    ).
*
*    " Favoriten hinzufügen
*    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_ft_addfav
*                                                             ir_base   = ir_base ).
*      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
*                                                 iv_text   = mutx->get_text( mutx->u092 )
*                                                 iv_icon   = 'sap-icon://add-favorite'
**                                                 iv_select =
**                                                 iv_href   =
**                                                 iv_key    =
*        ).
*    ENDIF.
*
*    " Verwendungsnachweis
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_verna
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u093 )
                                                 iv_icon   = 'sap-icon://split'
                                                 iv_select = _event( iv_name = mcu->events-where_used
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ENDIF.
    "
    " Absprung zum Knoten
    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_jump
                                                             ir_base   = ir_base ).
      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = io_navlist
*                                                 io_parent = lo_misc
                                                 iv_text   = mutx->get_text( mutx->u094 )
                                                 iv_icon   = 'sap-icon://inspect'
                                                 iv_select = _event( iv_name = mcu->events-show_data
                                                                     it_arg  = VALUE #( ( CONV #( iv_oguid ) )
                                                                                        ( CONV #( iv_guid ) ) ) ) ).

    ENDIF.
*
*    " Action Log
*    IF abap_false = /sct/qp_if_ui_objlist~is_fcode_excluded( iv_action = mc->action_create_child
*                                                             ir_base   = ir_base ).
*      /sct/qp_if_ui_objlist~do_add_navlist_item( io_parent = lo_misc
*                                                 iv_text   = mutx->get_text( mutx->u095 )
*                                                 iv_icon   = 'sap-icon://sap-box'
**                                                 iv_select =
**                                                 iv_href   =
**                                                 iv_key    =
*        ).
*    ENDIF.
  ENDMETHOD.


  METHOD get_marker.
    result-type       = mcu->sap-m-objectmarkertype-unsaved.
    result-visibility = 'IconOnly'.
    result-visible    = abap_false.

    IF ir_base IS NOT BOUND OR ir_base->oguid <> ir_base->guid.
      RETURN.
    ENDIF.

    IF ir_base->relattyp IN mc->relattyp_only_original.

      IF ir_base->workmode <> mc->workmode_display.
        IF ir_base->instance->ms_control-is_changed = abap_true.
          result-type       = mcu->sap-m-objectmarkertype-unsaved.
          result-visibility = 'IconAndText'.
          result-visible    = abap_true.
*      result-info = sy-uname.
        ELSE.
          result-type       = mcu->sap-m-objectmarkertype-locked.
          result-visibility = 'IconAndText'.
          result-visible    = abap_true.
        ENDIF.
      ELSE.
        TRY.
            mo_tools->do_enqueue_node( iv_guid = ir_base->guid ).

          CATCH /sct/qp_cx_error INTO DATA(lo_error). " Fehlerhandling im QV-Cockpit
            " Sperre nicht möglich -> bereits gesperrt.
            result-type       = mcu->sap-m-objectmarkertype-lockedby.
            result-visibility = 'IconAndText'.
            result-visible    = abap_true.
            result-info       = lo_error->(lo_error->t100key-attr1).

            RETURN.
        ENDTRY.

        " war nicht geperrt, wieder entsperren
        mo_tools->do_dequeue_node( iv_guid = ir_base->guid ).
      ENDIF.

    ELSE.
      result-type       = mcu->sap-m-objectmarkertype-lockedby.
      result-visibility = 'IconAndText'.
      result-visible    = abap_true.
      result-info       = | relattyp( { ir_base->relattyp } )|.

    ENDIF.
  ENDMETHOD.


  METHOD set_splitter_size.
    IF lines( /sct/qp_if_ui_objlist~mt_object_list ) > 1 AND /sct/qp_if_ui_objlist~mt_object_selected IS NOT INITIAL.
      mv_sel_size = `5rem`. " Bereich für den selektierten Knoten oben anzeigen
    ELSE.
      mv_sel_size = `0rem`. " unsichtbar
    ENDIF.
  ENDMETHOD.
ENDCLASS.
