CLASS /sct/qp_cl_ui_popup_whereused DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/au5_if_app.
    INTERFACES /sct/qp_if_ui_callback.

    TYPES:
      BEGIN OF ty_s_result,
        text            TYPE string,
        check_confirmed TYPE abap_bool,
      END OF ty_s_result.
    TYPES:
**********************************************************************
* Networkgraph
      BEGIN OF ty_attribute,
        label     TYPE string,
        value     TYPE string,
        labelicon TYPE string,
      END OF ty_attribute.
    TYPES tty_attribute TYPE STANDARD TABLE OF ty_attribute WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_node,
        id          TYPE string,
        oguid       TYPE string,
        title       TYPE string,
        status      TYPE string,
        description TYPE string,
        icon        TYPE string,
        src         TYPE string,
        attributes  TYPE tty_attribute,
      END OF ty_node.
    TYPES:
      BEGIN OF ty_line,
        from TYPE string,
        to   TYPE string,
      END OF ty_line.
    TYPES tty_node TYPE STANDARD TABLE OF ty_node WITH DEFAULT KEY.
    TYPES tty_line TYPE STANDARD TABLE OF ty_line WITH DEFAULT KEY.
    TYPES:
      BEGIN OF t_networkgraph_model,
        nodes TYPE tty_node,
        lines TYPE tty_line,
      END OF t_networkgraph_model.

    DATA ms_data TYPE t_networkgraph_model.

    CLASS-METHODS factory IMPORTING i_button_text_cancel TYPE string                       DEFAULT `Cancel`
                                    iv_guid              TYPE /sct/qp_guid
                                    is_node              TYPE /sct/qp_node                 OPTIONAL
                                    is_callback_event    TYPE /sct/au5_if_client=>ty_s_get OPTIONAL " AD, 2026.10.09, changed
                                    i_no_button_cancel   TYPE abap_bool                    OPTIONAL
                          RETURNING VALUE(r_result)      TYPE REF TO /sct/qp_cl_ui_popup_whereused.

  PROTECTED SECTION.
    DATA client                 TYPE REF TO /sct/au5_if_client.
    DATA title                  TYPE string.
    DATA icon                   TYPE string.
    DATA button_text_confirm    TYPE string.
    DATA button_text_cancel     TYPE string.
    DATA check_initialized      TYPE abap_bool.
    DATA check_result_confirmed TYPE abap_bool.
    DATA no_button_confirm      TYPE abap_bool.
    DATA no_button_cancel       TYPE abap_bool.
    DATA mv_guid                TYPE /sct/qp_guid.

    METHODS prepare_sub IMPORTING iv_guid      TYPE /sct/qp_guid
                                  it_tree_data TYPE /sct/qp_t_tree_data
                                  iv_level     TYPE i OPTIONAL.

    METHODS prepare_graph IMPORTING it_tree_data TYPE /sct/qp_t_tree_data.
    METHODS get_list      IMPORTING iv_guid      TYPE /sct/qp_guid.
    METHODS view_display.
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_POPUP_WHEREUSED IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
    me->client ?= client.

    IF check_initialized = abap_false.
      check_initialized = abap_true.
      get_list( mv_guid ).
      view_display( ).
      RETURN.
    ENDIF.

    DATA(ls_get) = client->get( ).
    CASE ls_get-event.
      WHEN `GOTO`.
        client->popup_destroy( ).
        client->nav_app_leave( ).
        /sct/qp_if_ui_callback~ms_callback-s_get = VALUE #( event       = /sct/qp_cl_ui_const=>events-show_data
                                                            t_event_arg = ls_get-t_event_arg ).

      WHEN `UI_POPUP_CONFIRM`.
*        check_result_confirmed = abap_true.
        client->popup_destroy( ).
        client->nav_app_leave( ).
*        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

      WHEN `UI_POPUP_CANCEL`.
        /sct/qp_if_ui_callback~ms_callback-cancelled = abap_true.
