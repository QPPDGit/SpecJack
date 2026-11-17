CLASS /sct/qp_cl_ui_tree_navlist DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_tree_mt.

    ALIASES init          FOR /sct/qp_if_ui_app~init.
    ALIASES process_fcode FOR /sct/qp_if_ui_app~process_fcode.

    DATA mt_tree TYPE /sct/qp_if_ui_tree_mt=>ty_t_tree1.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~init REDEFINITION.

  PROTECTED SECTION.

    METHODS do_build_tree_fcat.
    METHODS do_build_tree      IMPORTING it_guid TYPE /sct/qp_t_guid.

    METHODS process_fcode_self REDEFINITION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_TREE_NAVLIST IMPLEMENTATION.


  METHOD do_build_tree.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.16, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

*    " TODO: variable is assigned but never used (ABAP cleaner)
*    DATA(lv_clear_vvs) = abap_false.
*
*    CLEAR mt_tree.
*
*    mo_ui_handler->get_object( EXPORTING it_guid     = CORRESPONDING #( it_guid MAPPING low = guid )
*                               IMPORTING et_base_all = DATA(lt_base) ).
*
*    LOOP AT lt_base ASSIGNING FIELD-SYMBOL(<root>)
*         WHERE relattyp IS INITIAL.
*      IF <root>-key <> <root>-guid.
*        CONTINUE.
*      ENDIF.
*
*      IF line_exists( mt_tree[ key = <root>-key ] ).
*        CONTINUE.
*      ENDIF.
*
*      INSERT CORRESPONDING #( <root>-instance->ms_node_data ) INTO TABLE mt_tree ASSIGNING FIELD-SYMBOL(<t0>).
*      <t0>-descr = <root>-instance->ms_node_data-nodet[ 1 ]-vtext.
*      <t0>-istat = <root>-instance->ms_node_data-status-istat.
*      <t0>-key   = <root>-key.
*      <t0>-oguid = <root>-oguid.
*      <t0>-guid  = <root>-guid.
*      LOOP AT lt_base USING KEY parent_key_pos ASSIGNING FIELD-SYMBOL(<c1>)
*           WHERE parent_key = <root>-key.
*        INSERT CORRESPONDING #( <c1>-instance->ms_node_data ) INTO TABLE <t0>-nodes ASSIGNING FIELD-SYMBOL(<t1>).
*        <t1>-descr = <c1>-instance->ms_node_data-nodet[ 1 ]-vtext.
*        <t1>-istat = <c1>-instance->ms_node_data-status-istat.
*        <t1>-key   = <c1>-key.
*        <t1>-oguid = <c1>-oguid.
*        <t1>-guid  = <c1>-guid.
*        LOOP AT lt_base USING KEY parent_key_pos ASSIGNING FIELD-SYMBOL(<c2>)
*             WHERE parent_key = <c1>-key.
*          INSERT CORRESPONDING #( <c2>-instance->ms_node_data ) INTO TABLE <t1>-nodes ASSIGNING FIELD-SYMBOL(<t2>).
*          <t2>-descr = <c2>-instance->ms_node_data-nodet[ 1 ]-vtext.
*          <t2>-istat = <c2>-instance->ms_node_data-status-istat.
*          <t2>-key   = <c2>-key.
*          <t2>-oguid = <c2>-oguid.
*          <t2>-guid  = <c2>-guid.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
  ENDMETHOD.


  METHOD process_fcode_self.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"
*
*    CASE is_get-event.
*      WHEN mcu->events-mt_clear_tree.
*
*        CLEAR mt_tree.
*
*        mo_bus->free( ).
*
*      WHEN mcu->events-mt_build_tree.
*        DATA lt_guid TYPE /sct/qp_t_guid.
*
*        LOOP AT is_get-t_event_arg ASSIGNING FIELD-SYMBOL(<ls_event>).
*          DATA lv_char32 TYPE char32.
*          WRITE <ls_event> TO lv_char32.
*          INSERT VALUE #( guid = lv_char32 ) INTO TABLE lt_guid.
*        ENDLOOP.
*
*        do_build_tree( it_guid = lt_guid ).
*    ENDCASE.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.25, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->/sct/qp_if_ui_app~init( is_control = is_control ).

    do_build_tree_fcat( ).
  ENDMETHOD.


  METHOD constructor.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.11, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler  ).
  ENDMETHOD.


  METHOD do_build_tree_fcat.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.17, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " **    DATA(lo_navlist) = ms_control-parent_view->navigation_list( ).
    " **    lo_navlist->navigation_list_item( text = '1'
    " **                                      key  = '1' ).
    " **    lo_navlist->navigation_list_item( text = '2'
    " **                                      key  = '2' ).
    " **    DATA(lo_navlist3) = lo_navlist->navigation_list_item( text = '3'
    " **                                                          key  = '3' ).
    " **
    " **    lo_navlist3->navigation_list_item( text = '3.1'
    " **                                       key  = '3.1' ).
    " **
    " **    lo_navlist3->navigation_list_item( text = '3.2'
    " **                                       key  = '3.2' ).
    " **
    " **    lo_navlist3->navigation_list_item( text = '3.3'
    " **                                       key  = '3.3  ' ).
