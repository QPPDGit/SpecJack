CLASS /sct/qp_cl_ui_popup_file_ul DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/au5_if_app.
    INTERFACES /sct/qp_if_ui_callback.

    TYPES:
      BEGIN OF ty_s_result,
        value           TYPE string,
        check_confirmed TYPE abap_bool,
      END OF ty_s_result.

    DATA ms_result             TYPE ty_s_result.
    DATA mv_path               TYPE string.
    DATA mv_value              TYPE string.
    DATA check_confirm_enabled TYPE abap_bool.
    DATA mv_data               TYPE string.

    CLASS-METHODS factory IMPORTING i_text                TYPE string                       DEFAULT `Choose the file to upload:`
                                    i_title               TYPE string                       DEFAULT `File Upload`
                                    i_button_text_confirm TYPE string                       DEFAULT `OK`
                                    i_button_text_cancel  TYPE string                       DEFAULT `Cancel`
                                    i_data                TYPE string                       OPTIONAL
                                    i_path                TYPE string                       OPTIONAL
                                    is_callback_event     TYPE /sct/au5_if_client=>ty_s_get OPTIONAL " AD, 2026.10.09, changed
                          RETURNING VALUE(r_result)       TYPE REF TO /sct/qp_cl_ui_popup_file_ul.

    METHODS result RETURNING VALUE(result) TYPE ty_s_result.

  PROTECTED SECTION.
    DATA client                 TYPE REF TO /sct/au5_if_client.
    DATA title                  TYPE string.
    DATA icon                   TYPE string.
    DATA question_text          TYPE string.
    DATA button_text_confirm    TYPE string.
    DATA button_text_cancel     TYPE string.
    DATA check_initialized      TYPE abap_bool.
    DATA check_result_confirmed TYPE abap_bool.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_POPUP_FILE_UL IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
    me->client = client.

    IF check_initialized = abap_false.
      check_initialized = abap_true.
      view_display( ).
      RETURN.
    ENDIF.

    CASE client->get( )-event.

      WHEN `UPLOAD`.
        DATA lv_xstring TYPE xstring.
        " mv_path hat den filename fürs bds
        SPLIT mv_value AT `;` INTO DATA(lv_dummy) DATA(lv_data).
        SPLIT lv_data AT `,` INTO lv_dummy lv_data.
        INSERT mv_value INTO TABLE /sct/qp_if_ui_callback~ms_callback-s_get-t_event_arg.
        INSERT mv_path INTO TABLE /sct/qp_if_ui_callback~ms_callback-s_get-t_event_arg.

        lv_xstring = /sct/au5_cl_util=>conv_decode_x_base64( lv_data ).
*        ms_result-value = /sct/au5_cl_util=>conv_get_string_by_xstring( lv_xstring ).

        /sct/qp_if_ui_callback~ms_callback-xstring = lv_xstring.

*        /sct/qp_cl_doc=>convert_xstring_to_content( EXPORTING xstring    = lv_xstring
*                                                    " TODO: variable is assigned but never used (ABAP cleaner)
*                                                    IMPORTING content    = DATA(lt_content)
*                                                    " TODO: variable is assigned but never used (ABAP cleaner)
*                                                              filelength = DATA(lv_filelength) ).
        check_confirm_enabled = abap_true.

        CLEAR mv_value.
        CLEAR mv_path.
        client->popup_model_update( ).

      WHEN `BUTTON_CONFIRM`.
        ms_result-check_confirmed = abap_true.
        client->popup_destroy( ).
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).
      WHEN `BUTTON_CANCEL`.
        /sct/qp_if_ui_callback~ms_callback-cancelled = abap_true.
        client->popup_destroy( ).
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_callback~get_callback_event.
    IF /sct/qp_if_ui_callback~ms_callback-cancelled = abap_false.
      result = /sct/qp_if_ui_callback~ms_callback-s_get.
    ENDIF.
  ENDMETHOD.


  METHOD result.
    result = ms_result.
  ENDMETHOD.


  METHOD factory.
    r_result = NEW #( ).
    r_result->title               = i_title.
    r_result->question_text       = i_text.
    r_result->button_text_confirm = i_button_text_confirm.
    r_result->button_text_cancel  = i_button_text_cancel.
    r_result->mv_path             = i_path.
    r_result->mv_data             = i_data.
    r_result->/sct/qp_if_ui_callback~ms_callback-s_get = is_callback_event.
  ENDMETHOD.


  METHOD view_display.
    DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( )->dialog( title      = title
                                                                  icon       = icon
                                                                  afterclose = client->_event( 'BUTTON_CANCEL' )
              )->content(
                  )->vbox( 'sapUiMediumMargin'
                  )->label( question_text
                  )->_sctau5( )->file_uploader( value       = client->_bind( mv_value )
                                                path        = client->_bind( mv_path )
                                                placeholder = 'filepath here...'
                                                upload      = client->_event( 'UPLOAD' )
              )->get_parent( )->get_parent(
              )->buttons(
                  )->button( text  = button_text_cancel
                             press = client->_event( 'BUTTON_CANCEL' )
                  )->button( text    = button_text_confirm
                             press   = client->_event( 'BUTTON_CONFIRM' )
                             enabled = client->_bind( check_confirm_enabled )
                             type    = 'Emphasized' ).

    client->popup_display( popup->stringify( ) ).
  ENDMETHOD.
ENDCLASS.
