CLASS /sct/qp_cl_ui_doc DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_objtyp
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES:
      BEGIN OF ty_sel,
        mamba_sel TYPE abap_bool,
        rowid     TYPE /sct/qp_rowid,
      END OF ty_sel.
    TYPES  BEGIN OF ty_ui_data.
    TYPES:   view           TYPE string,
             download       TYPE string.
             INCLUDE TYPE /sct/qp_s_doc_data.
    TYPES:   extension_icon TYPE string,
             file_length    TYPE string,
             er_tmstp       TYPE string,
             ae_tmstp       TYPE string,
           END OF ty_ui_data.
    TYPES tty_sel     TYPE STANDARD TABLE OF ty_sel WITH DEFAULT KEY.
    TYPES tty_ui_data TYPE STANDARD TABLE OF ty_ui_data WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_sug,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF ty_sug.
    TYPES tty_sug TYPE SORTED TABLE OF ty_sug WITH UNIQUE KEY value.
    TYPES:
      BEGIN OF elem_sug,
        element TYPE string,
        sug_tab TYPE tty_sug,
      END OF elem_sug.
    TYPES tty_elem_sug TYPE STANDARD TABLE OF elem_sug WITH DEFAULT KEY.
    TYPES:
      BEGIN OF s_suggestion_items,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF s_suggestion_items.

    DATA mv_edit TYPE abap_boolean.
    DATA mt_data TYPE tty_ui_data.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp OPTIONAL.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_objtyp~check_changes   REDEFINITION.

  PROTECTED SECTION.
    DATA ms_fcat TYPE /sct/qp_s_fcat.
    DATA mo_doc  TYPE REF TO /sct/qp_if_doc.

    METHODS get_file_length IMPORTING iv_filelength TYPE i
                            RETURNING VALUE(result) TYPE string.

    METHODS do_show_document     IMPORTING iv_id TYPE string.
    METHODS do_download_document IMPORTING iv_id TYPE string.
    METHODS do_add_document.

    METHODS do_upload_document IMPORTING iv_guid     TYPE /sct/qp_guid
                                         iv_filename TYPE string
                                         iv_file     TYPE string.

    METHODS get_raw IMPORTING iv_index      TYPE int4
                    EXPORTING ev_mimetype   TYPE string
                              ev_filename   TYPE string
                    RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Baut die Toolbar auf</p>
    "! Kontextabhängig, werden unterschiedlichen Drucktasten zur Verfügung gestellt
    "! @parameter IO_VIEW | <p class="shorttext synchronized"></p>
    METHODS set_toolbar IMPORTING io_view TYPE REF TO /sct/au5_cl_xml_view.
    "! <p class="shorttext synchronized">Tabellarische Anzeige der Daten</p>
    METHODS do_show_tab.
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

    METHODS init REDEFINITION.

    METHODS get_extension_icon IMPORTING iv_extension  TYPE string
                               RETURNING VALUE(result) TYPE string.

    METHODS process_fcode_self REDEFINITION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_DOC IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~display.
    get_objtyp_data( ).
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.
    do_show_tab( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    init( ms_control-client ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
    CHECK mv_bound = abap_true.

  ENDMETHOD.


  METHOD constructor.
    super->constructor( is_obj ).
*    IF is_obj IS NOT INITIAL.
*      ms_obj = is_obj.
*    ELSE.
*      start_standalone = abap_true.
*    ENDIF.
  ENDMETHOD.


  METHOD do_show_document.
    " *********************************************************************
    " Preview in einem Popup (HTML iFrame: der Browser steuert selber wie die Anzeige aussieht)
    " *********************************************************************
    DATA(lv_index) = line_index( mt_data[ doc_id = iv_id ] ).
    IF lv_index IS INITIAL.
      RETURN.
    ENDIF.

    get_raw( EXPORTING iv_index    = lv_index
             IMPORTING ev_mimetype = DATA(lv_mimetype)
             RECEIVING result      = DATA(lv_b64_data) ).

    " Callback Event aufbereiten ( ein Redraw ist leider notwendig )
    " FT20251126 Kein Redraw mehr !
*    DATA(ls_callback_event) = VALUE /sct/au5_if_types=>ty_s_get( ).
*    ls_callback_event-event = mcu->events-show_data.
*    LOOP AT mt_def_arg ASSIGNING FIELD-SYMBOL(<arg>) TO 2.
*      INSERT <arg> INTO TABLE ls_callback_event-t_event_arg.
*    ENDLOOP.
*
** Jetzt wird was völlig anderes angezeigt beim Schließen des Popups.
*    ls_callback_event-t_event_arg[ 1 ] = '00155D076E071EDE8FB5BDC4593923FC'.
*    ls_callback_event-t_event_arg[ 2 ] = '00155D076E071EDE8FB5BDC4593A43FC'.

    DATA(lo_popup) = /sct/qp_cl_ui_popup=>factory( i_title             = |Doc Viewer ({ lv_mimetype })|
                                                   i_no_button_confirm = abap_true
                                                   i_mime_type         = lv_mimetype
                                                   i_data              = lv_b64_data ).
*                                                   is_callback_event   = ls_callback_event ).
    ms_control-client->nav_app_call( lo_popup ).
  ENDMETHOD.


  METHOD do_add_document.
    " *********************************************************************
    " Upload eines Dokumentes
    " *********************************************************************
    DATA(ls_callback_event) = VALUE /sct/au5_if_client=>ty_s_get( ). " AD, 2026.10.09, changed " event = mcu->events-show_data ). OPTIONAL
    ls_callback_event-event = 'DOC_UPLOAD'.
    INSERT LINES OF mt_def_arg INTO TABLE ls_callback_event-t_event_arg.

    DATA(lo_popupfu) = /sct/qp_cl_ui_popup_file_ul=>factory( is_callback_event = ls_callback_event ).
    ms_control-client->nav_app_call( lo_popupfu ).
  ENDMETHOD.


  METHOD do_upload_document.
    " *********************************************************************
    " Upload eines Dokumentes
    " *********************************************************************

    DATA(lv_filename) = iv_filename.
    DATA(lv_string) = iv_file.

    SPLIT lv_string AT `;` INTO DATA(lv_header) DATA(lv_data).
    " TODO: variable is assigned but never used (ABAP cleaner)
    SPLIT lv_data AT `,` INTO DATA(lv_dummy) lv_data.
    SPLIT lv_header AT `:` INTO lv_dummy DATA(lv_mimetype).

    DATA(lv_xstring) = /sct/au5_cl_util=>conv_decode_x_base64( lv_data ).

    /sct/qp_cl_doc=>convert_xstring_to_content( EXPORTING xstring    = lv_xstring
                                                IMPORTING content    = DATA(lt_content)
                                                          filelength = DATA(lv_filelength) ).

    mo_bus->change( EXPORTING is_header = VALUE #( guid = iv_guid  )
                              it_change = VALUE #( ( guid = iv_guid
                                                     bds  = VALUE #( ( description = lv_filename
                                                                       filename    = lv_filename
                                                                       mimetype    = lv_mimetype
                                                                       content     = lt_content
                                                                       filelength  = lv_filelength ) ) ) )
                    " TODO: variable is assigned but never used (ABAP cleaner)
                    IMPORTING et_return = DATA(lt_return_change)
                    " TODO: variable is assigned but never used (ABAP cleaner)
                              ev_error  = DATA(lv_error_change) ).
  ENDMETHOD.


  METHOD do_show_tab.
    " Scroll container immer at 100%
    DATA(lo_view) = ms_control-parent_view->scroll_container( width      = '100%'
                                                              horizontal = abap_true ).
    " Table width > 100% -> Scrollbar visible
    " Wenn mehr als 10 Spalten -> Scrollbar
