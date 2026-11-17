CLASS /sct/qp_cl_ui_demo_toe DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/au5_if_app.

    DATA:
      BEGIN OF screen,
        check_is_active TYPE abap_bool,
        element         TYPE /sct/qp_element,
        colour          TYPE string,
        combo_key       TYPE string,
        combo_key2      TYPE string,
        segment_key     TYPE string,
        date            TYPE string,
        date_time       TYPE string,
        time_start      TYPE string,
        time_end        TYPE string,
        check_switch_01 TYPE abap_bool       VALUE abap_false,
        check_switch_02 TYPE abap_bool       VALUE abap_false,
      END OF screen.

    TYPES:
      BEGIN OF s_suggestion_items,
        value TYPE string,
        descr TYPE string,
      END OF s_suggestion_items.

    DATA mt_suggestion TYPE STANDARD TABLE OF s_suggestion_items WITH EMPTY KEY.

    TYPES:
      BEGIN OF s_combobox,
        key  TYPE string,
        text TYPE string,
      END OF s_combobox.

    TYPES ty_t_combo TYPE STANDARD TABLE OF s_combobox WITH EMPTY KEY.

    DATA mv_value   TYPE /sct/qp_value.
    DATA mv_element TYPE /sct/qp_element.

  PROTECTED SECTION.
    DATA mo_toe    TYPE REF TO /sct/qp_if_toe.
    DATA mo_client TYPE REF TO /sct/au5_if_client.

    METHODS callback RETURNING VALUE(result)  TYPE /sct/au5_if_client=>ty_s_get. " AD, 2026.10.09, changed
    METHODS do_init.
    METHODS do_display.
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_DEMO_TOE IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
    " client->set_session_stateful( abap_true ).

    mo_client ?= client.  " AD, 2026.10.09, changed

    IF mo_client->check_on_init( ).
      do_init( ).
      do_display( ).
      mo_client->view_model_update( ).
    ENDIF.

    IF mo_client->check_on_navigated( ) = abap_true.
      callback( ).
    ENDIF.

    CASE mo_client->get( )-event.
      WHEN 'SEARCHHELP'.

        /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                          CHANGING  co_instance  = mo_toe ).

        mo_toe->f4_call( is_toe       = VALUE #( element = mv_element
                                                 value   = mv_value )
                         io_ui_client = client
                         is_callback  = VALUE #( s_get-event       = 'F4_BACK'
                                                 s_get-t_event_arg = VALUE #( ( |{ mv_element }| ) ) ) ).

    ENDCASE.
  ENDMETHOD.


  METHOD do_display.
    DATA(lo_view) = /sct/au5_cl_xml_view=>factory( ).
    DATA(lo_page) = lo_view->shell(
        )->page( showheader     = xsdbool( abap_false = mo_client->get( )-check_launchpad_active )
                 title          = 'Demo TOE'
                 navbuttonpress = mo_client->_event( 'BACK' )
                 shownavbutton  = xsdbool( mo_client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL ) ).

    DATA(lo_grid) = lo_page->grid( 'L6 M12 S12'
      )->content( 'layout' ).

    DATA(lo_form) = lo_grid->simple_form( title    = 'Demo TOE'
                                          editable = abap_true ).

    lo_form->label( 'Element'
      )->combobox( selectedkey = mo_client->_bind( screen-combo_key )
                   value       = mo_client->_bind( mv_element )
                   items       = mo_client->_bind( VALUE ty_t_combo( ( key  = 'DEMO_PRODUCT'
                                                                             text = 'DEMO_PRODUCT' )
                                                                           ( key  = 'MATNR'
                                                                             text = 'MATNR' )
                                                                           ( key  = 'QUALITY'
                                                                             text = 'QUALITY' ) ) )
              )->item( key  = '{KEY}'
                       text = '{TEXT}'
      )->get_parent( )->get_parent( ).

    lo_form->content( 'form'
        )->label( 'Value'
        )->input( id               = `VALUE`
                  placeholder      = 'QPPD Value'
                  value            = mo_client->_bind_edit( mv_value )
                  showvaluehelp    = abap_true
                  valuehelprequest = mo_client->_event( val = 'SEARCHHELP' ) ).

    mo_client->view_display( lo_page->stringify( ) ).
  ENDMETHOD.


  METHOD do_init.
*    mv_element = 'DEMO_PRODUCT'.
    mv_element = 'MATNR'.
*    mv_value   = 'Init'.
    screen = VALUE #( check_is_active = abap_true
                      element         = 'DEMO_PRODUCT'
                      colour          = 'BLUE'
                      combo_key       = 'GRAY'
                      segment_key     = 'GREEN'
                      date            = '07.12.22'
                      date_time       = '23.12.2022, 19:27:20'
                      time_start      = '05:24:00'
                      time_end        = '17:23:57' ).

    mt_suggestion = VALUE #( ( descr = 'Produkt'
                               value = 'DAEMO_PRODUCT' )
                             ( descr = 'Material'
                               value = 'MATNR' )
                             ( descr = 'Qualität'
                               value = 'QUALITY' ) ).
  ENDMETHOD.


  METHOD callback.
    TRY.
        DATA(lo_prev) = mo_client->get_app( mo_client->get( )-s_draft-id_prev_app ).
        result = CAST /sct/qp_if_ui_callback( lo_prev )->get_callback_event( ).
*        ms_control-client->message_box_display( `Navigate back to main App` ).
      CATCH cx_root.
    ENDTRY.

    CASE result-event.
      WHEN 'F4_BACK'.
        LOOP AT result-t_comp_params ASSIGNING FIELD-SYMBOL(<param>).

*          IF <param>-n = 'VALUE'.
          mv_value = <param>-v.
          mo_client->view_model_update( ).
*          ENDIF.
          EXIT.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
