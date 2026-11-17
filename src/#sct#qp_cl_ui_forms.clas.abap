"! <p class="shorttext synchronized">UI formular</p>
CLASS /sct/qp_cl_ui_forms DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES:
      BEGIN OF ty_ui_data,
        ident   TYPE string,
        caption TYPE string.
        INCLUDE  TYPE /sct/qp_tforms_key.
        INCLUDE  TYPE /sct/qp_tforms_data.
    TYPES:
      END OF ty_ui_data.
    TYPES tty_ui_data TYPE STANDARD TABLE OF ty_ui_data WITH DEFAULT KEY.

    DATA mt_data         TYPE tty_ui_data.
    DATA ms_data         TYPE ty_ui_data.
    DATA mv_selected_key TYPE string.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_objtyp~check_changes   REDEFINITION.

  PROTECTED SECTION.
    DATA mo_forms TYPE REF TO /sct/qp_if_forms.

    METHODS get_file_length IMPORTING iv_filelength TYPE i
                            RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Display document preview</p>
    METHODS do_show_document     IMPORTING is_form TYPE ty_ui_data.
    METHODS do_download_document IMPORTING iv_id   TYPE string.

    METHODS get_raw IMPORTING is_form       TYPE ty_ui_data
                    RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">display data</p>
    METHODS do_show_data.
    "! <p class="shorttext synchronized">display data</p>
    METHODS do_show_data2.
    "! <p class="shorttext synchronized">Objektypdaten laden/aufbereiten</p>
    "!
    "! @parameter IV_INIT | <p class="shorttext synchronized"></p>
    METHODS get_objtyp_data IMPORTING iv_init TYPE abap_bool OPTIONAL.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter IS_GET       | <p class="shorttext synchronized"></p>
    "! @parameter RV_PROCESSED | <p class="shorttext synchronized"></p>
    METHODS process_event IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get  " AD, 2026.10.09, changed
                          RETURNING VALUE(rv_processed) TYPE abap_bool.

    METHODS process_fcode_self REDEFINITION.

    METHODS init               REDEFINITION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_FORMS IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    get_objtyp_data( ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.
*    IF sy-uname = 'TROMFRA'.
    do_show_data2( ).
*    ELSE.
*    do_show_data( ).
*    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    init( ms_control-client ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
    IF mv_bound = abap_false.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( is_obj ).
*    IF is_obj IS NOT INITIAL.
*      ms_obj = is_obj.
*    ELSE.
*      start_standalone = abap_true.
*    ENDIF.
  ENDMETHOD.


  METHOD do_download_document.
    " *********************************************************************
    " Download am Frontend (Base64-Datei)
    " *********************************************************************
*    DATA(lv_index) = CONV numc10( line_index( mt_data[ doc_id = iv_id ] ) ).
*    IF lv_index IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    get_raw( EXPORTING iv_index    = lv_index
*             IMPORTING ev_filename = DATA(lv_filename)
*             RECEIVING result      = DATA(lv_b64_data) ).
*
*    ms_control-client->follow_up_action( val = ms_control-client->_event_client( val   = ms_control-client->cs_event-download_b64_file
*                                                                                 t_arg = VALUE #( ( lv_b64_data )
*                                                                                                  ( lv_filename ) ) ) ).
  ENDMETHOD.


  METHOD do_show_data.
    DATA(lo_hbox) = ms_control-parent_view->hbox( alignitems = 'Center' ).
    lo_hbox->select( selectedkey = _bind( iv_fieldname = |mv_selected_key|  )
                     items       = _bind( iv_fieldname = |mt_data| )
                     change      = _event( iv_name = 'SEL_CHANGE'
                                           it_arg  = VALUE #( BASE mt_def_arg
                                                              ( `${$parameters>/selectedItem/mProperties/key}` ) ) )
                                  )->item( key  = '{IDENT}'
                                           text = '{CAPTION}' ).

    lo_hbox->button( " text    = <spras>-laiso
                     class   = `sapUiTinyMargin`
                     icon    = `sap-icon://show`
                     press   = _event( iv_name = 'FORM_DISPLAY'
                                       it_arg  = mt_def_arg )
                     tooltip = 'display document' ).
*    ->get_parent( )->get_parent( ).

