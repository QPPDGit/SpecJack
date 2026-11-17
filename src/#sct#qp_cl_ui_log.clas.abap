CLASS /sct/qp_cl_ui_log DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS mc_event_popover       TYPE string VALUE 'POPOVER' ##NO_TEXT.
    CONSTANTS mc_event_popover_close TYPE string VALUE 'POPOVER_CLOSE' ##NO_TEXT.

    TYPES:
      BEGIN OF ty_msg,
        type        TYPE string,
        title       TYPE string,
        subtitle    TYPE string,
        description TYPE string,
        group       TYPE string,
      END OF ty_msg.
    TYPES tty_msg TYPE STANDARD TABLE OF ty_msg WITH DEFAULT KEY.

    DATA mv_button_type TYPE string.
    DATA mv_cnt         TYPE i.
    DATA mt_msg         TYPE tty_msg.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.

  PROTECTED SECTION.
    DATA mo_log            TYPE REF TO /sct/qp_cl_log.

    DATA mv_popover_active TYPE abap_bool.

    METHODS display_popover.
    METHODS do_show_data.

    METHODS get_msg_type IMPORTING iv_msgty      TYPE msgty
                         RETURNING VALUE(result) TYPE string.

    METHODS get_log.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_LOG IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control ).
    mo_log ?= ms_obj-object.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-client      = io_client.
    ms_control-parent_view = io_view.
    get_log( ).
    do_show_data( ).
  ENDMETHOD.


  METHOD constructor.
    super->constructor( is_obj ).
    ms_node_object-objekttyp = is_obj-objekttyp.
  ENDMETHOD.


  METHOD display_popover.
    DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( ).
*    _bind( iv_fieldname = |mt_msg| ).

*    popup->message_popover( items             = _bind( ir_data = REF #( mt_msg ) )
    popup->message_popover( items             = ms_control-client->_bind( mt_msg )
                            groupitems        = abap_true
                            placement         = `Top`
                            initiallyexpanded = abap_true
                            beforeclose       = _event( mc_event_popover_close )
*                            afterclose        = _event( mc_event_popover_close )
        )->message_item( type        = `{TYPE}`
                         title       = `{TITLE}`
                         subtitle    = `{SUBTITLE}`
                         description = `{DESCRIPTION}`
                         groupname   = `{GROUP}` ).

    ms_control-root_app->popover_open( iv_close_event = mc_event_popover_close ).

    ms_control-client->popover_display( xml   = popup->stringify( )
                                        by_id = 'Log' ).
  ENDMETHOD.


  METHOD do_show_data.
    IF is_stateful( ).

      ms_control-parent_view->button( id    = 'Log'
                                      type  = ms_control-client->_bind( mv_button_type )
                                      text  = |Log ({ ms_control-client->_bind( mv_cnt ) })|
                                      press = _event( mc_event_popover ) ).

    ELSE.
      ms_control-parent_view->button( id    = 'Log'
                                      type  = mv_button_type
                                      text  = |Log ({ mv_cnt })|
                                      press = _event( mc_event_popover ) ).
    ENDIF.
  ENDMETHOD.


  METHOD get_log.
    CLEAR mt_msg.
    IF mo_log IS NOT BOUND.
      RETURN.
    ENDIF.

    mo_log->get_messages_count( IMPORTING e_priority_veryhigh = DATA(lv_veryhigh)
                                          e_priority_high     = DATA(lv_high)
                                          e_priority_medium   = DATA(lv_medium)
                                          e_priority_none     = DATA(lv_none) ).

    IF lv_veryhigh > 0.
      mv_cnt = lv_veryhigh.
      mv_button_type = 'Negative'.
    ELSEIF lv_high > 0.
      mv_cnt = lv_high.
      mv_button_type = 'Negative'.
    ELSEIF lv_medium > 0.
      mv_cnt = lv_medium.
      mv_button_type = 'Attention'.
    ELSEIF lv_none > 0.
      mv_cnt = lv_none.
      mv_button_type = 'Neutral'.
    ELSE.
      mv_cnt = 0.
      mv_button_type = 'Ghost'.
    ENDIF.

    LOOP AT mo_log->get_messages( ) ASSIGNING FIELD-SYMBOL(<log>).

      IF <log>-message IS INITIAL.
        <log>-message = mo_tools->get_msg_from_msgv( iv_id     = <log>-msgid
                                                     iv_number = <log>-msgno
                                                     iv_msgv1  = <log>-msgv1
                                                     iv_msgv2  = <log>-msgv2
                                                     iv_msgv3  = <log>-msgv3
                                                     iv_msgv4  = <log>-msgv4 ).

      ENDIF.

      mo_cust->get_tobjtyp( EXPORTING iv_objekttyp = <log>-objekttyp                  " Objekttyp
                            IMPORTING es_tobjtyp   = DATA(ls_obj) ). " Objekttypen mit Kurztext
      INSERT VALUE #( type  = get_msg_type( <log>-msgty )
                      title = <log>-message
*                      subtitle = 'SubTitle'
*                      description =
                      group = ls_obj-objekttyptext )
             INTO TABLE mt_msg.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_msg_type.
    CASE iv_msgty.
      WHEN mc->msgtype_a.
        result = mcu->sap-ui-core-message-MessageType-error.
      WHEN mc->msgtype_e.
        result = mcu->sap-ui-core-message-MessageType-error.
      WHEN mc->msgtype_w.
        result = mcu->sap-ui-core-message-MessageType-warning.
      WHEN mc->msgtype_i.
        result = mcu->sap-ui-core-message-MessageType-information.
      WHEN mc->msgtype_s.
        result = mcu->sap-ui-core-message-MessageType-success.
    ENDCASE.
  ENDMETHOD.


  METHOD process_fcode_self.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    IF is_event_relevant( is_get ) = abap_false.
      RETURN.
    ENDIF.
    rv_processed = abap_true.
    get_log( ).
    IF is_get-event = mc_event_popover.
      display_popover( ).
    ENDIF.
* Close event im ROOT-App
*    IF is_get-event = mc_event_popover_close.
**      mv_popover_active = abap_false.
*      ms_control-client->popover_destroy( ).
**      ms_control-root_app->popover_close( ).
*    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    get_log( ).
    _bind( iv_fieldname = |mv_button_type| ).
    _bind( iv_fieldname = |mv_cnt| ).
    _bind( iv_fieldname = |mt_msg| ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.
ENDCLASS.