*    DATA(lv_cnt_before_scroll) = 10.
*    DATA lv_cnt TYPE i.
*    LOOP AT ms_fcat-fieldcat TRANSPORTING NO FIELDS
*         WHERE no_out = space.
*      lv_cnt = lv_cnt + 1.
*    ENDLOOP.
*    IF lv_cnt <= lv_cnt_before_scroll.
*      DATA(lv_table_width) = |100%|.
*    ELSE.
*      lv_table_width = |{ 100 * lv_cnt DIV lv_cnt_before_scroll }%|.
*    ENDIF.
*
    DATA(lv_edit) = is_editable( ).
    "
    IF lv_edit = abap_true.
      DATA(lv_mode) = 'MultiSelect'.
    ELSE.
      CLEAR lv_mode.
    ENDIF.

    DATA(lo_table) = lo_view->table( alternaterowcolors = abap_true
                                     id                 = |TAB{ ms_node_object-objekttyp }|
                                     items              = ms_control-client->_bind( mt_data ) " Bind the table data
*                                     class              = 'sapUiNoMargin'
*                                     showseparators     = abap_true
                                     mode               = lv_mode "'MultiSelect'
*                                     fixedlayout        = abap_true
                                     autopopinmode      = abap_true
*                                     width              = lv_table_width
                                     ).

    DATA(lo_otb) = lo_table->header_toolbar( )->overflow_toolbar( ).

    lo_otb->button( icon    = 'sap-icon://add'
                    text    = 'Upload Document'
                    press   = _event( 'DOC_ADD' )
                    visible = lv_edit ).