*    do_show_document( is_form = VALUE #( spras = ms_spras-spras
*                                         ident = mt_data[ standard = abap_true ]-ident ) ).
  ENDMETHOD.


  METHOD do_show_data2.
    DATA(lo_table) = ms_control-parent_view->table( alternaterowcolors = abap_true
                                                    id                 = |TAB{ ms_node_object-objekttyp }|
                                                    items              = _bind( iv_fieldname = |mt_data| ) ). " Bind the table data

    DATA(lo_cells) = lo_table->items( )->column_list_item( )->cells( ).

    lo_table->columns( )->column( class = 'sapUiSizeCondensed' ).
*                ->text( text     = ms_node_object-objekttyptext
*                         wrapping = abap_false ).

    lo_cells->text( '{CAPTION}' ).

    lo_table->columns( )->column( class = 'sapUiSizeCondensed' ).

    lo_cells->button( icon    = `sap-icon://show`
                      press   = _event( iv_name = 'FORM_DISPLAY'
                                        it_arg  = VALUE #( BASE mt_def_arg
                                                           ( `${IDENT}` ) ) )
                      tooltip = 'display document' ).
  ENDMETHOD.


  METHOD do_show_document.
    " *********************************************************************
    " Preview in einem Popup (HTML iFrame: der Browser steuert selber wie die Anzeige aussieht)
    " *********************************************************************

*    DATA(lv_index) = CONV numc10( line_index( mt_data[ doc_id = iv_id ] ) ).
*    IF lv_index IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    get_raw( EXPORTING iv_index    = lv_index
*             IMPORTING ev_mimetype = DATA(lv_mimetype)
*             RECEIVING result      = DATA(lv_b64_data) ).
*
*    " Callback Event aufbereiten ( ein Redraw ist leider notwendig )
*    " FT20251126 Kein Redraw mehr !
**    DATA(ls_callback_event) = VALUE /sct/au5_if_types=>ty_s_get( ).
**    ls_callback_event-event = mcu->events-show_data.
**    LOOP AT mt_def_arg ASSIGNING FIELD-SYMBOL(<arg>) TO 2.
**      INSERT <arg> INTO TABLE ls_callback_event-t_event_arg.
**    ENDLOOP.
**
*** Jetzt wird was völlig anderes angezeigt beim Schließen des Popups.
**    ls_callback_event-t_event_arg[ 1 ] = '00155D076E071EDE8FB5BDC4593923FC'.
**    ls_callback_event-t_event_arg[ 2 ] = '00155D076E071EDE8FB5BDC4593A43FC'.
*
    DATA(lo_popup) = /sct/qp_cl_ui_popup=>factory( " i_title             = |Doc Viewer ({ lv_mimetype })|
                                                   i_no_button_confirm = abap_true
*                                                   i_mime_type         = lv_mimetype
                                                   i_data              = get_raw( is_form ) ).
*                                                   is_callback_event   = ls_callback_event ).
    ms_control-client->nav_app_call( lo_popup ).

*    ms_control-parent_view->_generic( ns     = `html`
*                                      name   = `iframe`
*                                      t_prop = VALUE #( ( n = `src`
*                                                          v = get_raw( is_form ) )
*                                                        ( n = `height`
**                                                                                                  v = `800px` )
*                                                         v = `800px` )
*                                                        ( n = `width`
**                                                                                                  v = `1600px` ) )
*                                                          v = `100%` ) ) ).
  ENDMETHOD.


  METHOD get_file_length.
    DATA size TYPE p LENGTH 8 DECIMALS 2.

    DATA(prefix) = VALUE i( ).
    size = iv_filelength.
    DO.
      IF size > 1025.
        prefix += 1.
        size /= 1024.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

    CASE prefix.
      WHEN 0.
        DATA(lv_multiple) = ``.
      WHEN 1.
        lv_multiple = 'K'.
      WHEN 2.
        lv_multiple = 'M'.
      WHEN 3.
        lv_multiple = 'G'.
      WHEN 4.
        lv_multiple = 'T'.
    ENDCASE.

    result = |{ size } { lv_multiple }B|.
  ENDMETHOD.


  METHOD get_objtyp_data.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT20260302 angelegt
    " --------------------------------------------------------------------*

    CLEAR mt_data.
    DATA(lt_forms) = mo_forms->get_forms( ).

    LOOP AT lt_forms INTO DATA(lr_form).
      lr_form->o_forms->modify_forms( EXPORTING ir_form  = lr_form
                                      CHANGING  ct_forms = mo_forms->mt_forms ).
    ENDLOOP.

    LOOP AT mo_forms->mt_forms ASSIGNING FIELD-SYMBOL(<form>).

      INSERT CORRESPONDING #( <form> ) INTO TABLE mt_data ASSIGNING FIELD-SYMBOL(<data>).
      IF <data>-caption IS INITIAL.
        <data>-caption = <data>-ident.
      ENDIF.
    ENDLOOP.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(a) = mv_selected_key.
    ms_data = CORRESPONDING #( mo_forms->mr_form->* ).
    ms_data-caption = ms_data-ident.
  ENDMETHOD.


  METHOD get_raw.
