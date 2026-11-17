CLASS /sct/qp_cl_ui_hiera DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Networkgraph
    TYPES: BEGIN OF ty_attribute,
             label     TYPE string,
             value     TYPE string,
             labelicon TYPE string,
           END OF ty_attribute.
    TYPES tty_attribute TYPE STANDARD TABLE OF ty_attribute WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_node,
             id          TYPE string,
             oguid       TYPE string,
             title       TYPE string,
             status      TYPE string,
             description TYPE string,
             icon        TYPE string,
             src         TYPE string,
             attributes  TYPE tty_attribute,
           END OF ty_node.
    TYPES: BEGIN OF ty_line,
             from TYPE string,
             to   TYPE string,
           END OF ty_line.
    TYPES tty_node TYPE STANDARD TABLE OF ty_node WITH DEFAULT KEY.
    TYPES tty_line TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    TYPES: BEGIN OF t_networkgraph_model,
             nodes TYPE tty_node,
             lines TYPE tty_line,
           END OF t_networkgraph_model.

    DATA ms_data TYPE t_networkgraph_model.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.

  PROTECTED SECTION.
    METHODS get_data.

    METHODS get_sub_data IMPORTING is_child TYPE /sct/qp_s_childs.

    METHODS get_pf_status_state IMPORTING iv_istat      TYPE /sct/qp_istat             OPTIONAL
                                          io_instance   TYPE REF TO /sct/qp_if_nodetyp OPTIONAL
      PREFERRED PARAMETER io_instance
                                RETURNING VALUE(result) TYPE string.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_HIERA IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    get_data( ).
    _bind( iv_fieldname = |ms_data-nodes| ).
    _bind( iv_fieldname = |ms_data-lines| ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.

    DATA(lo_textelem) = NEW /sct/qp_cl_textelement( ).

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(graph) = ms_control-parent_view->network_graph( enablewheelzoom = abap_false
*                                                         orientation     = `TopBottom`
                                                         orientation     = `LeftRight`
                                                         nodes           = ms_control-client->_bind( ms_data-nodes )
                                                         lines           = ms_control-client->_bind( ms_data-lines )
*                                                         layout          = `Layered`
                                                         searchsuggest   = `suggest`
                                                         search          = `search`
                                                         id              = `graph`
                                     )->get( )->layout_algorithm( )->layered_layout( mergeedges    = abap_true
*                                                                                     nodeplacement = `Simple`
                                                                                     nodeplacement = `LinearSegment`
                                                                                     nodespacing   = `30`
                                     )->get_parent(
                                     )->get_parent(
                                  )->nodes( ns = `networkgraph`
                                    )->node( " icon                  = `{ICON}` "sap-icon://action-settings`
                                             key                   = `{ID}`
                                             description           = `{DESCRIPTION}`
                                             title                 = `{TITLE}`
                                             titlelinesize         = `2`
*                                             width                 = `150`
                                             maxwidth              = `250`
                                             collapsed             = `{COLLAPSED}`
                                             attributes            = `{ATTRIBUTES}`
                                             statusicon            = `{ICON}`
                                             showactionlinksbutton = abap_false
                                             showdetailbutton      = abap_false
                                             descriptionlinesize   = `0`
                                             shape                 = `Box`
                                             status                = `{STATUS}`
*                                            )->get( )->custom_data( ns = `networkgraph` )->core_custom_data( key = `supervisor` value = `{SUPERVISOR}`
*                                                                                        )->core_custom_data( key = `team` value = `{TEAM}`
*                                                                                        )->core_custom_data( key = `location` value = `{LOCATION}`
*                                                                                        )->core_custom_data( key = `position` value = `{POSITION}`
*                                                                                        )->core_custom_data( key = `team` value = `{TEAM}`
*                                                                                        )->core_custom_data( key = `email` value = `{EMAIL}`
*                                                                                        )->core_custom_data( key = `phone` value = `{PHONE}`
*                                           )->get_parent(
*                                           )->get( )->get_parent( )->get_parent( )->attributes( ns = `networkgraph`
                                           )->get( )->attributes( ns = `networkgraph`
                                            )->element_attribute( label = `{LABEL}`
                                                                  value = `{VALUE}`
                                                                  icon  = `{LABELICON}`
                                           )->get_parent(
                                           )->get_parent(
                                           )->get( )->get_parent( )->get_parent( )->action_buttons(
                                            )->action_button( " id = `{ID}`
                                                              position = `Right`
                                                              title    = lo_textelem->get_text( 'TAY' )
                                                              icon     = `sap-icon://arrow-right`
*                                                              press    = ms_control-client->_event( val = `DETAIL` t_arg = VALUE #( ( `${$source>/id}` )
*                                                                                                                              ( `${ID}` )
                                                              press    = ms_control-client->_event( val   = mcu->events-show_data
                                                                                                    t_arg = VALUE #( ( `${OGUID}` )
                                                                                                                     ( `${ID}` ) ) )
                                           )->get_parent(
                                           )->get_parent(
                                           )->get( )->get_parent( )->get_parent( )->_generic( ns   = `networkgraph`
                                                                                              name = `image`
                                            )->node_image( src    = `{SRC}`
                                                           width  = `80`
                                                           height = `80`
                                                          )->get_parent(
                                                       )->get_parent(
                                                )->get_parent(
                                          )->get_parent(
                                          )->lines(
                                            )->line( from             = `{FROM}`
                                                     to               = `{TO}`
                                                     arroworientation = `None`
*                                                     press            = ms_control-client->_event( `LINE_PRESS` )
                                                     ).
  ENDMETHOD.


  METHOD get_data.
    IF ms_control-base IS NOT BOUND.
      ms_control-base = ms_obj-base.
    ENDIF.
    IF ms_control-base IS NOT BOUND.
      RETURN.
    ENDIF.
    CLEAR ms_data.

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

* Vorsicht Stufe !
*    get_data_sub( io_instance = ms_control-base->instance ). "Process_flow
    get_sub_data( is_child = VALUE #( cguid = ms_control-base->guid
                                      node  = ms_control-base->instance ) ).
  ENDMETHOD.


  METHOD get_pf_status_state.
    IF io_instance IS BOUND.
      DATA(lv_istat) = io_instance->ms_node_data-status-istat.
    ELSEIF iv_istat IS NOT INITIAL.
      lv_istat = iv_istat.
    ELSEIF ms_control-base IS NOT INITIAL AND ms_control-base->instance IS NOT INITIAL.
      lv_istat = ms_control-base->instance->ms_node_data-status-istat.
    ENDIF.
    IF lv_istat IS INITIAL.
      result = mcu->sap-ui-core-message-MessageType-none. "  'None'. " Keine Farbe
      RETURN.
    ENDIF.

    CASE lv_istat.
      WHEN 'IZQOK'
        OR 'IZQFR'.
        result = 'Positive'. " Grün
      WHEN 'IZQWA'.
        result = 'Neutral'.
      WHEN 'IZQXX'
        OR 'IZQCN'
        OR 'IZQTD'.
        result = 'Negative'. " Rot
      WHEN 'IZQSP'
        OR 'IZQLO'
        OR 'IZQAL'
        OR 'IZQDN'.
        result = 'Neutral'.
      WHEN OTHERS.
        result = 'Neutral'. " Keine Farbe
    ENDCASE.
  ENDMETHOD.


  METHOD get_sub_data.
    DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = is_child-cguid
                                             iv_oguid    = ms_control-base->root_guid
                                             iv_stateful = /sct/qp_if_ui_app~is_stateful( ) ).

    IF lr_base IS NOT BOUND.
      RETURN.
    ENDIF.

    IF lr_base->instance->ms_node_data-vname IS NOT INITIAL.
      DATA(lv_name) = |{ lr_base->instance->ms_node_data-vname } |.
    ELSE.
      lv_name = get_node_vnr( lr_base ).
    ENDIF.

    INSERT VALUE #( id          = is_child-cguid
                    oguid       = lr_base->root_guid
                    title       = lv_name
                    description = get_vart_vtyp_text( lr_base )
                    status      = get_status_state( ir_base = lr_base )
                    icon        = get_ui_icon( ir_base = lr_base )
