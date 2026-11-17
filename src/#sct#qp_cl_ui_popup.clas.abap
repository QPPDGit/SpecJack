CLASS /sct/qp_cl_ui_popup DEFINITION
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

    DATA mv_data TYPE string.

    CLASS-METHODS factory IMPORTING i_title               TYPE string                       DEFAULT `Doc Viewer`
                                    i_button_text_confirm TYPE string                       DEFAULT `OK`
                                    i_button_text_cancel  TYPE string                       DEFAULT `Cancel`
                                    i_data                TYPE string                       OPTIONAL
                                    is_callback_event     TYPE /sct/au5_if_client=>ty_s_get OPTIONAL " AD, 2026.10.09, changed
                                    is_callback_cancel    TYPE /sct/au5_if_client=>ty_s_get OPTIONAL " AD, 2026.10.09, changed
                                    i_text                TYPE string                       OPTIONAL
                                    i_no_button_confirm   TYPE abap_bool                    OPTIONAL
                                    i_no_button_cancel    TYPE abap_bool                    OPTIONAL
                                    i_mime_type           TYPE string                       DEFAULT 'plain/text'
                          RETURNING VALUE(r_result)       TYPE REF TO /sct/qp_cl_ui_popup.

  PROTECTED SECTION.
    DATA client                 TYPE REF TO /sct/au5_if_client.
    DATA title                  TYPE string.
    DATA icon                   TYPE string.
    DATA question_text          TYPE string.
    DATA button_text_confirm    TYPE string.
    DATA button_text_cancel     TYPE string.
    DATA check_initialized      TYPE abap_bool.
    DATA check_result_confirmed TYPE abap_bool.
    DATA no_button_confirm      TYPE abap_bool.
    DATA no_button_cancel       TYPE abap_bool.
    DATA mimetype               TYPE string.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_POPUP IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
    me->client = client.

    IF check_initialized = abap_false.
      check_initialized = abap_true.
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get( )-event.

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
    IF /sct/qp_if_ui_callback~ms_callback-cancelled = abap_false.
      result = /sct/qp_if_ui_callback~ms_callback-s_get.
    ELSE.
      result = /sct/qp_if_ui_callback~ms_callback-s_get_cancel.
    ENDIF.
  ENDMETHOD.


  METHOD factory.
    DATA lo_text TYPE REF TO /sct/qp_cl_ui_textelement.

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = lo_text ).

    r_result = NEW #( ).
    r_result->title = i_title.
    " 033  Ok
    " 034  Abbrechen
    IF i_button_text_confirm IS SUPPLIED.
      r_result->button_text_confirm = i_button_text_confirm.
    ELSE.
      r_result->button_text_confirm = lo_text->get_text( lo_text->u033 ).
    ENDIF.
    IF i_button_text_cancel IS SUPPLIED.
      r_result->button_text_cancel = i_button_text_cancel.
    ELSE.
      r_result->button_text_cancel = lo_text->get_text( lo_text->u034 ).
    ENDIF.
    r_result->no_button_confirm = i_no_button_confirm.
    r_result->no_button_cancel  = i_no_button_cancel.
    r_result->mv_data           = i_data.
    r_result->question_text     = i_text.
    r_result->mimetype          = i_mime_type.
    r_result->/sct/qp_if_ui_callback~ms_callback-s_get        = is_callback_event.
    r_result->/sct/qp_if_ui_callback~ms_callback-s_get_cancel = is_callback_cancel.
  ENDMETHOD.


  METHOD view_display.
    " FT20251203 Für bestimmten Mimie-Tpes einfacher ohne iframe
    IF mimetype CS 'audio'.
      DATA(lv_html) = |<audio controls><source src="{ mv_data }" type="{ mimetype }"></audio>|.
    ELSEIF mimetype CS 'image'.
      lv_html = |<img width='100%' height='100%'  src="{ mv_data }" type="{ mimetype }">|.
    ELSEIF mimetype CS 'video'.
      lv_html = |<video controls width='100%' height='100%' src="{ mv_data }" type="{ mimetype }">|.
    ENDIF.

    IF lv_html IS NOT INITIAL.
      DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( )->dialog( title         = title
                                                                    icon          = icon
                                                                    resizable     = abap_true
                                                                    draggable     = abap_true
                                                                    contentwidth  = `80%`
                                                                    contentheight = `80%`
                                                                    afterclose    = client->_event( 'UI_POPUP_CANCEL' )
                                                                  )->content(
                                                                      )->vbox( 'sapUiMediumMargin'
                                                                          )->html( lv_html
                                                                  )->get_parent( )->get_parent( )->get_parent(
                                                                  )->buttons(
                                                                       )->button( text    = button_text_cancel
                                                                                  visible = xsdbool( no_button_cancel = abap_false )
                                                                                  press   = client->_event( 'UI_POPUP_CANCEL' )
                                                                       )->button( text    = button_text_confirm
                                                                                  visible = xsdbool( no_button_confirm = abap_false )
                                                                                  press   = client->_event( 'UI_POPUP_CONFIRM' )
                                                                                  type    = 'Emphasized' ).

    ELSE.
      " Für anderen Typen die dekodierung an den Browser überlassen (iframe)

      IF mv_data IS NOT INITIAL.

        popup = /sct/au5_cl_xml_view=>factory_popup( )->dialog( title         = title
                                                                icon          = icon
                                                                resizable     = abap_true
                                                                draggable     = abap_true
                                                                contentwidth  = `80%`
                                                                contentheight = `80%`
                                                                afterclose    = client->_event( 'UI_POPUP_CANCEL' )
                                                             )->content(
                                                                 )->vbox( 'sapUiMediumMargin'
                                                                 )->label( question_text
                                                                 )->_generic( ns     = `html`
                                                                              name   = `iframe`
                                                                              t_prop = VALUE #( ( n = `src`
                                                                                                  v = mv_data )
                                                                                                ( n = `height`
                                                                                                  v = `800px` )