*    " *********************************************************************
*    " Document Preview
*    " *********************************************************************

*    DATA(o_base64) = NEW cl_hard_wired_encryptor( ).

    TRY.
        DATA(lr_form) = REF #( mo_forms->mt_forms[ ident = is_form-ident ] ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    IF lr_form->sfname IS NOT INITIAL.

      DATA(ls_smartforms) = mo_forms->mr_form->o_forms->do_generate_smartform( is_form = lr_form->* ).
      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA mv_pdf_size TYPE i.
      DATA mt_pdf_data TYPE TABLE OF mmpur_outline_tline. " text_line_tab.
*      TYPES pdf_uc_line_t TYPE x LENGTH 268.
*      DATA lt_pdf_uc_data        TYPE STANDARD TABLE OF pdf_uc_line_t.
*      DATA l_cline               TYPE c LENGTH 134.
*      DATA l_ind_unicode_system  TYPE c LENGTH 1 VALUE IS INITIAL.
*      DATA l_charlength_bytemode TYPE i.
*      FIELD-SYMBOLS <l_xline> TYPE x.
      DATA(lv_xstring) = VALUE xstring( ).

      CLEAR mv_pdf_size.
      CALL FUNCTION 'CONVERT_OTF' EXPORTING  format                = 'PDF'
                                  IMPORTING  bin_filesize          = mv_pdf_size
                                             bin_file              = lv_xstring
                                  TABLES     otf                   = ls_smartforms-otfdata
                                             lines                 = mt_pdf_data
                                  EXCEPTIONS err_max_linewidth     = 1
                                             err_format            = 2
                                             err_conv_not_possible = 3
                                             OTHERS                = 4.

      IF sy-subrc <> 0.
        mx->do_handle_internal_error( ).
      ENDIF.
* CleanCore
*      result = o_base64->base64_encode( lv_xstring ).
      result = cl_web_http_utility=>encode_x_base64( unencoded = lv_xstring ).
    ENDIF.

    IF is_form-afname IS NOT INITIAL.
      DATA(ls_adobe) = mo_forms->mr_form->o_forms->do_generate_adobeform( is_form = lr_form->* ).
* CleanCore
*      result = o_base64->base64_encode( ls_adobe-pdf ).
      result = cl_web_http_utility=>encode_x_base64( unencoded = ls_adobe-pdf ).

    ENDIF.

    result = |data:application/pdf;base64,{ result }|.
  ENDMETHOD.


  METHOD init.
    ms_control-client = client.

    mo_forms ?= ms_obj-object.
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc
*                                                 eo_conv  = mo_conv
*                                                 eo_fcat  = mo_fcat
                                                ).
  ENDMETHOD.


  METHOD process_event.
    get_objtyp_data( ).
    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.

    CASE is_get-event.
      WHEN 'SEL_CHANGE'.
        mv_selected_key = is_get-t_event_arg[ 4 ].
        ms_data-ident = is_get-t_event_arg[ 4 ].
        mo_forms->mr_form = REF #( mo_forms->mt_forms[ ident = ms_data-ident ] ).

      WHEN 'FORM_DISPLAY'.

        do_show_document( is_form = VALUE #( ident = is_get-t_event_arg[ 4 ] ) ).

    ENDCASE.
  ENDMETHOD.


  METHOD process_fcode_self.
    rv_processed = process_event( is_get ).
  ENDMETHOD.
ENDCLASS.