*                    statusicon  = get_ui_icon( lr_base )
*                    src         = get_ui_icon( lr_base )
                  ) INTO TABLE ms_data-nodes REFERENCE INTO DATA(lr_node).

    DATA(lv_vnrvvs) = get_node_vnr( ir_base = lr_base ).
    IF lv_vnrvvs CO ' -'.
      CLEAR lv_vnrvvs.
    ENDIF.

    " Eine Zeile für:
    " -Links  : statusicon + Statustext
    " -Rechts :  VNR/VVS
    INSERT VALUE #( labelicon = get_status_icon( ir_base = lr_base )
                    label     = get_status_text( ir_base = lr_base )
                    value     = lv_vnrvvs ) INTO TABLE lr_node->attributes.

    IF is_child-pguid IS NOT INITIAL.
      INSERT VALUE #( from = is_child-pguid
                      to   = is_child-cguid ) INTO TABLE ms_data-lines.
    ENDIF.

    LOOP AT is_child-node->mt_childs ASSIGNING FIELD-SYMBOL(<child>).
      get_sub_data( is_child = <child> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD process_fcode_self.
*    IF is_get-event = 'NODE_PRESS' OR is_get-event = 'LBL_PRESS' OR is_get-event = 'HEAD_PRESS'.
*      DATA(lt_arg) = is_get-t_event_arg.
*      DELETE lt_arg FROM 2.
*      INSERT is_get-t_event_arg[ 4 ] INTO TABLE lt_arg.
*
*      ms_control-root_app->set_next_event( is_event = VALUE #( event = mcu->events-show_data t_event_arg = lt_arg ) ).
*
*    ENDIF.
  ENDMETHOD.
ENDCLASS.
