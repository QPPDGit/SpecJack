CLASS /sct/qp_cl_ui_tree_mt DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/au5_if_app.
    INTERFACES if_serializable_object.
    INTERFACES /sct/qp_if_ui_tree_mt.

    ALIASES init          FOR /sct/qp_if_ui_app~init.
    ALIASES process_fcode FOR /sct/qp_if_ui_app~process_fcode.

    TYPES: BEGIN OF ty_tree,
             selected TYPE abap_bool,
             visible  TYPE abap_bool,
             oguid    TYPE /sct/qp_guid,
             pguid    TYPE /sct/qp_guid,
             guid     TYPE /sct/qp_guid,
             vname    TYPE string,
             istat    TYPE string,
             descr    TYPE string,
           END OF ty_tree.

    TYPES tty_tree TYPE STANDARD TABLE OF ty_tree WITH DEFAULT KEY.

    DATA mt_tree  TYPE /sct/qp_if_ui_tree_mt=>ty_t_tree1.
    DATA mt_tree2 TYPE tty_tree.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~display REDEFINITION.
    METHODS /sct/qp_if_ui_app~init    REDEFINITION.

  PROTECTED SECTION.
    METHODS do_show_data.
    METHODS do_build_tree      IMPORTING it_guid TYPE /sct/qp_t_guid.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_TREE_MT IMPLEMENTATION.


  METHOD do_build_tree.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.16, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    LOOP AT it_guid ASSIGNING FIELD-SYMBOL(<ls_guid>).

      IF sy-tabix = 1.
        DATA(lv_expanded) = abap_true.
      ELSE.
        lv_expanded = abap_false.
      ENDIF.

* Hierarchie + Detailinfo des Roots einlesen
*      DATA(lr_base_root) =
      mo_ui_handler->get_hierarchy( EXPORTING iv_guid     = <ls_guid>-guid
                                              iv_oguid    = <ls_guid>-guid
                                              iv_stateful = is_stateful( )
                                    IMPORTING et_base     = DATA(lt_base)
                                    RECEIVING rr_base     = DATA(lr_base_root) ).

      IF lr_base_root IS INITIAL.
        CONTINUE.
      ELSE.
        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        ASSIGN lr_base_root->* TO FIELD-SYMBOL(<root>).
      ENDIF.

      LOOP AT lt_base INTO DATA(lr_base).
        IF lr_base->guid = lr_base->root_guid.
          DATA(lv_visible) = abap_true.
        ELSE.
          lv_visible = lv_expanded.
        ENDIF.

        INSERT VALUE #( visible = lv_visible
                        oguid   = lr_base->oguid
                        pguid   = lr_base->parent_guid
                        guid    = lr_base->guid
                        vname   = get_node_objtext( ir_base = lr_base )
                        istat   = get_status_text( ir_base = lr_base )
                        descr   = VALUE #( lr_base->instance->ms_node_data-nodet[ 1 ]-vtext OPTIONAL ) )

               INTO TABLE mt_tree2.

      ENDLOOP.
    ENDLOOP.