*    set_toolbar( lo_otb ).
*
    DATA(lo_cells) = lo_table->items( )->column_list_item( " selected = '{MAMBA_SEL/BOOL}'
                                                          )->cells( ).
    "
    LOOP AT ms_fcat-fieldcat ASSIGNING FIELD-SYMBOL(<fcat>).

      CASE <fcat>-fieldname.
        WHEN 'VIEW'.
          lo_table->columns( )->column( halign     = 'Center'
                                        width      = `6em`
                                        importance = 'High'
                       )->text( text     = <fcat>-scrtext_s
                                wrapping = abap_false ).

          lo_cells->icon( src   = |\{{ <fcat>-fieldname }\}|
                          press = _event( iv_name = 'DOC_VIEW'
                                          it_arg  = VALUE #( BASE mt_def_arg
                                                             ( `${DOC_ID}` ) ) ) ).
        WHEN 'DOWNLOAD'.
          lo_table->columns( )->column( halign     = 'Center'
                                        width      = `6em`
                                        importance = 'High'
                  )->text( text     = <fcat>-scrtext_s
                           wrapping = abap_false ).

          lo_cells->icon( src   = |\{{ <fcat>-fieldname }\}|
                          press = _event( iv_name = 'DOC_DOWNLOAD'
                                          it_arg  = VALUE #( BASE mt_def_arg
                                                             ( `${DOC_ID}` ) ) ) ).
        WHEN 'EXTENSION_ICON'.

          lo_table->columns( )->column( halign     = 'Center'
                                        width      = `6em`
                                        importance = 'High'
                      )->text( text     = <fcat>-scrtext_s
                               wrapping = abap_false ).

          lo_cells->icon( src  = |\{{ <fcat>-fieldname }\}|
                          size = `1.5em` ).

        WHEN OTHERS.

          lo_table->columns( )->column( " visible = xsdbool( <fcat>-no_out = abap_false ) " sortindicator = 'None' "'Ascending' 'Descending'
                                        width      = COND #( WHEN <fcat>-fieldname = 'SPRAS'
                                                             THEN `6em`
                                                             ELSE `` )
                                        importance = COND #( WHEN <fcat>-fieldname = 'FIELDNAME'
                                                             THEN 'High'
                                                             ELSE 'None' )
*                                        styleclass = 'sapUiTinyMarginBeginEnd'
                                        styleclass = 'sapUiSizeCondensed'
                                        class      = 'sapUiSizeCondensed'
*                                        minscreenwidth = '20rem'
                      )->text( text     = <fcat>-scrtext_s
                               wrapping = abap_false ).

          lo_cells->text( text = |\{{ <fcat>-fieldname }\}|
*                          wrapping = abap_false
                          ).
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_extension_icon.
*FuGr BDS_TOOLS
*FORM get_icon_for_lv_ext USING lv_ext result.
*

    DATA(lv_ext) = to_upper( iv_extension ).
    IF lv_ext = 'PDF'.
      result = 'sap-icon://pdf-attachment'.
    ELSEIF lv_ext = 'BMP'.
      result = 'sap-icon://attachment-photo'.