*        check_result_confirmed = abap_false.
        client->popup_destroy( ).
        client->nav_app_leave( ).
*        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_callback~get_callback_event.
    " FT20251125
    " Displax Preview Popup : EVENT immer zurückgeben selbst wenn cancelled.
    " damit mittig/rechts sauber refreshed wird.
    "    IF /sct/qp_if_ui_callback~ms_callback-cancelled = abap_false.
    result = /sct/qp_if_ui_callback~ms_callback-s_get.
*    ENDIF.
  ENDMETHOD.


  METHOD factory.
    DATA lo_text TYPE REF TO /sct/qp_cl_ui_textelement.

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = lo_text ).

    r_result = NEW #( ).
    r_result->title = lo_text->get_text( 'TDF' ).
    " 033  Ok
    " 034  Abbrechen
*    IF i_button_text_confirm IS SUPPLIED.
*      r_result->button_text_confirm = i_button_text_confirm.
*    ELSE.
*      r_result->button_text_confirm = lo_text->get_text( lo_text->u033 ).
*    ENDIF.
    IF i_button_text_cancel IS SUPPLIED.
      r_result->button_text_cancel = i_button_text_cancel.
    ELSE.
      r_result->button_text_cancel = lo_text->get_text( lo_text->u034 ).
    ENDIF.
    r_result->mv_guid           = iv_guid.
    r_result->no_button_confirm = abap_true.
    r_result->no_button_cancel  = i_no_button_cancel.
    r_result->/sct/qp_if_ui_callback~ms_callback-s_get = is_callback_event.
  ENDMETHOD.


  METHOD get_list.
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_data = DATA(lo_data) ).
    lo_data->where_used_list( EXPORTING iv_guid   = iv_guid
                                        is_filter = VALUE #(
*                                                             ra_vart = so_vart[]
*                                                             ra_aedat = so_aeda[]
*                                                             ra_aename = so_aena[]
*                                                             ra_erdat = so_erda[]
*                                                             ra_ername = so_erna[]
                                                             direct  = abap_true
*                                                             maxrows = p_data_rows
                                                             via_toe = abap_true )
                              IMPORTING et_tree   = DATA(lt_tree_data) ).

    prepare_graph( lt_tree_data ).
  ENDMETHOD.


  METHOD prepare_graph.
    CLEAR ms_data.
    " Vorsicht, Stufe !
    prepare_sub( iv_guid      = VALUE #( )
                 it_tree_data = it_tree_data ).