*    DATA(lo_menu) = ms_control-parent_view->menu_button( text       = '1'
*                                                         buttonmode = 'split'
*                                                         " defaultaction = 'true'
*                                                         " enabled       = 'true'
*                                                         " activeicon    = 'sap-icon://edit'
*                                                          )->_generic( 'Menu' ). "->_generic( `Menu` ).

    DATA(lo_item_selected) = ms_control-parent_view->_generic( name   = 'MenuButton'
                                                               t_prop = VALUE #( ( n = 'text'
                                                                                   v = 'MENU' )
                                                                                 ( n = 'buttonMode'
                                                                                   v = 'Split' )
                                                                                 ( n = 'useDefaultActionOnly'
                                                                                   v = 'true' )  )
                        )->_generic( name = 'menu'
                        )->_generic( name   = 'Menu'
                                     t_prop = VALUE #( ( n = 'itemSelected'
                                                         v = 'onMenuAction' )  ) ).

    lo_item_selected->_generic( name   = 'MenuItem'
                                t_prop = VALUE #( ( n = 'text'
                                                    v = 'A' )
                                                  ( n = 'icon'
                                                    v = 'sap-icon://chalkboard' )  )
    )->_generic( name = 'items'
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'A Ebene 2' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  )
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'A 3' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  )
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'A 4' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  ) ).

    lo_item_selected->_generic( name   = 'MenuItem'
                                t_prop = VALUE #( ( n = 'text'
                                                    v = 'B' )
                                                  ( n = 'icon'
                                                    v = 'sap-icon://chalkboard' )  )
    )->_generic( name = 'items'
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'B 2' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  )
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'B 3' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  )
    )->_generic( name   = 'MenuItem'
                 t_prop = VALUE #( ( n = 'text'
                                     v = 'B 4' )
                                   ( n = 'icon'
                                     v = 'sap-icon://chalkboard' )  ) ).

    " lo_menu_01->_generic( name = 'items' )->menu_item( text = 'MENU_01-01'  )->get_parent(  ).

*    lo_menu->menu_item( text = 'MENU_02'
*    )->menu_item( text = 'MENU_03'
*    )->menu_item( text = 'MENU_04'   ).

*    lo_menu->menu_item( text = '1.1' ).
*    lo_menu->get_parent(  ).

**    ms_control-parent_view->tree_table( id               = 'treeTable'
**                                        rows             = |\{path:'{ ms_control-client->_bind_edit_ref( ir_data = REF #( mt_tree )
**                                                                                                         path    = abap_true ) }', parameters: \{arrayNames:['NODES']\}\}|
**                                        toggleopenstate  = `saveState()`
**                                        fixedrowcount    = 'false'
**                                        minautorowcount  = 'true'
***                                        width            = '50rem'
**                                        expandfirstlevel = 'true'
***                          )->drag_drop_config(
***                            )->drag_info( sourceaggregation = `items`
***                                )->grid_drop_info( targetaggregation = `items`
***                                        dropposition     = `Between`
***                                        droplayout       = `Horizontal`
***                                        drop             = io_client->_event(
***                                        val              = 'onDrop'
***                                        t_arg            = VALUE #( ( `${$parameters>/draggedControl/oParent}.indexOfItem(${$parameters>/draggedControl})` )
***                                                                    ( `${$parameters>/droppedControl/oParent}.indexOfItem(${$parameters>/droppedControl})` )
***                                                                    ( `${$parameters>/dropPosition}` ) ) ) )->get_parent( )->get_parent( )->get_parent(
**                              )->tree_columns(
**                                )->tree_column( label = 'Knoten'  " width = '40%'
**                                    )->tree_template(
**                                    )->text( text     = '{VNAME}'
**                                             wrapping = abap_false
***                                             width    = '50px'
**                                )->get_parent( )->get_parent(
**                                )->tree_column( label = 'Status' " width = '20%'
**                                    )->tree_template(
**                                    )->text( text = '{ISTAT}'
***                                             width = '20px'
**                                )->get_parent( )->get_parent(
**                                )->tree_column( label = '' " width = '20%'
**                                    )->tree_template(
**                                    )->icon( src   = 'sap-icon://process'
**                                             color = 'green'
***                                             width = '30px'
**                                             press = ms_control-client->_event( val   = mcu->events-show_data
**                                                                                t_arg = VALUE #( ( `${OGUID}` )
**                                                                                                 ( `${GUID}` ) ) )
**                                )->get_parent( )->get_parent(
**                                )->tree_column( label = 'Beschreibung'
**                                    )->tree_template(
**                                    )->text( text = '{DESCR}'
**                                )->get_parent( )->get_parent( ).

*    DATA(xml) = ms_control-parent_view->stringify( ).

*    io_client->view_display( lo_view->stringify( ) ).
  ENDMETHOD.
ENDCLASS.