*  ELSEIF lv_ext = 'FAX'.
*    result  = '@IV@'.
    ELSEIF lv_ext = 'GIF'.
      result = 'sap-icon://attachment-photo'.
*  ELSEIF lv_ext = 'HLP'.
*    result    = '@IX@'.
*  ELSEIF lv_ext = 'HTT'.
*    result   = '@IY@'.
*  ELSEIF lv_ext = 'ITS'.
*    result   = '@IZ@'.
    ELSEIF lv_ext = 'JPG'.
      result = 'sap-icon://attachment-photo'.
*  ELSEIF lv_ext = 'MSG'.
*    result  = '@J1@'.
    ELSEIF lv_ext = 'XLS' OR lv_ext = 'XLSM' OR lv_ext = 'XLSX'.
      result = 'sap-icon://excel-attachment'.
*  ELSEIF lv_ext = 'XLV'.
*    result    = '@J3@'.
    ELSEIF lv_ext = 'HTM'.
      result = 'sap-icon://attachment-html'.
    ELSEIF lv_ext = 'PPT' OR lv_ext = 'PPTM' OR lv_ext = 'PPTX'.
      result = 'sap-icon://ppt-attachment'.
*  ELSEIF lv_ext = 'DOT' or lv_ext = 'DOTM' or lv_ext = 'DOTX'.
*    result  = '@J6@'.
    ELSEIF lv_ext = 'DOC' OR lv_ext = 'DOCM' OR lv_ext = 'DOCX'.
      result = 'sap-icon://doc-attachment'.
*  ELSEIF lv_ext = 'EML'.
*    result   = '@J8@'.
    ELSEIF lv_ext = 'RTF'.
      result = 'sap-icon://attachment-text-file'.
    ELSEIF lv_ext = 'TIF'.
      result = 'sap-icon://attachment-photo'.
    ELSEIF lv_ext = 'WRI'.
      result = 'sap-icon://attachment-text-file'.
*  ELSEIF lv_ext = 'LWP'.
*    result  = '@JC@'.
*  ELSEIF lv_ext = '123'.
*    result  = '@JD@'.
    ELSEIF lv_ext = 'VSD'.
      result = 'sap-icon://vds-file'.