*                                                                                                 v = `100%` )
                                                                                                ( n = `width`
*                                                                                                  v = `1600px` ) )
                                                                                                  v = `100%` ) )
                                                             )->get_parent( )->get_parent( )->get_parent(
                                                             )->buttons(
                                                                 )->button( text    = button_text_cancel
                                                                            visible = xsdbool( no_button_cancel = abap_false )
                                                                            press   = client->_event( 'UI_POPUP_CANCEL' )
                                                                 )->button( text    = button_text_confirm
                                                                            visible = xsdbool( no_button_confirm = abap_false )
                                                                            press   = client->_event( 'UI_POPUP_CONFIRM' )
                                                                            type    = 'Emphasized' ).
      ELSE.
        popup = /sct/au5_cl_xml_view=>factory_popup( )->dialog( title      = title
                                                                icon       = icon
                                                                draggable  = abap_true
                                                                afterclose = client->_event( 'UI_POPUP_CANCEL' )
                                                               )->content(
                                                                   )->vbox( 'sapUiMediumMargin'
                                                                   )->text( question_text

                                                               )->get_parent( )->get_parent(
                                                               )->buttons(
                                                                         )->button( text    = button_text_cancel
                                                                                    visible = xsdbool( no_button_cancel = abap_false )
                                                                                    press   = client->_event( 'UI_POPUP_CANCEL' )
                                                                         )->button( text    = button_text_confirm
                                                                                    visible = xsdbool( no_button_confirm = abap_false )
                                                                                    press   = client->_event( 'UI_POPUP_CONFIRM' )
                                                                                    type    = 'Emphasized' ).

      ENDIF.
    ENDIF.

    client->popup_display( popup->stringify( ) ).
  ENDMETHOD.
ENDCLASS.