*
*      INSERT CORRESPONDING #( <root>-instance->ms_node_data ) INTO TABLE mt_tree ASSIGNING FIELD-SYMBOL(<t0>).
*      <t0>-descr = <root>-instance->ms_node_data-nodet[ 1 ]-vtext.
*      <t0>-istat = <root>-instance->ms_node_data-status-istat.
*      <t0>-key   = <root>-key.
*      <t0>-oguid = <root>-oguid.
*      <t0>-guid  = <root>-guid.
*      LOOP AT lt_base "USING KEY parent_key_pos
*        ASSIGNING FIELD-SYMBOL(<c1>)
*           WHERE table_line->parent_key = <root>-key.
*        INSERT CORRESPONDING #( <c1>->instance->ms_node_data ) INTO TABLE <t0>-nodes ASSIGNING FIELD-SYMBOL(<t1>).
*        <t1>-descr = <c1>->instance->ms_node_data-nodet[ 1 ]-vtext.
*        <t1>-istat = <c1>->instance->ms_node_data-status-istat.
*        <t1>-key   = <c1>->key.
*        <t1>-oguid = <c1>->oguid.
*        <t1>-guid  = <c1>->guid.
*
*        LOOP AT lt_base "USING KEY parent_key_pos
*           ASSIGNING FIELD-SYMBOL(<c2>)
*             WHERE table_line->parent_key = <c1>->key.
*          INSERT CORRESPONDING #( <c2>->instance->ms_node_data ) INTO TABLE <t1>-nodes ASSIGNING FIELD-SYMBOL(<t2>).
*          <t2>-descr = <c2>->instance->ms_node_data-nodet[ 1 ]-vtext.
*          <t2>-istat = <c2>->instance->ms_node_data-status-istat.
*          <t2>-key   = <c2>->key.
*          <t2>-oguid = <c2>->oguid.
*          <t2>-guid  = <c2>->guid.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.

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

    CASE is_get-event.
      WHEN mcu->events-nav_list_clear.

        CLEAR mt_tree.

        mo_bus->free( ).
        rv_processed = abap_true.

      WHEN mcu->events-nav_list_build.
        DATA lt_guid TYPE /sct/qp_t_guid.

        LOOP AT is_get-t_event_arg ASSIGNING FIELD-SYMBOL(<ls_event>).
          INSERT VALUE #( guid = CONV bel_guid( <ls_event> ) ) INTO TABLE lt_guid.
        ENDLOOP.

        do_build_tree( it_guid = lt_guid ).
        rv_processed = abap_true.
    ENDCASE.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.25, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->/sct/qp_if_ui_app~init( is_control = is_control ).

*    do_build_tree_fcat( ).
  ENDMETHOD.


  METHOD constructor.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.11, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

    mt_def_arg = VALUE #( ( `${OGUID}` )
                          ( `${GUID}` ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.
    do_show_data( ).
  ENDMETHOD.


  METHOD do_show_data.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.17, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

* FT20261110 Muss übrarbeitet werden ( neue BIND syntax )

*
*    ms_control-parent_view->tree_table( id               = 'treeTable'
*                                        rows             = |\{path:'{ _bind( iv_edit = abap_true
*                                                                             ir_data = REF #( mt_tree2 )
*                                                                             iv_name = 'TREE_MT'
*                                                                             iv_path = abap_true ) }', parameters: \{arrayNames:['NODES']\}\}|
*                                        toggleopenstate  = `saveState()`
*                                        fixedrowcount    = 'false'
*                                        minautorowcount  = 'true'
**                                        width            = '50rem'
*                                        expandfirstlevel = 'true'
**                          )->drag_drop_config(
**                            )->drag_info( sourceaggregation = `items`
**                                )->grid_drop_info( targetaggregation = `items`
**                                        dropposition     = `Between`
**                                        droplayout       = `Horizontal`
**                                        drop             = io_client->_event(
**                                        val              = 'onDrop'
**                                        t_arg            = VALUE #( ( `${$parameters>/draggedControl/oParent}.indexOfItem(${$parameters>/draggedControl})` )
**                                                                    ( `${$parameters>/droppedControl/oParent}.indexOfItem(${$parameters>/droppedControl})` )
**                                                                    ( `${$parameters>/dropPosition}` ) ) ) )->get_parent( )->get_parent( )->get_parent(
*                              )->tree_columns(
*                                )->tree_column( label = 'Knoten'  " width = '40%'
*                                    )->tree_template(
*                                    )->text( text     = '{VNAME}'
*                                             wrapping = abap_false
**                                             width    = '50px'
*                                )->get_parent( )->get_parent(
*                                )->tree_column( label = 'Status' " width = '20%'
*                                    )->tree_template(
*                                    )->text( text = '{ISTAT}'
**                                             width = '20px'
*                                )->get_parent( )->get_parent(
*                                )->tree_column( label = '' " width = '20%'
*                                    )->tree_template(
*                                    )->icon( src   = 'sap-icon://process'
*                                             color = 'green'
**                                             width = '30px'
*                                             press = _event( iv_name = mcu->events-show_data )
*                                )->get_parent( )->get_parent(
*                                )->tree_column( label = mutx->get_text( mutx->u041 ) " Beschreibung
*                                    )->tree_template(
*                                    )->text( text = '{DESCR}'
*                                )->get_parent( )->get_parent( ).


  ENDMETHOD.
ENDCLASS.