*  ELSEIF lv_ext = 'RAW'.
*    result   = '@AL@'.
    ELSEIF lv_ext = 'XML'.
      result = 'sap-icon://attachment-html'.
    " *********************************************************************
    " FT20250915 Neu siehe Tabelle TOADD
    ELSEIF lv_ext = 'TXT'.
      result = 'sap-icon://attachment-text-file'.
    ELSEIF lv_ext = 'PNG'.
      result = 'sap-icon://attachment-photo'.
    ELSEIF lv_ext = 'MOV' OR lv_ext = 'MPG'.
      result = 'sap-icon://attachment-video'.
    ELSEIF lv_ext = 'MP3'.
      result = 'sap-icon://attachment-audio'.

    " *********************************************************************
    ELSE.
      result = 'sap-icon://attachment'.
    ENDIF.
  ENDMETHOD.


  METHOD get_objtyp_data.
    " *********************************************************************
    " Änderungslog
    " *********************************************************************
    " FT202500915 NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    ms_fcat = mo_doc->get_fcat( ).

    mt_data = CORRESPONDING #( ms_fcat-data->* ).
    LOOP AT mt_data ASSIGNING FIELD-SYMBOL(<data>).
      <data>-extension_icon = get_extension_icon( CONV #( <data>-extension ) ).
      <data>-view           = 'sap-icon://display'.
      <data>-download       = 'sap-icon://download'.

      " Ausgabeformat für größe und Timestamp
      <data>-file_length    = get_file_length( <data>-filelength ).

      DATA(lv_tmstp) = CONV /sct/qp_value( <data>-ertmstp ).
      mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_tmstp ).
      <data>-er_tmstp = lv_tmstp.
      lv_tmstp = CONV /sct/qp_value( <data>-aetmstp ).
      mo_conv->do_convert_tstm_to_out( CHANGING cv_value = lv_tmstp ).
      <data>-ae_tmstp = lv_tmstp.
    ENDLOOP.
    " Originalspalten durch Spalten ins Anzeigeformat ersetzen
    ms_fcat-fieldcat[ fieldname = 'EXTENSIONICON' ]-fieldname = 'EXTENSION_ICON'.
    ms_fcat-fieldcat[ fieldname = 'FILELENGTH' ]-fieldname = 'FILE_LENGTH'.
    ms_fcat-fieldcat[ fieldname = 'ERTMSTP' ]-fieldname = 'ER_TMSTP'.
    ms_fcat-fieldcat[ fieldname = 'AETMSTP' ]-fieldname = 'AE_TMSTP'.

    DELETE ms_fcat-fieldcat WHERE tech IS NOT INITIAL.
    SORT ms_fcat-fieldcat BY col_pos.
    DELETE ms_fcat-fieldcat INDEX 1.

    DATA(ls_fcat_icon) = ms_fcat-fieldcat[ fieldname = 'EXTENSION_ICON' ].
    ls_fcat_icon-col_pos   = 1.
    ls_fcat_icon-scrtext_s = mutx->get_text( mutx->n099 ).
    ls_fcat_icon-fieldname = 'DOWNLOAD'.
    INSERT ls_fcat_icon INTO ms_fcat-fieldcat INDEX 1.
    ls_fcat_icon-scrtext_s = mutx->get_text( mutx->n098 ).
    ls_fcat_icon-fieldname = 'VIEW'.
    INSERT ls_fcat_icon INTO ms_fcat-fieldcat INDEX 1.
  ENDMETHOD.


  METHOD get_raw.
    " *********************************************************************
    " Preview in einem Popup (HTML iFrame: der Browser steuert selber wie die Anzeige aussieht)
    " *********************************************************************
    DATA(lr_data) = mo_doc->get_data_row( iv_index           = CONV #( iv_index )
                                          iv_include_content = abap_true ).
    IF lr_data IS NOT BOUND.
      RETURN.
    ENDIF.

    ev_mimetype = lr_data->mimetype.
    ev_filename = lr_data->filename.

    DATA(lv_xstring) = /sct/qp_cl_doc=>convert_content_to_xstring( content    = lr_data->content
                                                                   filelength = lr_data->filelength ).

    " CleanCore
    result = cl_web_http_utility=>encode_x_base64( unencoded = lv_xstring ).
*    DATA(o_base64) = NEW cl_hard_wired_encryptor( ).
*    result = o_base64->base64_encode( lv_xstring ).

    result = |data:{ lr_data->mimetype };base64,{ result }|.
  ENDMETHOD.


  METHOD init.
    ms_control-client = client.

    mo_doc ?= ms_obj-object.
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc ).
  ENDMETHOD.


  METHOD process_event.
    get_objtyp_data( ).
    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.

    CASE is_get-event.

      WHEN 'DOC_VIEW'.
        do_show_document( iv_id = is_get-t_event_arg[ 4 ] ).
      WHEN 'DOC_DOWNLOAD'.
        do_download_document( iv_id = is_get-t_event_arg[ 4 ] ).
      WHEN 'DOC_ADD'.
        do_add_document( ).
      WHEN 'DOC_UPLOAD'.
        do_upload_document( iv_guid     = CONV #( is_get-t_event_arg[ 2 ] )
                            iv_file     = is_get-t_event_arg[ 4 ]
                            iv_filename = is_get-t_event_arg[ 5 ] ).
        ms_obj-must_redraw = abap_true.
        ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-show_data
                                                                 t_event_arg = VALUE #( ( is_get-t_event_arg[ 1 ] )
                                                                                        ( is_get-t_event_arg[ 2 ] ) ) ) ).
    ENDCASE.
  ENDMETHOD.


  METHOD process_fcode_self.
    rv_processed = process_event( is_get ).
  ENDMETHOD.


  METHOD set_toolbar.