*    LOOP AT it_tree_data ASSIGNING FIELD-SYMBOL(<data>).
*      INSERT VALUE #( id          = <data>-guid
*                      oguid       = <data>-oguid
*                      title       = <data>-vname
*                      description = <data>-varttext_o
*
**                      status      = get_status_state( ir_base = lr_base )
**                      icon        = get_ui_icon( ir_base = lr_base )
**                      statusicon  = get_ui_icon( lr_base )
**                      src         = get_ui_icon( lr_base )
*                    ) INTO TABLE ms_data-nodes REFERENCE INTO DATA(lr_node).
*
*      DATA(lv_value) = CONV /sct/qp_value( <data>-vnr ).
*      SHIFT lv_value LEFT DELETING LEADING '0'.
*      IF lv_value IS NOT INITIAL.
*        IF <data>-vvs IS NOT INITIAL.
*          lv_value = |{ lv_value }-{ <data>-vvs }|.
*        ENDIF.
*      ENDIF.
*
*      INSERT VALUE #( label = <data>-relattyp_text
*                      value = lv_value ) INTO TABLE lr_node->attributes.
*
*      IF <data>-relat_guid IS NOT INITIAL.
*        INSERT VALUE #( from = <data>-guid
*                        to   = <data>-relat_guid ) INTO TABLE ms_data-lines.
*      ENDIF.
*
*    ENDLOOP.
  ENDMETHOD.


  METHOD view_display.
    DATA(lo_textelem) = NEW /sct/qp_cl_textelement( ).

    DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( )->dialog( title         = title
                                                                  icon          = icon
                                                                  resizable     = abap_true
                                                                  draggable     = abap_true
                                                                  contentwidth  = `80%`
                                                                  contentheight = `80%`
                                                                  afterclose    = client->_event( 'UI_POPUP_CANCEL' )
                                                                )->content(
                                                                    )->vbox( 'sapUiMediumMargin'
*                                                                          )->html( lv_html

                                 )->network_graph( enablewheelzoom = abap_false
*                                                   orientation     = `TopBottom`
                                                   orientation     = `LeftRight`
*                                                   orientation     = `RightLeft`
                                                   nodes           = client->_bind( ms_data-nodes  )
                                                   lines           = client->_bind( ms_data-lines )
                                                   layout          = `Layered`
                                                   searchsuggest   = `suggest`
                                                   search          = `search`
                                                   id              = `graph`
                                   )->get( )->layout_algorithm( )->layered_layout( mergeedges    = abap_true
*                                                                                   nodeplacement = `Simple`
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
*                                           width                 = `150`
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
*                                                            press    = ms_control-client->_event( val = `DETAIL` t_arg = VALUE #( ( `${$source>/id}` )
*                                                                                                                              ( `${ID}` )
                                                            press    = client->_event( val   = 'GOTO'
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
*                                                   press            = ms_control-client->_event( `LINE_PRESS` )

                                                               )->get_parent( )->get_parent(

                                                                )->get_parent( )->get_parent( )->get_parent(
                                                                )->buttons(
                                                                     )->button( text    = button_text_cancel
                                                                                visible = xsdbool( no_button_cancel = abap_false )
                                                                                press   = client->_event( 'UI_POPUP_CANCEL' )
                                                                     )->button( text    = button_text_confirm
                                                                                visible = xsdbool( no_button_confirm = abap_false )
                                                                                press   = client->_event( 'UI_POPUP_CONFIRM' )
                                                                                type    = 'Emphasized' ).

    client->popup_display( popup->stringify( ) ).
  ENDMETHOD.


  METHOD prepare_sub.
    IF iv_level >= 2.
      RETURN.
    ENDIF.
    LOOP AT it_tree_data ASSIGNING FIELD-SYMBOL(<data>) WHERE relat_guid = iv_guid.
      INSERT VALUE #( id          = <data>-guid
                      oguid       = <data>-oguid
                      title       = <data>-vname
                      description = <data>-varttext_o

*                      status      = get_status_state( ir_base = lr_base )
*                      icon        = get_ui_icon( ir_base = lr_base )
*                      statusicon  = get_ui_icon( lr_base )
*                      src         = get_ui_icon( lr_base )
                    ) INTO TABLE ms_data-nodes REFERENCE INTO DATA(lr_node).

      DATA(lv_value) = CONV /sct/qp_value( <data>-vnr ).
      SHIFT lv_value LEFT DELETING LEADING '0'.
      IF lv_value IS NOT INITIAL.
        IF <data>-vvs IS NOT INITIAL.
          lv_value = |{ lv_value }-{ <data>-vvs }|.
        ENDIF.
      ENDIF.

      INSERT VALUE #( label = <data>-relattyp_text
                      value = lv_value ) INTO TABLE lr_node->attributes.

      IF <data>-relat_guid IS NOT INITIAL.
*        INSERT VALUE #( from = <data>-guid
*                        to   = <data>-relat_guid ) INTO TABLE ms_data-lines.
        INSERT VALUE #( from = <data>-relat_guid
                        to   = <data>-guid ) INTO TABLE ms_data-lines.
      ENDIF.

      prepare_sub( it_tree_data = it_tree_data
                   iv_guid      = <data>-guid
                   iv_level     = iv_level + 1 ).

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