*
*    TYPES: BEGIN OF ty_button,
*             function TYPE string,
*             type     TYPE string,
*             text     TYPE string,
*             icon     TYPE string,
*             disabled TYPE abap_bool,
*             visible  TYPE abap_bool,
*           END OF ty_button.
*    DATA lt_button TYPE TABLE OF ty_button.
*
*    IF is_editable( ) = abap_true.
*      " New
*      INSERT VALUE #( function = mc->action_newline
*                      type     = ''
*                      text     = mutx->get_text( mutx->u012 ) " Neues Element
*                      icon     = |sap-icon://add-document|
*                      disabled = abap_false
*                      visible  = abap_true )
*             INTO TABLE lt_button.
*      IF ms_node_object-elementgrp_sp IS NOT INITIAL. " Nur im GRID-Modus
*        " Delete
*        INSERT VALUE #( function = mc->action_delline
*                        type     = ''
*                        text     = mutx->get_text( mutx->u013 ) " Element löschen
*                        icon     = |sap-icon://delete|
*                        disabled = abap_false
*                        visible  = abap_true )
*               INTO TABLE lt_button.
*        " Copy
*        INSERT VALUE #( function = mc->action_copyline
*                        type     = ''
*                        text     = mutx->get_text( mutx->u014 ) " Element kopieren
*                        icon     = |sap-icon://copy|
*                        disabled = abap_false
*                        visible  = abap_true )
*               INTO TABLE lt_button.
*      ENDIF.
*    ENDIF.
*    INSERT VALUE #( type = 'spacer' ) INTO TABLE lt_button.
*
*    IF  mo_mamba->ms_control-workmode      = mc->workmode_change
*    AND mo_mamba->ms_node_object-genclass IS NOT INITIAL.
*
*      " Separator
*      INSERT VALUE #( type = 'spacer' ) INTO TABLE lt_button.
*
*      " Generieren
*      INSERT VALUE #( function = mc->action_gener
*                      type     = ''
*                      text     = mutx->get_text( mutx->u017 ) " Generieren
*                      icon     = |sap-icon://da|
*                      disabled = abap_false
*                      visible  = abap_true )
*             INTO TABLE lt_button.
*
*      " Generieren mit Überschreiben
*      INSERT VALUE #( function = mc->action_generu
*                      type     = ''
*                      text     = mutx->get_text( mutx->u018 ) " Generieren mit Überschreiben
*                      icon     = |sap-icon://da-2|
*                      disabled = abap_false
*                      visible  = abap_true )
*             INTO TABLE lt_button.
*
*    ENDIF.
*
*    LOOP AT lt_button ASSIGNING FIELD-SYMBOL(<button>).
*      IF <button>-type = 'spacer'.
*        io_view->toolbar_spacer( ).
*      ELSE.
*        io_view->button( text    = <button>-text
*                         icon    = <button>-icon
*                         type    = <button>-type
*                         enabled = xsdbool( <button>-disabled = abap_false )
*                         visible = <button>-visible
*                         press   = ms_control-client->_event( val   = <button>-function
*                                                              t_arg = mt_def_arg )  )->get_parent( )->get_parent( ).
*
*      ENDIF.
*    ENDLOOP.
  ENDMETHOD.


  METHOD do_download_document.
    " *********************************************************************
    " Download am Frontend (Base64-Datei)
    " *********************************************************************
    DATA(lv_index) = line_index( mt_data[ doc_id = iv_id ] ).
    IF lv_index IS INITIAL.
      RETURN.
    ENDIF.

    get_raw( EXPORTING iv_index    = lv_index
             IMPORTING ev_filename = DATA(lv_filename)
             RECEIVING result      = DATA(lv_b64_data) ).

    ms_control-client->follow_up_action( val = ms_control-client->_event_client( val   = ms_control-client->cs_event-download_b64_file
                                                                                 t_arg = VALUE #( ( lv_b64_data )
                                                                                                  ( lv_filename ) ) ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    get_objtyp_data( ).
    _bind( iv_fieldname = |mt_data| ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
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
ENDCLASS.
